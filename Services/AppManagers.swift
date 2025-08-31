import Foundation
import SwiftUI


class CreditManager: ObservableObject {
    static let shared = CreditManager()
    
    @AppStorage("dailyCredits") var dailyCredits: Int = 5
    @AppStorage("isPremium") var isPremium: Bool = false
    @AppStorage("lastResetDate") private var lastResetDateString: String = ""
    
    private let freeCreditsPerDay = 5
    private let premiumCreditsPerDay = 999
    
    private init() {
        checkAndResetDailyCredits()
        // For testing - automatically set premium
        #if DEBUG
        isPremium = true
        dailyCredits = premiumCreditsPerDay
        #endif
    }
    
    func checkAndResetDailyCredits() {
        let today = dateString(from: Date())
        
        if lastResetDateString != today {
            lastResetDateString = today
            dailyCredits = isPremium ? premiumCreditsPerDay : freeCreditsPerDay
        }
    }
    
    func useCredit() -> Bool {
        guard dailyCredits > 0 || isPremium else { return false }
        
        if !isPremium {
            dailyCredits -= 1
        }
        
        return true
    }
    
    func refundCredit() {
        if !isPremium {
            dailyCredits += 1
        }
    }
    
    func upgradeToPremium() {
        isPremium = true
        dailyCredits = premiumCreditsPerDay
    }
    
