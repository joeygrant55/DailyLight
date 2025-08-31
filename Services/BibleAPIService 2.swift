import Foundation

// Bible API Response Models
struct BibleVersionsResponse: Codable {
    let data: [BibleVersion]
}

struct BibleVersion: Codable, Identifiable {
    let id: String
    let dblId: String?
    let abbreviation: String
    let name: String
    let language: Language
    let type: String?
    let updatedAt: String?
    
    struct Language: Codable {
        let id: String
        let name: String
    }
}

struct PassageResponse: Codable {
    let data: PassageData
}

struct PassageData: Codable {
    let id: String
    let orgId: String?
    let bibleId: String
    let bookId: String?
    let chapterIds: [String]?
    let content: String
    let reference: String
    let verseCount: Int?
    let copyright: String?
}

struct BooksResponse: Codable {
    let data: [BibleBook]
}

struct BibleBook: Codable, Identifiable {
    let id: String
    let bibleId: String
    let abbreviation: String
    let name: String
    let nameLong: String
}

// Main Bible API Service
class BibleAPIService: ObservableObject {
    static let shared = BibleAPIService()
    
    private let apiKey = APIConfig.bibleAPIKey
    private let baseURL = APIConfig.bibleAPIEndpoint
    private let session = URLSession.shared
    
    // Cached Bible versions and books for offline use
    @Published var availableVersions: [BibleVersion] = []
    @Published var currentBibleId = "de4e12af7f28f599-02" // World English Bible as default, will be updated to RSV if available
    @Published var currentVersionName = "World English Bible"
    @Published var isLoading = false
    
    private init() {
        Task {
            await loadBibleVersions()
        }
    }
    
    // MARK: - Public API Methods
    
