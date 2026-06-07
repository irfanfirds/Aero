import Foundation

struct TheMealDBService {

    // MARK: - Search Meals by Name

    static func search(query: String) async throws -> [SharedRecipe] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        let urlString = "https://www.themealdb.com/api/json/v1/1/search.php?s=\(encoded)"
        guard let url = URL(string: urlString) else { return [] }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let meals = json["meals"] as? [[String: Any]] else {
            return []
        }

        return meals.compactMap { parseMeal($0, query: trimmed) }
    }

    // MARK: - Private

    private static func parseMeal(_ meal: [String: Any], query: String) -> SharedRecipe? {
        guard let name = meal["strMeal"] as? String,
              let instructions = meal["strInstructions"] as? String else { return nil }

        var ingredients: [String] = []
        for i in 1...20 {
            if let ingredient = meal["strIngredient\(i)"] as? String,
               !ingredient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let measure = meal["strMeasure\(i)"] as? String ?? ""
                ingredients.append("\(measure) \(ingredient)".trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        if ingredients.isEmpty { ingredients = [query] }

        return SharedRecipe(
            title: name,
            description: instructions,
            highlightedIngredient: query,
            ingredients: ingredients,
            time: "20-30 Mins",
            instructions: instructions
        )
    }
}
