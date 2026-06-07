import Foundation
import SwiftUI

// No changes needed to the Enums, keeping them for context
enum FoodCategory: String, Codable, CaseIterable {
    case fruits = "Fruits", vegetables = "Vegetables", dairy = "Dairy", meat = "Meat", pantry = "Pantry", produce = "Produce"
}

enum ItemStatus: String, Codable {
    case fresh = "Fresh", expiring = "Expiring", expired = "Expired", consumed = "Consumed", wasted = "Wasted"
}

struct FoodItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: FoodCategory
    var expiryDate: Date
    var quantity: String
    var imageEmoji: String?
    var imageData: Data?
    
    // NEW: Property to store scanned barcode/UPC/EAN data
    var barcode: String?

    var userAction: ItemStatus? = nil
    
    var nutrients: Nutriments?
    
    // UPDATED: Initializer now accepts barcode as an optional parameter
    init(
        id: UUID = UUID(),
        name: String,
        category: FoodCategory,
        expiryDate: Date,
        quantity: String = "1",
        imageEmoji: String? = nil,
        imageData: Data? = nil,
        barcode: String? = nil,
        nutrients: Nutriments? = nil
        // Added barcode here
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.expiryDate = expiryDate
        self.quantity = quantity
        self.imageEmoji = imageEmoji
        self.imageData = imageData
        self.barcode = barcode
        self.nutrients = nutrients
        // Set the property
    }
    
    // UI HELPER: Logic for the "Aero" Terminal Status
    var status: ItemStatus {
        if let userAction = userAction { return userAction }
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        if daysUntilExpiry < 0 { return .expired }
        else if daysUntilExpiry <= 3 { return .expiring }
        else { return .fresh }
    }
    
    // Returns actual SwiftUI Color types instead of strings for safer UI building
    var themeColor: Color {
        switch status {
        case .fresh, .consumed: return .green
        case .expiring: return .yellow
        case .expired, .wasted: return .red
        }
    }
}