    func downgradeFromPremium() {
        isPremium = false
        dailyCredits = min(dailyCredits, freeCreditsPerDay)
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

class ReadingsManager: ObservableObject {
    static let shared = ReadingsManager()
    
    @Published var todaysReading: Reading?
    @Published var allReadings: [Reading] = []
    @Published var isLoading = false
    
    private let bibleAPI = BibleAPIService.shared
    
    private init() {
        loadReadings()
        selectTodaysReading()
    }
    
    private func loadReadings() {
        // Load static readings as fallback, then try to load dynamic content
        allReadings = SampleReadings.getAllReadings()
        
        Task {
            await loadDynamicContent()
        }
    }
    
    private func selectTodaysReading() {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % allReadings.count
        todaysReading = allReadings[index]
    }
    
    /// Load dynamic content from Bible API
    private func loadDynamicContent() async {
        isLoading = true
        
        do {
            // Fetch today's dynamic reading
            let dynamicReading = try await fetchTodaysReading()
            
            await MainActor.run {
                // Only update if we got verses successfully
                if !dynamicReading.verses.isEmpty {
                    self.todaysReading = dynamicReading
                    print("📖 Successfully loaded dynamic reading: \(dynamicReading.title)")
                } else {
                    print("📖 Dynamic reading was empty, keeping static fallback")
                }
                self.isLoading = false
            }
            
        } catch {
            print("📖 Failed to load dynamic content, using static fallback: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    /// Fetch today's reading from Bible API
    private func fetchTodaysReading() async throws -> Reading {
        // Define a set of inspiring daily readings that rotate
        let dailyReadings = [
            ("The Beatitudes", "Jesus teaches on the mountain", ["MAT.5.3", "MAT.5.4", "MAT.5.5", "MAT.5.6"], "Blessings and the Kingdom of Heaven"),
            ("The Lord's Prayer", "Jesus teaches us to pray", ["MAT.6.9", "MAT.6.10", "MAT.6.11"], "Perfect prayer from Christ"),
            ("Psalm of Trust", "The Lord is my shepherd", ["PSA.23.1", "PSA.23.2", "PSA.23.3", "PSA.23.4"], "God's protection and providence"),
            ("Love Chapter", "Greatest gift of love", ["1CO.13.4", "1CO.13.5", "1CO.13.7", "1CO.13.8"], "Divine love and charity"),
            ("Good Shepherd", "Jesus protects His flock", ["JHN.10.11", "JHN.10.14"], "Christ's protective love"),
            ("Living Water", "Jesus and the Samaritan woman", ["JHN.4.13", "JHN.4.14"], "Spiritual refreshment"),
            ("Bread of Life", "Jesus feeds the multitude", ["JHN.6.35"], "Christ as spiritual nourishment")
        ]
        
        // Select based on day of year to ensure variety
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let readingIndex = (dayOfYear - 1) % dailyReadings.count
        let selectedReading = dailyReadings[readingIndex]
        
        // Fetch the reading using Bible API
        return try await bibleAPI.fetchReading(
            title: selectedReading.0,
            subtitle: selectedReading.1,
            references: selectedReading.2,
            theme: selectedReading.3
        )
    }
    
    /// Fetch a specific reading by title (for collections)
    func fetchReading(title: String, references: [String], theme: String) async throws -> Reading {
        return try await bibleAPI.fetchReading(
            title: title,
            subtitle: "Live from Scripture",
            references: references,
            theme: theme
        )
    }
    
    /// Refresh today's reading
    func refreshTodaysReading() async {
        await loadDynamicContent()
    }
}

struct SampleReadings {
    static func getAllReadings() -> [Reading] {
        return [
            createBeatitudesReading(),
            createPsalm23Reading(),
            createLordsPrayerReading(),
            createLoveChapterReading(),
            createCreationReading(),
            // New biblical scene readings
            createNativityReading(),
            createStormCalmedReading(),
            createGoodShepherdReading(),
            createTransfigurationReading(),
            createWeddingAtCanaReading()
        ]
    }
    
    static func createBeatitudesReading() -> Reading {
        let verses = [
            Verse(
                text: "Blessed are the poor in spirit, for theirs is the kingdom of heaven. Blessed are those who mourn, for they shall be comforted. Blessed are the meek, for they shall inherit the earth. Blessed are those who hunger and thirst for righteousness, for they shall be satisfied. Blessed are the merciful, for they shall obtain mercy. Blessed are the pure in heart, for they shall see God. Blessed are the peacemakers, for they shall be called children of God. Blessed are those who are persecuted for righteousness' sake, for theirs is the kingdom of heaven.",
                reference: "Matthew 5:3-10",
                bookName: "Matthew",
                chapter: 5,
                verseNumber: 3
            )
        ]
        
        return Reading(
            title: "The Beatitudes",
            subtitle: "Jesus teaches on the mountain",
            verses: verses,
            theme: "Blessings and the Kingdom of Heaven",
            liturgicalContext: "Sermon on the Mount"
        )
    }
    
    static func createPsalm23Reading() -> Reading {
        let verses = [
            Verse(
                text: "The Lord is my shepherd; I shall not want. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul. He leads me in paths of righteousness for his name's sake. Even though I walk through the valley of the shadow of death, I will fear no evil, for you are with me; your rod and your staff, they comfort me. You prepare a table before me in the presence of my enemies; you anoint my head with oil; my cup overflows. Surely goodness and mercy shall follow me all the days of my life, and I shall dwell in the house of the Lord forever.",
                reference: "Psalm 23:1-6",
                bookName: "Psalms",
                chapter: 23,
                verseNumber: 1
            )
        ]
        
        return Reading(
            title: "The Lord is My Shepherd",
            subtitle: "Psalm of David",
            verses: verses,
            theme: "God's protection and providence",
            liturgicalContext: "Beloved prayer of comfort"
        )
    }
    
    static func createLordsPrayerReading() -> Reading {
        let verses = [
            Verse(
                text: "Our Father who art in heaven, hallowed be thy name. Thy kingdom come, thy will be done, on earth as it is in heaven. Give us this day our daily bread. And forgive us our trespasses, as we forgive those who trespass against us. And lead us not into temptation, but deliver us from evil. For thine is the kingdom, and the power, and the glory, forever. Amen.",
                reference: "Matthew 6:9-13",
                bookName: "Matthew",
                chapter: 6,
                verseNumber: 9
            )
        ]
        
        return Reading(
            title: "The Lord's Prayer",
            subtitle: "Jesus teaches us to pray",
            verses: verses,
            theme: "Perfect prayer from Christ",
            liturgicalContext: "Central prayer of the Mass"
        )
    }
    
    static func createLoveChapterReading() -> Reading {
        let verses = [
            Verse(text: "If I speak in the tongues of men and of angels, but have not love, I am a noisy gong or a clanging cymbal.",
                  reference: "1 Corinthians 13:1", bookName: "1 Corinthians", chapter: 13, verseNumber: 1),
            Verse(text: "Love is patient and kind; love does not envy or boast; it is not arrogant or rude.",
                  reference: "1 Corinthians 13:4-5", bookName: "1 Corinthians", chapter: 13, verseNumber: 4),
            Verse(text: "Love bears all things, believes all things, hopes all things, endures all things.",
                  reference: "1 Corinthians 13:7", bookName: "1 Corinthians", chapter: 13, verseNumber: 7),
            Verse(text: "Love never ends. As for prophecies, they will pass away; as for tongues, they will cease; as for knowledge, it will pass away.",
                  reference: "1 Corinthians 13:8", bookName: "1 Corinthians", chapter: 13, verseNumber: 8),
            Verse(text: "So now faith, hope, and love abide, these three; but the greatest of these is love.",
                  reference: "1 Corinthians 13:13", bookName: "1 Corinthians", chapter: 13, verseNumber: 13)
        ]
        
        return Reading(
            title: "The Gift of Love",
            subtitle: "St. Paul's hymn to love",
            verses: verses,
            theme: "Divine love and charity",
            liturgicalContext: "Popular wedding reading"
        )
    }
    
    static func createCreationReading() -> Reading {
        let verses = [
            Verse(text: "In the beginning, God created the heavens and the earth.",
                  reference: "Genesis 1:1", bookName: "Genesis", chapter: 1, verseNumber: 1),
            Verse(text: "And God said, 'Let there be light,' and there was light.",
                  reference: "Genesis 1:3", bookName: "Genesis", chapter: 1, verseNumber: 3),
            Verse(text: "And God saw that the light was good. And God separated the light from the darkness.",
                  reference: "Genesis 1:4", bookName: "Genesis", chapter: 1, verseNumber: 4),
            Verse(text: "God called the light Day, and the darkness he called Night. And there was evening and there was morning, the first day.",
                  reference: "Genesis 1:5", bookName: "Genesis", chapter: 1, verseNumber: 5),
            Verse(text: "Then God said, 'Let us make man in our image, after our likeness.'",
                  reference: "Genesis 1:26", bookName: "Genesis", chapter: 1, verseNumber: 26)
        ]
        
        return Reading(
            title: "The Creation",
            subtitle: "God creates the world",
            verses: verses,
            theme: "God as Creator of all",
            liturgicalContext: "Easter Vigil reading"
        )
    }
    
    // MARK: - Biblical Scene Readings
    
    static func createNativityReading() -> Reading {
        let verses = [
            Verse(
                text: "There were shepherds in the same country staying in the field, and keeping watch by night over their flock. Behold, an angel of the Lord stood by them, and the glory of the Lord shone around them, and they were terrified. The angel said to them, \"Don't be afraid, for behold, I bring you good news of great joy which will be to all the people. For there is born to you today, in David's city, a Savior, who is Christ the Lord.\"",
                reference: "Luke 2:8-11",
                bookName: "Luke",
                chapter: 2,
                verseNumber: 8
            )
        ]
        
        return Reading(
            title: "The Nativity",
            subtitle: "Angels announce Christ's birth",
            verses: verses,
            theme: "The Incarnation and God's gift to humanity",
            liturgicalContext: "Christmas Gospel"
        )
    }
    
    static func createStormCalmedReading() -> Reading {
        let verses = [
            Verse(
                text: "A big wind storm arose, and the waves beat into the boat, so much that the boat was already filled. He himself was in the stern, asleep on the cushion, and they woke him up, and told him, \"Teacher, don't you care that we are dying?\" He awoke, and rebuked the wind, and said to the sea, \"Peace! Be still!\" The wind ceased, and there was a great calm.",
                reference: "Mark 4:37-39",
                bookName: "Mark",
                chapter: 4,
                verseNumber: 37,
            )
        ]
        
        return Reading(
            title: "Jesus Calms the Storm",
            subtitle: "Christ shows power over nature",
            verses: verses,
            theme: "Faith in Jesus during life's storms",
            liturgicalContext: "Gospel of trust in Divine Providence"
        )
    }
    
    static func createGoodShepherdReading() -> Reading {
        let verses = [
            Verse(
                text: "I am the good shepherd. The good shepherd lays down his life for the sheep. The hired hand, who is not the shepherd, who doesn't own the sheep, sees the wolf coming, leaves the sheep, and flees. The wolf snatches the sheep, and scatters them. I am the good shepherd. I know my own, and I'm known by my own.",
                reference: "John 10:11-14",
                bookName: "John",
                chapter: 10,
                verseNumber: 11,
            )
        ]
        
        return Reading(
            title: "The Good Shepherd",
            subtitle: "Jesus protects His flock",
            verses: verses,
            theme: "Christ's protective love for His people",
            liturgicalContext: "Good Shepherd Sunday"
        )
    }
    
    static func createTransfigurationReading() -> Reading {
        let verses = [
            Verse(
                text: "After six days, Jesus took with him Peter, James, and John his brother, and brought them up into a high mountain by themselves. He was transfigured before them. His face shone like the sun, and his clothing became as white as the light. Behold, Moses and Elijah appeared to them, talking with him.",
                reference: "Matthew 17:1-3",
                bookName: "Matthew",
                chapter: 17,
                verseNumber: 1,
            )
        ]
        
        return Reading(
            title: "The Transfiguration",
            subtitle: "Jesus reveals His glory",
            verses: verses,
            theme: "Divine glory revealed in Christ",
            liturgicalContext: "Feast of the Transfiguration"
        )
    }
    
    static func createWeddingAtCanaReading() -> Reading {
        let verses = [
            Verse(
                text: "The third day, there was a marriage in Cana of Galilee. Jesus' mother was there. Jesus also was invited, with his disciples, to the marriage. When the wine ran out, Jesus' mother said to him, \"They have no wine.\" Jesus said to the servants, \"Fill the water pots with water.\" So they filled them up to the brim. He said to them, \"Now draw some out, and take it to the ruler of the feast.\" So they took it.",
                reference: "John 2:1-8",
                bookName: "John",
                chapter: 2,
                verseNumber: 1,
            )
        ]
        
        return Reading(
            title: "The Wedding at Cana",
            subtitle: "Jesus' first miracle",
            verses: verses,
            theme: "Christ's blessing on marriage and family",
            liturgicalContext: "Wedding liturgy"
        )
    }
}

