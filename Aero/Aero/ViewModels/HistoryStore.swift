import Foundation
import SwiftUI
import Combine

final class HistoryStore: ObservableObject {
    @Published var foodItems: [FoodItem] = []
    @Published var movements: [FoodMovement] = []
    private var cancellables: Set<AnyCancellable> = []

    // Firestore sync state
    private var firestoreEnabled = false
    private var hasInitialItemsSynced = false
    private var hasInitialMovementsSynced = false

    var items: [FoodItem] {
        get { foodItems }
        set { foodItems = newValue }
    }

    init(foodItems: [FoodItem] = [], movements: [FoodMovement] = []) {
        self.foodItems = foodItems
        self.movements = movements

        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" { return }

        DispatchQueue.main.async {
            if let jsonItems = try? JSONDatabase.shared.loadFoodItems(), !jsonItems.isEmpty {
                self.foodItems = jsonItems
            }
            if let jsonMovements = try? JSONDatabase.shared.loadMovements(), !jsonMovements.isEmpty {
                self.movements = jsonMovements
            }

            let storedItems = HistoryService.shared.loadInventory()
            let storedMovements = HistoryService.shared.loadMovements()

            if self.foodItems.isEmpty && !storedItems.isEmpty { self.foodItems = storedItems }
            if self.movements.isEmpty && !storedMovements.isEmpty { self.movements = storedMovements }

            self.setupObservers()
        }
    }

    private func setupObservers() {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }

        $foodItems
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { items in
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

    // MARK: - Firestore Sync Control

    func startFirestoreSync(uid: String) {
        firestoreEnabled = true
        hasInitialItemsSynced = false
        hasInitialMovementsSynced = false

        FirestoreService.shared.configure(
            uid: uid,
            onItemsChanged: { [weak self] items in self?.handleRemoteItems(items) },
            onMovementsChanged: { [weak self] movements in self?.handleRemoteMovements(movements) }
        )
    }

    func stopFirestoreSync() {
        FirestoreService.shared.stop()
        firestoreEnabled = false
        hasInitialItemsSynced = false
        hasInitialMovementsSynced = false
    }

    // MARK: - Remote Update Handlers

    private func handleRemoteItems(_ remoteItems: [FoodItem]) {
        if !hasInitialItemsSynced {
            hasInitialItemsSynced = true
            if remoteItems.isEmpty && !foodItems.isEmpty {
                // First-time sync: push existing local items up to Firestore
                FirestoreService.shared.uploadItems(foodItems)
                return
            }
        }

        guard !remoteItems.isEmpty else { return }

        // Merge: Firestore is source of truth for everything including image (Base64 decoded).
        // If Firestore has no image (write failed due to quota), keep the local full-resolution copy.
        let localById = Dictionary(uniqueKeysWithValues: foodItems.map { ($0.id, $0) })
        let merged = remoteItems.map { remote -> FoodItem in
            var item = remote
            if item.imageData == nil, let local = localById[remote.id] {
                item.imageData = local.imageData
            }
            return item
        }

        foodItems = merged
    }

    private func handleRemoteMovements(_ remoteMovements: [FoodMovement]) {
        if !hasInitialMovementsSynced {
            hasInitialMovementsSynced = true
            if remoteMovements.isEmpty && !movements.isEmpty {
                FirestoreService.shared.uploadMovements(movements)
                return
            }
        }
        guard !remoteMovements.isEmpty else { return }
        movements = remoteMovements
    }

    // MARK: - Core Inventory Actions

    func addItem(_ item: FoodItem) {
        foodItems.append(item)
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            NotificationService.shared.scheduleExpiryAlert(for: item)
        }
        if firestoreEnabled { FirestoreService.shared.syncItem(item) }
    }

    func updateItem(id: UUID, newName: String, newExpiry: Date, newImage: Data?, newNutrients: Nutriments? = nil) {
        if let index = foodItems.firstIndex(where: { $0.id == id }) {
            foodItems[index].name = newName
            foodItems[index].expiryDate = newExpiry
            foodItems[index].imageData = newImage
            if let newNutrients { foodItems[index].nutrients = newNutrients }

            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                NotificationService.shared.cancelAlert(for: foodItems[index])
                NotificationService.shared.scheduleExpiryAlert(for: foodItems[index])
            }

            DispatchQueue.global(qos: .background).async {
                do { try JSONDatabase.shared.saveFoodItems(self.foodItems) } catch { print("JSONDB save error: \(error)") }
            }

            if firestoreEnabled { FirestoreService.shared.syncItem(foodItems[index]) }

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

        if firestoreEnabled { FirestoreService.shared.deleteItem(id: id) }

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

        if firestoreEnabled {
            FirestoreService.shared.syncMovement(movement)
            FirestoreService.shared.deleteItem(id: item.id)
        }
    }

    func performExpiredSweep() {
        let now = Date()
        let expiredItems = foodItems.filter { $0.expiryDate < now }
        guard !expiredItems.isEmpty else { return }

        for item in expiredItems { markAs(item, status: .wasted) }

        DispatchQueue.global(qos: .background).async {
            do {
                try JSONDatabase.shared.saveFoodItems(self.foodItems)
                try JSONDatabase.shared.saveMovements(self.movements)
            } catch { print("JSONDB save error: \(error)") }
        }

        print("Aero_Sweep: \(expiredItems.count) records archived.")
    }

    func clearAllData() {
        let itemIDs = foodItems.map { $0.id }
        let movementIDs = movements.map { $0.id }

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

        if firestoreEnabled {
            itemIDs.forEach { FirestoreService.shared.deleteItem(id: $0) }
            movementIDs.forEach { FirestoreService.shared.deleteMovement(id: $0) }
        }
    }

    func reloadFromDisk() {
        DispatchQueue.main.async {
            if let jsonItems = try? JSONDatabase.shared.loadFoodItems(), !jsonItems.isEmpty {
                self.foodItems = jsonItems
            } else {
                let stored = HistoryService.shared.loadInventory()
                if !stored.isEmpty { self.foodItems = stored }
            }
            if let jsonMovements = try? JSONDatabase.shared.loadMovements(), !jsonMovements.isEmpty {
                self.movements = jsonMovements
            } else {
                let stored = HistoryService.shared.loadMovements()
                if !stored.isEmpty { self.movements = stored }
            }
        }
    }
}

// MARK: - Metrics Helpers
extension HistoryStore {
    var consumedPercentage: Double {
        let count = movements.filter { $0.status == .consumed }.count
        guard movements.count > 0 else { return 0.0 }
        return Double(count) / Double(movements.count)
    }

    var wastedPercentage: Double {
        let count = movements.filter { $0.status == .wasted }.count
        guard movements.count > 0 else { return 0.0 }
        return Double(count) / Double(movements.count)
    }

    func percentageForCategory(_ category: FoodCategory) -> Int {
        let normalized = category.rawValue.lowercased()
        let events = foodItems.filter { $0.category == category }.count +
            movements.filter { $0.category.lowercased() == normalized }.count
        let total = foodItems.count + movements.count
        guard total > 0 else { return 0 }
        return Int((Double(events) / Double(total)) * 100)
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
