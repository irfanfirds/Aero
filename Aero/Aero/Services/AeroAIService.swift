import Foundation
import FirebaseCore
import GoogleGenerativeAI

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

    // MARK: - Model Names
    private static let primaryModelName  = "gemini-2.5-flash"
    private static let fallbackModelName = "gemini-2.5-flash-lite"

    // MARK: - Primary Model Instances
    private var _chatModel: GenerativeModel?
    private var _insightModel: GenerativeModel?
    private var _recipeModel: GenerativeModel?

    // MARK: - Fallback Model Instances (gemini-2.5-flash-lite — separate infra)
    private var _chatModelFallback: GenerativeModel?
    private var _insightModelFallback: GenerativeModel?
    private var _recipeModelFallback: GenerativeModel?

    // MARK: - Quota Tracking
    private let quotaLimit = 500
    private let usageKey   = "AERO_DAILY_USAGE"
    private let dateKey    = "AERO_LAST_REQUEST_DATE"

    // MARK: - Response Caches (in-memory, cleared on app restart)
    private var insightCache: [String: SustainabilityResponse] = [:]
    private var recipeCache:  [String: [SharedRecipe]] = [:]

    private var isFirebaseConfigured: Bool { FirebaseApp.app() != nil }

    private init() {}

    // MARK: - API Key

    private func geminiAPIKey() -> String {
        guard let url = Bundle.main.url(forResource: "APIKeys", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url),
              let key = dict["GEMINI_API_KEY"] as? String,
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              key != "ADD_YOUR_GEMINI_KEY_HERE" else {
            fatalError("Missing GEMINI_API_KEY in APIKeys.plist. Add your Gemini API key there.")
        }
        return key
    }

    // MARK: - Model Accessors

    private func chatModel() -> GenerativeModel {
        if let m = _chatModel { return m }
        let m = GenerativeModel(
            name: Self.primaryModelName,
            apiKey: geminiAPIKey(),
            generationConfig: GenerationConfig(temperature: 0.7, maxOutputTokens: 2000),
            systemInstruction: ModelContent(role: "system", parts: [.text(Self.chatManifesto)])
        )
        _chatModel = m
        return m
    }

    private func chatFallbackModel() -> GenerativeModel {
        if let m = _chatModelFallback { return m }
        let m = GenerativeModel(
            name: Self.fallbackModelName,
            apiKey: geminiAPIKey(),
            generationConfig: GenerationConfig(temperature: 0.7, maxOutputTokens: 2000),
            systemInstruction: ModelContent(role: "system", parts: [.text(Self.chatManifesto)])
        )
        _chatModelFallback = m
        return m
    }

    private func insightModel() -> GenerativeModel {
        if let m = _insightModel { return m }
        let m = GenerativeModel(
            name: Self.primaryModelName,
            apiKey: geminiAPIKey(),
            generationConfig: GenerationConfig(temperature: 0.3, maxOutputTokens: 512, responseMIMEType: "application/json"),
            systemInstruction: ModelContent(role: "system", parts: [.text(Self.systemManifesto)])
        )
        _insightModel = m
        return m
    }

    private func insightFallbackModel() -> GenerativeModel {
        if let m = _insightModelFallback { return m }
        let m = GenerativeModel(
            name: Self.fallbackModelName,
            apiKey: geminiAPIKey(),
            generationConfig: GenerationConfig(temperature: 0.3, maxOutputTokens: 512, responseMIMEType: "application/json"),
            systemInstruction: ModelContent(role: "system", parts: [.text(Self.systemManifesto)])
        )
        _insightModelFallback = m
        return m
    }

    private func recipeModel() -> GenerativeModel {
        if let m = _recipeModel { return m }
        let m = GenerativeModel(
            name: Self.primaryModelName,
            apiKey: geminiAPIKey(),
            generationConfig: GenerationConfig(temperature: 0.5, maxOutputTokens: 2000, responseMIMEType: "application/json"),
            systemInstruction: ModelContent(role: "system", parts: [.text(Self.systemManifesto)])
        )
        _recipeModel = m
        return m
    }

    private func recipeFallbackModel() -> GenerativeModel {
        if let m = _recipeModelFallback { return m }
        let m = GenerativeModel(
            name: Self.fallbackModelName,
            apiKey: geminiAPIKey(),
            generationConfig: GenerationConfig(temperature: 0.5, maxOutputTokens: 2000, responseMIMEType: "application/json"),
            systemInstruction: ModelContent(role: "system", parts: [.text(Self.systemManifesto)])
        )
        _recipeModelFallback = m
        return m
    }

    // MARK: - System Prompts

    private static let chatManifesto = """
    You are the Aero Intelligence Cluster — a kitchen assistant AI with a clinical, brutalist tone.
    Help users manage their food inventory, suggest recipes, and reduce food waste.
    Respond in clear, direct plain text. No JSON, no code blocks, no markdown formatting.
    Keep responses concise and actionable.
    """

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

        let context = inventory.map { $0.name }.joined(separator: ", ")
        let prompt  = "Current inventory: [\(context)]. User request: \(userMessage)"

        do {
            let result = try await withRetryAndFallback(
                primary: chatModel(),
                fallback: chatFallbackModel(),
                prompt: prompt
            )
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

        // Return cached result if inventory hasn't changed
        let cacheKey = inventory.sorted().joined(separator: ",")
        if let cached = insightCache[cacheKey] { return cached }

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
            let result = try await withRetryAndFallback(
                primary: insightModel(),
                fallback: insightFallbackModel(),
                prompt: prompt
            )

            guard let responseText = result.text, !responseText.isEmpty else {
                throw AeroError.emptyResponse
            }

            let cleanJSON = sanitizeJSON(responseText)

            guard let data = cleanJSON.data(using: .utf8) else {
                throw AeroError.invalidJSON
            }

            let response = try JSONDecoder().decode(SustainabilityResponse.self, from: data)
            insightCache[cacheKey] = response
            incrementUsage()
            return response

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

        // Return cached result if ingredient list hasn't changed
        let cacheKey = items.sorted().joined(separator: ",")
        if let cached = recipeCache[cacheKey] { return cached }

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
            let result = try await withRetryAndFallback(
                primary: recipeModel(),
                fallback: recipeFallbackModel(),
                prompt: prompt
            )

            guard let responseText = result.text, !responseText.isEmpty else {
                throw AeroError.emptyResponse
            }

            let cleanJSON = sanitizeJSON(responseText)

            guard let data = cleanJSON.data(using: .utf8) else {
                throw AeroError.invalidJSON
            }

            let recipes = try JSONDecoder().decode([SharedRecipe].self, from: data)
            recipeCache[cacheKey] = recipes
            incrementUsage()
            return recipes

        } catch let error as AeroError {
            throw error
        } catch let error as DecodingError {
            print("❌ AeroAIService [Recipes] Decode Error: \(error)")
            throw AeroError.invalidJSON
        } catch {
            throw mapGenerateError(error)
        }
    }

    // MARK: - Retry with Fallback
    //
    // Attempt 1: gemini-2.5-flash          (immediate)
    //   503 → wait 1s
    // Attempt 2: gemini-2.5-flash          (retry)
    //   503 → wait 3s
    // Attempt 3: gemini-2.5-flash-lite     (fallback, separate infra)
    //   fail → throw to caller for mapping
    //
    // Any non-503 error (quota, offline, auth) short-circuits immediately.

    private func withRetryAndFallback(
        primary: GenerativeModel,
        fallback: GenerativeModel,
        prompt: String
    ) async throws -> GenerateContentResponse {
        // Attempt 1: primary
        do {
            return try await primary.generateContent(prompt)
        } catch {
            guard (mapGenerateError(error) as? AeroError) == .serviceUnavailable else { throw error }
        }

        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s

        // Attempt 2: primary retry
        do {
            return try await primary.generateContent(prompt)
        } catch {
            guard (mapGenerateError(error) as? AeroError) == .serviceUnavailable else { throw error }
        }

        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3s

        // Attempt 3: fallback model
        return try await fallback.generateContent(prompt)
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

    private func httpStatusCode(from error: Error) -> Int? {
        let ns = error as NSError
        if ns.code >= 400 && ns.code < 600 { return ns.code }
        if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? NSError,
           underlying.code >= 400 && underlying.code < 600 {
            return underlying.code
        }
        return nil
    }

    private func mapGenerateError(_ error: Error) -> Error {
        if let aeroErr = error as? AeroError { return aeroErr }

        let nsErr = error as NSError

        if nsErr.domain == NSURLErrorDomain {
            return AeroError.offline
        }

        if let code = httpStatusCode(from: error) {
            switch code {
            case 503: return AeroError.serviceUnavailable
            case 429: return AeroError.quotaExceeded
            case 401, 403: return AeroError.invalidAPIKey
            case 404: return AeroError.serviceUnavailable
            default: break
            }
        }

        let desc = nsErr.localizedDescription.lowercased()

        if desc.contains("api key") || desc.contains("unauthenticated") {
            return AeroError.invalidAPIKey
        }
        if desc.contains("unavailable") || desc.contains("503") || desc.contains("high demand") || desc.contains("overloaded") {
            return AeroError.serviceUnavailable
        }
        if desc.contains("quota") || desc.contains("429") || desc.contains("rate") || desc.contains("too many") {
            return AeroError.quotaExceeded
        }
        if desc.contains("not found") || desc.contains("not supported") {
            return AeroError.serviceUnavailable
        }

        return AeroError.serviceUnavailable
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
