import SwiftUI

struct RecipesScreen: View {
    // MARK: - Dependencies
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var historyStore: HistoryStore
    @EnvironmentObject var recipeVM: RecipeViewModel
    @ObservedObject private var stateManager = AppStateManager.shared

    // MARK: - State Properties
    @State private var selectedFilter: String = "All Recipes"
    @State private var aiResult: SustainabilityResponse? = nil
    @State private var isAnalyzing: Bool = false
    @State private var showChat: Bool = false
    @State private var showingShoppingOverlay = false

    // MARK: - Constants
    private let filters = ["All Recipes", "Fast (15m)", "Low Carbon", "High Protein"]
    private let backgroundColor = Color(hex: "#F5F5F5")

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: BrutalistTheme.spacingS) {

                    // MARK: - HEADER BLOCK
                    VStack(spacing: BrutalistTheme.spacingXS) {
                        Text("RECIPES")
                            .font(.system(size: 32, weight: BrutalistTheme.fontBlack))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, BrutalistTheme.spacingS)

                        AuthHeaderComponent(title: "", subtitle: "Smart suggestions")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, BrutalistTheme.spacingM)

                    // MARK: - ACTION ROW (Search Bar + Cart Button)
                    HStack(spacing: BrutalistTheme.spacingM) {

                        // Extended Search Bar Container with 3D Sandwich Effect
                        ZStack {
                            // 1. Shadow Layer
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                .fill(BrutalistTheme.brutalistBlack)
                                .frame(height: 48)
                                .offset(x: 3, y: 3)

                            // 2. Main Fill Layer
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                .fill(BrutalistTheme.brutalistWhite)
                                .frame(height: 48)

                            // 3. Content Layout (Icon + TextField)
                            HStack(spacing: BrutalistTheme.spacingS) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(BrutalistTheme.brutalistBlack)

                                TextField("Search recipes...", text: $recipeVM.searchFieldText)
                                    .font(.system(size: BrutalistTheme.bodyMedium, weight: BrutalistTheme.fontBold, design: .monospaced))
                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                                    .submitLabel(.search)
                                    .onSubmit {
                                        Task { await recipeVM.searchMealDB(query: recipeVM.searchFieldText) }
                                    }
                            }
                            .padding(.horizontal, BrutalistTheme.spacingM)
                            .frame(height: 48)

                            // 4. Solid Inset Outline Framework
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                .strokeBorder(BrutalistTheme.brutalistBlack, lineWidth: 3)
                                .frame(height: 48)
                        }
                        .padding(.trailing, 3)
                        .padding(.bottom, 3)

                        // Shopping Cart Button
                        Button(action: {
                            FeedbackManager.shared.triggerClack()
                            showingShoppingOverlay.toggle()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                    .fill(BrutalistTheme.brutalistBlack)
                                    .frame(width: 48, height: 48)
                                    .offset(x: 3, y: 3)

                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                    .fill(BrutalistTheme.brutalistWhite)
                                    .frame(width: 48, height: 48)

                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "cart.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(BrutalistTheme.brutalistBlack)

                                    if stateManager.shoppingCartCount > 0 {
                                        Text("\(stateManager.shoppingCartCount)")
                                            .font(.system(size: 8, weight: BrutalistTheme.fontBlack))
                                            .foregroundColor(.white)
                                            .frame(width: 14, height: 14)
                                            .background(BrutalistTheme.brutalistRed)
                                            .clipShape(Circle())
                                            .offset(x: 6, y: -6)
                                    }
                                }
                                .frame(width: 48, height: 48)

                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                    .strokeBorder(BrutalistTheme.brutalistBlack, lineWidth: 3)
                                    .frame(width: 48, height: 48)
                            }
                            .padding(.trailing, 3)
                            .padding(.bottom, 3)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)

                    // MARK: - AI Sustainability Alert & Gemini Copilot Trigger
                    VStack(spacing: BrutalistTheme.spacingM) {
                        AISustainabilityAlert(
                            result: aiResult,
                            isLoading: isAnalyzing,
                            onOpenChat: { showChat = true }
                        )

                        Button(action: {
                            guard !historyStore.foodItems.isEmpty else { return }
                            FeedbackManager.shared.triggerClack()
                            let inventoryNames = historyStore.foodItems.map { $0.name }
                            Task { await recipeVM.generateGeminiRecipes(inventoryNames: inventoryNames) }
                        }) {
                            HStack {
                                Image(systemName: !historyStore.foodItems.isEmpty ? "sparkles" : "exclamationmark.triangle")
                                Text(!historyStore.foodItems.isEmpty ? "ASK GEMINI CO-PILOT FOR FRESH RECIPES" : "ADD ITEMS TO FRIDGE FIRST")
                                    .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack))
                            }
                            .foregroundColor(BrutalistTheme.brutalistBlack.opacity(!historyStore.foodItems.isEmpty ? 1.0 : 0.4))
                            .frame(maxWidth: .infinity)
                            .padding(BrutalistTheme.spacingM)
                            .brutalistBox(
                                cornerRadius: BrutalistTheme.cornerRadiusMedium,
                                fillColor: !historyStore.foodItems.isEmpty ? BrutalistTheme.brutalistCyan : Color.gray.opacity(0.2),
                                shadowOffset: !historyStore.foodItems.isEmpty ? 3 : 0
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(historyStore.foodItems.isEmpty)
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)

                    // MARK: - Filter Section
                    filterBar

                    // MARK: - Recipe Feed
                    if recipeVM.isSearchingRecipes && recipeVM.discoveredRecipes.isEmpty {
                        VStack(spacing: BrutalistTheme.spacingM) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: BrutalistTheme.brutalistBlack))
                            Text("COOKING UP STRUCTURED ANSWERS...")
                                .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack))
                        }
                        .padding(.top, 40)
                    } else if let error = recipeVM.recipeErrorMessage {
                        VStack(spacing: BrutalistTheme.spacingS) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.system(size: 20, weight: .bold))
                            Text(error)
                                .font(.system(size: 11, weight: BrutalistTheme.fontBlack))
                        }
                        .foregroundColor(BrutalistTheme.brutalistRed)
                        .padding(.top, 40)
                    } else if recipeVM.discoveredRecipes.isEmpty {
                        VStack(spacing: BrutalistTheme.spacingM) {
                            Image(systemName: "tray.and.arrow.down")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(BrutalistTheme.brutalistBlack.opacity(0.4))
                            Text("NO RECIPES LOADED YET")
                                .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack))
                                .foregroundColor(BrutalistTheme.brutalistBlack.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(recipeVM.discoveredRecipes) { recipe in
                            InteractiveRecipeCard(recipe: recipe)
                                .padding(.horizontal, BrutalistTheme.spacingL)
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .background(backgroundColor)
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationBarHidden(true)
            .sheet(isPresented: $showChat) {
                ChatTerminalView()
            }
            .sheet(isPresented: $showingShoppingOverlay) {
                ShoppingListModalView()
            }
        }
    }
}

