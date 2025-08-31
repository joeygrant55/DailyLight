import SwiftUI

struct ReadingView: View {
    let reading: Reading
    @State private var currentIndex = 0
    @State private var generatedImages: [String: UIImage] = [:]
    @State private var isGenerating: Set<String> = []
    
    @EnvironmentObject var creditManager: CreditManager
    @StateObject private var imageGenerator = ImageGenerator()
    @Environment(\.dismiss) var dismiss
    
    var currentVerse: Verse {
        reading.verses[currentIndex]
    }
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > geometry.size.height {
                // Landscape - Side by side
                HStack(spacing: 0) {
                    verseView
                        .frame(width: geometry.size.width * 0.5)
                    
                    Divider()
                    
                    imageView
                        .frame(width: geometry.size.width * 0.5)
                }
            } else {
                // Portrait - Stacked
                VStack(spacing: 0) {
                    verseView
                        .frame(height: geometry.size.height * 0.5)
                    
                    Divider()
                    
                    imageView
                        .frame(height: geometry.size.height * 0.5)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(currentIndex + 1) of \(reading.verses.count)")
                    .font(.headline)
            }
            
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 50 && currentIndex > 0 {
                        withAnimation { currentIndex -= 1 }
                    } else if value.translation.width < -50 && currentIndex < reading.verses.count - 1 {
                        withAnimation { currentIndex += 1 }
                        generateUpcomingImages()
                    }
                }
        )
        .onAppear {
            generateInitialImages()
        }
    }
    
    var verseView: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(currentVerse.text)
                        .font(.title3)
                        .fontWeight(.medium)
                        .lineSpacing(8)
                        .padding(.horizontal, 24)
                        .padding(.top, 40)
                    
                    Spacer(minLength: 20)
                    
                    Text(currentVerse.reference)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            
            HStack(spacing: 20) {
                Button(action: previousVerse) {
                    Label("Previous", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                }
                .disabled(currentIndex == 0)
                .foregroundColor(currentIndex == 0 ? .gray : .primary)
                
                Spacer()
                
                if creditManager.dailyCredits > 0 || creditManager.isPremium {
                    Button(action: regenerateImage) {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                            .font(.callout)
                    }
                }
                
                Spacer()
                
                Button(action: nextVerse) {
                    Label("Next", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                }
                .disabled(currentIndex == reading.verses.count - 1)
                .foregroundColor(currentIndex == reading.verses.count - 1 ? .gray : .primary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(Color(UIColor.systemBackground))
    }
    
    var imageView: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
            
            if let image = generatedImages[currentVerse.id] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        Menu {
                            Button(action: saveToPhotos) {
                                Label("Save to Photos", systemImage: "square.and.arrow.down")
                            }
                            
                            Button(action: shareImage) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .padding()
                    }
                }
            } else if isGenerating.contains(currentVerse.id) {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Creating sacred art...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "photo.artframe")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    if creditManager.dailyCredits > 0 || creditManager.isPremium {
                        Button(action: generateCurrentImage) {
                            Text("Generate Image")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Text("No credits remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button(action: {}) {
                                Text("Upgrade to Premium")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func generateInitialImages() {
        Task {
            // Generate current and next 3 verses
            for i in 0..<min(4, reading.verses.count) {
                await generateImage(for: reading.verses[i])
            }
        }
    }
    
    func generateUpcomingImages() {
        Task {
            // Generate 3 verses ahead
            let nextIndex = currentIndex + 3
            if nextIndex < reading.verses.count {
                await generateImage(for: reading.verses[nextIndex])
            }
        }
    }
    
    func generateCurrentImage() {
        Task {
            await generateImage(for: currentVerse)
        }
    }
    
    func regenerateImage() {
        generatedImages[currentVerse.id] = nil
        Task {
            await generateImage(for: currentVerse)
        }
    }
    
    @MainActor
    func generateImage(for verse: Verse) async {
        guard generatedImages[verse.id] == nil,
              !isGenerating.contains(verse.id),
              creditManager.useCredit() else { return }
        
        isGenerating.insert(verse.id)
        
        do {
            let image = try await imageGenerator.generate(
                verse: verse,
                theme: reading.theme
            )
            
            withAnimation {
                generatedImages[verse.id] = image
                isGenerating.remove(verse.id)
            }
        } catch {
            print("Failed to generate image: \(error)")
            isGenerating.remove(verse.id)
            // Return the credit since generation failed
            creditManager.refundCredit()
        }
    }
    
    func previousVerse() {
        if currentIndex > 0 {
            withAnimation {
                currentIndex -= 1
            }
        }
    }
    
    func nextVerse() {
        if currentIndex < reading.verses.count - 1 {
            withAnimation {
                currentIndex += 1
            }
            generateUpcomingImages()
        }
    }
    
    func saveToPhotos() {
        guard let image = generatedImages[currentVerse.id] else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    func shareImage() {
        guard generatedImages[currentVerse.id] != nil else { return }
        // Implementation for sharing
    }
}

