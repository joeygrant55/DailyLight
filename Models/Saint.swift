import Foundation
import SwiftUI

struct Saint: Identifiable, Codable {
    let id: String
    let name: String
    let feastDay: String // Format: "MM-dd" for recurring annual feast
    let title: String // e.g., "Martyr", "Bishop", "Virgin and Martyr"
    let biography: String
    let patronOf: [String]
    let livedPeriod: String // e.g., "c. 251-288", "1515-1582"
    let birthPlace: String?
    let keyVirtues: [String]
    let famousQuote: String?
    let miraclesAttribted: [String]
    let canonizationDate: String?
    let iconographySymbols: [String] // For AI art generation
    let liturgicalRank: SaintRank
    let associatedPrayers: [String]
    
    // Computed properties for display
    var fullTitle: String {
        return "\(title.isEmpty ? "" : "\(title) ")\(name)"
    }
    
    var shortBiography: String {
        return String(biography.prefix(200)) + (biography.count > 200 ? "..." : "")
    }
    
    var artPrompt: String {
        let symbols = iconographySymbols.joined(separator: ", ")
        return "Catholic saint iconography of \(name), \(title), with traditional symbols: \(symbols), golden halo, religious robes, divine light, traditional Catholic art style"
    }
}

enum SaintRank: String, CaseIterable, Codable {
    case solemnity = "Solemnity"
    case feast = "Feast" 
    case memorial = "Memorial"
    case optionalMemorial = "Optional Memorial"
    case commemoration = "Commemoration"
    
    var liturgicalPriority: Int {
        switch self {
        case .solemnity: return 1
        case .feast: return 2
        case .memorial: return 3
        case .optionalMemorial: return 4
        case .commemoration: return 5
        }
    }
    
    var color: Color {
        switch self {
        case .solemnity: return .yellow
        case .feast: return .orange
        case .memorial: return .blue
        case .optionalMemorial: return .green
        case .commemoration: return .gray
        }
    }
}

