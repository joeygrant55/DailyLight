import Foundation

enum APIConfig {
    // Get API key from environment variable or Info.plist
    static var geminiAPIKey: String {
        // 1. First try to get from environment variable (for development)
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // 2. Try to get from Info.plist (for production builds)
        if let infoPlistKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String, !infoPlistKey.isEmpty {
            return infoPlistKey
        }
        
        // 3. Fallback for testing (remove this in production!)
        #if DEBUG
        print("⚠️ Warning: No API key configured. Set GEMINI_API_KEY environment variable in Xcode scheme.")
        return "demo-key-placeholder"
        #else
        fatalError("❌ Gemini API key not found. Please set GEMINI_API_KEY environment variable or add to Info.plist")
        #endif
    }
    
    // Correct Gemini image generation endpoint from Context7 MCP docs
    static let geminiImageEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent"
    
    static let apiEndpoint = geminiImageEndpoint
    
    // Bible API Configuration
    static var bibleAPIKey: String {
        if let envKey = ProcessInfo.processInfo.environment["BIBLE_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        if let infoPlistKey = Bundle.main.object(forInfoDictionaryKey: "BIBLE_API_KEY") as? String, !infoPlistKey.isEmpty {
            return infoPlistKey
        }
        #if DEBUG
        print("⚠️ Warning: No Bible API key configured. Set BIBLE_API_KEY environment variable.")
        return "demo-bible-key-placeholder"
        #else
        fatalError("❌ Bible API key not found. Please set BIBLE_API_KEY environment variable or add to Info.plist")
        #endif
    }
    static let bibleAPIEndpoint = "https://api.scripture.api.bible/v1"
}