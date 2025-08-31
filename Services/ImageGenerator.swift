import Foundation
import UIKit

class ImageGenerator: ObservableObject {
    private let apiKey = APIConfig.geminiAPIKey
    private let apiEndpoint = APIConfig.apiEndpoint
    
    private let imageCache = ImageCache.shared
    private let session = URLSession.shared
    private let liturgicalService = USCCBLiturgicalService.shared
    
    func generate(verse: Verse, theme: String) async throws -> UIImage {
        return try await generateImage(
            prompt: createPrompt(for: verse, theme: theme),
            verse: verse,
            theme: theme
        )
    }
    
    func generateImage(prompt: String, verse: Verse, theme: String) async throws -> UIImage {
        // Check cache first
        let cacheKey = "\(verse.id)_natural_style"
        if let cachedImage = imageCache.get(key: cacheKey) {
            return cachedImage
        }
        
        // Generate prompt
        // Use provided prompt instead of generating one
        let finalPrompt = prompt
        
        // Make API request
        let image = try await generateWithNanoBanana(prompt: finalPrompt)
        
        // Cache the result
        imageCache.set(image, for: cacheKey)
        
        return image
    }
    
    func generateForScripture(_ scripture: Scripture) async throws -> UIImage {
        // Check cache first
        let cacheKey = "\(scripture.id)_contextual"
        if let cachedImage = imageCache.get(key: cacheKey) {
            return cachedImage
        }
        
        // Generate context-aware prompt
        let prompt = createContextAwarePrompt(for: scripture)
        
        // Make API request
        let image = try await generateWithNanoBanana(prompt: prompt)
        
        // Cache the result
        imageCache.set(image, for: cacheKey)
        
        return image
    }
    
    private func createContextAwarePrompt(for scripture: Scripture) -> String {
        let liturgicalTheme = getLiturgicalEnhancement()
        
        // Create a prompt that helps readers understand the context
        let contextDescription = getContextDescription(for: scripture.context)
        let visualStyle = getVisualStyle(for: scripture.context)
        
        return """
        Create a \(visualStyle) depicting: "\(scripture.text)"
        
        Biblical context: \(scripture.reference.displayText)
        Scripture type: \(scripture.context.rawValue)
        Theme: \(scripture.metadata.theme)
        \(liturgicalTheme)
        
        Visual requirements:
        \(contextDescription)
        
        Style guidelines:
        - Help the viewer understand the historical and spiritual context
        - Show the setting and characters appropriate to the time period
        - Include visual elements that clarify the meaning
        - Make it reverent and suitable for Catholic meditation
        - Use lighting and composition to convey the spiritual significance
        """
    }
    
    private func getContextDescription(for context: ScriptureContext) -> String {
        switch context {
        case .narrative:
            return """
            - Show the actual biblical scene with historically accurate settings
            - Include the main characters and their interactions
            - Depict the landscape and architecture of ancient Israel/Middle East
            - Use natural, realistic lighting to set the mood
            """
        case .psalm:
            return """
            - Create a contemplative scene of worship and prayer
            - Show figures in reverent poses with hands raised or kneeling
            - Include elements of creation praising God (mountains, seas, heavens)
            - Use divine light streaming from above
            """
        case .parable:
            return """
            - Illustrate the story with clear visual metaphors
            - Show both the earthly story and hint at the spiritual meaning
            - Include symbolic elements that reveal deeper truths
            - Use composition to guide the eye through the narrative
            """
        case .gospel:
            return """
            - Focus on Jesus as the central figure with divine presence
            - Show disciples and crowds in period-appropriate dress
            - Include details of 1st century Jewish life and customs
            - Use sacred art traditions with halos or divine light for holy figures
            """
        case .prophecy:
            return """
            - Create a vision-like quality with mystical elements
            - Show the prophet receiving or proclaiming the message
            - Include symbolic imagery from the prophecy
            - Use dramatic lighting and supernatural elements
            """
        case .epistle:
            return """
            - Show early Christian communities gathering or in prayer
            - Include scrolls or letters being read
            - Depict the unity and love of the early Church
            - Use warm, intimate lighting suggesting indoor gatherings
            """
        case .wisdom:
            return """
            - Create a contemplative scene with wise figures
            - Include symbols of knowledge (scrolls, books, light)
            - Show the beauty of God's order in creation
            - Use balanced, harmonious composition
            """
        case .apocalyptic:
            return """
            - Show heavenly visions with angels and divine throne
            - Include symbolic creatures and numbers from the text
            - Depict the cosmic battle between good and evil
            - Use dramatic contrasts of light and darkness
            """
        case .law:
            return """
            - Show Moses or lawgivers with tablets or scrolls
            - Include the mountain or temple setting
            - Depict the solemnity and authority of God's commands
            - Use strong, authoritative composition
            """
        }
    }
    
