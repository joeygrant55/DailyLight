import Foundation

// Daily Mass readings for the Catholic liturgical calendar
// This provides the actual scripture references for each day's Mass

struct DailyMassReading {
    let date: String // Format: "MM-dd"
    let firstReading: String // Old Testament or Acts
    let responsorialPsalm: String
    let secondReading: String? // Only for Sundays/Solemnities
    let gospelAcclamation: String?
    let gospel: String
    let liturgicalNote: String?
}

// Sample Mass readings - this would be expanded to full liturgical calendar
let dailyMassReadings: [DailyMassReading] = [
    // August 30, 2025 - Saturday of the Twenty-first Week in Ordinary Time
    DailyMassReading(
        date: "08-30",
        firstReading: "1TH.4.9-11", // 1 Thessalonians 4:9-11 (complete passage)
        responsorialPsalm: "PSA.98.1-9", // Psalm 98:1, 7-8, 9 (representative verses)
        secondReading: nil, // Weekday - no second reading
        gospelAcclamation: "JHN.13.34",
        gospel: "MAT.25.14-30", // Matthew 25:14-30 (Parable of the Talents - complete)
        liturgicalNote: "Saturday of the Twenty-first Week in Ordinary Time"
    ),
    
    // August 31, 2025 - Twenty-second Sunday in Ordinary Time
    DailyMassReading(
        date: "08-31",
        firstReading: "DEU.4.1", // Deuteronomy 4:1-2, 6-8
        responsorialPsalm: "PSA.15.2", // Psalm 15:2-3, 3-4, 4-5
        secondReading: "JAS.1.17", // James 1:17-18, 21b-22, 27
        gospelAcclamation: "JAS.1.18",
        gospel: "MRK.7.1", // Mark 7:1-8, 14-15, 21-23
        liturgicalNote: "Twenty-second Sunday in Ordinary Time"
    ),
    
    // September 1, 2025 - Monday of the Twenty-second Week
    DailyMassReading(
        date: "09-01",
        firstReading: "1TH.4.13", // 1 Thessalonians 4:13-18
        responsorialPsalm: "PSA.96.1", // Psalm 96:1, 3-5, 11-13
        secondReading: nil,
        gospelAcclamation: "LUK.4.18",
        gospel: "LUK.4.16", // Luke 4:16-30
        liturgicalNote: "Monday of the Twenty-second Week in Ordinary Time"
    ),
    
    // August 29 - Memorial of the Passion of Saint John the Baptist
    DailyMassReading(
        date: "08-29",
        firstReading: "JER.1.17", // Jeremiah 1:17-19
        responsorialPsalm: "PSA.71.1", // Psalm 71:1-6, 15, 17
        secondReading: nil,
        gospelAcclamation: "MAT.5.10",
        gospel: "MRK.6.17", // Mark 6:17-29
        liturgicalNote: "Memorial of the Passion of Saint John the Baptist"
    ),
    
    // August 28 - Saint Augustine
    DailyMassReading(
        date: "08-28",
        firstReading: "1TH.2.9", // 1 Thessalonians 2:9-13
        responsorialPsalm: "PSA.139.7", // Psalm 139:7-12
        secondReading: nil,
        gospelAcclamation: "JHN.10.27",
        gospel: "MAT.23.27", // Matthew 23:27-32
        liturgicalNote: "Memorial of Saint Augustine, Bishop and Doctor"
    ),
    
    // August 27 - Saint Monica
    DailyMassReading(
        date: "08-27",
        firstReading: "1TH.2.1", // 1 Thessalonians 2:1-8
        responsorialPsalm: "PSA.139.1", // Psalm 139:1-6
        secondReading: nil,
        gospelAcclamation: "JHN.13.34",
        gospel: "MAT.23.23", // Matthew 23:23-26
        liturgicalNote: "Memorial of Saint Monica"
    )
]

// Helper to get readings for a specific date
extension DailyMassReading {
    static func getReadingsFor(date: Date) -> DailyMassReading? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        let dateString = formatter.string(from: date)
        
        return dailyMassReadings.first { $0.date == dateString }
    }
    
    // Get complete list of scripture references
    func getAllReferences() -> [String] {
        var refs = [firstReading, responsorialPsalm, gospel]
        if let second = secondReading {
            refs.insert(second, at: 2) // Insert after psalm
        }
        if let acclamation = gospelAcclamation {
            refs.insert(acclamation, at: refs.count - 1) // Before gospel
        }
        return refs
    }
    
    // Check if this is a Sunday/Solemnity (has second reading)
    var isSunday: Bool {
        return secondReading != nil
    }
    
    // Get proper Mass structure
    func getMassStructure() -> [(title: String, reference: String)] {
        var structure: [(title: String, reference: String)] = []
        
        structure.append(("First Reading", firstReading))
        structure.append(("Responsorial Psalm", responsorialPsalm))
        
        if let second = secondReading {
            structure.append(("Second Reading", second))
        }
        
        if let acclamation = gospelAcclamation {
            structure.append(("Gospel Acclamation", acclamation))
        }
        
        structure.append(("Gospel", gospel))
        
        return structure
    }
}