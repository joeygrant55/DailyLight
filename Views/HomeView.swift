import SwiftUI

struct HomeView: View {
    @EnvironmentObject var creditManager: CreditManager
    @EnvironmentObject var readingsManager: ReadingsManager
    @EnvironmentObject var collectionsManager: BiblicalCollectionsManager
    @EnvironmentObject var liturgicalService: USCCBLiturgicalService
    @StateObject private var saintService = SaintService.shared
    @State private var showingSubscription = false
    @State private var showingCollections = false
    
    var todaysReading: Reading? {
        readingsManager.todaysReading
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        liturgicalContextCard
                        
                        // Saint of the Day Card - Debug
                        Group {
                            if let saint = saintService.todaysSaint {
                                SaintCardView(saint: saint)
                            } else {
                                // Debug: Show why no saint is loading
                                Text("🔧 DEBUG: No saint found for today")
                                    .foregroundColor(.red)
                                    .padding()
                                    .background(Color.yellow.opacity(0.3))
                                    .cornerRadius(8)
                                    .onAppear {
                                        print("🔧 DEBUG: saintService.todaysSaint is nil")
                                        print("🔧 DEBUG: SaintService data count: \(SaintService.shared)")
                                        let testSaint = saintService.getTodaysSaint()
                                        print("🔧 DEBUG: getTodaysSaint() returns: \(testSaint?.name ?? "nil")")
                                    }
                            }
                        }
                        
                        if let reading = todaysReading {
                            todaysReadingCard(reading)
                        }
                        
                        biblicalCollectionsSection
                        
                        creditsView
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
        .sheet(isPresented: $showingCollections) {
            CollectionsView()
                .environmentObject(collectionsManager)
        }
    }
    
    var headerView: some View {
        VStack(spacing: 4) {
            Text("Daily Light")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Catholic Scripture & Sacred Art")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
    }
    
    func todaysReadingCard(_ reading: Reading) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Reading")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(reading.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(reading.subtitle)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                
                if let context = reading.liturgicalContext {
                    Label(context, systemImage: "cross.fill")
                        .font(.caption)
                        .foregroundColor(.yellow.opacity(0.9))
                        .padding(.top, 4)
                }
            }
            
            Text("\(reading.verses.count) verses • \(estimatedReadingTime(reading)) min read")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            NavigationLink(destination: ReadingView(reading: reading)) {
                HStack {
                    Text("Begin Reading")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
            .disabled(creditManager.dailyCredits == 0 && !creditManager.isPremium)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    var creditsView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                
                if creditManager.isPremium {
                    Text("Premium Member")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("Unlimited")
                        .foregroundColor(.green)
                } else {
                    Text("Daily Credits")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(creditManager.dailyCredits) remaining")
                        .foregroundColor(creditManager.dailyCredits > 0 ? .green : .red)
                }
            }
            .foregroundColor(.white)
            
            if !creditManager.isPremium {
                Button(action: { showingSubscription = true }) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        Text("Upgrade to Premium")
                            .fontWeight(.medium)
                        Spacer()
                        Text("$4.99/mo")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.black)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                Text("Get unlimited readings and image generations")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    var biblicalCollectionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Biblical Collections")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Explore Timeline, Themes & Character Journeys")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button("Browse Collections") {
                    showingCollections = true
                }
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(collectionsManager.featuredCollections.prefix(4)) { collection in
                    NavigationLink(destination: CollectionDetailView(collection: collection)) {
                        CollectionGridCard(collection: collection)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    func estimatedReadingTime(_ reading: Reading) -> Int {
        let wordsPerVerse = 25
        let wordsPerMinute = 200
        let totalWords = reading.verses.count * wordsPerVerse
        return max(1, totalWords / wordsPerMinute)
    }
    
    var liturgicalContextCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.title3)
                
                Text("LITURGICAL CALENDAR")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)
                
                Spacer()
                
                if liturgicalService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white.opacity(0.6))
                }
            }
            
            if let liturgy = liturgicalService.todaysLiturgy {
                VStack(alignment: .leading, spacing: 12) {
                    // Liturgical Day Title
                    Text(liturgy.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    // Season and Color Info
                    HStack(spacing: 12) {
                        // Liturgical Season
                        HStack(spacing: 6) {
                            Circle()
                                .fill(liturgy.color.swiftUIColor)
                                .frame(width: 12, height: 12)
                            
                            Text(liturgy.season.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        // Rank
                        Text(liturgy.rank.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    
                    // Season Theme
                    Text(liturgy.season.themeDescription)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .italic()
                    
                    // Mass Readings Summary - Always show
                    HStack {
                        Image(systemName: "book.closed")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.caption)
                        
                        if !liturgy.readings.allReadings.isEmpty {
                            Text("\(liturgy.readings.allReadings.count) Mass readings available")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text("Today's Mass readings")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        NavigationLink(destination: MassReadingsView(liturgicalDay: liturgy)) {
                            Text("View Readings")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                }
            } else if liturgicalService.error != nil {
                Text("Unable to load liturgical calendar")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .italic()
            } else {
                Text("Loading today's liturgy...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .italic()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct CollectionGridCard: View {
    let collection: BibleCollection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: collection.color))
                    .frame(width: 50, height: 50)
                
                Image(systemName: collection.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text("\(collection.scenes.count) scenes")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: collection.color).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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