import SwiftUI

struct EnhancedReadingView: View {
    let scripture: Scripture
    
    @EnvironmentObject var creditManager: CreditManager
    @EnvironmentObject var scriptureService: UnifiedScriptureService
    @StateObject private var imageGenerator = ImageGenerator()
    
    @State private var currentVerseIndex = 0
    @State private var generatedImage: UIImage?
    @State private var isGeneratingImage = false
    @State private var readingMode: ReadingMode = .normal
    @State private var showingModeSelector = false
    @State private var showingRelatedScriptures = false
    @State private var relatedScriptures: [Scripture] = []
    @State private var imageGenerationError: String?
    @State private var savedToLibrary = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    enum ReadingMode: String, CaseIterable {
        case normal = "Normal"
        case study = "Study"
        case lectio = "Lectio Divina"
        case journey = "Journey"
        
        var icon: String {
            switch self {
            case .normal: return "book.fill"
            case .study: return "magnifyingglass"
            case .lectio: return "hands.sparkles.fill"
            case .journey: return "map.fill"
            }
        }
        
        var description: String {
            switch self {
            case .normal: return "Standard reading with images"
            case .study: return "Deep dive with context and cross-references"
            case .lectio: return "Slow, meditative reading"
            case .journey: return "Guided progression through related passages"
            }
        }
        
        var readingPace: TimeInterval {
            switch self {
            case .normal: return 3.0
            case .study: return 5.0
            case .lectio: return 8.0
            case .journey: return 4.0
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient based on scripture context
                backgroundGradient
                
                // Main content
                if isLandscape(geometry) {
                    // Side-by-side layout for landscape
                    HStack(spacing: 0) {
                        scriptureView
                            .frame(width: geometry.size.width * 0.5)
                        
                        Divider()
                        
                        imageView
                            .frame(width: geometry.size.width * 0.5)
                    }
                } else {
                    // Stacked layout for portrait
                    VStack(spacing: 0) {
                        scriptureView
                            .frame(height: geometry.size.height * 0.5)
                        
                        Divider()
                        
                        imageView
                            .frame(height: geometry.size.height * 0.5)
                    }
                }
                
                // Overlay controls
                VStack {
                    topControls
                    Spacer()
                    if readingMode != .normal {
                        bottomControls
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            generateInitialImage()
            loadRelatedScriptures()
        }
        .sheet(isPresented: $showingModeSelector) {
            ReadingModeSelector(
                currentMode: $readingMode,
                onSelect: { mode in
                    readingMode = mode
                    showingModeSelector = false
                }
            )
        }
        .sheet(isPresented: $showingRelatedScriptures) {
            RelatedScripturesView(
                scriptures: relatedScriptures,
                onSelect: { related in
                    // Navigate to related scripture
                    showingRelatedScriptures = false
                }
            )
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: gradientColors(for: scripture.context)),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .opacity(0.05)
        .ignoresSafeArea()
    }
    
    private func gradientColors(for context: ScriptureContext) -> [Color] {
        switch context {
        case .psalm:
            return [.blue, .purple]
        case .gospel:
            return [.yellow, .orange]
        case .prophecy:
            return [.purple, .pink]
        case .wisdom:
            return [.green, .mint]
        default:
            return [.blue, .cyan]
        }
    }
    
    // MARK: - Scripture View
    
    private var scriptureView: some View {
        VStack(spacing: 0) {
            // Scripture header
            scriptureHeader
            
            // Scripture content
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if readingMode == .study {
                            // Historical context in study mode
                            if let context = scripture.metadata.historicalContext {
                                contextCard(title: "Historical Context", content: context)
                            }
                        }
                        
                        // Main scripture text
                        ForEach(Array(scripture.verses.enumerated()), id: \.element.id) { index, verse in
                            VerseView(
                                verse: verse,
                                isHighlighted: index == currentVerseIndex,
                                readingMode: readingMode
                            )
                            .id(verse.id)
                            .onTapGesture {
                                withAnimation {
                                    currentVerseIndex = index
                                }
                            }
                        }
                        
                        if readingMode == .study {
                            // Application notes in study mode
                            if let notes = scripture.metadata.applicationNotes {
                                contextCard(title: "Application", content: notes)
                            }
                            
                            // Cross references
                            if !scripture.metadata.relatedReferences.isEmpty {
                                crossReferencesCard
                            }
                        }
                        
                        if readingMode == .lectio {
                            // Lectio Divina prompts
                            lectioDivinaPrompts
                        }
                    }
                    .padding()
                }
                .onChange(of: currentVerseIndex) { newIndex in
                    withAnimation {
                        proxy.scrollTo(scripture.verses[newIndex].id, anchor: .center)
                    }
                }
            }
            
            // Navigation controls
            if scripture.verses.count > 1 {
                verseNavigationControls
            }
        }
        .background(Color(UIColor.systemBackground).opacity(0.95))
    }
    
