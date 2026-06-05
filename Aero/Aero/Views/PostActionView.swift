import SwiftUI

struct PostActionView: View {
    let item: FoodItem
    let action: ItemStatus

    var body: some View {
        VStack {
            Text("Confirmed \(action.rawValue) for \(item.name)")
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
        .padding()
    }
}

// MARK: - Preview

#if DEBUG
struct PostActionView_Previews: PreviewProvider {
    static var previews: some View {
        // Uncomment and provide mock implementations below if FoodItem and ItemStatus are defined
        // PostActionView(item: FoodItem(name: "Sample Food"), action: .consumed)
        Text("Preview not available: Missing FoodItem or ItemStatus definitions")
    }
}
#endif
