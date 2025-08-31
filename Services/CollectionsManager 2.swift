import Foundation
import SwiftUI

class BiblicalCollectionsManager: ObservableObject {
    static let shared = BiblicalCollectionsManager()
    
    @Published var allCollections: [BibleCollection] = []
    @Published var featuredCollections: [BibleCollection] = []
    
    private init() {
        loadCollections()
    }
    
    private func loadCollections() {
        allCollections = SampleCollections.getAllCollections()
        featuredCollections = Array(allCollections.prefix(4)) // Featured on home screen
    }
    
    func getCollection(by id: String) -> BibleCollection? {
        return allCollections.first { $0.id == id }
    }
    
    func getCollections(by category: CollectionCategory) -> [BibleCollection] {
        return allCollections.filter { $0.category == category }
    }
}

// MARK: - Sample Collections Data
struct SampleCollections {
    static func getAllCollections() -> [BibleCollection] {
        return [
            createWalkWithJesusCollection(),
            createMiraclesCollection(),
            createFaithHeroesCollection(),
            createEarlyWorldCollection()
        ]
    }
    
    static func createWalkWithJesusCollection() -> BibleCollection {
        let scenes = [
            BibleScene(
                title: "The Birth of Jesus",
                description: "The miraculous birth of our Savior in Bethlehem",
                readings: [createNativityReading()],
                imagePrompt: "nativity scene with Mary, Joseph, and baby Jesus in a stable",
                order: 1
            ),
            BibleScene(
                title: "Baptism by John",
                description: "Jesus begins His public ministry",
                readings: [createBaptismReading()],
                imagePrompt: "Jesus being baptized by John the Baptist in the Jordan River",
                order: 2
            ),
            BibleScene(
                title: "The Temptation",
                description: "Jesus overcomes temptation in the wilderness",
                readings: [createTemptationReading()],
                imagePrompt: "Jesus praying in the wilderness, resisting temptation",
                order: 3
            ),
            BibleScene(
                title: "Calling the Disciples",
                description: "Jesus calls His first followers",
                readings: [createCallingReading()],
                imagePrompt: "Jesus calling fishermen to follow Him by the Sea of Galilee",
                order: 4
            ),
            BibleScene(
                title: "The Sermon on the Mount",
                description: "Jesus teaches the Beatitudes and perfect way of life",
                readings: [createSermonReading()],
                imagePrompt: "Jesus teaching a crowd on a mountainside",
                order: 5
            ),
            BibleScene(
                title: "The Last Supper",
                description: "Jesus institutes the Eucharist",
                readings: [createLastSupperReading()],
                imagePrompt: "Jesus with His disciples at the Last Supper",
                order: 6
            ),
            BibleScene(
                title: "The Crucifixion",
                description: "Jesus sacrifices Himself for our salvation",
                readings: [createCrucifixionReading()],
                imagePrompt: "Jesus on the cross at Calvary",
                order: 7
            ),
            BibleScene(
                title: "The Resurrection",
                description: "Jesus rises from the dead on Easter morning",
                readings: [createResurrectionReading()],
                imagePrompt: "Jesus rising from the tomb in glory",
                order: 8
            ),
            BibleScene(
                title: "The Great Commission",
                description: "Jesus sends forth His disciples",
                readings: [createCommissionReading()],
                imagePrompt: "Jesus appearing to His disciples and commissioning them",
                order: 9
            ),
            BibleScene(
                title: "The Ascension",
                description: "Jesus ascends to Heaven",
                readings: [createAscensionReading()],
                imagePrompt: "Jesus ascending into heaven before His disciples",
                order: 10
            )
        ]
        
        return BibleCollection(
            title: "Walk with Jesus",
            subtitle: "Follow Christ's earthly journey",
            description: "Experience the life of Jesus from His birth to His ascension, walking alongside our Lord through His most important moments on earth.",
            icon: "figure.walk",
            color: "#F59E0B",
            scenes: scenes,
            category: .jesusLife
        )
    }
    