    private func getVisualStyle(for context: ScriptureContext) -> String {
        switch context {
        case .narrative, .gospel:
            return "realistic biblical scene in the style of classical religious paintings"
        case .psalm:
            return "ethereal worship scene with luminous, spiritual atmosphere"
        case .parable:
            return "illustrative scene that clearly shows both story and meaning"
        case .prophecy, .apocalyptic:
            return "visionary mystical scene with symbolic imagery"
        case .epistle:
            return "warm scene of early Christian community life"
        case .wisdom:
            return "contemplative scene showing divine wisdom in creation"
        case .law:
            return "majestic scene showing divine authority and reverence"
        }
    }
    
    private func createPrompt(for verse: Verse, theme: String) -> String {
        // Get current liturgical context for enhanced theming
        let liturgicalTheme = getLiturgicalEnhancement()
        
        return """
        Create a natural style cinematic biblical scene depicting: "\(verse.text)"
        
        Biblical context: \(verse.bookName) \(verse.chapter):\(verse.verseNumber)
        Theme: \(theme)
        \(liturgicalTheme)
        
        Style requirements:
        - Sacred and reverent
        - Appropriate for Catholic worship
        - Beautiful and inspiring
        - Natural, cinematic style
        - Contemporary Catholic art approach
        - Clean composition with symbolic elements
        - Peaceful and meditative
        - Soft, harmonious colors
        - Accessible modern interpretation
        - High detail and artistic quality
        """
    }
    
    private func getLiturgicalEnhancement() -> String {
        guard let liturgy = liturgicalService.todaysLiturgy else {
            return ""
        }
        
        let seasonalGuidance = """
        
        Liturgical context: \(liturgy.title)
        Season: \(liturgy.season.displayName) - \(liturgy.season.themeDescription)
        Liturgical color: \(liturgy.color.rawValue)
        
        Seasonal art enhancement: \(liturgy.season.artTheme)
        """
        
        return seasonalGuidance
    }
    
