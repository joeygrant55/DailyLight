import Foundation

struct Verse: Identifiable, Codable {
    let id: String
    let text: String
    let reference: String
    let bookName: String
    let chapter: Int
    let verseNumber: Int
    
    init(id: String? = nil, text: String, reference: String, bookName: String, chapter: Int, verseNumber: Int) {
        self.id = id ?? UUID().uuidString
        self.text = text
        self.reference = reference
        self.bookName = bookName
        self.chapter = chapter
        self.verseNumber = verseNumber
    }
}

struct Reading: Identifiable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let verses: [Verse]
    let theme: String
    let liturgicalContext: String?
    
    init(id: String? = nil, title: String, subtitle: String, verses: [Verse], theme: String, liturgicalContext: String? = nil) {
        self.id = id ?? UUID().uuidString
        self.title = title
        self.subtitle = subtitle
        self.verses = verses
        self.theme = theme
        self.liturgicalContext = liturgicalContext
    }
}

enum ArtStyle: String, CaseIterable {
    case naturalStyle = "natural style cinematic biblical scene"
    
    var displayName: String {
        switch self {
        case .naturalStyle: return "Natural Style"
        }
    }
}

// MARK: - Biblical Collections Models

enum CollectionCategory: String, CaseIterable, Codable {
    case jesusLife = "jesus_life"
    case miracles = "miracles"
    case heroes = "heroes"
    case earlyWorld = "early_world"
    case parables = "parables"
    case psalms = "psalms"
    
    var displayName: String {
        switch self {
        case .jesusLife: return "Walk with Jesus"
        case .miracles: return "Jesus' Miracles"
        case .heroes: return "Faith Heroes"
        case .earlyWorld: return "Early World"
        case .parables: return "Parables"
        case .psalms: return "Psalms"
        }
    }
    
    var iconName: String {
        switch self {
        case .jesusLife: return "figure.walk"
        case .miracles: return "sparkles"
        case .heroes: return "shield"
        case .earlyWorld: return "globe"
        case .parables: return "book"
        case .psalms: return "music.note"
        }
    }
    
    var color: String {
        switch self {
        case .jesusLife: return "#F59E0B"
        case .miracles: return "#06B6D4"
        case .heroes: return "#DC2626"
        case .earlyWorld: return "#92400E"
        case .parables: return "#7C3AED"
        case .psalms: return "#059669"
        }
    }
}

struct BibleScene: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let readings: [Reading]
    let imagePrompt: String?
    let order: Int
    
    init(id: String? = nil, title: String, description: String, readings: [Reading], imagePrompt: String? = nil, order: Int) {
        self.id = id ?? UUID().uuidString
        self.title = title
        self.description = description
        self.readings = readings
        self.imagePrompt = imagePrompt
        self.order = order
    }
}

struct BibleCollection: Identifiable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: String
    let scenes: [BibleScene]
    let category: CollectionCategory
    
    init(id: String? = nil, title: String, subtitle: String, description: String, icon: String, color: String, scenes: [BibleScene], category: CollectionCategory) {
        self.id = id ?? UUID().uuidString
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.icon = icon
        self.color = color
        self.scenes = scenes
        self.category = category
    }
}