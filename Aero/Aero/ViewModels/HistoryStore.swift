import Foundation
import SwiftUI
import Combine

final class HistoryStore: ObservableObject {
    @Published var foodItems: [FoodItem] = [] // Initialized with empty array
    @Published var movements: [FoodMovement] = []
    private var cancellables: Set<AnyCancellable> = []
     
    var items: [FoodItem] {
        get { foodItems }
        set { foodItems = newValue }
    }
     
    init(foodItems: [FoodItem] = [], movements: [FoodMovement] = []) {
        // 1. Assign immediate parameters (if any)
        self.foodItems = foodItems
        self.movements = movements

        // 2. SHORT-CIRCUIT FOR XCODE PREVIEWS
        // Stops execution here so previews don't try to access protected disk/notification systems
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // Optional: Populate mock data here if you want your previews to look populated by default
            return
        }

        // 3. Load from disk ASYNCHRONOUSLY to prevent the 5s crash (Production Only)
        DispatchQueue.main.async {
            // Prefer JSONDatabase if available
            if let jsonItems = try? JSONDatabase.shared.loadFoodItems(), !jsonItems.isEmpty {
                self.foodItems = jsonItems
            }

            if let jsonMovements = try? JSONDatabase.shared.loadMovements(), !jsonMovements.isEmpty {
                self.movements = jsonMovements
            }

            let storedItems = HistoryService.shared.loadInventory()
            let storedMovements = HistoryService.shared.loadMovements()

            if self.foodItems.isEmpty && !storedItems.isEmpty {
                self.foodItems = storedItems
            }

            if self.movements.isEmpty && !storedMovements.isEmpty {
                self.movements = storedMovements
            }
            
            // 4. Only start observing AFTER the initial load to prevent save-looping
            self.setupObservers()
        }
    }

    private func setupObservers() {
        // Guard checking to ensure background observation streams aren't running in a preview target
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }

        // AUTO-SAVE OBSERVERS (Using debounce to keep the UI smooth)
        $foodItems
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { items in
                // Save on a background thread
                DispatchQueue.global(qos: .background).async {
                    HistoryService.shared.saveInventory(items)
                    do { try JSONDatabase.shared.saveFoodItems(items) } catch { print("JSONDB save error: \(error)") }
                }
            }
            .store(in: &cancellables)

        $movements
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { movements in
                DispatchQueue.global(qos: .background).async {
                    HistoryService.shared.saveMovements(movements)
                    do { try JSONDatabase.shared.saveMovements(movements) } catch { print("JSONDB movements save error: \(error)") }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Core Inventory Actions

    func addItem(_ item: FoodItem) {
        foodItems.append(item)
        
        // Prevent background systems from firing during layout previews
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            NotificationService.shared.scheduleExpiryAlert(for: item)
        }
        
        DispatchQueue.global(qos: .background).async {
            do { try JSONDatabase.shared.saveFoodItems(self.foodItems) } catch { print("JSONDB save error: \(error)") }
        }
    }

    func updateItem(id: UUID, newName: String, newExpiry: Date, newImage: Data?) {
        if let index = foodItems.firstIndex(where: { $0.id == id }) {
            foodItems[index].name = newName
            foodItems[index].expiryDate = newExpiry
            foodItems[index].imageData = newImage
             
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                NotificationService.shared.cancelAlert(for: foodItems[index])
                NotificationService.shared.scheduleExpiryAlert(for: foodItems[index])
            }
             
            DispatchQueue.global(qos: .background).async {
                do { try JSONDatabase.shared.saveFoodItems(self.foodItems) } catch { print("JSONDB save error: \(error)") }
            }
             
            objectWillChange.send()
            print("Aero_Core: Record [\(id)] updated successfully.")
        }
    }

    func deleteItem(id: UUID) {
        if let item = foodItems.first(where: { $0.id == id }) {
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                NotificationService.shared.cancelAlert(for: item)
            }
        }
        foodItems.removeAll { $0.id == id }
        
        DispatchQueue.global(qos: .background).async {
            do { try JSONDatabase.shared.saveFoodItems(self.foodItems) } catch { print("JSONDB save error: \(error)") }
        }
        
        print("Aero_Core: Record [\(id)] purged from active system.")
    }

    // MARK: - Movement & Lifecycle Logic

    func markAs(_ item: FoodItem, status: FoodMovementStatus) {
        let movement = FoodMovement(
            name: item.name,
            status: status,
            date: Date(),
            category: item.category.rawValue.capitalized,
            estimatedCost: 0.0
        )
        movements.append(movement)
        foodItems.removeAll { $0.id == item.id }
        
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            NotificationService.shared.cancelAlert(for: item)
        }
        
        DispatchQueue.global(qos: .background).async {
            do {
                try JSONDatabase.shared.saveFoodItems(self.foodItems)
                try JSONDatabase.shared.saveMovements(self.movements)
            } catch { print("JSONDB save error: \(error)") }
        }
    }

    func performExpiredSweep() {
        let now = Date()
        let expiredItems = foodItems.filter { $0.expiryDate < now }
        guard !expiredItems.isEmpty else { return }
         
        for item in expiredItems {
            markAs(item, status: .wasted)
        }
        
        DispatchQueue.global(qos: .background).async {
            do {
                try JSONDatabase.shared.saveFoodItems(self.foodItems)
                try JSONDatabase.shared.saveMovements(self.movements)
            } catch { print("JSONDB save error: \(error)") }
        }
        
        print("Aero_Sweep: \(expiredItems.count) records archived.")
    }

    func clearAllData() {
        foodItems.removeAll()
        movements.removeAll()
        
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            HistoryService.shared.purgeAllData()
        }
        
        DispatchQueue.global(qos: .background).async {
            do {
                try JSONDatabase.shared.saveFoodItems([])
                try JSONDatabase.shared.saveMovements([])
            } catch { print("JSONDB purge error: \(error)") }
        }
    }
    
    // Reload inventory from persistent stores (JSON first, then HistoryService fallback)
    func reloadFromDisk() {
        DispatchQueue.main.async {
            if let jsonItems = try? JSONDatabase.shared.loadFoodItems(), !jsonItems.isEmpty {
                self.foodItems = jsonItems
            } else {
                let storedItems = HistoryService.shared.loadInventory()
                if !storedItems.isEmpty { self.foodItems = storedItems }
            }
            // Movements fallback
            if let jsonMovements = try? JSONDatabase.shared.loadMovements(), !jsonMovements.isEmpty {
                self.movements = jsonMovements
            } else {
                let storedMovements = HistoryService.shared.loadMovements()
                if !storedMovements.isEmpty { self.movements = storedMovements }
            }
        }
    }
}

