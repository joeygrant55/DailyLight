import Foundation
import SwiftUI

class SaintService: ObservableObject {
    static let shared = SaintService()
    
    @Published var todaysSaint: Saint?
    @Published var isLoading = false
    @Published var error: String?
    
    private var allSaints: [Saint] = []
    private let imageGenerator = ImageGenerator()
    
    private init() {
        loadSaintsData()
        updateTodaysSaint()
    }
    
    // MARK: - Public API
    
    /// Get the saint for today's date
    func getTodaysSaint() -> Saint? {
        return getSaintFor(date: Date())
    }
    
    /// Get saint for a specific date
    func getSaintFor(date: Date) -> Saint? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        let dateString = formatter.string(from: date)
        
        // Find saint with matching feast day
        let saint = allSaints.first { $0.feastDay == dateString }
        
        if let saint = saint {
            print("🕊️ Found saint for \(dateString): \(saint.name)")
            return saint
        } else {
            print("🕊️ No specific saint found for \(dateString)")
            return nil
        }
    }
    
    /// Generate saint iconographic art
    func generateSaintArt(for saint: Saint) async throws -> UIImage {
        // Use existing ImageGenerator but with saint-specific prompts
        let enhancedPrompt = """
        \(saint.artPrompt), 
        Catholic iconographic style, 
        golden halo, divine light, 
        traditional religious art, 
        peaceful expression, 
        sacred atmosphere,
        renaissance style religious painting
        """
        
        // Create a temporary verse for the art generation system
        let saintVerse = Verse(
            text: saint.shortBiography,
            reference: "Life of \(saint.name)",
            bookName: "Saints",
            chapter: 1,
            verseNumber: 1
        )
        
        return try await imageGenerator.generateImage(
            prompt: enhancedPrompt,
            verse: saintVerse,
            theme: "Catholic Saints and Holy People"
        )
    }
    
    /// Search saints by name or patronage
    func searchSaints(query: String) -> [Saint] {
        let lowercaseQuery = query.lowercased()
        
        return allSaints.filter { saint in
            saint.name.lowercased().contains(lowercaseQuery) ||
            saint.title.lowercased().contains(lowercaseQuery) ||
            saint.patronOf.joined(separator: " ").lowercased().contains(lowercaseQuery) ||
            saint.keyVirtues.joined(separator: " ").lowercased().contains(lowercaseQuery)
        }
    }
    
    /// Get saints by month for browsing
    func getSaintsForMonth(_ month: Int) -> [Saint] {
        let monthString = String(format: "%02d", month)
        
        return allSaints.filter { saint in
            saint.feastDay.hasPrefix(monthString)
        }.sorted { saint1, saint2 in
            // Sort by day within the month
            let day1 = Int(saint1.feastDay.suffix(2)) ?? 0
            let day2 = Int(saint2.feastDay.suffix(2)) ?? 0
            return day1 < day2
        }
    }
    
    /// Update today's saint (call when date changes)
    func updateTodaysSaint() {
        Task {
            await MainActor.run {
                todaysSaint = getTodaysSaint()
            }
        }
    }
    
    // MARK: - Private Implementation
    
    private func loadSaintsData() {
        // Start with sample saints, expand this to full liturgical calendar
        allSaints = sampleSaints
        
        // TODO: Load from comprehensive saints database or API
        // This could be expanded to include all saints from:
        // - Roman Martyrology
        // - National saint calendars
        // - Diocesan saint calendars
        
        print("🕊️ Loaded \(allSaints.count) saints")
    }
    
    /// Get liturgically appropriate saint when multiple saints share a feast day
    private func selectPrimarySaint(candidates: [Saint]) -> Saint? {
        // Sort by liturgical rank priority (Solemnity > Feast > Memorial, etc.)
        let sorted = candidates.sorted { 
            $0.liturgicalRank.liturgicalPriority < $1.liturgicalRank.liturgicalPriority 
        }
        
        return sorted.first
    }
    
    /// Generate daily saint notification content
    func getSaintNotificationContent(for saint: Saint) -> (title: String, body: String) {
        let title = "🕊️ Today's Saint: \(saint.name)"
        let body = "\(saint.title) • Patron of \(saint.patronOf.first ?? "the faithful") • \(saint.famousQuote ?? saint.shortBiography)"
        
        return (title, body)
    }
    
    /// Get saints related to current liturgical season
    func getSaintsForLiturgicalSeason(_ season: LiturgicalSeason) -> [Saint] {
        switch season {
        case .advent:
            // Mary, Joseph, John the Baptist
            return allSaints.filter { 
                $0.name.contains("Mary") || $0.name.contains("Joseph") || $0.name.contains("John")
            }
        case .christmasTime:
            // Holy Family, Stephen, Holy Innocents
            return allSaints.filter { 
                $0.name.contains("Stephen") || $0.name.contains("Innocent") || $0.name.contains("Family")
            }
        case .lent:
            // Saints known for penance, fasting, conversion
            return allSaints.filter { saint in
                saint.keyVirtues.contains("Conversion") || 
                saint.keyVirtues.contains("Penance") ||
                saint.keyVirtues.contains("Asceticism")
            }
        case .easterTime:
            // Martyrs and apostles
            return allSaints.filter { saint in
                saint.title.contains("Martyr") || saint.title.contains("Apostle")
            }
        case .ordinaryTime:
            // All saints, focus on daily Christian living
            return allSaints
        }
    }
}

// MARK: - Extensions for Integration

extension Saint {
    /// Check if saint's feast day aligns with today's liturgical celebration
    func alignsWithLiturgicalDay(_ liturgicalDay: LiturgicalDay) -> Bool {
        return liturgicalDay.title.contains(self.name) ||
               liturgicalDay.commemorations.contains(where: { $0.contains(self.name) })
    }
    
    /// Get recommended Bible readings related to this saint
    func getRelatedScriptureReferences() -> [String] {
        // Return scripture references that relate to the saint's life or patronage
        // Using individual verses instead of ranges for API compatibility
        
        if title.contains("Martyr") {
            return ["REV.7.9", "ROM.8.35", "MAT.10.28"]
        } else if title.contains("Bishop") {
            return ["1TI.3.1", "TIT.1.7", "JHN.10.11"]
        } else if title.contains("Virgin") || title.contains("Mystic") {
            return ["MAT.25.1", "1CO.7.25", "REV.14.4"]
        } else if patronOf.contains("Mothers") {
            return ["PRO.31.10", "LUK.1.46", "1TI.2.15"]
        } else {
            return ["HEB.12.1", "1CO.4.16", "GAL.2.20"]
        }
    }
}