    static func createMiraclesCollection() -> BibleCollection {
        let scenes = [
            BibleScene(
                title: "Water into Wine",
                description: "Jesus' first miracle at Cana",
                readings: [createWaterWineReading()],
                imagePrompt: "Jesus at the wedding feast of Cana, water jars nearby",
                order: 1
            ),
            BibleScene(
                title: "Feeding the 5000",
                description: "Jesus multiplies loaves and fishes",
                readings: [createFeedingReading()],
                imagePrompt: "Jesus blessing bread and fish before a large crowd",
                order: 2
            ),
            BibleScene(
                title: "Walking on Water",
                description: "Jesus walks across the Sea of Galilee",
                readings: [createWalkingWaterReading()],
                imagePrompt: "Jesus walking on water towards the disciples' boat",
                order: 3
            ),
            BibleScene(
                title: "Healing the Blind",
                description: "Jesus restores sight to the blind",
                readings: [createHealingBlindReading()],
                imagePrompt: "Jesus healing a blind man with His hands",
                order: 4
            ),
            BibleScene(
                title: "Raising Lazarus",
                description: "Jesus brings Lazarus back to life",
                readings: [createLazarusReading()],
                imagePrompt: "Jesus calling Lazarus forth from the tomb",
                order: 5
            )
        ]
        
        return BibleCollection(
            title: "Jesus' Miracles",
            subtitle: "Witness divine power",
            description: "Experience the miraculous works of Jesus that demonstrated His divine nature and compassion for humanity.",
            icon: "sparkles",
            color: "#06B6D4",
            scenes: scenes,
            category: .miracles
        )
    }
    
    static func createFaithHeroesCollection() -> BibleCollection {
        let scenes = [
            BibleScene(
                title: "Abraham's Faith",
                description: "The father of faith obeys God's call",
                readings: [createAbrahamReading()],
                imagePrompt: "Abraham looking up at the stars, receiving God's promise",
                order: 1
            ),
            BibleScene(
                title: "Moses and the Exodus",
                description: "Leading God's people to freedom",
                readings: [createMosesReading()],
                imagePrompt: "Moses parting the Red Sea with his staff raised",
                order: 2
            ),
            BibleScene(
                title: "David vs Goliath",
                description: "Young David defeats the giant",
                readings: [createDavidReading()],
                imagePrompt: "Young David facing the giant Goliath with his sling",
                order: 3
            ),
            BibleScene(
                title: "Daniel in the Lions' Den",
                description: "Faith protects in the face of danger",
                readings: [createDanielReading()],
                imagePrompt: "Daniel praying peacefully among lions",
                order: 4
            ),
            BibleScene(
                title: "Esther's Courage",
                description: "A queen saves her people",
                readings: [createEstherReading()],
                imagePrompt: "Queen Esther approaching the king's throne courageously",
                order: 5
            )
        ]
        
        return BibleCollection(
            title: "Faith Heroes",
            subtitle: "Learn from biblical courage",
            description: "Discover the stories of men and women who showed extraordinary faith and courage in following God's will.",
            icon: "shield",
            color: "#DC2626",
            scenes: scenes,
            category: .heroes
        )
    }
    
    static func createEarlyWorldCollection() -> BibleCollection {
        let scenes = [
            BibleScene(
                title: "The Creation",
                description: "God creates the heavens and earth",
                readings: [createCreationReading()],
                imagePrompt: "God creating light, separating light from darkness",
                order: 1
            ),
            BibleScene(
                title: "Adam and Eve",
                description: "The first humans in Paradise",
                readings: [createAdamEveReading()],
                imagePrompt: "Adam and Eve in the Garden of Eden",
                order: 2
            ),
            BibleScene(
                title: "Noah's Ark",
                description: "Salvation through the great flood",
                readings: [createNoahReading()],
                imagePrompt: "Noah's ark on the waters during the great flood",
                order: 3
            ),
            BibleScene(
                title: "Tower of Babel",
                description: "Human pride and God's response",
                readings: [createBabelReading()],
                imagePrompt: "The Tower of Babel reaching toward heaven",
                order: 4
            )
        ]
        
        return BibleCollection(
            title: "Early World",
            subtitle: "The beginning of all things",
            description: "Journey through the earliest stories of creation, fall, and God's covenant with humanity.",
            icon: "globe",
            color: "#92400E",
            scenes: scenes,
            category: .earlyWorld
        )
    }
}