// MARK: - Metrics Helpers
extension HistoryStore {
    var consumedPercentage: Double {
        let consumedCount = movements.filter { $0.status == .consumed }.count
        let processedCount = movements.count
        guard processedCount > 0 else { return 0.0 }
        return Double(consumedCount) / Double(processedCount)
    }
     
    var wastedPercentage: Double {
        let wastedCount = movements.filter { $0.status == .wasted }.count
        let processedCount = movements.count
        guard processedCount > 0 else { return 0.0 }
        return Double(wastedCount) / Double(processedCount)
    }
     
    func percentageForCategory(_ category: FoodCategory) -> Int {
        let normalizedCategory = category.rawValue.lowercased()
        let categoryEvents = foodItems.filter { $0.category == category }.count +
            movements.filter { $0.category.lowercased() == normalizedCategory }.count
        let totalEvents = foodItems.count + movements.count
        guard totalEvents > 0 else { return 0 }
        return Int((Double(categoryEvents) / Double(totalEvents)) * 100)
    }
     
    func expiringItems(within days: Int = 3) -> [FoodItem] {
        let now = Calendar.current.startOfDay(for: Date())
        return foodItems.filter { item in
            let expiryDay = Calendar.current.startOfDay(for: item.expiryDate)
            let diff = Calendar.current.dateComponents([.day], from: now, to: expiryDay).day ?? 0
            return diff >= 0 && diff <= days
        }
    }

    func activeCount(for category: FoodCategory) -> Int {
        foodItems.filter { $0.category == category }.count
    }

    func movementCount(for category: FoodCategory, status: FoodMovementStatus? = nil) -> Int {
        movements.filter { movement in
            guard movement.category.lowercased() == category.rawValue.lowercased() else { return false }
            guard let status else { return true }
            return movement.status == status
        }.count
    }
}

