import Foundation
import SwiftUI

// MARK: - Unified Scripture Models

struct Scripture: Identifiable, Codable {
    let id: String
    let reference: ScriptureReference
    let text: String
    let verses: [ScriptureVerse]
    let context: ScriptureContext
    let metadata: ScriptureMetadata
    
    init(id: String? = nil, reference: ScriptureReference, text: String, verses: [ScriptureVerse], context: ScriptureContext, metadata: ScriptureMetadata) {
        self.id = id ?? UUID().uuidString
        self.reference = reference
        self.text = text
        self.verses = verses
        self.context = context
        self.metadata = metadata
    }
}

struct ScriptureReference: Codable, Hashable {
    let book: String
    let chapter: Int
    let startVerse: Int
    let endVerse: Int?
    let displayText: String
    let apiFormat: String
    
    init(book: String, chapter: Int, startVerse: Int, endVerse: Int? = nil) {
        self.book = book
        self.chapter = chapter
        self.startVerse = startVerse
        self.endVerse = endVerse
        
        if let endVerse = endVerse {
            self.displayText = "\(book) \(chapter):\(startVerse)-\(endVerse)"
        } else {
            self.displayText = "\(book) \(chapter):\(startVerse)"
        }
        
        // Convert to API format (e.g., "MAT.5.3-12" for Matthew 5:3-12)
        let bookCode = ScriptureReference.bookToCode[book] ?? book.prefix(3).uppercased()
        if let endVerse = endVerse {
            self.apiFormat = "\(bookCode).\(chapter).\(startVerse)-\(endVerse)"
        } else {
            self.apiFormat = "\(bookCode).\(chapter).\(startVerse)"
        }
    }
    
    static let bookToCode: [String: String] = [
        "Genesis": "GEN", "Exodus": "EXO", "Leviticus": "LEV",
        "Matthew": "MAT", "Mark": "MRK", "Luke": "LUK", "John": "JHN",
        "Psalms": "PSA", "Psalm": "PSA", "Proverbs": "PRO",
        "1 Corinthians": "1CO", "2 Corinthians": "2CO",
        "Revelation": "REV", "Isaiah": "ISA", "Romans": "ROM"
    ]
}

struct ScriptureVerse: Identifiable, Codable {
    let id: String
    let number: Int
    let text: String
    let reference: ScriptureReference
    
    init(id: String? = nil, number: Int, text: String, reference: ScriptureReference) {
        self.id = id ?? UUID().uuidString
        self.number = number
        self.text = text
        self.reference = reference
    }
}

enum ScriptureContext: String, Codable {
    case narrative = "Biblical Narrative"
    case psalm = "Psalm/Prayer"
    case parable = "Parable"
    case prophecy = "Prophecy"
    case epistle = "Letter/Teaching"
    case gospel = "Gospel Account"
    case wisdom = "Wisdom Literature"
    case apocalyptic = "Apocalyptic"
    case law = "Law/Commandment"
    
    var imageStyle: String {
        switch self {
        case .narrative:
            return "realistic biblical scene illustration showing the events described"
        case .psalm:
            return "ethereal worship scene with divine light and spiritual atmosphere"
        case .parable:
            return "symbolic visual metaphor illustrating the spiritual lesson"
        case .prophecy:
            return "mystical visionary art with prophetic symbolism"
        case .epistle:
            return "illuminated manuscript style with decorative elements"
        case .gospel:
            return "sacred traditional art depicting Christ and disciples"
        case .wisdom:
            return "contemplative scene showing wisdom and understanding"
        case .apocalyptic:
            return "dramatic heavenly vision with divine imagery"
        case .law:
            return "solemn tablets or scrolls with divine authority"
        }
    }
    
    var readingPace: TimeInterval {
        switch self {
        case .psalm, .wisdom:
            return 4.0  // Slower, meditative
        case .narrative, .gospel:
            return 3.0  // Normal narrative pace
        case .parable, .prophecy:
            return 3.5  // Thoughtful pace
        default:
            return 3.0
        }
    }
}

struct ScriptureMetadata: Codable {
    let liturgicalUse: String?
    let feastDay: String?
    let theme: String
    let relatedReferences: [ScriptureReference]
    let historicalContext: String?
    let applicationNotes: String?
}

// MARK: - Unified Scripture Service