// MARK: - Sample Reading Creation Methods
extension SampleCollections {
    static func createNativityReading() -> Reading {
        let verses = [
            Verse(text: "And she gave birth to her firstborn son and wrapped him in swaddling cloths and laid him in a manger, because there was no place for them in the inn.",
                  reference: "Luke 2:7", bookName: "Luke", chapter: 2, verseNumber: 7),
            Verse(text: "And the angel said to them, 'Fear not, for behold, I bring you good news of great joy that will be for all the people.'",
                  reference: "Luke 2:10", bookName: "Luke", chapter: 2, verseNumber: 10)
        ]
        
        return Reading(
            title: "The Birth of Jesus",
            subtitle: "God becomes man",
            verses: verses,
            theme: "Incarnation and God's love",
            liturgicalContext: "Christmas"
        )
    }
    
    static func createBaptismReading() -> Reading {
        let verses = [
            Verse(text: "And when Jesus was baptized, immediately he went up from the water, and behold, the heavens were opened to him, and he saw the Spirit of God descending like a dove and coming to rest on him;",
                  reference: "Matthew 3:16", bookName: "Matthew", chapter: 3, verseNumber: 16),
            Verse(text: "and behold, a voice from heaven said, 'This is my beloved Son, with whom I am well pleased.'",
                  reference: "Matthew 3:17", bookName: "Matthew", chapter: 3, verseNumber: 17)
        ]
        
        return Reading(
            title: "The Baptism of Jesus",
            subtitle: "The Trinity revealed",
            verses: verses,
            theme: "Jesus' divine sonship",
            liturgicalContext: "Baptism of the Lord"
        )
    }
    
    static func createTemptationReading() -> Reading {
        let verses = [
            Verse(text: "Then Jesus was led up by the Spirit into the wilderness to be tempted by the devil.",
                  reference: "Matthew 4:1", bookName: "Matthew", chapter: 4, verseNumber: 1),
            Verse(text: "But he answered, 'It is written, Man shall not live by bread alone, but by every word that comes from the mouth of God.'",
                  reference: "Matthew 4:4", bookName: "Matthew", chapter: 4, verseNumber: 4)
        ]
        
        return Reading(
            title: "The Temptation",
            subtitle: "Jesus overcomes evil",
            verses: verses,
            theme: "Resisting temptation through God's word",
            liturgicalContext: "First Sunday of Lent"
        )
    }
    
    static func createWaterWineReading() -> Reading {
        let verses = [
            Verse(text: "When the wine ran out, the mother of Jesus said to him, 'They have no wine.'",
                  reference: "John 2:3", bookName: "John", chapter: 2, verseNumber: 3),
            Verse(text: "Jesus said to the servants, 'Fill the jars with water.' And they filled them up to the brim.",
                  reference: "John 2:7", bookName: "John", chapter: 2, verseNumber: 7)
        ]
        
        return Reading(
            title: "Water into Wine",
            subtitle: "The first miracle",
            verses: verses,
            theme: "Jesus' divine power revealed",
            liturgicalContext: "Second Sunday in Ordinary Time"
        )
    }
    
    // Additional reading creation methods would go here...
    // For brevity, I'll create simplified versions of the remaining readings
    
    static func createCallingReading() -> Reading {
        return Reading(
            title: "Calling the Disciples",
            subtitle: "Follow me",
            verses: [
                Verse(text: "And he said to them, 'Follow me, and I will make you fishers of men.'",
                      reference: "Matthew 4:19", bookName: "Matthew", chapter: 4, verseNumber: 19)
            ],
            theme: "Discipleship and calling",
            liturgicalContext: "Vocations"
        )
    }
    
    static func createSermonReading() -> Reading {
        return Reading(
            title: "The Sermon on the Mount",
            subtitle: "The Beatitudes",
            verses: [
                Verse(text: "Blessed are the poor in spirit, for theirs is the kingdom of heaven.",
                      reference: "Matthew 5:3", bookName: "Matthew", chapter: 5, verseNumber: 3)
            ],
            theme: "Christian living",
            liturgicalContext: "All Saints Day"
        )
    }
    
    static func createLastSupperReading() -> Reading {
        return Reading(
            title: "The Last Supper",
            subtitle: "Do this in memory of me",
            verses: [
                Verse(text: "And he took bread, and when he had given thanks, he broke it and gave it to them, saying, 'This is my body, which is given for you. Do this in remembrance of me.'",
                      reference: "Luke 22:19", bookName: "Luke", chapter: 22, verseNumber: 19)
            ],
            theme: "Eucharist and sacrifice",
            liturgicalContext: "Holy Thursday"
        )
    }
    
