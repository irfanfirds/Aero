import Foundation

class HistoryService {
    static let shared = HistoryService()
    private let inventoryKey = "aero_inventory_data"
    private let archiveKey = "aero_archive_data"
    private let movementsKey = "aero_movements_data"

    // SAVE: Encodes and writes to disk
    func saveInventory(_ items: [FoodItem]) {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: inventoryKey)
        }
    }

    // LOAD: Decodes from disk
    func loadInventory() -> [FoodItem] {
        guard let data = UserDefaults.standard.data(forKey: inventoryKey),
              let decoded = try? JSONDecoder().decode([FoodItem].self, from: data) else {
            return []
        }
        return decoded
    }

    // ARCHIVE: Separate storage for the Waste Report stats
    func archiveItem(_ item: FoodItem) {
        var archived = loadArchive()
        archived.append(item)
        if let encoded = try? JSONEncoder().encode(archived) {
            UserDefaults.standard.set(encoded, forKey: archiveKey)
        }
    }

    func loadArchive() -> [FoodItem] {
        guard let data = UserDefaults.standard.data(forKey: archiveKey),
              let decoded = try? JSONDecoder().decode([FoodItem].self, from: data) else {
            return []
        }
        return decoded
    }

    // Replace entire inventory (useful for imports/resets)
    func replaceInventory(with items: [FoodItem]) {
        saveInventory(items)
    }

    // Purge only active inventory
    func purgeInventory() {
        UserDefaults.standard.removeObject(forKey: inventoryKey)
    }

    // Purge only archive
    func purgeArchive() {
        UserDefaults.standard.removeObject(forKey: archiveKey)
    }

    // Purge both inventory and archive
    func purgeAllData() {
        purgeInventory()
        purgeArchive()
        purgeMovements()
    }

    // Export archive as JSON blob for sharing/audit
    func exportArchiveJSON() -> Data? {
        let archived = loadArchive()
        return try? JSONEncoder().encode(archived)
    }

    // MARK: - Movement Persistence
    func saveMovements(_ movements: [FoodMovement]) {
        if let encoded = try? JSONEncoder().encode(movements) {
            UserDefaults.standard.set(encoded, forKey: movementsKey)
        }
    }

    func loadMovements() -> [FoodMovement] {
        guard let data = UserDefaults.standard.data(forKey: movementsKey),
              let decoded = try? JSONDecoder().decode([FoodMovement].self, from: data) else {
            return []
        }
        return decoded
    }

    func purgeMovements() {
        UserDefaults.standard.removeObject(forKey: movementsKey)
    }
}
