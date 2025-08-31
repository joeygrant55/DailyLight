import SwiftUI

struct UnifiedHomeView: View {
    @EnvironmentObject var scriptureService: UnifiedScriptureService
    @EnvironmentObject var creditManager: CreditManager
    @EnvironmentObject var saintService: SaintService
    
    @State private var selectedTab: BibleTab = .today
    @State private var searchQuery = ""
    @State private var showingSearch = false
    @State private var selectedScripture: Scripture?
    
    enum BibleTab: String, CaseIterable {
        case today = "Today"
        case bible = "Bible"
        case journeys = "Journeys"
        case saved = "Library"
        
        var icon: String {
            switch self {
            case .today: return "sun.max.fill"
            case .bible: return "book.fill"
            case .journeys: return "map.fill"
            case .saved: return "bookmark.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with unified search
                headerView
                
                // Tab selector
                tabSelector
                
                // Content based on selected tab
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case .today:
                            todayView
                        case .bible:
                            bibleView
                        case .journeys:
                            journeysView
                        case .saved:
                            libraryView
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedScripture) { scripture in
                EnhancedReadingView(scripture: scripture)
                    .environmentObject(creditManager)
                    .environmentObject(scriptureService)
            }
            .sheet(isPresented: $showingSearch) {
                ScriptureSearchView(
                    query: $searchQuery,
                    onSelect: { scripture in
                        selectedScripture = scripture
                        showingSearch = false
                    }
                )
                .environmentObject(scriptureService)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Light")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(Date(), style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Credits indicator
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text("\(creditManager.dailyCredits)")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
            }
            
            // Unified search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search scriptures, themes, or saints...", text: $searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        if !searchQuery.isEmpty {
                            showingSearch = true
                        }
                    }
                
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 2)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(BibleTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                        Text(tab.rawValue)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundColor(selectedTab == tab ? .blue : .gray)
                    .background(
                        VStack {
                            Spacer()
                            if selectedTab == tab {
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(height: 2)
                            }
                        }
                    )
                }
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Today View
    
    private var todayView: some View {
        VStack(spacing: 20) {
            // Today's liturgy card
            if let liturgy = scriptureService.dailyLiturgy {
                liturgyCard(liturgy)
            }
            
            // Saint of the day
            if let saint = saintService.todaysSaint {
                saintCard(saint)
            }
            
            // Quick access to daily readings
            dailyReadingsCard
            
            // Suggested journey
            suggestedJourneyCard
        }
    }
    
    private func liturgyCard(_ liturgy: LiturgicalReadings) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(liturgicalColor(liturgy.liturgicalColor))
                    .frame(width: 12, height: 12)
                
                Text("Today's Mass Readings")
                    .font(.headline)
                
                Spacer()
                
                if let feast = liturgy.feastDay {
                    Text(feast)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            ForEach(liturgy.readings.prefix(3)) { scripture in
                Button(action: { selectedScripture = scripture }) {
                    HStack {
                        Image(systemName: iconForContext(scripture.context))
                            .frame(width: 30)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(scripture.reference.displayText)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(scripture.metadata.theme)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
                
                if scripture.id != liturgy.readings.last?.id {
                    Divider()
                }
            }
            
            Button(action: { 
                if let firstReading = liturgy.readings.first {
                    selectedScripture = firstReading
                }
            }) {
                Text("Begin Today's Readings")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func saintCard(_ saint: Saint) -> some View {
        Button(action: {
            // Load saint's scripture if available
            Task {
                if let reference = saint.scriptureReference {
                    let scriptureRef = parseReference(reference)
                    if let scripture = try? await scriptureService.getScripture(reference: scriptureRef) {
                        selectedScripture = scripture
                    }
                }
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saint of the Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(saint.name)
                        .font(.headline)
                    Text(saint.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dailyReadingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Scripture")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(["Morning", "Evening", "Night"], id: \.self) { time in
                    Button(action: {
                        // Load appropriate reading for time of day
                        loadDailyReading(for: time)
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: timeIcon(for: time))
                                .font(.title2)
                            Text(time)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var suggestedJourneyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Suggested Journey")
                    .font(.headline)
                Spacer()
                Text("NEW")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            
            Text("The Parables of Jesus")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Explore 7 parables that reveal the Kingdom of Heaven")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                // Navigate to parables journey
                selectedTab = .journeys
            }) {
                Text("Start Journey")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
    
    // MARK: - Bible View
    
    private var bibleView: some View {
        VStack(spacing: 20) {
            // Quick navigation
            BibleQuickNavView { reference in
                Task {
                    if let scripture = try? await scriptureService.getScripture(reference: reference) {
                        selectedScripture = scripture
                    }
                }
            }
            
            // Recently read
            recentlyReadSection
            
            // Popular passages
            popularPassagesSection
        }
    }
    
    // MARK: - Journeys View
    
    private var journeysView: some View {
        VStack(spacing: 20) {
            ForEach(CollectionCategory.allCases, id: \.self) { category in
                JourneyCategoryCard(
                    category: category,
                    onSelectJourney: { collection in
                        // Navigate to journey
                        if let firstScene = collection.scenes.first,
                           let firstReading = firstScene.readings.first {
                            let scripture = convertReadingToScripture(firstReading)
                            selectedScripture = scripture
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Library View
    
    private var libraryView: some View {
        VStack(spacing: 20) {
            // Saved images
            Text("Your Saved Images")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray.opacity(0.5))
                        )
                }
            }
            
            // Bookmarked scriptures
            Text("Bookmarked Scriptures")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Your bookmarked scriptures will appear here")
                .foregroundColor(.secondary)
                .padding(.vertical, 40)
        }
    }
    
    // MARK: - Helper Views
    
    private var recentlyReadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Read")
                .font(.headline)
            
            Text("Your reading history will appear here")
                .foregroundColor(.secondary)
                .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var popularPassagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Passages")
                .font(.headline)
            
            ForEach([
                ("John 3:16", "For God so loved the world..."),
                ("Psalm 23", "The Lord is my shepherd..."),
                ("1 Corinthians 13", "Love is patient, love is kind...")
            ], id: \.0) { reference, preview in
                Button(action: {
                    loadPopularPassage(reference)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reference)
                                .fontWeight(.medium)
                            Text(preview)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func liturgicalColor(_ color: String) -> Color {
        switch color.lowercased() {
        case "green": return .green
        case "red": return .red
        case "purple": return .purple
        case "white": return .white
        case "gold": return .yellow
        default: return .gray
        }
    }
    
    private func iconForContext(_ context: ScriptureContext) -> String {
        switch context {
        case .gospel: return "book.closed.fill"
        case .psalm: return "music.note"
        case .epistle: return "envelope.fill"
        case .narrative: return "text.book.closed.fill"
        default: return "book.fill"
        }
    }
    
    private func timeIcon(for time: String) -> String {
        switch time {
        case "Morning": return "sunrise.fill"
        case "Evening": return "sunset.fill"
        case "Night": return "moon.stars.fill"
        default: return "clock.fill"
        }
    }
    
    private func loadDailyReading(for time: String) {
        // Load appropriate reading based on time
        Task {
            // This would fetch time-appropriate scripture
            if let todaysReading = scriptureService.readingsManager.todaysReading {
                let scripture = convertReadingToScripture(todaysReading)
                selectedScripture = scripture
            }
        }
    }
    
    private func loadPopularPassage(_ reference: String) {
        Task {
            let scriptureRef = parseReference(reference)
            if let scripture = try? await scriptureService.getScripture(reference: scriptureRef) {
                selectedScripture = scripture
            }
        }
    }
    
    private func parseReference(_ reference: String) -> ScriptureReference {
        // Simple parser for common references
        if reference == "John 3:16" {
            return ScriptureReference(book: "John", chapter: 3, startVerse: 16)
        } else if reference == "Psalm 23" {
            return ScriptureReference(book: "Psalms", chapter: 23, startVerse: 1, endVerse: 6)
        } else if reference == "1 Corinthians 13" {
            return ScriptureReference(book: "1 Corinthians", chapter: 13, startVerse: 1, endVerse: 13)
        }
        // Default
        return ScriptureReference(book: "Genesis", chapter: 1, startVerse: 1)
    }
    
    private func convertReadingToScripture(_ reading: Reading) -> Scripture {
        let verses = reading.verses.map { verse in
            ScriptureVerse(
                number: verse.verseNumber,
                text: verse.text,
                reference: ScriptureReference(
                    book: verse.bookName,
                    chapter: verse.chapter,
                    startVerse: verse.verseNumber
                )
            )
        }
        
        let reference = ScriptureReference(
            book: reading.verses.first?.bookName ?? "Unknown",
            chapter: reading.verses.first?.chapter ?? 1,
            startVerse: reading.verses.first?.verseNumber ?? 1,
            endVerse: reading.verses.last?.verseNumber
        )
        
        let context = scriptureService.detectContext(
            for: reading.verses.map { $0.text }.joined(separator: " "),
            book: reference.book
        )
        
        return Scripture(
            reference: reference,
            text: reading.verses.map { $0.text }.joined(separator: "\n"),
            verses: verses,
            context: context,
            metadata: ScriptureMetadata(
                liturgicalUse: reading.liturgicalContext,
                feastDay: nil,
                theme: reading.theme,
                relatedReferences: [],
                historicalContext: nil,
                applicationNotes: nil
            )
        )
    }
}

// MARK: - Supporting Views

struct BibleQuickNavView: View {
    let onSelect: (ScriptureReference) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Navigation")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(["Genesis", "Psalms", "Matthew", "John", "Romans", "Revelation"], id: \.self) { book in
                        Button(action: {
                            onSelect(ScriptureReference(book: book, chapter: 1, startVerse: 1))
                        }) {
                            Text(book)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(20)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

struct JourneyCategoryCard: View {
    let category: CollectionCategory
    let onSelectJourney: (BibleCollection) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundColor(Color(hex: category.color))
                Text(category.displayName)
                    .font(.headline)
            }
            
            // Journey previews would go here
            Text("Explore \(category.displayName) journeys")
                .foregroundColor(.secondary)
                .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ScriptureSearchView: View {
    @Binding var query: String
    let onSelect: (Scripture) -> Void
    @EnvironmentObject var scriptureService: UnifiedScriptureService
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            VStack {
                if scriptureService.isLoading {
                    ProgressView("Searching...")
                        .padding()
                } else if scriptureService.searchResults.isEmpty {
                    Text("No results found")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List(scriptureService.searchResults) { scripture in
                        Button(action: { onSelect(scripture) }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(scripture.reference.displayText)
                                    .fontWeight(.medium)
                                Text(scripture.text.prefix(100) + "...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Search Results")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                searchTask = Task {
                    try? await scriptureService.searchScripture(query: query)
                }
            }
            .onDisappear {
                searchTask?.cancel()
            }
        }
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}