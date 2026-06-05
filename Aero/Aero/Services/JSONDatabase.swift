import Foundation

/// A service for saving and loading Codable data as JSON files in the app's documents directory.
struct JSONDatabase {
    /// Shared singleton instance of JSONDatabase.
    static let shared = JSONDatabase()
    
    private let queue = DispatchQueue(label: "jsondb.queue", attributes: .concurrent)
    
    private init() {}
    
    /// Errors that can occur during JSON database operations.
    enum JSONDBError: Error {
        case notFound
        case decodeFailed
        case encodeFailed
        case writeFailed
    }
    
    /// Returns the file URL in the documents directory for the given filename ensuring `.json` extension.
    /// - Parameter filename: The name of the file without extension.
    /// - Returns: URL pointing to the JSON file in the documents directory.
    private func fileURL(for filename: String) -> URL {
        var name = filename
        if !name.hasSuffix(".json") {
            name.append(".json")
        }
        return FileManager.default.documentsDirectory.appendingPathComponent(name)
    }
    
    /// Loads and decodes a Codable value of type `T` from a JSON file.
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - filename: The name of the JSON file (without extension).
    /// - Throws: `JSONDBError.notFound` if file doesn't exist and T is not an Array<FoodItem> or Array<FoodMovement>.
    ///           `JSONDBError.decodeFailed` if decoding fails.
    /// - Returns: Decoded object of type `T` or empty array if T is Array<FoodItem> or Array<FoodMovement> and file missing.
    func load<T: Decodable>(_ type: T.Type, from filename: String) throws -> T {
        try queue.sync {
            let url = fileURL(for: filename)
            guard FileManager.default.fileExists(atPath: url.path) else {
                // If T is Array<FoodItem> or Array<FoodMovement>, return empty array as default
                if T.self == Array<FoodItem>.self || T.self == Array<FoodMovement>.self {
                    return [] as! T
                }
                throw JSONDBError.notFound
            }
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            } catch {
                throw JSONDBError.decodeFailed
            }
        }
    }
    
    /// Saves and encodes an Encodable value `data` to a JSON file.
    /// - Parameters:
    ///   - data: The data to encode and save.
    ///   - filename: The name of the JSON file (without extension).
    /// - Throws: `JSONDBError.encodeFailed` if encoding fails.
    ///           `JSONDBError.writeFailed` if writing to file fails.
    func save<T: Encodable>(_ data: T, to filename: String) throws {
        try queue.sync(flags: .barrier) {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                encoder.dateEncodingStrategy = .iso8601
                let jsonData = try encoder.encode(data)
                let url = fileURL(for: filename)
                try jsonData.write(to: url, options: .atomic)
            } catch let error as EncodingError {
                throw JSONDBError.encodeFailed
            } catch {
                throw JSONDBError.writeFailed
            }
        }
    }
    
    /// Loads an array of `FoodItem` from the default JSON file "FoodItems.json".
    /// - Throws: Propagates errors from the generic load method.
    /// - Returns: Array of `FoodItem` loaded from disk or empty array if none found.
    func loadFoodItems() throws -> [FoodItem] {
        try load([FoodItem].self, from: "FoodItems")
    }
    
    /// Saves an array of `FoodItem` to the default JSON file "FoodItems.json".
    /// - Parameter items: The array of `FoodItem` to save.
    /// - Throws: Propagates errors from the generic save method.
    func saveFoodItems(_ items: [FoodItem]) throws {
        try save(items, to: "FoodItems")
    }
    
    /// Loads an array of `FoodMovement` from the default JSON file "Movements.json".
    func loadMovements() throws -> [FoodMovement] {
        try load([FoodMovement].self, from: "Movements")
    }
    
    /// Saves an array of `FoodMovement` to the default JSON file "Movements.json".
    func saveMovements(_ movements: [FoodMovement]) throws {
        try save(movements, to: "Movements")
    }
}

/// TODO: Ensure `FoodItem` conforms to `Codable` in your project.

extension FileManager {
    /// URL to the app's documents directory.
    var documentsDirectory: URL {
        urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