    private var scriptureHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scripture.reference.displayText)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        Label(scripture.context.rawValue, systemImage: iconForContext(scripture.context))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let liturgicalUse = scripture.metadata.liturgicalUse {
                            Label(liturgicalUse, systemImage: "building.columns.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            Text(scripture.metadata.theme)
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var verseNavigationControls: some View {
        HStack(spacing: 20) {
            Button(action: previousVerse) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title)
                    .foregroundColor(currentVerseIndex > 0 ? .blue : .gray)
            }
            .disabled(currentVerseIndex == 0)
            
            Text("Verse \(currentVerseIndex + 1) of \(scripture.verses.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: nextVerse) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title)
                    .foregroundColor(currentVerseIndex < scripture.verses.count - 1 ? .blue : .gray)
            }
            .disabled(currentVerseIndex >= scripture.verses.count - 1)
            
            Spacer()
            
            // Auto-advance for Lectio Divina
            if readingMode == .lectio {
                Button(action: toggleAutoAdvance) {
                    Image(systemName: autoAdvancing ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Image View
    
    private var imageView: some View {
        ZStack {
            if let image = generatedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.3)]),
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
            } else if isGeneratingImage {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Creating sacred art...")
                        .font(.headline)
                    
                    Text("Interpreting: \(scripture.context.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
            } else if let error = imageGenerationError {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Unable to generate image")
                        .font(.headline)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: generateInitialImage) {
                        Label("Try Again", systemImage: "arrow.clockwise")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
            } else {
                // Placeholder
                VStack(spacing: 20) {
                    Image(systemName: "photo.artframe")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Tap to generate image")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if creditManager.dailyCredits > 0 || creditManager.isPremium {
                        Button(action: generateInitialImage) {
                            Label("Generate Image", systemImage: "sparkles")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    } else {
                        Text("No credits remaining")
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
            }
            
            // Image controls overlay
            if generatedImage != nil {
                VStack {
                    Spacer()
                    imageControls
                }
            }
        }
    }
    
    private var imageControls: some View {
        HStack(spacing: 20) {
            Button(action: regenerateImage) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                    Text("Regenerate")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
            
            Button(action: saveImage) {
                VStack(spacing: 4) {
                    Image(systemName: savedToLibrary ? "checkmark.circle.fill" : "square.and.arrow.down")
                    Text(savedToLibrary ? "Saved" : "Save")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
            
            Button(action: shareImage) {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
        .padding()
    }
    
    // MARK: - Controls
    
    private var topControls: some View {
        HStack {
            // Reading mode selector
            Button(action: { showingModeSelector = true }) {
                HStack(spacing: 4) {
                    Image(systemName: readingMode.icon)
                    Text(readingMode.rawValue)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(20)
            }
            
            Spacer()
            
            // Credits indicator
            if !creditManager.isPremium {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("\(creditManager.dailyCredits)")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(20)
            }
        }
        .padding()
    }
    
    private var bottomControls: some View {
        HStack {
            if readingMode == .journey {
                Button(action: { showingRelatedScriptures = true }) {
                    Label("Related", systemImage: "link")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Study Mode Components
    
    private func contextCard(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: "info.circle.fill")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            
            Text(content)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var crossReferencesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Cross References", systemImage: "link.circle.fill")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.purple)
            
            ForEach(scripture.metadata.relatedReferences, id: \.displayText) { reference in
                Button(action: {
                    // Load cross reference
                    Task {
                        if let related = try? await scriptureService.getScripture(reference: reference) {
                            // Handle navigation to related scripture
                        }
                    }
                }) {
                    Text("→ \(reference.displayText)")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Lectio Divina Components
    
    private var lectioDivinaPrompts: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reflect")
                .font(.headline)
            
            ForEach([
                ("Read", "What word or phrase stands out to you?"),
                ("Meditate", "What is God saying to you through this passage?"),
                ("Pray", "What do you want to say to God in response?"),
                ("Contemplate", "Rest in God's presence with this word")
            ], id: \.0) { stage, prompt in
                VStack(alignment: .leading, spacing: 4) {
                    Text(stage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                    Text(prompt)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isLandscape(_ geometry: GeometryProxy) -> Bool {
        geometry.size.width > geometry.size.height
    }
    
    private func iconForContext(_ context: ScriptureContext) -> String {
        switch context {
        case .psalm: return "music.note"
        case .gospel: return "cross.fill"
        case .epistle: return "envelope.fill"
        case .prophecy: return "eye.fill"
        case .wisdom: return "lightbulb.fill"
        case .narrative: return "book.closed.fill"
        case .parable: return "bubble.left.and.bubble.right.fill"
        case .apocalyptic: return "flame.fill"
        case .law: return "scroll.fill"
        }
    }
    
    private func generateInitialImage() {
        guard creditManager.useCredit() else {
            imageGenerationError = "No credits available"
            return
        }
        
        isGeneratingImage = true
        imageGenerationError = nil
        
        Task {
            do {
                let image = try await imageGenerator.generateForScripture(scripture)
                await MainActor.run {
                    self.generatedImage = image
                    self.isGeneratingImage = false
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingImage = false
                    self.imageGenerationError = error.localizedDescription
                    creditManager.refundCredit()
                }
            }
        }
    }
    
    private func regenerateImage() {
        generatedImage = nil
        generateInitialImage()
    }
    
    private func saveImage() {
        guard let image = generatedImage else { return }
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        withAnimation {
            savedToLibrary = true
        }
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            savedToLibrary = false
        }
    }
    
    private func shareImage() {
        guard let image = generatedImage else { return }
        
        let activityController = UIActivityViewController(
            activityItems: [image, scripture.reference.displayText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
    
    private func loadRelatedScriptures() {
        Task {
            if let related = try? await scriptureService.getRelatedScriptures(to: scripture) {
                await MainActor.run {
                    self.relatedScriptures = related
                }
            }
        }
    }
    
    private func previousVerse() {
        if currentVerseIndex > 0 {
            currentVerseIndex -= 1
        }
    }
    
    private func nextVerse() {
        if currentVerseIndex < scripture.verses.count - 1 {
            currentVerseIndex += 1
        }
    }
    
    @State private var autoAdvancing = false
    @State private var autoAdvanceTimer: Timer?
    
    private func toggleAutoAdvance() {
        autoAdvancing.toggle()
        
        if autoAdvancing {
            startAutoAdvance()
        } else {
            stopAutoAdvance()
        }
    }
    
    private func startAutoAdvance() {
        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: readingMode.readingPace, repeats: true) { _ in
            if currentVerseIndex < scripture.verses.count - 1 {
                withAnimation {
                    currentVerseIndex += 1
                }
            } else {
                stopAutoAdvance()
            }
        }
    }
    
    private func stopAutoAdvance() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil
        autoAdvancing = false
    }
}

// MARK: - Supporting Views

struct VerseView: View {
    let verse: ScriptureVerse
    let isHighlighted: Bool
    let readingMode: EnhancedReadingView.ReadingMode
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(verse.number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(isHighlighted ? .blue : .gray)
                .frame(width: 30, alignment: .trailing)
            
            Text(verse.text)
                .font(readingMode == .lectio ? .title3 : .body)
                .lineSpacing(readingMode == .lectio ? 8 : 4)
                .foregroundColor(isHighlighted ? .primary : .secondary)
                .animation(.easeInOut, value: isHighlighted)
            
            Spacer()
        }
        .padding(.vertical, readingMode == .lectio ? 12 : 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHighlighted ? Color.blue.opacity(0.1) : Color.clear)
        )
    }
}

struct ReadingModeSelector: View {
    @Binding var currentMode: EnhancedReadingView.ReadingMode
    let onSelect: (EnhancedReadingView.ReadingMode) -> Void
    
    var body: some View {
        NavigationView {
            List(EnhancedReadingView.ReadingMode.allCases, id: \.self) { mode in
                Button(action: { onSelect(mode) }) {
                    HStack {
                        Image(systemName: mode.icon)
                            .frame(width: 30)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.rawValue)
                                .fontWeight(.medium)
                            Text(mode.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if mode == currentMode {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("Reading Mode")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct RelatedScripturesView: View {
    let scriptures: [Scripture]
    let onSelect: (Scripture) -> Void
    
    var body: some View {
        NavigationView {
            List(scriptures) { scripture in
                Button(action: { onSelect(scripture) }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(scripture.reference.displayText)
                            .fontWeight(.medium)
                        Text(scripture.metadata.theme)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("Related Scriptures")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}