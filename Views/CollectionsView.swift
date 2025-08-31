import SwiftUI

struct CollectionsView: View {
    @EnvironmentObject var collectionsManager: BiblicalCollectionsManager
    @Environment(\.dismiss) private var dismiss
    
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
                    LazyVStack(spacing: 20) {
                        ForEach(collectionsManager.allCollections) { collection in
                            NavigationLink(destination: CollectionDetailView(collection: collection)) {
                                CollectionCard(collection: collection)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Biblical Collections")
            .navigationBarTitleDisplayMode(.large)
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
}

struct CollectionCard: View {
    let collection: BibleCollection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
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
                    
                    Text(collection.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(collection.scenes.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: collection.color))
                    
                    Text("scenes")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Text(collection.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(3)
            
            HStack {
                Label("Start Journey", systemImage: "arrow.right")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
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
    CollectionsView()
        .environmentObject(BiblicalCollectionsManager.shared)
}