// MARK: - Sub-views (Extracted for readability)
private extension RecipesScreen {

    var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BrutalistTheme.spacingM) {
                ForEach(filters, id: \.self) { filter in
                    let isSelected = selectedFilter == filter
                    Button(action: { selectedFilter = filter }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                .fill(BrutalistTheme.brutalistBlack)
                                .offset(x: 3, y: 3)
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                .fill(isSelected ? BrutalistTheme.brutalistBlack : BrutalistTheme.brutalistWhite)
                            Text(filter.uppercased())
                                .font(.system(size: 12, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                .foregroundColor(isSelected ? BrutalistTheme.brutalistWhite : BrutalistTheme.brutalistBlack)
                                .padding(.horizontal, BrutalistTheme.spacingM)
                                .padding(.vertical, BrutalistTheme.spacingS)
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, BrutalistTheme.spacingL)
        }
    }
}

// MARK: - Interactive Brutalist Recipe Card Component
struct InteractiveRecipeCard: View {
    let recipe: SharedRecipe
    @EnvironmentObject var historyStore: HistoryStore

    @State private var isExpanded = false
    @State private var addedIngredients: Set<String> = []

    private var normalizedInventory: [String] {
        historyStore.foodItems.map { normalize($0.name) }
    }

    private func normalize(_ s: String) -> String {
        let lowered = s.lowercased()
        let removedPunct = lowered.replacingOccurrences(of: "[.,()\n\r]", with: " ", options: .regularExpression)
        let collapsed = removedPunct.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func ingredientKeywords(from ingredient: String) -> [String] {
        let blacklist: Set<String> = [
            "g","kg","ml","l","tbsp","tsp","cup","cups","oz","ounce","ounces","gram","grams","pinch","to","taste","of","and","or","fresh","chopped","sliced","diced","large","small","medium"
        ]
        let cleaned = normalize(ingredient)
            .replacingOccurrences(of: "[0-9/]+", with: " ", options: .regularExpression)
        let tokens = cleaned.split(separator: " ").map(String.init)
        return tokens.filter { $0.count > 2 && !blacklist.contains($0) }
    }

    private func isIngredientAvailable(_ ingredient: String) -> Bool {
        let tokens = ingredientKeywords(from: ingredient)
        guard !tokens.isEmpty else { return false }
        for inv in normalizedInventory {
            for t in tokens {
                if inv.contains(t) || t.contains(inv) { return true }
            }
        }
        return false
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                // Main Card Trigger Row
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: BrutalistTheme.spacingXS) {
                            HStack {
                                Text(recipe.title)
                                    .font(.system(size: BrutalistTheme.bodyLarge, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                            }

                            Text(recipe.description)
                                .font(.system(size: BrutalistTheme.bodyMedium, weight: .medium, design: .monospaced))
                                .foregroundColor(BrutalistTheme.brutalistBlack.opacity(0.7))
                                .multilineTextAlignment(.leading)
                                .lineLimit(isExpanded ? nil : 2)

                            HStack(spacing: BrutalistTheme.spacingS) {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                    Text(recipe.time)
                                }
                                .font(.system(size: 10, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(BrutalistTheme.brutalistCyan)
                                .cornerRadius(BrutalistTheme.cornerRadiusSmall)
                                .overlay(
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                        .strokeBorder(BrutalistTheme.brutalistBlack, lineWidth: 1.5)
                                )
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.all, BrutalistTheme.spacingM)
                }
                .buttonStyle(PlainButtonStyle())

                // Expanded Ingredient Checklist Segment
                if isExpanded {
                    Divider()
                        .background(BrutalistTheme.brutalistBlack)
                        .frame(height: 3)

                    VStack(alignment: .leading, spacing: BrutalistTheme.spacingS) {
                        Text("INGREDIENTS MATCH CHECK")
                            .font(.system(size: 12, weight: BrutalistTheme.fontBlack, design: .monospaced))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                            .padding(.bottom, 4)

                        ForEach(recipe.ingredients, id: \.self) { (ingredient: String) in
                            let isAvailable = isIngredientAvailable(ingredient)
                            let wasAdded = addedIngredients.contains(ingredient)

                            HStack {
                                Image(systemName: isAvailable ? "checkmark.square.fill" : (wasAdded ? "checkmark.seal.fill" : "exclamationmark.square.fill"))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(isAvailable ? BrutalistTheme.brutalistLime : (wasAdded ? BrutalistTheme.brutalistCyan : BrutalistTheme.brutalistRed))
                                    .transition(.scale.combined(with: .opacity))

                                Text(ingredient.capitalized)
                                    .font(.system(size: BrutalistTheme.bodyMedium, weight: isAvailable ? .medium : BrutalistTheme.fontBlack, design: .monospaced))
                                    .foregroundColor(isAvailable ? BrutalistTheme.brutalistBlack : (wasAdded ? BrutalistTheme.brutalistBlack : BrutalistTheme.brutalistRed))

                                Spacer()

                                if isAvailable {
                                    Text("IN FRIDGE")
                                        .font(.system(size: 10, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                        .foregroundColor(BrutalistTheme.brutalistBlack)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(BrutalistTheme.brutalistLime)
                                        .cornerRadius(BrutalistTheme.cornerRadiusSmall)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: 1.5)
                                        )
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    if wasAdded {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark")
                                            Text("ADDED")
                                        }
                                        .font(.system(size: 10, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                        .foregroundColor(BrutalistTheme.brutalistBlack)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(BrutalistTheme.brutalistCyan)
                                        .cornerRadius(BrutalistTheme.cornerRadiusSmall)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: 1.5)
                                        )
                                        .transition(.scale.combined(with: .opacity))
                                    } else {
                                        Button(action: {
                                            FeedbackManager.shared.triggerClack()
                                            AppStateManager.shared.addToShoppingCart(item: ingredient)
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                                addedIngredients.insert(ingredient)
                                            }
                                        }) {
                                            HStack(spacing: 4) {
                                                Text("ADD")
                                                Image(systemName: "cart.badge.plus")
                                            }
                                            .font(.system(size: 10, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 6)
                                            .background(BrutalistTheme.brutalistBlack)
                                            .cornerRadius(BrutalistTheme.cornerRadiusSmall)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                            .scaleEffect(wasAdded ? 1.02 : 1.0)
                            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: wasAdded)
                        }

                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            HStack(spacing: 6) {
                                Image(systemName: "book.pages")
                                    .font(.system(size: 14, weight: .bold))
                                Text("VIEW FULL RECIPE")
                                    .font(.system(size: 12, weight: BrutalistTheme.fontBlack, design: .monospaced))
                            }
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                        .fill(BrutalistTheme.brutalistBlack)
                                        .offset(x: 3, y: 3)
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                        .fill(BrutalistTheme.brutalistCyan)
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                        .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, BrutalistTheme.spacingS)
                    }
                    .padding(.all, BrutalistTheme.spacingM)
                    .background(Color(hex: "#EAEAEA"))
                }
            }
            .background(BrutalistTheme.brutalistWhite)
            .cornerRadius(BrutalistTheme.cornerRadiusMedium)

            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .strokeBorder(BrutalistTheme.brutalistBlack, lineWidth: 3)
        }
        .brutalistBox(
            cornerRadius: BrutalistTheme.cornerRadiusMedium,
            fillColor: Color.clear,
            shadowOffset: 3
        )
    }
}

#Preview {
    RecipesScreen()
        .environmentObject(HistoryStore())
        .environmentObject(ChatService())
        .environmentObject(RecipeViewModel())
}
