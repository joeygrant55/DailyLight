import SwiftUI

@main
struct DailyLightApp: App {
    @StateObject private var creditManager = CreditManager.shared
    @StateObject private var scriptureService = UnifiedScriptureService.shared
    @StateObject private var saintService = SaintService.shared
    @StateObject private var readingsManager = ReadingsManager.shared
    @StateObject private var collectionsManager = BiblicalCollectionsManager.shared
    @StateObject private var bibleAPIService = BibleAPIService.shared
    @StateObject private var liturgicalService = USCCBLiturgicalService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(creditManager)
                .environmentObject(scriptureService)
                .environmentObject(saintService)
                .environmentObject(readingsManager)
                .environmentObject(collectionsManager)
                .environmentObject(bibleAPIService)
                .environmentObject(liturgicalService)
                .onAppear {
                    creditManager.checkAndResetDailyCredits()
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var creditManager: CreditManager
    @EnvironmentObject var scriptureService: UnifiedScriptureService
    @EnvironmentObject var saintService: SaintService
    
    var body: some View {
        UnifiedHomeView()
            .preferredColorScheme(.light)
    }
}