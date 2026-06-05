//
//  ItemsView.swift
//  Aero
//
//  Created by SWITCH on 07/01/2026.
//

import SwiftUI

struct ItemsView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @EnvironmentObject var chatService: ChatService
    @State private var selectedCategory: String = "ALL ITEMS"
    @State private var showingManualEntry = false
    @State private var showingAIOrb = false // FIXED: Added state for sheet presentation
    @State private var showFridge = false // Added state for fridge sheet

    @State private var selectedItemForDetail: FoodItem? = nil
    @State private var postActionContext: (item: FoodItem, status: ItemStatus)? = nil

    let categories = ["ALL ITEMS", "PRODUCE", "FRUITS", "DAIRY", "MEAT", "PANTRY"]

    // MARK: - Logic Refactored to prevent Compiler Timeout
    private var filteredItems: [FoodItem] {
        // 1. Get the base list
        let allItems = historyStore.foodItems

        // 2. Early return if no filter needed
        if selectedCategory == "ALL ITEMS" {
            return allItems
        }

        // 3. Perform filtering in a separate step
        return performFilter(on: allItems, categoryName: selectedCategory)
    }

    private func performFilter(on items: [FoodItem], categoryName: String) -> [FoodItem] {
        // NEW: Handle the Expiry Alert category
        if categoryName == "EXPIRING" {
            return items.filter { item in
                let days = Calendar.current.dateComponents([.day], from: Date(), to: item.expiryDate).day ?? 0
                return days <= 2 // Shows items expiring in 48 hours or already expired
            }
        }

        // Map string to enum (Your existing mapping)
        let mapping: [String: FoodCategory] = [
            "PRODUCE": .produce,
            "FRUITS": .fruits,
            "DAIRY": .dairy,
            "MEAT": .meat,
            "PANTRY": .pantry
        ]

        guard let targetCategory = mapping[categoryName] else {
            // Fallback for custom categories
            return items.filter { $0.category.rawValue.uppercased() == categoryName.uppercased() }
        }

        // Handle the PRODUCE special case (Produce + Vegetables)
        if targetCategory == .produce {
            return items.filter { $0.category == .produce || $0.category == .vegetables }
        }

        return items.filter { $0.category == targetCategory }
    }
    
    private func filterByExpiry() {
        FeedbackManager.shared.triggerClack() // Keep that tactile feel!
        selectedCategory = "EXPIRING"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: BrutalistTheme.spacingL) {
                    // MARK: - FIXED HEADER
                    AuthHeaderComponent(
                        title: "Items",
                        subtitle: "Inventory manager",
                        trailingAction: AnyView( // Wrap in AnyView if your component requires it
                            HStack(spacing: 16) {
                                
                                // 1. THE WARNING BUTTON (Expired Sweep)
                                Button(action: {
                                    FeedbackManager.shared.triggerWarning()
                                    historyStore.performExpiredSweep()
                                }) {
                                    ZStack {
                                        // Brutalist Shadow
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(BrutalistTheme.brutalistBlack)
                                            .offset(x: 2, y: 2)
                                        
                                        // Main Yellow Fill
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(BrutalistTheme.brutalistYellow)
                                        
                                        // Triangle Icon
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(BrutalistTheme.brutalistBlack)
                                        
                                        // Sharp Border
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                                    }
                                    .frame(width: 32, height: 32)
                                }
                                .buttonStyle(BrutalistSinkingStyle()) // Tactile press effect
                                
                                // 2. THE FILTER BUTTON
                                Button(action: { filterByExpiry() }) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .font(.title3)
                                        .foregroundColor(BrutalistTheme.brutalistBlack)
                                }
                            }
                            .padding(.trailing, 8) // Prevents hugging the screen edge too tightly
                        )
                    )
                    topActionButtons
                    
                    AIChefCoreView(showAIOrb: $showingAIOrb)
                        .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    categoryFilters
                    
                    itemsGrid
                    
                    Spacer().frame(height: 100)
                }
                // ... (rest of your sheets and modifiers remain the same)
                .sheet(isPresented: $showFridge) { FridgeView() }
                .sheet(isPresented: $showingManualEntry) { ManualEntryView() }
                .sheet(isPresented: $showingAIOrb) { AIOrbView() }
                .sheet(item: $selectedItemForDetail) { item in ItemDetailView(item: item) }
                .sheet(item: Binding(get: {
                    postActionContext.map { ContextWrapper(id: $0.item.id, value: $0) }
                }, set: { postActionContext = $0?.value })) { wrapper in
                    PostActionView(item: wrapper.value.item, action: wrapper.value.status)
                }
            }
            .background(Color(hex: "#F5F5F5"))
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Sub-Views
    private var topActionButtons: some View {
        VStack(spacing: BrutalistTheme.spacingM) {
            
            // Calculate expiring items specifically for this button
            let expiringCount = historyStore.expiringItems().count
            
            VirtualFridgeButton(expiringCount: expiringCount) {
                FeedbackManager.shared.triggerClack()
                // This now acts as a shortcut to show the specific filtered view
                showFridge = true
            }
            
            HStack {
                Spacer()
                // Your existing Add button
                AddCircularButton(action: { showingManualEntry = true })
            }
        }
        .padding(.horizontal, BrutalistTheme.spacingL)
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BrutalistTheme.spacingM) {
                ForEach(categories, id: \.self) { category in
                    CategoryPill(
                        title: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, BrutalistTheme.spacingL)
        }
    }

    private var itemsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: BrutalistTheme.spacingM),
                      GridItem(.flexible(), spacing: BrutalistTheme.spacingM)],
            spacing: BrutalistTheme.spacingM
        ) {
            ForEach(filteredItems) { item in
                FoodItemCard(
                    item: item,
                    onMarkConsumed: {
                        historyStore.markAs(item, status: .consumed)
                        postActionContext = (item, .consumed)
                    },
                    onMarkWasted: {
                        historyStore.markAs(item, status: .wasted)
                        postActionContext = (item, .wasted)
                    },
                    onTap: { selectedItemForDetail = item }
                )
                .allowsHitTesting(true)
            }
        }
        .id(selectedCategory)
        .padding(.horizontal, BrutalistTheme.spacingL)
    }

    private func openItemIfExists(id: UUID) {
        // Check main inventory first
        if let found = historyStore.foodItems.first(where: { $0.id == id }) {
            selectedItemForDetail = found
            return
        }
        // If not in inventory, optionally check history movements if available
        if let historyArray = (historyStore as AnyObject).value(forKey: "movements") as? [FoodItem],
           let archived = historyArray.first(where: { $0.id == id }) {
            // For now, just log; you can navigate to a history detail view if desired
            print("Item found in history: \(archived.name)")
            return
        }
        // Fallback behavior could set a filter to expiring items, or no-op
        selectedCategory = "ALL ITEMS"
    }
}

