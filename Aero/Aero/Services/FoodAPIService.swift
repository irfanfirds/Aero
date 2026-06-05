import Foundation

// MARK: - Nutrient Model (moved here as single source of truth)
struct Nutriments: Codable {
    let energyKcal: Double?
    let fat: Double?
    let carbohydrates: Double?
    let proteins: Double?
    let fiber: Double?
    let sugars: Double?
    let sodium: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal    = "energy-kcal_100g"
        case fat           = "fat_100g"
        case carbohydrates = "carbohydrates_100g"
        case proteins      = "proteins_100g"
        case fiber         = "fiber_100g"
        case sugars        = "sugars_100g"
        case sodium        = "sodium_100g"
    }

    // MARK: - Display Helpers
    var caloriesDisplay: String   { energyKcal.map    { "\(Int($0)) kcal" }   ?? "N/A" }
    var fatDisplay: String        { fat.map           { String(format: "%.1fg", $0) } ?? "N/A" }
    var carbsDisplay: String      { carbohydrates.map { String(format: "%.1fg", $0) } ?? "N/A" }
    var proteinsDisplay: String   { proteins.map      { String(format: "%.1fg", $0) } ?? "N/A" }
    var fiberDisplay: String      { fiber.map         { String(format: "%.1fg", $0) } ?? "N/A" }
    var sugarsDisplay: String     { sugars.map        { String(format: "%.1fg", $0) } ?? "N/A" }
    var sodiumDisplay: String     { sodium.map        { String(format: "%.0fmg", $0 * 1000) } ?? "N/A" }
}

// MARK: - Product Info Result
struct ProductInfo {
    let name: String?
    let imageUrl: String?
    let nutrients: Nutriments?
}

// MARK: - API Response Models
class FoodAPIService {
    static let shared = FoodAPIService()
    private init() {}

    // MARK: - Internal Decodable Models
    private struct OFFResponse: Codable {
        let product: OFFProduct?
        let status: Int
    }

    private struct OFFProduct: Codable {
        let productName: String?
        let imageFrontUrl: String?
        let categories: String?
        let nutriments: Nutriments?

        enum CodingKeys: String, CodingKey {
            case productName   = "product_name"
            case imageFrontUrl = "image_front_url"
            case categories
            case nutriments
        }
    }

    // MARK: - Unified Fetch (name + image + nutrients in ONE call)
    /// Fetches product name, image URL, and full nutritional data in a single API call.
    func fetchProductInfo(barcode: String, completion: @escaping (ProductInfo) -> Void) {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        guard let url = URL(string: urlString) else {
            completion(ProductInfo(name: nil, imageUrl: nil, nutrients: nil))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(ProductInfo(name: nil, imageUrl: nil, nutrients: nil))
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(OFFResponse.self, from: data)
                let product = decoded.product
                let info = ProductInfo(
                    name:      product?.productName,
                    imageUrl:  product?.imageFrontUrl,
                    nutrients: product?.nutriments
                )
                DispatchQueue.main.async { completion(info) }
            } catch {
                print("Aero_API: Decoding failed → \(error)")
                DispatchQueue.main.async {
                    completion(ProductInfo(name: nil, imageUrl: nil, nutrients: nil))
                }
            }
        }.resume()
    }

    // MARK: - Image Download (unchanged)
    func downloadImage(from urlString: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async { completion(data) }
        }.resume()
    }
}