    static func createCrucifixionReading() -> Reading {
        return Reading(
            title: "The Crucifixion",
            subtitle: "It is finished",
            verses: [
                Verse(text: "When Jesus had received the sour wine, he said, 'It is finished,' and he bowed his head and gave up his spirit.",
                      reference: "John 19:30", bookName: "John", chapter: 19, verseNumber: 30)
            ],
            theme: "Sacrifice and redemption",
            liturgicalContext: "Good Friday"
        )
    }
    
    static func createResurrectionReading() -> Reading {
        return Reading(
            title: "The Resurrection",
            subtitle: "He is risen",
            verses: [
                Verse(text: "But the angel said to the women, 'Do not be afraid, for I know that you seek Jesus who was crucified. He is not here, for he has risen, as he said.'",
                      reference: "Matthew 28:5-6", bookName: "Matthew", chapter: 28, verseNumber: 5)
            ],
            theme: "Victory over death",
            liturgicalContext: "Easter Sunday"
        )
    }
    
    static func createCommissionReading() -> Reading {
        return Reading(
            title: "The Great Commission",
            subtitle: "Go and make disciples",
            verses: [
                Verse(text: "Go therefore and make disciples of all nations, baptizing them in the name of the Father and of the Son and of the Holy Spirit.",
                      reference: "Matthew 28:19", bookName: "Matthew", chapter: 28, verseNumber: 19)
            ],
            theme: "Mission and evangelization",
            liturgicalContext: "Missionary Sunday"
        )
    }
    
    static func createAscensionReading() -> Reading {
        return Reading(
            title: "The Ascension",
            subtitle: "Jesus returns to the Father",
            verses: [
                Verse(text: "And when he had said these things, as they were looking on, he was lifted up, and a cloud took him out of their sight.",
                      reference: "Acts 1:9", bookName: "Acts", chapter: 1, verseNumber: 9)
            ],
            theme: "Jesus' glorification",
            liturgicalContext: "Ascension Thursday"
        )
    }
    
    static func createFeedingReading() -> Reading {
        return Reading(
            title: "Feeding the 5000",
            subtitle: "Jesus provides abundantly",
            verses: [
                Verse(text: "And they all ate and were satisfied. And they took up twelve baskets full of the broken pieces left over.",
                      reference: "Matthew 14:20", bookName: "Matthew", chapter: 14, verseNumber: 20)
            ],
            theme: "God's abundant provision",
            liturgicalContext: "17th Sunday in Ordinary Time"
        )
    }
    
    static func createWalkingWaterReading() -> Reading {
        return Reading(
            title: "Walking on Water",
            subtitle: "Jesus calms the storm",
            verses: [
                Verse(text: "And in the fourth watch of the night he came to them, walking on the sea.",
                      reference: "Matthew 14:25", bookName: "Matthew", chapter: 14, verseNumber: 25)
            ],
            theme: "Faith over fear",
            liturgicalContext: "19th Sunday in Ordinary Time"
        )
    }
    
    static func createHealingBlindReading() -> Reading {
        return Reading(
            title: "Healing the Blind",
            subtitle: "Jesus gives sight",
            verses: [
                Verse(text: "Then he spit on the ground and made mud with the saliva. Then he anointed the man's eyes with the mud and said to him, 'Go, wash in the pool of Siloam.'",
                      reference: "John 9:6-7", bookName: "John", chapter: 9, verseNumber: 6)
            ],
            theme: "Spiritual blindness healed",
            liturgicalContext: "4th Sunday of Lent"
        )
    }
    
    static func createLazarusReading() -> Reading {
        return Reading(
            title: "Raising Lazarus",
            subtitle: "I am the resurrection and the life",
            verses: [
                Verse(text: "Jesus said to her, 'I am the resurrection and the life. Whoever believes in me, though he die, yet shall he live.'",
                      reference: "John 11:25", bookName: "John", chapter: 11, verseNumber: 25)
            ],
            theme: "Victory over death",
            liturgicalContext: "5th Sunday of Lent"
        )
    }
    
