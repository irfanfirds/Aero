import Foundation
import Combine

@MainActor
final class RecipeViewModel: ObservableObject {
    @Published var discoveredRecipes: [SharedRecipe] = []
    @Published var searchFieldText: String = ""
    @Published var isSearchingRecipes: Bool = false
    @Published var recipeErrorMessage: String? = nil

    // MARK: - TheMealDB Search

    func searchMealDB(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            discoveredRecipes = []
            isSearchingRecipes = false
            recipeErrorMessage = nil
            return
        }
        isSearchingRecipes = true
        recipeErrorMessage = nil
        defer { isSearchingRecipes = false }

        do {
            discoveredRecipes = try await TheMealDBService.search(query: trimmed)
        } catch {
            recipeErrorMessage = "THEMEALDB LIVE SYNC FAILED"
        }
    }

    // MARK: - Gemini Smart Recipe Generation

    func generateGeminiRecipes(inventoryNames: [String]) async {
        guard !inventoryNames.isEmpty else {
            discoveredRecipes = []
            recipeErrorMessage = nil
            return
        }
        isSearchingRecipes = true
        recipeErrorMessage = nil
        defer { isSearchingRecipes = false }

        do {
            discoveredRecipes = try await AeroAIService.shared.generateSmartRecipes(from: inventoryNames)
        } catch {
            if let aero = error as? AeroError {
                switch aero {
                case .offline:           recipeErrorMessage = "No internet connection. Please try again."
                case .invalidAPIKey:     recipeErrorMessage = "Gemini API key invalid or missing."
                case .quotaExceeded:     recipeErrorMessage = "Daily request limit reached. Try again tomorrow."
                case .serviceUnavailable: recipeErrorMessage = "Gemini service is temporarily unavailable."
                case .emptyResponse:     recipeErrorMessage = "No response from Gemini."
                case .invalidJSON:       recipeErrorMessage = "Unexpected data format from Gemini."
                case .previewMode:       recipeErrorMessage = nil
                }
            } else {
                recipeErrorMessage = error.localizedDescription
            }
            discoveredRecipes = []
        }
    }

}