// MARK: - AI Chef Core Component with Brain Icon (FIXED: Button triggers sheet)
struct AIChefCoreView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @Binding var showAIOrb: Bool // FIXED: Binding instead of NavigationLink
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Outer ring 3
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                .frame(width: 200, height: 200)

            // Outer ring 2
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                .frame(width: 160, height: 160)

            // Main cyan ring with breathing effect
            Circle()
                .stroke(BrutalistTheme.brutalistCyan, lineWidth: 6)
                .frame(width: 120, height: 120)
                .scaleEffect(isPulsing ? 1.05 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                    value: isPulsing
                )

            // Inner white circle with breathing effect (FIXED: Sandwich Method)
            ZStack {
                // Shadow
                Circle()
                    .fill(BrutalistTheme.brutalistBlack)
                    .frame(width: 82, height: 82)
                    .offset(x: 1, y: 1)

                // Fill
                Circle()
                    .fill(BrutalistTheme.brutalistWhite)
                    .frame(width: 80, height: 80)

                // Border
                Circle()
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                    .frame(width: 80, height: 80)
            }
            .scaleEffect(isPulsing ? 1.03 : 1.0)
            .animation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )

            // Center brain icon button (FIXED: Button triggers sheet)
            Button(action: {
                FeedbackManager.shared.triggerClack()
                showAIOrb = true
            }) {
                ZStack {
                    // Shadow
                    Circle()
                        .fill(BrutalistTheme.brutalistBlack)
                        .frame(width: 56, height: 56)
                        .offset(x: 4, y: 4)

                    // Fill
                    Circle()
                        .fill(BrutalistTheme.brutalistWhite)
                        .frame(width: 56, height: 56)

                    // Content - Brain Icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(BrutalistTheme.brutalistBlack)

                    // Border
                    Circle()
                        .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                        .frame(width: 56, height: 56)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(height: 200)
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Refined Components using the Unified Sandwich Method

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            FeedbackManager.shared.triggerClack()
            action()
        }) {
            Text(title)
                .font(.system(size: 12, weight: BrutalistTheme.fontBlack, design: .monospaced))
                .foregroundColor(isSelected ? BrutalistTheme.brutalistWhite : BrutalistTheme.brutalistBlack)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        // Shadow
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                            .fill(BrutalistTheme.brutalistBlack)
                            .offset(x: 3, y: 3)
                        // Fill
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                            .fill(isSelected ? BrutalistTheme.brutalistBlack : BrutalistTheme.brutalistWhite)
                        // Border lineWidth changed to 1.5 as requested
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: 1.5)
                    }
                )
        }
        .buttonStyle(BrutalistSinkingStyle()) // Consistent mechanical feel
    }
}
// MARK: - Food Item Card Component (FIXED: Sandwich Method - No Double Shadows)
struct FoodItemCard: View {
    let item: FoodItem
    let onMarkConsumed: () -> Void
    let onMarkWasted: () -> Void
    let onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: BrutalistTheme.spacingM) {
                // Image Area
                ZStack {
                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                        .fill(Color(hex: "#FFF8DC"))
                        .overlay(
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                        )
                    Text(item.imageEmoji ?? "🍽️")
                        .font(.system(size: 40))
                }
                .frame(height: 80)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name.uppercased())
                        .font(.system(size: 14, weight: BrutalistTheme.fontBlack))
                        .lineLimit(1)
                    
                    Text("\(item.quantity)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                }

                HStack {
                    MiniActionButton(title: "EAT", fill: BrutalistTheme.brutalistLime, action: onMarkConsumed)
                    MiniActionButton(title: "TRASH", fill: BrutalistTheme.brutalistRed, action: onMarkWasted)
                }
            }
            .padding(BrutalistTheme.spacingM)
            .background(
                ZStack {
                    // Sandwich Layer 1: Shadow
                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                        .fill(BrutalistTheme.brutalistBlack)
                        .offset(x: 4, y: 4)
                    // Sandwich Layer 2: Fill
                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                        .fill(BrutalistTheme.brutalistWhite)
                    // Sandwich Layer 3: Border
                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                        .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                }
            )
        }
        .buttonStyle(BrutalistSinkingStyle())
    }
}
private struct ItemImageArea: View {
    let emoji: String
    let statusColor: Color

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                    .fill(BrutalistTheme.brutalistBlack)
                    .offset(x: 2, y: 2)

                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                    .fill(Color(hex: "#FFF8DC"))