    static func createAbrahamReading() -> Reading {
        return Reading(
            title: "Abraham's Faith",
            subtitle: "The call of Abraham",
            verses: [
                Verse(text: "Now the Lord said to Abram, 'Go from your country and your kindred and your father's house to the land that I will show you.'",
                      reference: "Genesis 12:1", bookName: "Genesis", chapter: 12, verseNumber: 1)
            ],
            theme: "Faith and obedience",
            liturgicalContext: "2nd Sunday of Lent"
        )
    }
    
    static func createMosesReading() -> Reading {
        return Reading(
            title: "Moses and the Exodus",
            subtitle: "God delivers His people",
            verses: [
                Verse(text: "Then Moses stretched out his hand over the sea, and the Lord drove the sea back by a strong east wind all night and made the sea dry land.",
                      reference: "Exodus 14:21", bookName: "Exodus", chapter: 14, verseNumber: 21)
            ],
            theme: "God's deliverance",
            liturgicalContext: "Easter Vigil"
        )
    }
    
    static func createDavidReading() -> Reading {
        return Reading(
            title: "David vs Goliath",
            subtitle: "Faith defeats fear",
            verses: [
                Verse(text: "Then David said to the Philistine, 'You come to me with a sword and with a spear and with a javelin, but I come to you in the name of the Lord of hosts.'",
                      reference: "1 Samuel 17:45", bookName: "1 Samuel", chapter: 17, verseNumber: 45)
            ],
            theme: "Trusting in God's strength",
            liturgicalContext: "4th Sunday in Ordinary Time"
        )
    }
    
    static func createDanielReading() -> Reading {
        return Reading(
            title: "Daniel in the Lions' Den",
            subtitle: "Faith protects the faithful",
            verses: [
                Verse(text: "My God sent his angel and shut the lions' mouths, and they have not harmed me, because I was found blameless before him.",
                      reference: "Daniel 6:22", bookName: "Daniel", chapter: 6, verseNumber: 22)
            ],
            theme: "God's protection",
            liturgicalContext: "14th Sunday in Ordinary Time"
        )
    }
    
    static func createEstherReading() -> Reading {
        return Reading(
            title: "Esther's Courage",
            subtitle: "For such a time as this",
            verses: [
                Verse(text: "And who knows whether you have not come to the kingdom for such a time as this?",
                      reference: "Esther 4:14", bookName: "Esther", chapter: 4, verseNumber: 14)
            ],
            theme: "Courage in God's plan",
            liturgicalContext: "33rd Sunday in Ordinary Time"
        )
    }
    
    static func createCreationReading() -> Reading {
        return Reading(
            title: "The Creation",
            subtitle: "In the beginning",
            verses: [
                Verse(text: "In the beginning, God created the heavens and the earth.",
                      reference: "Genesis 1:1", bookName: "Genesis", chapter: 1, verseNumber: 1)
            ],
            theme: "God as Creator",
            liturgicalContext: "Easter Vigil"
        )
    }
    
    static func createAdamEveReading() -> Reading {
        return Reading(
            title: "Adam and Eve",
            subtitle: "Made in God's image",
            verses: [
                Verse(text: "So God created man in his own image, in the image of God he created him; male and female he created them.",
                      reference: "Genesis 1:27", bookName: "Genesis", chapter: 1, verseNumber: 27)
            ],
            theme: "Human dignity",
            liturgicalContext: "Trinity Sunday"
        )
    }
    
    static func createNoahReading() -> Reading {
        return Reading(
            title: "Noah's Ark",
            subtitle: "God's covenant with Noah",
            verses: [
                Verse(text: "And God said, 'This is the sign of the covenant that I make between me and you and every living creature that is with you, for all future generations: I have set my bow in the cloud.'",
                      reference: "Genesis 9:12-13", bookName: "Genesis", chapter: 9, verseNumber: 12)
            ],
            theme: "God's faithfulness",
            liturgicalContext: "1st Sunday of Lent"
        )
    }
    
    static func createBabelReading() -> Reading {
        return Reading(
            title: "Tower of Babel",
            subtitle: "The confusion of languages",
            verses: [
                Verse(text: "Come, let us build ourselves a city and a tower with its top in the heavens, and let us make a name for ourselves.",
                      reference: "Genesis 11:4", bookName: "Genesis", chapter: 11, verseNumber: 4)
            ],
            theme: "Human pride vs. God's will",
            liturgicalContext: "Pentecost"
        )
    }
}