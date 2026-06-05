import Foundation
import UserNotifications

// MARK: - UNIFIED STATUS ENUM
// This satisfies both 'MovementStatus' and 'FoodMovementStatus' names
enum MovementStatus: String, Codable, CaseIterable {
    case consumed = "Consumed"
    case wasted = "Wasted"
}

// Typealias ensures both names work without changing your other files
typealias FoodMovementStatus = MovementStatus

// MARK: - UNIFIED MOVEMENT MODEL
struct FoodMovement: Identifiable, Codable {
    let id: UUID
    let name: String
    let status: MovementStatus
    let date: Date
    let category: String
    let estimatedCost: Double
    
    init(
        id: UUID = UUID(),
        name: String,
        status: MovementStatus,
        date: Date = Date(),
        category: String = "General",
        estimatedCost: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.date = date
        self.category = category
        self.estimatedCost = estimatedCost
    }
}

// MARK: - NOTIFICATION SERVICE
class NotificationService {
    static let shared = NotificationService()

    func scheduleExpiryAlert(for item: FoodItem) {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            // Fire the alert one day before expiry; skip if already past
            let alertDate = Calendar.current.date(byAdding: .day, value: -1, to: item.expiryDate) ?? item.expiryDate
            guard alertDate > Date() else { return }

            let content = UNMutableNotificationContent()
            content.title = "Expiring Soon"
            content.body = "\(item.name) expires tomorrow — use it or lose it."
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)

            center.add(request)
        }
    }

    func cancelAlert(for item: FoodItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
    }
}