                Text(emoji)
                    .font(.system(size: 48))

                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
            }
            .frame(height: 100)

            ZStack {
                Circle()
                    .fill(BrutalistTheme.brutalistBlack)
                    .frame(width: 18, height: 18)
                    .offset(x: 1, y: 1)

                Circle()
                    .fill(statusColor)
                    .frame(width: 16, height: 16)

                Circle()
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                    .frame(width: 16, height: 16)
            }
            .offset(x: 4, y: -4)
        }
    }
}

private struct DaysLeftLabel: View {
    let daysLeft: Int
    let textColor: Color

    var body: some View {
        if daysLeft >= 0 {
            Text("\(daysLeft) DAYS LEFT")
                .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBold))
                .foregroundColor(textColor)
        } else {
            Text("EXPIRED")
                .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBold))
                .foregroundColor(BrutalistTheme.brutalistRed)
        }
    }
}

private struct CategoryLabel: View {
    let text: String

    var body: some View {
        ZStack {
            // Shadow with offset (x:3, y:3) and cornerRadiusSmall
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                .fill(BrutalistTheme.brutalistBlack)
                .offset(x: 3, y: 3)

            // Fill
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                .fill(BrutalistTheme.brutalistWhite)

            Text(text)
                .font(.system(size: 10, weight: BrutalistTheme.fontBlack))
                .foregroundColor(BrutalistTheme.brutalistBlack)
                .padding(.horizontal, BrutalistTheme.spacingS)
                .padding(.vertical, 6)

            // Border with lineWidth 2 and cornerRadiusSmall
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
        }
    }
}

private struct ActionsRow: View {
    let onMarkConsumed: () -> Void
    let onMarkWasted: () -> Void

    var body: some View {
        HStack(spacing: BrutalistTheme.spacingS) {
            MiniActionButton(
                title: "EAT",
                fill: BrutalistTheme.brutalistLime,
                action: onMarkConsumed
            )
            .allowsHitTesting(true)

            MiniActionButton(
                title: "WASTE",
                fill: BrutalistTheme.brutalistRed,
                action: onMarkWasted
            )
            .allowsHitTesting(true)
        }
    }
}

struct MiniActionButton: View {
    let title: String
    let fill: Color
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            FeedbackManager.shared.triggerClack()
            action()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(BrutalistTheme.brutalistBlack)
                    .offset(x: 2, y: 2)

                RoundedRectangle(cornerRadius: 6)
                    .fill(fill)
                
                // Added border layer above fill
                RoundedRectangle(cornerRadius: 6)
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)

                Text(title)
                    .font(.system(size: 10, weight: BrutalistTheme.fontBlack))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
                    .padding(.horizontal, BrutalistTheme.spacingS)
                    .padding(.vertical, 6)
            }
            .offset(x: isPressed ? 2 : 0, y: isPressed ? 2 : 0)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
        }
        .contentShape(Rectangle())
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

private struct ContextWrapper<T>: Identifiable {
    let id: UUID
    let value: T
}

struct AddCircularButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: {
            FeedbackManager.shared.triggerClack()
            action()
        }) {
            ZStack {
                Circle().fill(BrutalistTheme.brutalistBlack).frame(width: 56, height: 56).offset(x: 5, y: 5)
                Circle().fill(BrutalistTheme.brutalistYellow).frame(width: 56, height: 56)
                Image(systemName: "face.smiling.fill").font(.system(size: 28)).foregroundColor(BrutalistTheme.brutalistBlack)
                Circle().stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth).frame(width: 56, height: 56)
            }
        }.buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ItemsView()
        .environmentObject(HistoryStore())
        .environmentObject(ChatService())
}

