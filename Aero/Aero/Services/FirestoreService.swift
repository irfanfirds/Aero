import UIKit
import FirebaseFirestore

// MARK: - FirestoreService

final class FirestoreService {
    static let shared = FirestoreService()

    private let db: Firestore
    private var uid: String?
    private var itemsListener: ListenerRegistration?
    private var movementsListener: ListenerRegistration?

    private init() {
        let firestore = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        firestore.settings = settings
        self.db = firestore
    }

    // MARK: - Lifecycle

    func configure(
        uid: String,
        onItemsChanged: @escaping ([FoodItem]) -> Void,
        onMovementsChanged: @escaping ([FoodMovement]) -> Void
    ) {
        stop()
        self.uid = uid

        let userRef = db.collection("users").document(uid)

        itemsListener = userRef.collection("foodItems")
            .addSnapshotListener { snapshot, _ in
                guard let snapshot else { return }
                let items = snapshot.documents.compactMap { FoodItem.fromFirestore($0.data()) }
                DispatchQueue.main.async { onItemsChanged(items) }
            }

        movementsListener = userRef.collection("movements")
            .addSnapshotListener { snapshot, _ in
                guard let snapshot else { return }
                let movements = snapshot.documents.compactMap { FoodMovement.fromFirestore($0.data()) }
                DispatchQueue.main.async { onMovementsChanged(movements) }
            }
    }

    func stop() {
        itemsListener?.remove()
        movementsListener?.remove()
        itemsListener = nil
        movementsListener = nil
        uid = nil
    }

    // MARK: - Item Writes (split: text first, image separate)

    func syncItem(_ item: FoodItem) {
        guard let uid else { return }
        let itemRef = db.collection("users").document(uid)
            .collection("foodItems").document(item.id.uuidString)

        Task {
            // Write 1: text data — always succeeds while online, never blocked by image size
            try? await itemRef.setData(item.toFirestoreDict(), merge: true)

            // Write 2: compressed image as Base64 — silently skipped if Firestore quota is full
            if let imageData = item.imageData,
               let base64 = compressImageToBase64(imageData) {
                try? await itemRef.setData(["image": base64], merge: true)
            }
        }
    }

    func deleteItem(id: UUID) {
        guard let uid else { return }
        Task {
            try? await db.collection("users").document(uid)
                .collection("foodItems").document(id.uuidString).delete()
        }
    }

    // MARK: - Movement Writes

    func syncMovement(_ movement: FoodMovement) {
        guard let uid else { return }
        let dict = movement.toFirestoreDict()
        Task {
            try? await db.collection("users").document(uid)
                .collection("movements").document(movement.id.uuidString)
                .setData(dict)
        }
    }

    func deleteMovement(id: UUID) {
        guard let uid else { return }
        Task {
            try? await db.collection("users").document(uid)
                .collection("movements").document(id.uuidString).delete()
        }
    }

    // MARK: - Bulk Upload (first-time sync: local → Firestore)

    func uploadItems(_ items: [FoodItem]) {
        items.forEach { syncItem($0) }
    }

    func uploadMovements(_ movements: [FoodMovement]) {
        movements.forEach { syncMovement($0) }
    }

    // MARK: - Image Compression

    // Resizes to max 150×150 and encodes as JPEG Base64 (~15–25 KB).
    // Returns nil if the data isn't a valid image.
    private func compressImageToBase64(_ data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }

        let maxDimension: CGFloat = 150
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resized.jpegData(compressionQuality: 0.4)?.base64EncodedString()
    }
}

// MARK: - FoodItem ↔ Firestore

extension FoodItem {
    // Text-only dict — image is written in a separate call so a quota failure
    // never blocks the item's core data from reaching Firestore.
    func toFirestoreDict() -> [String: Any] {
        var dict: [String: Any] = [
            "id":         id.uuidString,
            "name":       name,
            "category":   category.rawValue,
            "expiryDate": Timestamp(date: expiryDate),
            "quantity":   quantity,
            "updatedAt":  FieldValue.serverTimestamp()
        ]
        if let imageEmoji { dict["imageEmoji"] = imageEmoji }
        if let barcode    { dict["barcode"]    = barcode }
        if let userAction { dict["userAction"] = userAction.rawValue }
        if let n = nutrients {
            var nd: [String: Any] = [:]
            if let v = n.energyKcal    { nd["energyKcal"]    = v }
            if let v = n.fat           { nd["fat"]           = v }
            if let v = n.carbohydrates { nd["carbohydrates"] = v }
            if let v = n.proteins      { nd["proteins"]      = v }
            if let v = n.fiber         { nd["fiber"]         = v }
            if let v = n.sugars        { nd["sugars"]        = v }
            if let v = n.sodium        { nd["sodium"]        = v }
            dict["nutrients"] = nd
        }
        return dict
    }

    static func fromFirestore(_ data: [String: Any]) -> FoodItem? {
        guard
            let idStr  = data["id"]         as? String, let id = UUID(uuidString: idStr),
            let name   = data["name"]       as? String,
            let catRaw = data["category"]   as? String, let category = FoodCategory(rawValue: catRaw),
            let expTS  = data["expiryDate"] as? Timestamp
        else { return nil }

        var item = FoodItem(
            id:         id,
            name:       name,
            category:   category,
            expiryDate: expTS.dateValue(),
            quantity:   data["quantity"]   as? String ?? "1",
            imageEmoji: data["imageEmoji"] as? String,
            barcode:    data["barcode"]    as? String
        )

        if let actionRaw = data["userAction"] as? String {
            item.userAction = ItemStatus(rawValue: actionRaw)
        }

        // Restore compressed photo from Base64
        if let base64 = data["image"] as? String {
            item.imageData = Data(base64Encoded: base64)
        }

        if let nd = data["nutrients"] as? [String: Any] {
            item.nutrients = Nutriments(
                energyKcal:    nd["energyKcal"]    as? Double,
                fat:           nd["fat"]           as? Double,
                carbohydrates: nd["carbohydrates"] as? Double,
                proteins:      nd["proteins"]      as? Double,
                fiber:         nd["fiber"]         as? Double,
                sugars:        nd["sugars"]        as? Double,
                sodium:        nd["sodium"]        as? Double
            )
        }
        return item
    }
}

// MARK: - FoodMovement ↔ Firestore

extension FoodMovement {
    func toFirestoreDict() -> [String: Any] {
        [
            "id":            id.uuidString,
            "name":          name,
            "status":        status.rawValue,
            "date":          Timestamp(date: date),
            "category":      category,
            "estimatedCost": estimatedCost,
            "updatedAt":     FieldValue.serverTimestamp()
        ]
    }

    static func fromFirestore(_ data: [String: Any]) -> FoodMovement? {
        guard
            let idStr   = data["id"]     as? String, let id = UUID(uuidString: idStr),
            let name    = data["name"]   as? String,
            let statRaw = data["status"] as? String, let status = MovementStatus(rawValue: statRaw),
            let dateTS  = data["date"]   as? Timestamp
        else { return nil }

        return FoodMovement(
            id:            id,
            name:          name,
            status:        status,
            date:          dateTS.dateValue(),
            category:      data["category"]      as? String ?? "General",
            estimatedCost: data["estimatedCost"] as? Double ?? 0.0
        )
    }
}
