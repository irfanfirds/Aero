import Foundation
import SwiftUI
import Combine

struct ShoppingItem: Identifiable, Codable {
    let id: UUID
    let name: String
    var isAcquired: Bool = false
    let addedDate: Date
}

final class ShoppingStore: ObservableObject {
    @Published var items: [ShoppingItem] = []
    
    func addItem(_ name: String) {
        let newItem = ShoppingItem(id: UUID(), name: name, isAcquired: false, addedDate: Date())
        items.insert(newItem, at: 0)
    }
    
    func toggleAcquired(id: UUID) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items[idx].isAcquired.toggle()
        }
    }
    
    func transferAcquiredToFridge(historyStore: HistoryStore) {
        let acquiredItems = items.filter { $0.isAcquired }
        for item in acquiredItems {
            let newFood = FoodItem(
                name: item.name,
                category: .pantry,
                expiryDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                quantity: "1"
            )
            historyStore.addItem(newFood)
        }
        items.removeAll { $0.isAcquired }
    }
}

