import SwiftUI

struct VirtualFridgeButton: View {
    let expiringCount: Int
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // 1. SHADOW (Bottom Layer)
                RoundedRectangle(cornerRadius: 12)
                    .fill(BrutalistTheme.brutalistBlack)
                    .offset(x: 4, y: 4)

                // 2. DYNAMIC FILL
                // Stays Aero Blue normally, turns Red to signal urgency
                RoundedRectangle(cornerRadius: 12)
                    .fill(expiringCount > 0 ? BrutalistTheme.brutalistRed : Color(hex: "#63E2FF"))
                
                // 3. CONTENT (Middle Layer)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VIRTUAL FRIDGE")
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                        
                        Text(expiringCount > 0 ? "\(expiringCount) ITEMS EXPIRING SOON" : "All items are fresh")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .opacity(0.8)
                    }
                    // Contrast adjustment for readability
                    .foregroundColor(expiringCount > 0 ? .white : BrutalistTheme.brutalistBlack)
                    
                    Spacer()
                    
                    // 4. DYNAMIC ICON
                    Image(systemName: expiringCount > 0 ? "exclamationmark.triangle.fill" : "refrigerator.fill")
                        .font(.system(size: 24))
                        .foregroundColor(expiringCount > 0 ? .white : BrutalistTheme.brutalistBlack)
                }
                .padding(.horizontal, 16)
                
                // 5. BORDER (Top Layer)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
            }
        }
        .buttonStyle(BrutalistClickStyle())
        .frame(height: 80)
    }
}

// MARK: - Mechanical Press Style
struct BrutalistClickStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(x: configuration.isPressed ? 2 : 0, y: configuration.isPressed ? 2 : 0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    // 1. Setup mock data
    let mockStore = HistoryStore(
        foodItems: [
            FoodItem(
                name: "Organic Milk",
                category: .dairy,
                expiryDate: Date().addingTimeInterval(86400 * 5),
                imageEmoji: "🥛"
            )
        ]
    )
    
    // 2. Return the view with the environment injected
    return NavigationStack {
        ItemDetailView(item: mockStore.foodItems[0])
            .environmentObject(mockStore)
    }
}
