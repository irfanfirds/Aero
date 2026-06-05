import SwiftUI

struct ShoppingListModalView: View {
    @ObservedObject private var stateManager = AppStateManager.shared
    @State private var newItemName = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: BrutalistTheme.spacingM) {
            // Header Row
            HStack {
                Text("SHOPPING LIST")
                    .font(.system(size: BrutalistTheme.titleSmall, weight: BrutalistTheme.fontBlack))
                Spacer()
                Button("CLOSE") { dismiss() }
                    .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack))
                    .foregroundColor(BrutalistTheme.brutalistRed)
            }
            .padding([.top, .horizontal], BrutalistTheme.spacingM)
            
            // Manual Add Form Input Field
            HStack {
                TextField("Add custom item...", text: $newItemName)
                    .padding(BrutalistTheme.spacingM)
                    .background(Color.white)
                    .brutalistBox(cornerRadius: BrutalistTheme.cornerRadiusMedium, fillColor: .white, shadowOffset: 1)
                
                Button(action: {
                    // FIX: Removed the extra 'isManual' argument to match your exact struct implementation
                    stateManager.addIngredientToShoppingList(newItemName)
                    newItemName = ""
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(BrutalistTheme.spacingM)
                        .brutalistBox(cornerRadius: BrutalistTheme.cornerRadiusMedium, fillColor: BrutalistTheme.brutalistBlack, shadowOffset: 1)
                }
            }
            .padding(.horizontal, BrutalistTheme.spacingM)
            
            // Core List Layout Collection View
            List {
                ForEach(stateManager.shoppingList, id: \.id) { item in // FIX: Iterates explicitly over the stable array structure
                    HStack {
                        Text(item.name.uppercased())
                            .font(.system(size: BrutalistTheme.bodyMedium, weight: BrutalistTheme.fontBold))
                        Spacer()
                        
                        // Clean indicator design using standard list bullet accent style
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                            .padding(.horizontal, 8)
                        
                        Button(action: { stateManager.removeIngredientFromShoppingList(item) }) {
                            Image(systemName: "trash.fill")
                                .foregroundColor(BrutalistTheme.brutalistRed)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(PlainListStyle())
        }
        .background(Color(hex: "#F5F5F5"))
    }
}
