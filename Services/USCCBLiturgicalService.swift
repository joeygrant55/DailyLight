import Foundation
import SwiftUI

// USCCB Liturgical Data Models
struct LiturgicalDay: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let season: LiturgicalSeason
    let color: LiturgicalColor
    let rank: LiturgicalRank
    let readings: MassReadings
    let commemorations: [String]
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

struct MassReadings {
    let lectionary: String
    let firstReading: Reading?
    let responsorialPsalm: Reading?
    let alleluia: Reading?
    let gospel: Reading
    let secondReading: Reading? // For Sundays
    
    var allReadings: [Reading] {
        return [firstReading, responsorialPsalm, alleluia, secondReading, gospel].compactMap { $0 }
    }
}

enum LiturgicalSeason: String, CaseIterable {
    case advent = "Advent"
    case christmasTime = "Christmas Time"
    case lent = "Lent"
    case easterTime = "Easter Time"
    case ordinaryTime = "Ordinary Time"
    
    var displayName: String { rawValue }
    
    var themeDescription: String {
        switch self {
        case .advent:
            return "Preparation and expectation for Christ's coming"
        case .christmasTime:
            return "Celebration of the Incarnation"
        case .lent:
            return "Penance, prayer, and preparation for Easter"
        case .easterTime:
            return "Celebration of Christ's Resurrection"
        case .ordinaryTime:
            return "Growth in Christian discipleship"
        }
    }
    
    var artTheme: String {
        switch self {
        case .advent:
            return "expectation, hope, Mary and Joseph, purple tones, candlelight"
        case .christmasTime:
            return "nativity, angels, shepherds, gold and white, joy, celebration"
        case .lent:
            return "desert, cross, purple tones, penance, solitude, reflection"
        case .easterTime:
            return "resurrection, empty tomb, white and gold, alleluia, new life"
        case .ordinaryTime:
            return "teaching, parables, green tones, daily Christian life"
        }
    }
}

enum LiturgicalColor: String, CaseIterable {
    case white = "White"
    case red = "Red"
    case green = "Green"
    case violet = "Violet"
    case rose = "Rose"
    case gold = "Gold"
    case black = "Black"
    
    var swiftUIColor: Color {
        switch self {
        case .white: return .white
        case .red: return .red
        case .green: return .green
        case .violet: return .purple
        case .rose: return .pink
        case .gold: return .yellow
        case .black: return .black
        }
    }
}

enum LiturgicalRank: String, CaseIterable {
    case solemnity = "Solemnity"
    case feast = "Feast"
    case memorial = "Memorial"
    case optionalMemorial = "Optional Memorial"
    case ferial = "Ferial"
    
    var priority: Int {
        switch self {
        case .solemnity: return 1
        case .feast: return 2
        case .memorial: return 3
        case .optionalMemorial: return 4
        case .ferial: return 5
        }
    }
}

// USCCB RSS Feed Models
struct USCCBRSSFeed: Codable {
    let items: [USCCBRSSItem]
}

struct USCCBRSSItem: Codable {
    let title: String
    let link: String
    let description: String
    let pubDate: String
    let guid: String
}

// Main USCCB Liturgical Service
class USCCBLiturgicalService: ObservableObject {
    static let shared = USCCBLiturgicalService()
    
    @Published var todaysLiturgy: LiturgicalDay?
    @Published var isLoading = false
    @Published var error: String?
    
    private let rssURL = "https://bible.usccb.org/readings.rss"
    private let session = URLSession.shared
    private let bibleAPI = BibleAPIService.shared
    
    private init() {
        Task {
            await loadTodaysLiturgy()
        }
    }
    
    // MARK: - Public API
    
