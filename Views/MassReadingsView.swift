import SwiftUI

struct MassReadingsView: View {
    let liturgicalDay: LiturgicalDay
    @StateObject private var bibleAPI = BibleAPIService.shared
    @State private var expandedReading: String? = nil
    @State private var fullReadings: [String: Reading] = [:]
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if isLoading {
                        ProgressView("Loading scripture passages...")
                            .tint(.white)
                            .foregroundColor(.white)
                    } else {
                        readingsSection
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Mass Readings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Mass Readings")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            print("📖 MassReadingsView loaded for: \(liturgicalDay.title)")
            print("📖 Available readings: \(liturgicalDay.readings.allReadings.count)")
            print("📖 Gospel title: \(liturgicalDay.readings.gospel.title)")
            print("📖 First reading: \(liturgicalDay.readings.firstReading?.title ?? "None")")
            print("📖 Date for readings lookup: \(liturgicalDay.date)")
            loadFullReadings()
        }
    }
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(liturgicalDay.dateString)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(liturgicalDay.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
            }
            
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(liturgicalDay.color.swiftUIColor)
                        .frame(width: 12, height: 12)
                    
                    Text(liturgicalDay.season.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Text(liturgicalDay.rank.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    var readingsSection: some View {
        VStack(spacing: 16) {
            // Always show complete Mass structure
            
            // First Reading (Old Testament or Acts)
            readingCard(
                title: "First Reading",
                reading: fullReadings["first"] ?? liturgicalDay.readings.firstReading ?? createPlaceholderReading("First Reading"),
                id: "first"
            )
            
            // Responsorial Psalm
            readingCard(
                title: "Responsorial Psalm", 
                reading: fullReadings["psalm"] ?? liturgicalDay.readings.responsorialPsalm ?? createPlaceholderReading("Responsorial Psalm"),
                id: "psalm"
            )
            
            // Second Reading (Sundays/Solemnities only)
            let isSunday = Calendar.current.component(.weekday, from: liturgicalDay.date) == 1
            if isSunday {
                if let secondReading = fullReadings["second"] ?? liturgicalDay.readings.secondReading {
                    readingCard(
                        title: "Second Reading",
                        reading: secondReading,
                        id: "second"
                    )
                } else {
                    placeholderReadingCard(
                        title: "Second Reading",
                        id: "second"
                    )
                }
            }
            
            // Gospel Acclamation
            readingCard(
                title: "Gospel Acclamation",
                reading: fullReadings["alleluia"] ?? liturgicalDay.readings.alleluia ?? createPlaceholderReading("Gospel Acclamation"),
                id: "alleluia"
            )
            
            // Gospel (always present)
            readingCard(
                title: "Gospel",
                reading: fullReadings["gospel"] ?? liturgicalDay.readings.gospel,
                id: "gospel",
                isHighlighted: true
            )
        }
    }
    
    func createPlaceholderReading(_ title: String) -> Reading {
        return Reading(
            title: title,
            subtitle: "Loading...",
            verses: [Verse(text: "Loading scripture for \(title)...", reference: "Loading", bookName: title, chapter: 1, verseNumber: 1)],
            theme: "Mass Reading",
            liturgicalContext: title
        )
    }
    
    func placeholderReadingCard(title: String, id: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(.white.opacity(0.6))
            }
            
            Text("Loading scripture...")
                .font(.body)
                .foregroundColor(.white.opacity(0.4))
                .italic()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    func readingCard(title: String, reading: Reading, id: String, isHighlighted: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Tappable header with gesture
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isHighlighted ? .yellow : .white)
                
                Spacer()
                
                Image(systemName: expandedReading == id ? "chevron.up" : "chevron.down")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 16, weight: .medium))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    expandedReading = expandedReading == id ? nil : id
                }
            }
            
            // Show all verses with proper formatting
            if expandedReading == id {
                // Expanded - show all verses
                LazyVStack(alignment: .leading, spacing: 12) {
                    if let fullReading = fullReadings[id] {
                        ForEach(Array(fullReading.verses.enumerated()), id: \.element.id) { index, verse in
                            HStack(alignment: .top, spacing: 8) {
                                // Verse number
                                if fullReading.verses.count > 1 {
                                    Text("\(verse.verseNumber)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white.opacity(0.5))
                                        .frame(minWidth: 20, alignment: .leading)
                                }
                                
                                // Verse text (cleaned of verse numbers)
                                Text(cleanVerseText(verse.text, verseNumber: verse.verseNumber))
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineSpacing(4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        // Reference
                        Text(reading.subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 8)
                    } else {
                        // Fallback to basic reading
                        ForEach(reading.verses, id: \.id) { verse in
                            Text(verse.text)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(4)
                        }
                    }
                }
            } else {
                // Collapsed - show preview
                let previewText = (fullReadings[id]?.verses.first?.text ?? reading.verses.first?.text ?? "Loading...")
                let words = previewText.split(separator: " ")
                let preview = words.prefix(25).joined(separator: " ") + (words.count > 25 ? "..." : "")
                
                Text(preview)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(4)
                    .animation(.easeInOut(duration: 0.2), value: expandedReading == id)
            }
            
            if expandedReading == id {
                VStack(alignment: .leading, spacing: 12) {
                    
                    NavigationLink(destination: ReadingView(reading: fullReadings[id] ?? reading)) {
                        HStack {
                            Text("Read with Sacred Art")
                                .fontWeight(.semibold)
                            Image(systemName: "paintbrush.fill")
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: isHighlighted ? [.yellow, .orange] : [.white, .gray.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isHighlighted ? Color.yellow.opacity(0.1) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isHighlighted ? Color.yellow.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    func loadFullReadings() {
        isLoading = true
        
        Task {
            await loadReadingContent()
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    @MainActor
    func loadReadingContent() async {
        // First try to get proper Mass readings from our liturgical calendar
        if let dailyReadings = DailyMassReading.getReadingsFor(date: liturgicalDay.date) {
            // Fetch actual scripture for each reading
            for (title, reference) in dailyReadings.getMassStructure() {
                do {
                    // Fetch complete passage if it's a range, otherwise single verse
                    let verses = try await fetchScripturePassage(reference: reference)
                    let reading = Reading(
                        title: title,
                        subtitle: formatScriptureReference(reference),
                        verses: verses,
                        theme: liturgicalDay.season.displayName,
                        liturgicalContext: title
                    )
                    
                    // Map to proper key for display
                    switch title {
                    case "First Reading":
                        fullReadings["first"] = reading
                    case "Responsorial Psalm":
                        fullReadings["psalm"] = reading
                    case "Second Reading":
                        fullReadings["second"] = reading
                    case "Gospel Acclamation":
                        fullReadings["alleluia"] = reading
                    case "Gospel":
                        fullReadings["gospel"] = reading
                    default:
                        break
                    }
                } catch {
                    print("⚠️ Failed to load \(title) (\(reference)): \(error)")
                }
            }
        } else {
            // Fallback to existing readings from RSS if no daily readings found
            let readings = liturgicalDay.readings
            
            if let firstReading = readings.firstReading {
                fullReadings["first"] = await enhanceReading(firstReading)
            }
            
            if let psalm = readings.responsorialPsalm {
                fullReadings["psalm"] = await enhanceReading(psalm)
            }
            
            if let secondReading = readings.secondReading {
                fullReadings["second"] = await enhanceReading(secondReading)
            }
            
            if let alleluia = readings.alleluia {
                fullReadings["alleluia"] = await enhanceReading(alleluia)
            }
            
            fullReadings["gospel"] = await enhanceReading(readings.gospel)
        }
    }
    
    func fetchScripturePassage(reference: String) async throws -> [Verse] {
        // Handle verse ranges like "MAT.25.14-30" or single verses like "JHN.13.34"
        
        let parts = reference.split(separator: ".")
        guard parts.count >= 3 else {
            // If not enough parts, fetch as single verse
            let singleVerse = try await bibleAPI.fetchVerse(reference: reference)
            return [singleVerse]
        }
        
        let bookCode = String(parts[0])
        let chapter = String(parts[1])
        let versesPart = String(parts[2])
        
        // Check if it's a range (e.g., "14-30")
        if versesPart.contains("-") {
            let rangeParts = versesPart.split(separator: "-")
            guard rangeParts.count == 2,
                  let startVerse = Int(rangeParts[0]),
                  let endVerse = Int(rangeParts[1]) else {
                // Fallback to single verse
                let singleVerse = try await bibleAPI.fetchVerse(reference: reference)
                return [singleVerse]
            }
            
            // Fetch each verse in the range
            var verses: [Verse] = []
            for verseNum in startVerse...min(endVerse, startVerse + 20) { // Limit to 20 verses max
                do {
                    let verseRef = "\(bookCode).\(chapter).\(verseNum)"
                    let verse = try await bibleAPI.fetchVerse(reference: verseRef)
                    verses.append(verse)
                } catch {
                    print("⚠️ Failed to fetch verse \(verseNum): \(error)")
                    // Continue with other verses
                }
            }
            
            return verses.isEmpty ? [try await bibleAPI.fetchVerse(reference: "\(bookCode).\(chapter).\(startVerse)")] : verses
        } else {
            // Single verse
            let singleVerse = try await bibleAPI.fetchVerse(reference: reference)
            return [singleVerse]
        }
    }
    
    func cleanVerseText(_ text: String, verseNumber: Int) -> String {
        // Remove verse numbers from the beginning of text
        var cleanedText = text
        
        // Common patterns for verse numbers that the API might include
        let patterns = [
            "^\(verseNumber)\\s*",           // "9 " at start
            "^\(verseNumber)[A-Za-z]*\\s*",  // "9But " or "9And "
            "^\(verseNumber)[.,;:]?\\s*",    // "9. " or "9, "
        ]
        
        for pattern in patterns {
            cleanedText = cleanedText.replacingOccurrences(
                of: pattern, 
                with: "", 
                options: [.regularExpression, .anchored]
            )
        }
        
        // Also handle common cases where verse number is embedded
        if cleanedText.hasPrefix("\(verseNumber)") {
            // Remove the number and any following non-letter characters
            let startIndex = cleanedText.index(cleanedText.startIndex, offsetBy: String(verseNumber).count)
            if startIndex < cleanedText.endIndex {
                let remainder = String(cleanedText[startIndex...])
                // Skip any non-letter characters at the beginning
                if let firstLetterIndex = remainder.firstIndex(where: { $0.isLetter }) {
                    cleanedText = String(remainder[firstLetterIndex...])
                }
            }
        }
        
        return cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func formatScriptureReference(_ reference: String) -> String {
        // Convert API format to human-readable format
        // e.g., "1TH.4.9-11" -> "1 Thessalonians 4:9-11"
        let bookMappings: [String: String] = [
            "GEN": "Genesis", "EXO": "Exodus", "LEV": "Leviticus",
            "DEU": "Deuteronomy", "JER": "Jeremiah",
            "PSA": "Psalm", "MAT": "Matthew", "MRK": "Mark",
            "LUK": "Luke", "JHN": "John", "1TH": "1 Thessalonians",
            "JAS": "James"
        ]
        
        let parts = reference.split(separator: ".")
        guard parts.count >= 2 else { return reference }
        
        let bookCode = String(parts[0])
        let chapter = String(parts[1])
        let verse = parts.count > 2 ? String(parts[2]) : ""
        
        let bookName = bookMappings[bookCode] ?? bookCode
        return verse.isEmpty ? "\(bookName) \(chapter)" : "\(bookName) \(chapter):\(verse)"
    }
    
    func enhanceReading(_ reading: Reading) async -> Reading {
        // Try to extract and fetch actual scripture references
        let text = reading.verses.first?.text ?? ""
        
        // Look for scripture references in common formats
        if let reference = extractScriptureReference(from: text) {
            do {
                let enhancedVerse = try await bibleAPI.fetchVerse(reference: reference)
                return Reading(
                    title: reading.title,
                    subtitle: reading.subtitle,
                    verses: [enhancedVerse],
                    theme: reading.theme,
                    liturgicalContext: reading.liturgicalContext
                )
            } catch {
                print("Failed to fetch scripture for \(reference): \(error)")
            }
        }
        
        // If no reference found or fetch failed, return enhanced version of original
        return Reading(
            title: reading.title,
            subtitle: "From today's Mass",
            verses: reading.verses.map { verse in
                Verse(
                    text: cleanLiturgicalText(verse.text),
                    reference: "\(reading.title) - \(liturgicalDay.dateString)",
                    bookName: reading.title,
                    chapter: 1,
                    verseNumber: 1
                )
            },
            theme: "\(liturgicalDay.season.displayName) - \(reading.title)",
            liturgicalContext: reading.liturgicalContext
        )
    }
    
    func extractScriptureReference(from text: String) -> String? {
        // Common patterns for scripture references in liturgical texts
        let patterns = [
            #"([1-3]?\s*[A-Za-z]+)\s+(\d+):(\d+)(?:-(\d+))?"#, // "John 3:16" or "1 Cor 13:4-8"
            #"([A-Za-z]+)\s+(\d+),\s*(\d+)"#, // "Genesis 1, 3"
            #"(Ps|Psalm)\s+(\d+)"# // "Ps 23" or "Psalm 23"
        ]
        
        for pattern in patterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let reference = String(text[match])
                return convertToAPIFormat(reference)
            }
        }
        
        return nil
    }
    
    func convertToAPIFormat(_ reference: String) -> String? {
        // Convert common book names to API.Bible format
        let bookMappings = [
            "Genesis": "GEN", "Exodus": "EXO", "Leviticus": "LEV",
            "Matthew": "MAT", "Mark": "MRK", "Luke": "LUK", "John": "JHN",
            "Romans": "ROM", "1 Corinthians": "1CO", "2 Corinthians": "2CO",
            "Psalm": "PSA", "Psalms": "PSA", "Ps": "PSA"
        ]
        
        let components = reference.components(separatedBy: CharacterSet(charactersIn: " :,-"))
            .filter { !$0.isEmpty }
        
        guard components.count >= 2 else { return nil }
        
        let bookName = components[0]
        let chapter = components[1]
        let verse = components.count > 2 ? components[2] : "1"
        
        if let apiCode = bookMappings[bookName] {
            return "\(apiCode).\(chapter).\(verse)"
        }
        
        return nil
    }
    
    func cleanLiturgicalText(_ text: String) -> String {
        var cleanText = text
        
        // Remove all HTML tags
        cleanText = cleanText.replacingOccurrences(of: #"<[^>]*>"#, with: "", options: .regularExpression)
        
        // Decode HTML entities
        cleanText = cleanText
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&apos;", with: "'")
        
        // Remove reading labels
        cleanText = cleanText
            .replacingOccurrences(of: "Reading 1", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "First Reading", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Gospel", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Responsorial Psalm", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Alleluia", with: "", options: .caseInsensitive)
        
        // Clean up whitespace and newlines
        cleanText = cleanText
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If the text is still mostly HTML-like (has many special characters), extract meaningful content
        if cleanText.contains("href=") || cleanText.contains("class=") {
            // Try to extract just the meaningful text between quotes or after common patterns
            if let range = cleanText.range(of: #"[A-Za-z][^<>&]*[.!?]"#, options: .regularExpression) {
                cleanText = String(cleanText[range])
            } else {
                // Fallback: just take words and basic punctuation
                cleanText = cleanText.replacingOccurrences(of: #"[^A-Za-z0-9\s.,!?:;-]"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return cleanText.isEmpty ? "Today's reading from the liturgy" : cleanText
    }
}