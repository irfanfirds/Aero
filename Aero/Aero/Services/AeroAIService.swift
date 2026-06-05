import Foundation
import FirebaseCore // Keep this for FirebaseApp
import GoogleGenerativeAI // This is the ONLY AI import you need now

// MARK: - Error Types

enum AeroError: Error, LocalizedError {
    case emptyResponse
    case quotaExceeded
    case invalidJSON
    case offline
    case invalidAPIKey
    case serviceUnavailable
    case previewMode

    var errorDescription: String? {
        switch self {
        case .emptyResponse:      return "NO SIGNAL — AI returned an empty response."
        case .quotaExceeded:      return "QUOTA EXCEEDED — Daily limit reached. Try again tomorrow."
        case .invalidJSON:        return "PARSE FAILURE — Received malformed data from AI service."
        case .offline:            return "OFFLINE — No internet connection detected."
        case .invalidAPIKey:      return "AUTH FAILURE — Firebase AI is not configured correctly."
        case .serviceUnavailable: return "SERVICE DOWN — Gemini is temporarily unavailable."
        case .previewMode:        return "PREVIEW MODE — AI features disabled in canvas previews."
        }
    }
}

// MARK: - Sustainability Response Model

struct SustainabilityResponse: Codable {
    let alertTitle: String
    let co2Saved: String
    let recommendedRecipe: String
}

// MARK: - AeroAIService

class AeroAIService {
    static let shared = AeroAIService()
    
    // MARK: - Private Helper
    