class UnifiedScriptureService: ObservableObject {
    static let shared = UnifiedScriptureService()
    
    @Published var currentScripture: Scripture?
    @Published var dailyLiturgy: LiturgicalReadings?
    @Published var searchResults: [Scripture] = []
    @Published var isLoading = false
    
    private let bibleAPI = BibleAPIService.shared
    private let liturgicalService = USCCBLiturgicalService.shared
    private let readingsManager = ReadingsManager.shared
    private let collectionsManager = BiblicalCollectionsManager.shared
    
    private let cache = ScriptureCache()
    
    private init() {
        loadDailyLiturgy()
    }
    
    // MARK: - Primary Scripture Access
    
    func getScripture(reference: ScriptureReference) async throws -> Scripture {
        // Check cache first
        if let cached = cache.get(reference: reference) {
            return cached
        }
        
        // Try to fetch from API
        if let apiScripture = try? await fetchFromAPI(reference: reference) {
            cache.store(scripture: apiScripture)
            return apiScripture
        }
        
        // Fall back to local data
        return try getLocalScripture(reference: reference)
    }
    
    func getTodaysLiturgy() async throws -> LiturgicalReadings {
        // Combine USCCB data with enhanced Bible API content
        let massReadings = try await liturgicalService.fetchTodaysReadings()
        
        var enhancedReadings: [Scripture] = []
        
        // First Reading
        if let firstReading = massReadings.firstReading {
            let scripture = try await enhanceReading(
                text: firstReading.text,
                reference: firstReading.reference,
                context: .narrative
            )
            enhancedReadings.append(scripture)
        }
        
        // Responsorial Psalm
        if let psalm = massReadings.responsorialPsalm {
            let scripture = try await enhanceReading(
                text: psalm.text,
                reference: psalm.reference,
                context: .psalm
            )
            enhancedReadings.append(scripture)
        }
        
        // Gospel
        if let gospel = massReadings.gospel {
            let scripture = try await enhanceReading(
                text: gospel.text,
                reference: gospel.reference,
                context: .gospel
            )
            enhancedReadings.append(scripture)
        }
        
        return LiturgicalReadings(
            date: Date(),
            readings: enhancedReadings,
            liturgicalColor: massReadings.liturgicalColor ?? "green",
            feastDay: massReadings.saint
        )
    }
    
    // MARK: - Search and Discovery
    
    func searchScripture(query: String, context: ScriptureContext? = nil) async throws -> [Scripture] {
        isLoading = true
        defer { isLoading = false }
        
        var results: [Scripture] = []
        
        // Search through Bible API
        if let apiResults = try? await bibleAPI.searchPassages(query: query) {
            for passage in apiResults {
                if let scripture = convertAPIPassageToScripture(passage) {
                    if context == nil || scripture.context == context {
                        results.append(scripture)
                    }
                }
            }
        }
        
        // Search through local collections
        let localResults = searchLocalCollections(query: query, context: context)
        results.append(contentsOf: localResults)
        
        // Remove duplicates and sort by relevance
        results = Array(Set(results)).sorted { $0.reference.displayText < $1.reference.displayText }
        
        DispatchQueue.main.async {
            self.searchResults = results
        }
        
        return results
    }
    
    func getRelatedScriptures(to scripture: Scripture) async throws -> [Scripture] {
        var related: [Scripture] = []
        
        // Get scriptures from metadata
        for reference in scripture.metadata.relatedReferences {
            if let relatedScripture = try? await getScripture(reference: reference) {
                related.append(relatedScripture)
            }
        }
        
        // Get thematically similar scriptures
        let thematic = try await searchScripture(
            query: scripture.metadata.theme,
            context: scripture.context
        )
        related.append(contentsOf: thematic.prefix(3))
        
        return related
    }
    
    // MARK: - Context Detection
    
