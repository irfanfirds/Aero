import SwiftUI

struct FridgeView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        // 1. Grab only the expiring items
        let expiringItems = historyStore.expiringItems()
        
        ScrollView(showsIndicators: false) {
            VStack(spacing: BrutalistTheme.spacingL) {
                // Header
                HStack {
                    Button(action: {
                        FeedbackManager.shared.triggerClack()
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .black))
                    }
                    .buttonStyle(.brutalistButton)
                    
                    // 2. Changed Title to reflect focus
                    Text("RESCUE MODE")
                        .font(.system(size: 28, weight: .black))
                        .kerning(-1)
                        .foregroundColor(expiringItems.isEmpty ? BrutalistTheme.brutalistBlack : BrutalistTheme.brutalistRed)
                    
                    Spacer()
                }
                .padding(.horizontal, BrutalistTheme.spacingL)
                .padding(.top, BrutalistTheme.spacingL)

                // Expiring Section
                VStack(alignment: .leading, spacing: BrutalistTheme.spacingM) {
                    Text(expiringItems.isEmpty ? "FRIDGE IS FRESH" : "EXPIRING SOON")
                        .font(.system(size: BrutalistTheme.titleMedium, weight: BrutalistTheme.fontBlack))
                        .foregroundColor(BrutalistTheme.brutalistBlack)
                        .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    if expiringItems.isEmpty {
                        // Empty state illustration/text
                        VStack(spacing: 20) {
                            Text("🧊")
                                .font(.system(size: 60))
                            Text("All your items have plenty of time left.")
                                .font(.system(size: 14, design: .monospaced))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        // 3. Changed data source to expiringItems
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: BrutalistTheme.spacingM),
                                GridItem(.flexible(), spacing: BrutalistTheme.spacingM)
                            ],
                            spacing: BrutalistTheme.spacingM
                        ) {
                            ForEach(expiringItems) { item in
                                FoodItemCard(
                                    item: item,
                                    onMarkConsumed: {
                                        historyStore.markAs(item, status: .consumed)
                                    },
                                    onMarkWasted: {
                                        historyStore.markAs(item, status: .wasted)
                                    },
                                    onTap: {
                                        print("Tapped \(item.name)")
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, BrutalistTheme.spacingL)
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .background(Color(hex: "#F5F5F5"))
        .ignoresSafeArea(edges: .bottom)
    }
}
