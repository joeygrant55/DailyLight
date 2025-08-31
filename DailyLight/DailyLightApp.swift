import SwiftUI

@main
struct DailyLightApp: App {
    @StateObject private var creditManager = CreditManager.shared
    @StateObject private var readingsManager = ReadingsManager.shared
    @StateObject private var collectionsManager = BiblicalCollectionsManager.shared
    @StateObject private var bibleAPIService = BibleAPIService.shared
    @StateObject private var liturgicalService = USCCBLiturgicalService.shared
    @StateObject private var saintService = SaintService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(creditManager)
                .environmentObject(readingsManager)
                .environmentObject(collectionsManager)
                .environmentObject(bibleAPIService)
                .environmentObject(liturgicalService)
                .environmentObject(saintService)
                .onAppear {
                    creditManager.checkAndResetDailyCredits()
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var creditManager: CreditManager
    @EnvironmentObject var readingsManager: ReadingsManager
    @EnvironmentObject var collectionsManager: BiblicalCollectionsManager
    
    var body: some View {
        NavigationStack {
            HomeView()
        }
        .preferredColorScheme(.light)
    }
}