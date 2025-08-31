import SwiftUI

struct CollectionDetailView: View {
    let collection: BibleCollection
    @EnvironmentObject var creditManager: CreditManager
    @State private var selectedScene: BibleScene?
    
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
                    scenesSection
                }
                .padding()
            }
        }
        .navigationTitle(collection.title)
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedScene) { scene in
            SceneReadingView(scene: scene, collection: collection)
        }
    }
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: collection.color))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: collection.icon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(collection.scenes.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: collection.color))
                    
                    Text("scenes")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(1)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(collection.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(collection.subtitle)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(collection.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(nil)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: collection.color).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    var scenesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Journey Scenes")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(collection.scenes.count) scenes")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)
                    .tracking(1)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(collection.scenes.sorted(by: { $0.order < $1.order })) { scene in
                    SceneCard(
                        scene: scene,
                        collection: collection,
                        onTap: { selectedScene = scene }
                    )
                }
            }
        }
    }
}

struct SceneCard: View {
    let scene: BibleScene
    let collection: BibleCollection
    let onTap: () -> Void
    
    @EnvironmentObject var creditManager: CreditManager
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: collection.color).opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text("\(scene.order)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: collection.color))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(scene.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(scene.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Label("\(scene.readings.count) reading\(scene.readings.count == 1 ? "" : "s")", 
                              systemImage: "book")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        if scene.imagePrompt != nil {
                            Label("Sacred art", systemImage: "photo")
                                .font(.caption)
                                .foregroundColor(Color(hex: collection.color).opacity(0.8))
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .disabled(creditManager.dailyCredits == 0 && !creditManager.isPremium)
        .opacity(creditManager.dailyCredits == 0 && !creditManager.isPremium ? 0.5 : 1.0)
    }
}

struct SceneReadingView: View {
    let scene: BibleScene
    let collection: BibleCollection
    @Environment(\.dismiss) private var dismiss
    @State private var currentReadingIndex = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    sceneHeader
                    
                    if !scene.readings.isEmpty {
                        TabView(selection: $currentReadingIndex) {
                            ForEach(Array(scene.readings.enumerated()), id: \.offset) { index, reading in
                                ReadingView(reading: reading)
                                    .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                    }
                }
                .padding()
            }
            .navigationTitle(scene.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    var sceneHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: collection.color))
                        .frame(width: 40, height: 40)
                    
                    Text("\(scene.order)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(scene.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(collection.title)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: collection.color))
                }
                
                Spacer()
            }
            
            Text(scene.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
            
            if scene.readings.count > 1 {
                Text("\(scene.readings.count) readings • Swipe to navigate")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: collection.color).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    CollectionDetailView(collection: SampleCollections.createWalkWithJesusCollection())
        .environmentObject(CreditManager.shared)
}