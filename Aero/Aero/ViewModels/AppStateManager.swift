import SwiftUI
import Combine // FIX: Resolves the missing module and conformance errors

// REMOVED: The duplicate ShoppingItem struct declaration.
// We are now safely using your pre-existing model.

// Struct to represent items inside your fridge
struct FridgeItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: String
    let expiryDate: Date
}

@MainActor
class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    
    // Core Collections
    @Published var fridgeItems: [FridgeItem] = [
        FridgeItem(name: "Avocado", category: "Fruits", expiryDate: Date().addingTimeInterval(172800)), // 2 days
        FridgeItem(name: "Bread", category: "Bakery", expiryDate: Date().addingTimeInterval(86400))     // 1 day
    ]
    
    // FIX: Using an Array instead of a Set because your original ShoppingItem
    // might not conform to Hashable yet. This prevents strict hash conflicts.
    @Published var shoppingList: [ShoppingItem] = []
    
    // Computed Badge Value
    var shoppingCartCount: Int {
        shoppingList.count
    }
    
    // MARK: - Intent Actions
    
    /// Backward-compatibility alias to handle direct recipe card item injections cleanly
    func addToShoppingCart(item: String) {
        addIngredientToShoppingList(item)
    }
    
    func addIngredientToShoppingList(_ name: String) {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else { return }
        
        // Prevent duplicate string additions safely using lowercased matching
        if !shoppingList.contains(where: { $0.name.lowercased() == normalizedName.lowercased() }) {
            
            // FIX: Matching your existing ShoppingItem initialization requirements perfectly
            let newItem = ShoppingItem(
                id: UUID(),          // Pass a fresh unique identity
                name: normalizedName,
                addedDate: Date()    // Tracks exactly when it was added to the list
            )
            
            shoppingList.append(newItem)
        }
    }
    
    func removeIngredientFromShoppingList(_ item: ShoppingItem) {
        // FIX: Remove item cleanly by matching its unique ID signature
        shoppingList.removeAll(where: { $0.id == item.id })
    }
}
