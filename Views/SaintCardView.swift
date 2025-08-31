import SwiftUI

struct SaintCardView: View {
    let saint: Saint
    @StateObject private var saintService = SaintService.shared
    @State private var saintImage: UIImage?
    @State private var isGeneratingImage = false
    @State private var showingSaintDetail = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Saint Info
            saintHeaderView
            
            // Main Content
            HStack(spacing: 16) {
                // Saint Image
                saintImageView
                
                // Saint Information
                saintInfoView
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(saint.liturgicalRank.color.opacity(0.3), lineWidth: 1)
                )
        )
        .onTapGesture {
            showingSaintDetail = true
        }
        .sheet(isPresented: $showingSaintDetail) {
            SaintDetailView(saint: saint, existingImage: saintImage)
        }
        .onAppear {
            generateSaintImageIfNeeded()
        }
    }
    
    var saintHeaderView: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "figure.wave")
                    .foregroundColor(saint.liturgicalRank.color)
                    .font(.caption)
                
                Text("SAINT OF THE DAY")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.2)
            }
            
            Spacer()
            
            // Liturgical Rank Badge
            Text(saint.liturgicalRank.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(saint.liturgicalRank.color.opacity(0.2))
                .foregroundColor(saint.liturgicalRank.color)
                .cornerRadius(6)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    var saintImageView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .frame(width: 80, height: 80)
            
            if let image = saintImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if isGeneratingImage {
                VStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white.opacity(0.6))
                    
                    Text("Creating\nIcon")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Button("Generate") {
                        generateSaintImageIfNeeded()
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    var saintInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Saint Name and Title
            VStack(alignment: .leading, spacing: 2) {
                Text(saint.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if !saint.title.isEmpty {
                    Text(saint.title)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
            }
            
            // Life Period
            Text(saint.livedPeriod)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            // Patronage (first few items)
            if !saint.patronOf.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(saint.liturgicalRank.color)
                        .font(.caption)
                    
                    Text("Patron of \(saint.patronOf.prefix(2).joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            
            // Famous Quote Preview
            if let quote = saint.famousQuote {
                Text("\"\(quote.prefix(50))\(quote.count > 50 ? "..." : "")\"")
                    .font(.caption)
                    .italic()
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            
            // Tap to Learn More
            Text("Tap to learn more about \(saint.name)")
                .font(.caption2)
                .foregroundColor(.blue)
                .opacity(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    func generateSaintImageIfNeeded() {
        guard saintImage == nil && !isGeneratingImage else { return }
        
        isGeneratingImage = true
        
        Task {
            do {
                let image = try await saintService.generateSaintArt(for: saint)
                await MainActor.run {
                    saintImage = image
                    isGeneratingImage = false
                }
            } catch {
                print("Failed to generate saint image: \(error)")
                await MainActor.run {
                    isGeneratingImage = false
                }
            }
        }
    }
}

struct SaintDetailView: View {
    let saint: Saint
    let existingImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var saintService = SaintService.shared
    @StateObject private var bibleAPI = BibleAPIService.shared
    @State private var relatedReadings: [Reading] = []
    @State private var saintImage: UIImage?
    @State private var isLoadingReadings = false
    @State private var isGeneratingImage = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        saintHeaderDetail
                        biographySection
                        patronageSection
                        if let quote = saint.famousQuote {
                            quoteSection(quote)
                        }
                        virtuesSection
                        if !relatedReadings.isEmpty {
                            relatedReadingsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                // Use existing image if available
                saintImage = existingImage
                loadRelatedReadings()
            }
        }
    }
    
    var saintHeaderDetail: some View {
        VStack(spacing: 20) {
            // Enhanced Saint Image with better framing
            if let image = saintImage {
                // Beautiful framed image
                VStack(spacing: 0) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.yellow.opacity(0.6), Color.orange.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                    
                    // Golden ornamental divider
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color.yellow.opacity(0.5))
                            .frame(height: 1)
                        
                        Image(systemName: "cross.fill")
                            .foregroundColor(.yellow.opacity(0.7))
                            .font(.caption)
                        
                        Rectangle()
                            .fill(Color.yellow.opacity(0.5))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 16)
                }
            } else if isGeneratingImage {
                // Loading state
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 280)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.yellow.opacity(0.8))
                        
                        Text("Creating Sacred Art...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
            } else {
                // Placeholder with generate button
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 280)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    VStack(spacing: 16) {
                        Image(systemName: "figure.wave")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow.opacity(0.5))
                        
                        Text("Saint Iconography")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Button(action: generateSaintImage) {
                            HStack {
                                Image(systemName: "paintbrush.fill")
                                Text("Generate Sacred Art")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Saint Name and Title with enhanced typography
            VStack(spacing: 12) {
                Text(saint.name)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                
                Text(saint.title)
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundColor(.yellow.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .italic()
                
                // Life period and birthplace with icon
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        Text(saint.livedPeriod)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    if let birthPlace = saint.birthPlace {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            Text(birthPlace)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                // Liturgical rank badge
                Text(saint.liturgicalRank.rawValue.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(1.5)
                    .foregroundColor(saint.liturgicalRank.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(saint.liturgicalRank.color.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(saint.liturgicalRank.color.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .padding(.horizontal, 20)
        }
    }
    
    var biographySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Life & Legacy")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(saint.biography)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    var patronageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patronage")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(saint.patronOf, id: \.self) { patronage in
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(saint.liturgicalRank.color)
                            .font(.caption)
                        
                        Text(patronage)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    func quoteSection(_ quote: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.title2)
                .foregroundColor(saint.liturgicalRank.color)
            
            Text(quote)
                .font(.title3)
                .italic()
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Text("— \(saint.name)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(saint.liturgicalRank.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(saint.liturgicalRank.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    var virtuesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Virtues")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(saint.keyVirtues, id: \.self) { virtue in
                    Text(virtue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(saint.liturgicalRank.color.opacity(0.2))
                        .foregroundColor(saint.liturgicalRank.color)
                        .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    var relatedReadingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Scripture")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            ForEach(relatedReadings, id: \.id) { reading in
                NavigationLink(destination: ReadingView(reading: reading)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reading.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Text(reading.verses.first?.text.prefix(100) ?? "")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.caption)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    func loadRelatedReadings() {
        isLoadingReadings = true
        
        Task {
            let references = saint.getRelatedScriptureReferences()
            var readings: [Reading] = []
            
            for reference in references.prefix(3) { // Limit to 3 related readings
                do {
                    let verse = try await bibleAPI.fetchVerse(reference: reference)
                    let reading = Reading(
                        title: "Scripture for \(saint.name)",
                        subtitle: verse.reference,
                        verses: [verse],
                        theme: "Saint \(saint.name) - \(saint.title)",
                        liturgicalContext: "Related to \(saint.name)"
                    )
                    readings.append(reading)
                } catch {
                    print("⚠️ Failed to load scripture \(reference) for \(saint.name): \(error)")
                    // Continue with other references - don't let one failure stop the rest
                }
            }
            
            await MainActor.run {
                relatedReadings = readings
                isLoadingReadings = false
            }
        }
    }
    
    func generateSaintImage() {
        guard !isGeneratingImage else { return }
        
        isGeneratingImage = true
        
        Task {
            do {
                let image = try await saintService.generateSaintArt(for: saint)
                await MainActor.run {
                    saintImage = image
                    isGeneratingImage = false
                }
            } catch {
                print("Failed to generate saint image in detail view: \(error)")
                await MainActor.run {
                    isGeneratingImage = false
                }
            }
        }
    }
}