    /// Fetch scripture passage by reference (e.g., "JHN.3.16", "MAT.5.3-12")
    func fetchScriptureText(reference: String, bibleId: String? = nil) async throws -> String {
        let bible = bibleId ?? currentBibleId
        let url = URL(string: "\(baseURL)/bibles/\(bible)/passages/\(reference)")!
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "api-key") // Correct header name from docs
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            if let httpResponse = response as? HTTPURLResponse {
                print("❌ API Error: \(httpResponse.statusCode)")
            }
            if let errorData = String(data: data, encoding: .utf8) {
                print("❌ Error Response: \(errorData)")
            }
            throw BibleAPIError.invalidResponse
        }
        
        let passageResponse = try JSONDecoder().decode(PassageResponse.self, from: data)
        return cleanHTML(passageResponse.data.content)
    }
    
    /// Fetch a complete Verse object with metadata
    func fetchVerse(reference: String, bibleId: String? = nil) async throws -> Verse {
        let content = try await fetchScriptureText(reference: reference, bibleId: bibleId)
        let parsedRef = parseReference(reference)
        
        return Verse(
            text: content,
            reference: formatReference(parsedRef),
            bookName: parsedRef.bookName,
            chapter: parsedRef.chapter,
            verseNumber: parsedRef.verse
        )
    }
    
    /// Fetch multiple verses for a reading
    func fetchReading(title: String, subtitle: String, references: [String], theme: String, bibleId: String? = nil) async throws -> Reading {
        var verses: [Verse] = []
        var combinedText = ""
        
        for ref in references {
            do {
                let verse = try await fetchVerse(reference: ref, bibleId: bibleId)
                verses.append(verse)
                if !combinedText.isEmpty {
                    combinedText += " "
                }
                combinedText += verse.text
            } catch {
                print("Failed to fetch verse \(ref): \(error)")
                // Continue with other verses even if one fails
            }
        }
        
        // If we got verses, create a combined reading
        if !verses.isEmpty {
            // Create a single verse with combined text for better display
            let firstVerse = verses[0]
            let combinedVerse = Verse(
                text: combinedText,
                reference: "\(firstVerse.bookName) \(firstVerse.chapter):\(firstVerse.verseNumber)+",
                bookName: firstVerse.bookName,
                chapter: firstVerse.chapter,
                verseNumber: firstVerse.verseNumber
            )
            
            return Reading(
                title: title,
                subtitle: subtitle,
                verses: [combinedVerse],
                theme: theme,
                liturgicalContext: subtitle
            )
        } else {
            // Fallback to empty reading if all failed
            return Reading(
                title: title,
                subtitle: subtitle,
                verses: [],
                theme: theme,
                liturgicalContext: subtitle
            )
        }
    }
    
    /// Load available Bible versions
    func loadBibleVersions() async {
        guard let url = URL(string: "\(baseURL)/bibles") else { return }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "api-key") // Correct header name from docs
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, _) = try await session.data(for: request)
            let versionsResponse = try JSONDecoder().decode(BibleVersionsResponse.self, from: data)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.availableVersions = versionsResponse.data
                print("📖 Loaded \(self.availableVersions.count) Bible versions")
                
                // Debug: Show available RSV/NRSV versions
                let rsvVersions = versionsResponse.data.filter { 
                    $0.name.lowercased().contains("revised standard") || 
                    $0.abbreviation.lowercased().contains("rsv") ||
                    $0.abbreviation.lowercased().contains("nrsv")
                }
                print("📖 Available RSV/NRSV versions:")
                for version in rsvVersions {
                    print("   - \(version.name) (\(version.abbreviation)) ID: \(version.id)")
                }
                
                // Try to find a Catholic-friendly version
                self.selectBestCatholicVersion()
            }
        } catch {
            print("❌ Failed to load Bible versions: \(error)")
        }
    }
    
    /// Search for passages containing specific keywords
    func searchScripture(query: String, bibleId: String? = nil) async throws -> [String] {
        // Note: Search functionality may require different API endpoint
        // For now, return empty array as placeholder
        return []
    }
    
    /// Manually set the Bible version to RSV if available
    func selectRSV() {
        // Look specifically for RSV versions
        let rsvVersions = availableVersions.filter { version in
            let name = version.name.lowercased()
            let abbr = version.abbreviation.lowercased()
            return name.contains("revised standard") || abbr.contains("rsv")
        }
        
        if let rsv = rsvVersions.first {
            currentBibleId = rsv.id
            currentVersionName = rsv.name
            print("✅ Manually selected RSV: \(rsv.name) (\(rsv.abbreviation)) - ID: \(rsv.id)")
        } else {
            print("⚠️ No RSV version found in available translations")
            // Print available versions for debugging
            print("Available versions:")
            for version in availableVersions.prefix(10) {
                print("   - \(version.name) (\(version.abbreviation))")
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func selectBestCatholicVersion() {
        // Look for Catholic-friendly translations in order of preference
        // Prioritizing RSV (Revised Standard Version) as requested
        let preferredVersions = [
            "revised standard version", "rsv-ce", "rsv", 
            "new revised standard version", "nrsv-ce", "nrsv",
            "nabre", "douay", "catholic", "nab",
            "world english bible", "web", "american standard"
        ]
        
        for preferred in preferredVersions {
            if let version = availableVersions.first(where: { 
                $0.name.lowercased().contains(preferred) || 
                $0.abbreviation.lowercased().contains(preferred) 
            }) {
                currentBibleId = version.id
                currentVersionName = version.name
                print("✅ Selected Bible version: \(version.name) (\(version.abbreviation)) - ID: \(version.id)")
                return
            }
        }
        
        print("📖 Using default Bible version: \(currentVersionName)")
    }
    
    private func cleanHTML(_ html: String) -> String {
        // Remove HTML tags and decode entities
        let withoutTags = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return withoutTags
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseReference(_ reference: String) -> (bookName: String, chapter: Int, verse: Int) {
        // Parse references like "JHN.3.16" or "MAT.5.3"
        let components = reference.split(separator: ".")
        guard components.count >= 3 else {
            return ("Unknown", 1, 1)
        }
        
        let bookCode = String(components[0])
        let chapter = Int(components[1]) ?? 1
        let verse = Int(components[2]) ?? 1
        
        let bookName = bookCodeToName(bookCode)
        return (bookName, chapter, verse)
    }
    
    private func bookCodeToName(_ code: String) -> String {
        let bookMap = [
            "GEN": "Genesis", "EXO": "Exodus", "LEV": "Leviticus", "NUM": "Numbers", "DEU": "Deuteronomy",
            "JOS": "Joshua", "JDG": "Judges", "RUT": "Ruth", "1SA": "1 Samuel", "2SA": "2 Samuel",
            "1KI": "1 Kings", "2KI": "2 Kings", "1CH": "1 Chronicles", "2CH": "2 Chronicles",
            "EZR": "Ezra", "NEH": "Nehemiah", "EST": "Esther", "JOB": "Job", "PSA": "Psalms",
            "PRO": "Proverbs", "ECC": "Ecclesiastes", "SNG": "Song of Songs", "ISA": "Isaiah",
            "JER": "Jeremiah", "LAM": "Lamentations", "EZK": "Ezekiel", "DAN": "Daniel",
            "HOS": "Hosea", "JOL": "Joel", "AMO": "Amos", "OBA": "Obadiah", "JON": "Jonah",
            "MIC": "Micah", "NAM": "Nahum", "HAB": "Habakkuk", "ZEP": "Zephaniah", "HAG": "Haggai",
            "ZEC": "Zechariah", "MAL": "Malachi",
            "MAT": "Matthew", "MRK": "Mark", "LUK": "Luke", "JHN": "John", "ACT": "Acts",
            "ROM": "Romans", "1CO": "1 Corinthians", "2CO": "2 Corinthians", "GAL": "Galatians",
            "EPH": "Ephesians", "PHP": "Philippians", "COL": "Colossians", "1TH": "1 Thessalonians",
            "2TH": "2 Thessalonians", "1TI": "1 Timothy", "2TI": "2 Timothy", "TIT": "Titus",
            "PHM": "Philemon", "HEB": "Hebrews", "JAS": "James", "1PE": "1 Peter", "2PE": "2 Peter",
            "1JN": "1 John", "2JN": "2 John", "3JN": "3 John", "JUD": "Jude", "REV": "Revelation"
        ]
        
        return bookMap[code.uppercased()] ?? code
    }
    
    private func formatReference(_ parsed: (bookName: String, chapter: Int, verse: Int)) -> String {
        return "\(parsed.bookName) \(parsed.chapter):\(parsed.verse)"
    }
}

enum BibleAPIError: Error {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError
    case networkError(Error)
}