    func detectContext(for text: String, book: String) -> ScriptureContext {
        // Detect based on book
        if book.lowercased().contains("psalm") {
            return .psalm
        } else if ["Matthew", "Mark", "Luke", "John"].contains(book) {
            return .gospel
        } else if book.contains("Corinthians") || book.contains("Timothy") || book == "Romans" {
            return .epistle
        } else if book == "Proverbs" || book == "Ecclesiastes" {
            return .wisdom
        } else if book == "Revelation" {
            return .apocalyptic
        }
        
        // Detect based on content
        let lowerText = text.lowercased()
        if lowerText.contains("parable") || lowerText.contains("like a") || lowerText.contains("kingdom of heaven is like") {
            return .parable
        } else if lowerText.contains("thus says the lord") || lowerText.contains("oracle") {
            return .prophecy
        } else if lowerText.contains("thou shalt") || lowerText.contains("commandment") {
            return .law
        }
        
        return .narrative
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchFromAPI(reference: ScriptureReference) async throws -> Scripture? {
        // Implementation would call BibleAPIService
        return nil
    }
    
    private func getLocalScripture(reference: ScriptureReference) throws -> Scripture {
        // Search through local data
        throw ScriptureError.notFound
    }
    
    private func enhanceReading(text: String, reference: String, context: ScriptureContext) async throws -> Scripture {
        let ref = parseReference(reference)
        let verses = parseVerses(from: text, reference: ref)
        
        return Scripture(
            reference: ref,
            text: text,
            verses: verses,
            context: context,
            metadata: ScriptureMetadata(
                liturgicalUse: "Daily Mass",
                feastDay: nil,
                theme: detectTheme(from: text),
                relatedReferences: [],
                historicalContext: nil,
                applicationNotes: nil
            )
        )
    }
    
    private func parseReference(_ reference: String) -> ScriptureReference {
        // Parse references like "1 Thessalonians 4:9-11"
        let components = reference.components(separatedBy: " ")
        let book = components.dropLast().joined(separator: " ")
        let chapterVerse = components.last?.components(separatedBy: ":") ?? []
        
        let chapter = Int(chapterVerse.first ?? "1") ?? 1
        let verseRange = chapterVerse.last?.components(separatedBy: "-") ?? []
        let startVerse = Int(verseRange.first ?? "1") ?? 1
        let endVerse = verseRange.count > 1 ? Int(verseRange[1]) : nil
        
        return ScriptureReference(
            book: book,
            chapter: chapter,
            startVerse: startVerse,
            endVerse: endVerse
        )
    }
    
    private func parseVerses(from text: String, reference: ScriptureReference) -> [ScriptureVerse] {
        // Split text into verses if possible
        let lines = text.components(separatedBy: "\n").filter { !$0.isEmpty }
        return lines.enumerated().map { index, line in
            ScriptureVerse(
                number: reference.startVerse + index,
                text: line,
                reference: reference
            )
        }
    }
    
    private func detectTheme(from text: String) -> String {
        let lowerText = text.lowercased()
        
        if lowerText.contains("love") { return "Love and Charity" }
        if lowerText.contains("faith") { return "Faith and Trust" }
        if lowerText.contains("hope") { return "Hope and Perseverance" }
        if lowerText.contains("forgive") { return "Forgiveness and Mercy" }
        if lowerText.contains("pray") { return "Prayer and Devotion" }
        if lowerText.contains("blessed") { return "Blessings and Beatitudes" }
        
        return "Scripture Meditation"
    }
    
    private func searchLocalCollections(query: String, context: ScriptureContext?) -> [Scripture] {
        // Search through local collections
        return []
    }
    
    private func convertAPIPassageToScripture(_ passage: Any) -> Scripture? {
        // Convert API response to unified Scripture model
        return nil
    }
    
    private func loadDailyLiturgy() {
        Task {
            do {
                self.dailyLiturgy = try await getTodaysLiturgy()
            } catch {
                print("Failed to load daily liturgy: \(error)")
            }
        }
    }
}

// MARK: - Supporting Types

struct LiturgicalReadings: Identifiable {
    let id = UUID().uuidString
    let date: Date
    let readings: [Scripture]
    let liturgicalColor: String
    let feastDay: String?
}

enum ScriptureError: Error {
    case notFound
    case invalidReference
    case apiError
}

// MARK: - Cache

class ScriptureCache {
    private var cache: [ScriptureReference: Scripture] = [:]
    private let queue = DispatchQueue(label: "scripture.cache", attributes: .concurrent)
    
    func get(reference: ScriptureReference) -> Scripture? {
        queue.sync {
            return cache[reference]
        }
    }
    
    func store(scripture: Scripture) {
        queue.async(flags: .barrier) {
            self.cache[scripture.reference] = scripture
        }
    }
}

// MARK: - Scripture Extensions

extension Scripture: Hashable {
    static func == (lhs: Scripture, rhs: Scripture) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}