    private func geminiAPIKey() -> String {
        // Look for the Key Name "GEMINI_API_KEY" instead of the long hardcoded string
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fatalError("Missing GEMINI_API_KEY in Info.plist. Add your Gemini API key to Info.plist under the key name GEMINI_API_KEY.")
        }
        return key
    }

    // MARK: - Private Model Instances
    // Lazy so Firebase is only accessed after FirebaseApp.configure() runs
    // This prevents the SwiftUI Preview assertion crash
    private var _chatModel: GenerativeModel?
    private var _insightModel: GenerativeModel?
    private var _recipeModel: GenerativeModel?

    // MARK: - Quota Tracking
    private let quotaLimit = 250
    private let usageKey   = "AERO_DAILY_USAGE"
    private let dateKey    = "AERO_LAST_REQUEST_DATE"

    // MARK: - Firebase Configured Check
    // Guards against calling FirebaseAI before FirebaseApp.configure()
    private var isFirebaseConfigured: Bool {
        return FirebaseApp.app() != nil
    }

    // MARK: - Init
    // NOTE: Models are NOT initialized here to prevent Preview crashes
    // They are created lazily on first use via getModel()
    private init() {}

    // MARK: - Standardized Accessors
    // Ensure you have: import GoogleGenerativeAI at the top of your file

    private func chatModel() -> GenerativeModel {
        if let model = _chatModel { return model }
        
        let model = GenerativeModel(
            name: "gemini-1.5-flash",
            apiKey: geminiAPIKey(),
            generationConfig: GenerationConfig(temperature: 0.7, maxOutputTokens: 2000),
            systemInstruction: ModelContent(role: "system", parts: [.text(Self.systemManifesto)])
        )
        _chatModel = model
        return model
    }

    private func insightModel() -> GenerativeModel {
        if let model = _insightModel { return model }
        
        let model = GenerativeModel(
            name: "gemini-1.5-flash",
            apiKey: geminiAPIKey(),
            generationConfig: GenerationConfig(temperature: 0.3, maxOutputTokens: 512, responseMIMEType: "application/json"),
            systemInstruction: ModelContent(role: "system", parts: [.text(Self.systemManifesto)])
        )
        _insightModel = model
        return model
    }

    private func recipeModel() -> GenerativeModel {
        if let model = _recipeModel { return model }
        
        let model = GenerativeModel(
            name: "gemini-1.5-flash",
            apiKey: geminiAPIKey(),
            generationConfig: GenerationConfig(temperature: 0.5, maxOutputTokens: 2000, responseMIMEType: "application/json"),
            systemInstruction: ModelContent(role: "system", parts: [.text(Self.systemManifesto)])
        )
        _recipeModel = model
        return model
    }
    
    
    // MARK: - Shared System Prompt
    private static let systemManifesto = """
    You are the Aero Intelligence Cluster. Respond in a clinical, brutalist tone.
    CRITICAL OUTPUT RULES:
    - Return ONLY raw JSON. No markdown, no code fences, no preamble.
    - Never wrap output in ```json blocks.
    - Match the exact schema provided.
    """

    // MARK: - Public Interface

    func getRemainingQuota() -> Int {
        checkAndResetDailyQuota()
        return max(0, quotaLimit - UserDefaults.standard.integer(forKey: usageKey))
    }

    // MARK: - Chat Response

    func getChatResponse(userMessage: String, inventory: [FoodItem]) async throws -> String {
        checkAndResetDailyQuota()
        try checkQuota()

        let model  = try chatModel()
        let context = inventory.map { $0.name }.joined(separator: ", ")
        let prompt  = "Current inventory: [\(context)]. User request: \(userMessage)"

        do {
            let result = try await model.generateContent(prompt)
            incrementUsage()
            return result.text ?? "CORE_SILENT"
        } catch {
            throw mapGenerateError(error)
        }
    }

    // MARK: - Sustainability Insight

    func getSustainabilityInsight(inventory: [String]) async throws -> SustainabilityResponse {
        checkAndResetDailyQuota()
        try checkQuota()

        let model  = try insightModel()
        let prompt = """
        Analyze the sustainability impact of this food inventory: [\(inventory.joined(separator: ", "))].
        Return a JSON object with exactly these keys:
        {
            "alertTitle": "short urgent headline about expiring items",
            "co2Saved": "estimated CO2 savings as a string e.g. '0.8kg'",
            "recommendedRecipe": "one recipe name that uses the most at-risk ingredients"
        }
        """

        do {
            let result = try await model.generateContent(prompt)

            guard let responseText = result.text, !responseText.isEmpty else {
                throw AeroError.emptyResponse
            }

            let cleanJSON = sanitizeJSON(responseText)

            guard let data = cleanJSON.data(using: .utf8) else {
                throw AeroError.invalidJSON
            }

            incrementUsage()
            return try JSONDecoder().decode(SustainabilityResponse.self, from: data)

        } catch let error as AeroError {
            throw error
        } catch let error as DecodingError {
            print("❌ AeroAIService [Insight] Decode Error: \(error)")
            throw AeroError.invalidJSON
        } catch {
            throw mapGenerateError(error)
        }
    }

    // MARK: - Smart Recipe Generation

    func generateSmartRecipes(from items: [String]) async throws -> [SharedRecipe] {
        checkAndResetDailyQuota()
        try checkQuota()

        let model   = try recipeModel()
        let primary = items.first ?? "available ingredients"
        let prompt  = """
        Generate exactly 2 creative recipes using these ingredients: [\(items.joined(separator: ", "))].
        Prioritize using: \(primary).
        Return a JSON array with exactly this structure for each recipe:
        [
            {
                "title": "Recipe Name",
                "description": "One sentence description",
                "highlightedIngredient": "the main ingredient from the list",
                "ingredients": ["ingredient 1", "ingredient 2"],
                "time": "20 mins",
                "instructions": "Step by step cooking instructions as a single string."
            }
        ]
        """

        do {
            let result = try await model.generateContent(prompt)

            guard let responseText = result.text, !responseText.isEmpty else {
                throw AeroError.emptyResponse
            }

            let cleanJSON = sanitizeJSON(responseText)

            guard let data = cleanJSON.data(using: .utf8) else {
                throw AeroError.invalidJSON
            }

            incrementUsage()
            return try JSONDecoder().decode([SharedRecipe].self, from: data)

        } catch let error as AeroError {
            throw error
        } catch let error as DecodingError {
            print("❌ AeroAIService [Recipes] Decode Error: \(error)")
            throw AeroError.invalidJSON
        } catch {
            throw mapGenerateError(error)
        }
    }

    // MARK: - JSON Sanitizer

    private func sanitizeJSON(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.contains("```") {
            cleaned = cleaned
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```JSON", with: "")
                .replacingOccurrences(of: "```",     with: "")
        }

        if let jsonRange = firstTopLevelJSONRange(in: cleaned) {
            cleaned = String(cleaned[jsonRange])
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func firstTopLevelJSONRange(in text: String) -> Range<String.Index>? {
        guard let startIndex = text.firstIndex(where: { $0 == "{" || $0 == "[" }) else {
            return nil
        }

        let openChar:  Character = text[startIndex]
        let closeChar: Character = openChar == "{" ? "}" : "]"
        var depth = 0
        var idx   = startIndex

        while idx < text.endIndex {
            let char = text[idx]
            if char == openChar  { depth += 1 }
            if char == closeChar {
                depth -= 1
                if depth == 0 {
                    return startIndex..<text.index(after: idx)
                }
            }
            idx = text.index(after: idx)
        }
        return nil
    }

    // MARK: - Error Mapper

    private func mapGenerateError(_ error: Error) -> Error {
        let nsErr = error as NSError

        if nsErr.domain == NSURLErrorDomain {
            return AeroError.offline
        }

        let desc = nsErr.localizedDescription.lowercased()

        if desc.contains("api key") || desc.contains("401") || desc.contains("unauthenticated") {
            return AeroError.invalidAPIKey
        }
        if desc.contains("unavailable") || desc.contains("503") {
            return AeroError.serviceUnavailable
        }
        if desc.contains("quota") || desc.contains("429") || desc.contains("rate") {
            return AeroError.quotaExceeded
        }

        return error
    }

    // MARK: - Quota Management

    private func checkAndResetDailyQuota() {
        let defaults = UserDefaults.standard
        let now      = Date()

        if let lastDate = defaults.object(forKey: dateKey) as? Date {
            if !Calendar.current.isDate(now, inSameDayAs: lastDate) {
                defaults.set(0, forKey: usageKey)
            }
        } else {
            defaults.set(0, forKey: usageKey)
        }

        defaults.set(now, forKey: dateKey)
    }

    private func checkQuota() throws {
        if UserDefaults.standard.integer(forKey: usageKey) >= quotaLimit {
            throw AeroError.quotaExceeded
        }
    }

    private func incrementUsage() {
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: usageKey) + 1, forKey: usageKey)
    }
}