    private func generateWithNanoBanana(prompt: String) async throws -> UIImage {
        print("🎨 Generating image with Gemini API for prompt: \(prompt)")
        
        guard let url = URL(string: apiEndpoint) else {
            throw ImageGenerationError.apiError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        
        // Correct Gemini API request format from Context7 MCP documentation
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ImageGenerationError.apiError
            }
            
            print("📡 Gemini API Response Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("✅ Gemini API Response received")
                    
                    // Parse Gemini response format
                    if let candidates = json["candidates"] as? [[String: Any]],
                       let firstCandidate = candidates.first,
                       let content = firstCandidate["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]] {
                        
                        for part in parts {
                            // Look for image data
                            if let inlineData = part["inlineData"] as? [String: Any],
                               let base64Data = inlineData["data"] as? String,
                               let imageData = Data(base64Encoded: base64Data),
                               let image = UIImage(data: imageData) {
                                print("✅ Successfully generated image with Gemini!")
                                return image
                            }
                            
                            // Alternative format
                            if let imageData = part["imageData"] as? String,
                               let data = Data(base64Encoded: imageData),
                               let image = UIImage(data: data) {
                                print("✅ Successfully generated image with Gemini!")
                                return image
                            }
                        }
                    }
                }
            } else {
                // Log error details
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Gemini API Error (\(httpResponse.statusCode)): \(errorString)")
                }
            }
            
            // Fallback to placeholder
            print("🎭 Using placeholder image - API response parsing failed")
            return createPlaceholderImage(for: prompt)
            
        } catch {
            print("❌ Network error: \(error)")
            return createPlaceholderImage(for: prompt)
        }
    }
    
    private func createPlaceholderImage(for prompt: String) -> UIImage {
        let size = CGSize(width: 1024, height: 1024)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Create beautiful Catholic-themed gradient
            let colors = [
                UIColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1.0).cgColor, // Deep blue
                UIColor(red: 0.3, green: 0.1, blue: 0.3, alpha: 1.0).cgColor, // Deep purple
                UIColor(red: 0.2, green: 0.3, blue: 0.1, alpha: 1.0).cgColor  // Deep green
            ]
            
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: colors as CFArray,
                                        locations: [0.0, 0.5, 1.0]) {
                context.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: CGPoint(x: size.width/2, y: size.width/2),
                    startRadius: 0,
                    endCenter: CGPoint(x: size.width/2, y: size.width/2),
                    endRadius: size.width/2,
                    options: []
                )
            }
            
            // Add subtle cross pattern
            context.cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.1).cgColor)
            context.cgContext.setLineWidth(3)
            
            // Vertical line of cross
            context.cgContext.move(to: CGPoint(x: size.width/2, y: size.height*0.3))
            context.cgContext.addLine(to: CGPoint(x: size.width/2, y: size.height*0.7))
            
            // Horizontal line of cross
            context.cgContext.move(to: CGPoint(x: size.width*0.4, y: size.height/2))
            context.cgContext.addLine(to: CGPoint(x: size.width*0.6, y: size.height/2))
            
            context.cgContext.strokePath()
            
            // Add title
            let titleStyle = NSMutableParagraphStyle()
            titleStyle.alignment = .center
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: titleStyle
            ]
            
            let title = "Sacred Art"
            let titleRect = CGRect(x: 50, y: size.height*0.2, width: size.width - 100, height: 50)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Add preview text
            let bodyStyle = NSMutableParagraphStyle()
            bodyStyle.alignment = .center
            
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9),
                .paragraphStyle: bodyStyle
            ]
            
            let bodyText = "Image generation ready!\n\nConnecting to AI service..."
            let bodyRect = CGRect(x: 50, y: size.height*0.75, width: size.width - 100, height: 100)
            bodyText.draw(in: bodyRect, withAttributes: bodyAttributes)
        }
    }
}

enum ImageGenerationError: Error {
    case apiError
    case invalidResponse
    case noCredits
}

class ImageCache {
    static let shared = ImageCache()
    private var cache: [String: UIImage] = [:]
    private let queue = DispatchQueue(label: "imagecache", attributes: .concurrent)
    
    private init() {}
    
    func get(key: String) -> UIImage? {
        queue.sync {
            return cache[key]
        }
    }
    
    func set(_ image: UIImage, for key: String) {
        queue.async(flags: .barrier) {
            self.cache[key] = image
            
            // Save to disk for persistence
            self.saveToDisk(image, key: key)
        }
    }
    
    private func saveToDisk(_ image: UIImage, key: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileURL = getCacheDirectory().appendingPathComponent("\(key).jpg")
        try? data.write(to: fileURL)
    }
    
    private func loadFromDisk(key: String) -> UIImage? {
        let fileURL = getCacheDirectory().appendingPathComponent("\(key).jpg")
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else { return nil }
        return image
    }
    
    private func getCacheDirectory() -> URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDirectory = paths[0].appendingPathComponent("GeneratedImages")
        
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        
        return cacheDirectory
    }
}