// Sample saints data - this would be expanded to full liturgical calendar
let sampleSaints: [Saint] = [
    Saint(
        id: "john-baptist",
        name: "Saint John the Baptist",
        feastDay: "08-29", // Memorial of the Passion
        title: "Forerunner of Christ",
        biography: "John the Baptist was the forerunner of Jesus Christ, preparing the way for the Messiah through his preaching of repentance and baptism. Born to Elizabeth and Zechariah, he lived as an ascetic in the desert, wearing camel's hair and eating locusts and wild honey. He baptized Jesus in the Jordan River and boldly proclaimed Him as the 'Lamb of God who takes away the sins of the world.' John was imprisoned and eventually beheaded by King Herod Antipas for condemning the king's unlawful marriage. He is venerated as the greatest of the prophets and the last of the Old Testament figures.",
        patronOf: ["Baptism", "Converts", "Epilepsy", "Hailstorms", "Lambs"],
        livedPeriod: "c. 6 BC - c. 30 AD",
        birthPlace: "Judea",
        keyVirtues: ["Courage", "Humility", "Truth-telling", "Asceticism"],
        famousQuote: "He must increase, but I must decrease.",
        miraclesAttribted: ["Prophetic visions", "Recognition of Christ in the womb"],
        canonizationDate: "Pre-Congregation (ancient)",
        iconographySymbols: ["Lamb of God", "Baptismal shell", "Camel hair garment", "Scroll with 'Ecce Agnus Dei'", "Severed head on platter"],
        liturgicalRank: .memorial,
        associatedPrayers: ["Prayer to St. John the Baptist", "Baptismal prayers"]
    ),
    
    Saint(
        id: "augustine-hippo",
        name: "Saint Augustine of Hippo",
        feastDay: "08-28",
        title: "Bishop and Doctor of the Church",
        biography: "Augustine of Hippo was one of the most influential theologians in the history of Christianity. Born in North Africa to Saint Monica, he lived a worldly life in his youth before experiencing a profound conversion to Christianity at age 31. His 'Confessions' remains one of the most important spiritual autobiographies ever written. As Bishop of Hippo, he defended orthodox Catholic teaching against various heresies and developed much of the theological foundation for Western Christianity. His works on grace, original sin, and the Trinity shaped Catholic doctrine for centuries.",
        patronOf: ["Theologians", "Printers", "Brewers", "Sore eyes"],
        livedPeriod: "354-430 AD",
        birthPlace: "Thagaste, North Africa (modern-day Algeria)",
        keyVirtues: ["Wisdom", "Conversion", "Theological insight", "Pastoral care"],
        famousQuote: "You have made us for yourself, O Lord, and our hearts are restless until they rest in you.",
        miraclesAttribted: ["Healing of the sick through prayer", "Prophetic visions"],
        canonizationDate: "Pre-Congregation (ancient)",
        iconographySymbols: ["Bishop's mitre and crosier", "Book representing his writings", "Flaming heart", "Child with shell (Trinity vision)", "Black Augustinian habit"],
        liturgicalRank: .memorial,
        associatedPrayers: ["Prayer to St. Augustine", "Prayer for Theologians"]
    ),
    
    Saint(
        id: "monica",
        name: "Saint Monica",
        feastDay: "08-27",
        title: "Mother and Widow",
        biography: "Monica was the mother of Saint Augustine and is venerated as the patron saint of mothers and wives. Born in North Africa, she was married to a pagan husband, Patricius, whom she eventually converted to Christianity through her prayers and example. Her son Augustine lived a dissolute life for many years, causing Monica great sorrow. She prayed unceasingly for his conversion for over 15 years, following him from Africa to Italy. Her perseverance was rewarded when Augustine converted to Christianity and was baptized by Saint Ambrose in Milan. She died shortly after, having seen her prayers answered.",
        patronOf: ["Mothers", "Wives", "Abuse victims", "Difficult marriages", "Disappointing children"],
        livedPeriod: "c. 331-387 AD",
        birthPlace: "Thagaste, North Africa (modern-day Algeria)",
        keyVirtues: ["Perseverance in prayer", "Patience", "Maternal love", "Faith"],
        famousQuote: "Nothing is far from God.",
        miraclesAttribted: ["Conversion of her husband", "Conversion of her son Augustine"],
        canonizationDate: "Pre-Congregation (ancient)",
        iconographySymbols: ["Tears of supplication", "Black widow's veil", "Book representing her son's Confessions", "Praying hands", "Heart pierced with sorrow"],
        liturgicalRank: .memorial,
        associatedPrayers: ["Prayer to St. Monica for Children", "Prayer for Mothers"]
    ),
    
    Saint(
        id: "rose-lima",
        name: "Saint Rose of Lima",
        feastDay: "08-30",
        title: "Virgin and Mystic",
        biography: "Rose of Lima was the first canonized saint of the Americas. Born in Lima, Peru, she was known for her extraordinary beauty, which she deliberately marred to avoid marriage and worldly attention. She lived as a Dominican tertiary in her family's garden, practicing severe penances and experiencing mystical visions. She dedicated her life to prayer, penance, and caring for the poor and sick. Her deep devotion to Christ and her mystical experiences made her a model of sanctity for the New World. She died at age 31 and was canonized by Pope Clement X in 1671.",
        patronOf: ["Americas", "Peru", "Philippines", "Embroiderers", "Florists", "Gardeners"],
        livedPeriod: "1586-1617",
        birthPlace: "Lima, Peru",
        keyVirtues: ["Penance", "Mystical prayer", "Charity", "Humility"],
        famousQuote: "Apart from the cross there is no other ladder by which we may get to heaven.",
        miraclesAttribted: ["Mystical visions", "Healing of the sick", "Levitation during prayer"],
        canonizationDate: "April 12, 1671",
        iconographySymbols: ["Crown of roses", "Cross", "Dominican habit", "Crown of thorns", "Baby Jesus", "Anchor"],
        liturgicalRank: .memorial,
        associatedPrayers: ["Prayer to St. Rose of Lima", "Prayer for the Americas"]
    )
]