    /// Load today's liturgical day with Mass readings
    func loadTodaysLiturgy() async {
        await MainActor.run { isLoading = true }
        
        do {
            let liturgicalDay = try await fetchTodaysLiturgy()
            
            await MainActor.run {
                self.todaysLiturgy = liturgicalDay
                self.isLoading = false
                self.error = nil
                print("⛪ Successfully loaded today's liturgy: \(liturgicalDay.title)")
            }
            
        } catch {
            await MainActor.run {
                self.error = "Failed to load liturgical data: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ Liturgical service error: \(error)")
            }
        }
    }
    
    /// Get readings for a specific date
    func getLiturgyFor(date: Date) async throws -> LiturgicalDay {
        // For now, only today is implemented
        // Future: Parse RSS feed for specific dates or use historical data
        return try await fetchTodaysLiturgy()
    }
    
    /// Get current liturgical season
    func getCurrentSeason() -> LiturgicalSeason {
        return determineLiturgicalSeason(for: Date())
    }
    
    // MARK: - Private Implementation
    
    private func fetchTodaysLiturgy() async throws -> LiturgicalDay {
        // Fetch RSS feed
        guard let url = URL(string: rssURL) else {
            throw USCCBError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        
        // Parse RSS XML
        let rssItem = try parseRSSForToday(data)
        
        // Extract readings from description
        let readings = try parseReadingsFromDescription(rssItem.description)
        
        // Determine liturgical context
        let season = determineLiturgicalSeason(for: Date())
        let color = determineLiturgicalColor(for: rssItem.title, season: season)
        let rank = determineLiturgicalRank(from: rssItem.title)
        
        let liturgicalDay = LiturgicalDay(
            date: Date(),
            title: rssItem.title,
            season: season,
            color: color,
            rank: rank,
            readings: readings,
            commemorations: extractCommemorations(from: rssItem.title)
        )
        
        // Check if today's saint aligns with liturgical celebration
        if let todaysSaint = SaintService.shared.getTodaysSaint() {
            if todaysSaint.alignsWithLiturgicalDay(liturgicalDay) {
                print("⛪ Saint alignment: \(todaysSaint.name) aligns with today's liturgy")
            }
        }
        
        return liturgicalDay
    }
    
    private func parseRSSForToday(_ data: Data) throws -> USCCBRSSItem {
        // Simple XML parsing for RSS
        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw USCCBError.parsingError
        }
        
        // More flexible parsing - look for basic item structure
        guard let itemStart = xmlString.range(of: "<item>"),
              let itemEnd = xmlString.range(of: "</item>", range: itemStart.upperBound..<xmlString.endIndex) else {
            throw USCCBError.parsingError
        }
        
        let itemContent = String(xmlString[itemStart.upperBound..<itemEnd.lowerBound])
        
        // Extract title
        let title = extractXMLValue(from: itemContent, tag: "title") ?? "Today's Reading"
        
        // Extract link
        let link = extractXMLValue(from: itemContent, tag: "link") ?? ""
        
        // Extract description
        let description = extractXMLValue(from: itemContent, tag: "description") ?? ""
        
        // Extract pubDate
        let pubDate = extractXMLValue(from: itemContent, tag: "pubDate") ?? ""
        
        // Extract guid
        let guid = extractXMLValue(from: itemContent, tag: "guid") ?? ""
        
        return USCCBRSSItem(title: title, link: link, description: description, pubDate: pubDate, guid: guid)
    }
    
    private func extractXMLValue(from content: String, tag: String) -> String? {
        // Handle both CDATA and regular content
        let cdataPattern = "<\(tag)(?:[^>]*)><!\\[CDATA\\[(.*?)\\]\\]></\(tag)>"
        let regularPattern = "<\(tag)(?:[^>]*)>(.*?)</\(tag)>"
        
        // Try CDATA first
        if content.range(of: cdataPattern, options: .regularExpression) != nil {
            let regex = try? NSRegularExpression(pattern: cdataPattern, options: [.dotMatchesLineSeparators])
            if let match = regex?.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)),
               match.numberOfRanges > 1,
               let valueRange = Range(match.range(at: 1), in: content) {
                return String(content[valueRange])
            }
        }
        
        // Try regular content
        let regex = try? NSRegularExpression(pattern: regularPattern, options: [.dotMatchesLineSeparators])
        if let match = regex?.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)),
           match.numberOfRanges > 1,
           let valueRange = Range(match.range(at: 1), in: content) {
            return String(content[valueRange])
        }
        
        return nil
    }
    
    private func parseReadingsFromDescription(_ description: String) throws -> MassReadings {
        // Parse the HTML description to extract readings
        var firstReading: Reading?
        var psalm: Reading?
        var alleluia: Reading?
        var gospel: Reading?
        
        // Enhanced parsing for different reading types
        
        // First Reading
        let firstReadingPatterns = [
            #"Reading 1</strong><br />(.*?)(?=<strong>|$)"#,
            #"First Reading</strong><br />(.*?)(?=<strong>|$)"#,
            #"<strong>Reading I</strong>(.*?)(?=<strong>|$)"#
        ]
        
        for pattern in firstReadingPatterns {
            if let firstMatch = description.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let text = cleanHTMLContent(String(description[firstMatch]))
                
                if !text.isEmpty {
                    firstReading = Reading(
                        title: "First Reading",
                        subtitle: "From today's Mass",
                        verses: [Verse(text: text, reference: "First Reading", bookName: "Scripture", chapter: 1, verseNumber: 1)],
                        theme: "Daily Mass Reading",
                        liturgicalContext: "First Reading"
                    )
                    break
                }
            }
        }
        
        // Responsorial Psalm
        let psalmPatterns = [
            #"Responsorial Psalm</strong><br />(.*?)(?=<strong>|$)"#,
            #"Psalm</strong><br />(.*?)(?=<strong>|$)"#,
            #"<strong>Psalm</strong>(.*?)(?=<strong>|$)"#
        ]
        
        for pattern in psalmPatterns {
            if let psalmMatch = description.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let text = cleanHTMLContent(String(description[psalmMatch]))
                
                if !text.isEmpty {
                    psalm = Reading(
                        title: "Responsorial Psalm",
                        subtitle: "From today's Mass",
                        verses: [Verse(text: text, reference: "Psalm", bookName: "Psalms", chapter: 1, verseNumber: 1)],
                        theme: "Daily Mass Reading",
                        liturgicalContext: "Responsorial Psalm"
                    )
                    break
                }
            }
        }
        
        // Gospel Acclamation/Alleluia
        let alleluiaPatterns = [
            #"Alleluia</strong><br />(.*?)(?=<strong>|$)"#,
            #"Gospel Acclamation</strong><br />(.*?)(?=<strong>|$)"#,
            #"<strong>Alleluia</strong>(.*?)(?=<strong>|$)"#
        ]
        
        for pattern in alleluiaPatterns {
            if let alleluiaMatch = description.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let text = cleanHTMLContent(String(description[alleluiaMatch]))
                
                if !text.isEmpty {
                    alleluia = Reading(
                        title: "Gospel Acclamation",
                        subtitle: "From today's Mass",
                        verses: [Verse(text: text, reference: "Alleluia", bookName: "Liturgy", chapter: 1, verseNumber: 1)],
                        theme: "Daily Mass Reading",
                        liturgicalContext: "Gospel Acclamation"
                    )
                    break
                }
            }
        }
        
        // Gospel (required) - try multiple patterns with better parsing
        let gospelPatterns = [
            #"Gospel</strong><br />(.*?)(?=<strong>|$)"#,
            #"Gospel</strong>(.*?)(?=<strong>|$)"#,
            #"Gospel(.*?)(?=<strong>|$)"#,
            #"<strong>Gospel</strong>(.*?)(?=<strong>|$)"#,
            #"(?i)gospel.*?<br\s*/?>(.*?)(?=<strong>|$)"#,
            #"(?i)gospel.*?>(.*?)(?=</?strong>|$)"#
        ]
        
        for pattern in gospelPatterns {
            if let gospelMatch = description.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let text = cleanHTMLContent(String(description[gospelMatch]))
                
                if !text.isEmpty && text.count > 10 {
                    gospel = Reading(
                        title: "Gospel",
                        subtitle: "From today's liturgy",
                        verses: [Verse(text: text, reference: "Gospel", bookName: "Gospel", chapter: 1, verseNumber: 1)],
                        theme: "Daily Mass Reading",
                        liturgicalContext: "Gospel"
                    )
                    break
                }
            }
        }
        
        // If still no gospel found, extract any substantial text as fallback
        if gospel == nil {
            let fallbackText = cleanHTMLContent(description)
            
            let meaningfulText = fallbackText.isEmpty ? "Today's Gospel reading from the liturgy" : String(fallbackText.prefix(200))
            
            gospel = Reading(
                title: "Gospel",
                subtitle: "From today's liturgy", 
                verses: [Verse(text: meaningfulText, reference: "Gospel", bookName: "Gospel", chapter: 1, verseNumber: 1)],
                theme: "Daily Mass Reading",
                liturgicalContext: "Gospel"
            )
        }
        
        // Now we're guaranteed to have a gospel
        let gospelReading = gospel!
        
        let massReadings = MassReadings(
            lectionary: extractLectionaryInfo(from: description),
            firstReading: firstReading,
            responsorialPsalm: psalm,
            alleluia: alleluia,
            gospel: gospelReading,
            secondReading: nil
        )
        
        print("📖 Parsed Mass Readings:")
        print("   - First Reading: \(firstReading?.title ?? "None")")
        print("   - Psalm: \(psalm?.title ?? "None")")
        print("   - Alleluia: \(alleluia?.title ?? "None")")
        print("   - Gospel: \(gospelReading.title)")
        print("   - Total readings: \(massReadings.allReadings.count)")
        
        return massReadings
    }
    
    private func determineLiturgicalSeason(for date: Date) -> LiturgicalSeason {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        // Simplified liturgical season calculation
        // (In production, this would be more complex with Easter calculation)
        switch month {
        case 12: // December
            if day >= 1 && day <= 24 { return .advent }
            else { return .christmasTime }
        case 1: // January
            if day <= 13 { return .christmasTime } // Until Baptism of the Lord
            else { return .ordinaryTime }
        case 2, 3: // February-March (simplified Lent)
            return .lent
        case 4: // April (Easter Time)
            return .easterTime
        case 5: // May
            if day <= 15 { return .easterTime } // Approximate
            else { return .ordinaryTime }
        default:
            return .ordinaryTime
        }
    }
    
    private func determineLiturgicalColor(for title: String, season: LiturgicalSeason) -> LiturgicalColor {
        let lowercased = title.lowercased()
        
        // Check for specific feast types
        if lowercased.contains("martyr") { return .red }
        if lowercased.contains("virgin") || lowercased.contains("angel") { return .white }
        if lowercased.contains("pope") || lowercased.contains("bishop") { return .white }
        
        // Default by season
        switch season {
        case .advent, .lent: return .violet
        case .christmasTime, .easterTime: return .white
        case .ordinaryTime: return .green
        }
    }
    
    private func determineLiturgicalRank(from title: String) -> LiturgicalRank {
        let lowercased = title.lowercased()
        
        if lowercased.contains("solemnity") { return .solemnity }
        if lowercased.contains("feast") { return .feast }
        if lowercased.contains("memorial") && !lowercased.contains("optional") { return .memorial }
        if lowercased.contains("optional memorial") { return .optionalMemorial }
        
        return .ferial
    }
    
    private func extractCommemorations(from title: String) -> [String] {
        // Extract saint names and commemorations
        let components = title.components(separatedBy: ",")
        return components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    private func extractLectionaryInfo(from description: String) -> String {
        // Try to extract lectionary information from the description
        if let match = description.range(of: #"Lectionary:\s*(\d+)"#, options: .regularExpression) {
            return String(description[match])
        }
        
        // Determine by content type
        if description.lowercased().contains("sunday") {
            return "Sunday Lectionary"
        } else if description.lowercased().contains("weekday") {
            return "Weekday Lectionary"
        } else {
            return "Daily Lectionary"
        }
    }
    
    private func cleanHTMLContent(_ html: String) -> String {
        print("🔧 Original HTML: \(html.prefix(200))...")
        
        var cleanText = html
        
        // First decode HTML entities that might interfere with tag removal
        cleanText = cleanText
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&apos;", with: "'")
        
        // Remove HTML tags more aggressively with multiple passes
        for _ in 0..<3 { // Multiple passes to catch nested tags
            cleanText = cleanText.replacingOccurrences(of: #"<[^>]*>"#, with: " ", options: .regularExpression)
        }
        
        // Remove any remaining HTML-like content patterns
        cleanText = cleanText.replacingOccurrences(of: #"&[a-zA-Z0-9#]+;"#, with: "", options: .regularExpression)
        
        // If still contains HTML-like content, try more aggressive cleaning
        if cleanText.contains("<") || cleanText.contains("href=") || cleanText.contains("class=") {
            // Extract only text that looks like actual reading content
            let sentences = cleanText.components(separatedBy: .punctuationCharacters)
                .filter { sentence in
                    let clean = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                    return clean.count > 20 && 
                           !clean.contains("<") && 
                           !clean.contains("href") && 
                           !clean.contains("class") &&
                           clean.rangeOfCharacter(from: .letters) != nil
                }
            
            if !sentences.isEmpty {
                cleanText = sentences.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            } else {
                // Ultimate fallback - just remove all non-letter/space/punctuation characters
                cleanText = cleanText.replacingOccurrences(of: #"[^a-zA-Z0-9\s.,:;!?'-]"#, with: "", options: .regularExpression)
            }
        }
        
        // Remove reading labels
        cleanText = cleanText
            .replacingOccurrences(of: "Gospel", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Reading 1", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "First Reading", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Responsorial Psalm", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Psalm", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Alleluia", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Gospel Acclamation", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Readings for the", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Memorial of the Passion of", with: "", options: .caseInsensitive)
        
        // Clean up multiple spaces and newlines
        cleanText = cleanText.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        let result = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔧 Cleaned text: \(result.prefix(100))...")
        
        // If we end up with no meaningful content, provide a fallback
        if result.isEmpty || result.count < 10 {
            return "Today's Gospel reading from the Memorial of the Passion of Saint John the Baptist"
        }
        
        return result
    }
}

enum USCCBError: Error {
    case invalidURL
    case parsingError
    case missingGospel
    case networkError
}