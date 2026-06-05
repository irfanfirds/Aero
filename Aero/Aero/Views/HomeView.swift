import SwiftUI

struct HomeView: View {
    private enum Destination: Hashable {
        case fridge
        case fridgeView
        case impactReport
    }

    @EnvironmentObject var historyStore: HistoryStore
    @EnvironmentObject var chatService: ChatService
    @AppStorage("displayName") private var displayName: String = "Alex"
    @State private var searchText = ""
    @State private var showManualEntry = false
    @State private var showScanner = false
    @State private var showSuccess = false
    @State private var lastScanned: String? = nil
    @State private var isSettingsPressed = false
    @State private var showSettings = false
    @State private var navigationPath: [Destination] = []
    @State private var greetingPulse = false
    
    // NewsAPI State for Live Food Trends
    @State private var searchResults: [Article] = []
    
    var expiringItemsCount: Int {
        historyStore.expiringItems().count
    }
    
    var foodSavedPercentage: Int {
        Int(historyStore.consumedPercentage * 100)
    }

    private var categoryImpactBars: [ImpactBar] {
        let categories: [FoodCategory] = [.vegetables, .fruits, .dairy, .meat, .pantry, .produce]
        let rows = categories.map { category -> ImpactBar in
            let active = historyStore.activeCount(for: category)
            let consumed = historyStore.movementCount(for: category, status: .consumed)
            let wasted = historyStore.movementCount(for: category, status: .wasted)
            return ImpactBar(
                label: String(category.rawValue.prefix(3)).uppercased(),
                score: active + consumed + wasted,
                color: color(for: category)
            )
        }

        let totalScore = rows.reduce(0) { $0 + $1.score }
        guard totalScore > 0 else {
            return rows.map { ImpactBar(label: $0.label, score: 0, color: $0.color, normalized: 0.1) }
        }

        return rows.map { row in
            let normalized = max(0.1, Double(row.score) / Double(totalScore))
            return row.withNormalized(normalized)
        }
    }

    private func color(for category: FoodCategory) -> Color {
        switch category {
        case .vegetables: return .green
        case .fruits: return .orange
        case .dairy: return .blue
        case .meat: return BrutalistTheme.brutalistRed
        case .pantry: return BrutalistTheme.brutalistYellow
        case .produce: return BrutalistTheme.brutalistLime
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: BrutalistTheme.spacingL) {
                    // MARK: - Shared Header + Settings Access
                    ZStack {
                        AuthHeaderComponent(
                            title: "Home",
                            subtitle: "Inventory owner: \(displayName)",
                            showsBackButton: false
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, BrutalistTheme.spacingM)
                    
                    HStack(alignment: .center) {
                        ZStack {
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                .fill(BrutalistTheme.brutalistBlack)
                                .offset(x: 2, y: 2)

                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                .fill(BrutalistTheme.brutalistYellow)

                            Text("HI, \(displayName.uppercased())")
                                .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                                .lineLimit(1)
                                .padding(.horizontal, BrutalistTheme.spacingM)
                                .padding(.vertical, BrutalistTheme.spacingS)

                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                        }
                        .scaleEffect(greetingPulse ? 1.03 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: greetingPulse)

                        Spacer()
                        
                        Button(action: {
                            FeedbackManager.shared.triggerClack()
                            showSettings = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(BrutalistTheme.brutalistBlack)
                                    .frame(width: 56, height: 56)
                                    .offset(
                                        x: isSettingsPressed ? 0 : 5,
                                        y: isSettingsPressed ? 0 : 5
                                    )
                                  
                                Circle()
                                    .fill(BrutalistTheme.brutalistWhite)
                                    .frame(width: 56, height: 56)
                                  
                                Image(systemName: "square.grid.2x2.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                                  
                                Circle()
                                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                    .frame(width: 56, height: 56)
                            }
                            .frame(width: 56, height: 56)
                            .offset(
                                x: isSettingsPressed ? 5 : 0,
                                y: isSettingsPressed ? 5 : 0
                            )
                            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isSettingsPressed)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    isSettingsPressed = true
                                }
                                .onEnded { _ in
                                    isSettingsPressed = false
                                }
                        )
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    .onChange(of: displayName) {
                        greetingPulse = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            greetingPulse = false
                        }
                    }
                    
                    // MARK: - Search Bar (With External News/Trends Integration)
                    HStack(spacing: BrutalistTheme.spacingM) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.gray)
                        
                        TextField("Search viral trends...", text: $searchText)
                            .font(.system(size: BrutalistTheme.bodyLarge))
                            .onSubmit {
                                searchFoodTrends(query: searchText)
                            }
                    }
                    .padding(BrutalistTheme.spacingM)
                    .background(
                        ZStack {
                            // Shadow layer
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                                .fill(BrutalistTheme.brutalistBlack)
                                .offset(x: 4, y: 4)
                            
                            // Fill layer
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                                .fill(BrutalistTheme.brutalistWhite)
                            
                            // Border layer
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                        }
                    )
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    // MARK: - Live Search Trends Dynamic Section
                    if !searchResults.isEmpty {
                        VStack(alignment: .leading, spacing: BrutalistTheme.spacingM) {
                            Text("TRENDING FOOD DEEP-DIVES")
                                .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                .padding(.horizontal, BrutalistTheme.spacingM)
                                .padding(.vertical, 4)
                                .background(BrutalistTheme.brutalistCyan)
                                .border(BrutalistTheme.brutalistBlack, width: 2)
                            
                            ForEach(searchResults) { article in
                                if let url = URL(string: article.url) {
                                    Link(destination: url) {
                                        HStack(spacing: BrutalistTheme.spacingM) {
                                            AsyncImage(url: article.safeImageUrl) { image in
                                                image.resizable().scaledToFill()
                                            } placeholder: {
                                                ProgressView()
                                            }
                                            .frame(width: 60, height: 60)
                                            .border(BrutalistTheme.brutalistBlack, width: 2)
                                            .clipped()
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(article.title)
                                                    .font(.system(size: BrutalistTheme.bodyMedium, weight: BrutalistTheme.fontBold))
                                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                                
                                                Text("EXPLORE SOURCE ↗")
                                                    .font(.system(size: 11, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                                    .foregroundColor(.blue)
                                            }
                                            Spacer()
                                        }
                                        .padding(BrutalistTheme.spacingM)
                                        .background(BrutalistTheme.brutalistWhite)
                                        .border(BrutalistTheme.brutalistBlack, width: 2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, BrutalistTheme.spacingL)
                    }
                    
                    // MARK: - Waste Alert Card
                    if expiringItemsCount > 0 {
                        WasteAlertCard(
                            itemCount: expiringItemsCount,
                            onViewFridge: {
                                FeedbackManager.shared.triggerClack()
                                navigationPath.append(.fridgeView)
                            }
                        )
                        .padding(.horizontal, BrutalistTheme.spacingL)
                    }
                    
                    // MARK: - Impact Section Header
                    HStack {
                        Text("Impact")
                            .font(.system(size: BrutalistTheme.titleMedium, weight: BrutalistTheme.fontBlack))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                        
                        Spacer()
                        
                        Button(action: {
                            FeedbackManager.shared.triggerClack()
                            navigationPath.append(.impactReport)
                        }) {
                            Text("View Report")
                                .font(.system(size: BrutalistTheme.bodyMedium, weight: BrutalistTheme.fontBold))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                                .underline()
                        }
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    // MARK: - Impact Chart Card
                    ImpactChartCard(
                        percentage: foodSavedPercentage,
                        bars: categoryImpactBars
                    )
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    // MARK: - Quick Actions Header
                    Text("Quick Actions")
                        .font(.system(size: BrutalistTheme.titleMedium, weight: BrutalistTheme.fontBlack))
                        .foregroundColor(BrutalistTheme.brutalistBlack)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    // MARK: - Quick Action Buttons
                    HStack(spacing: BrutalistTheme.spacingM) {
                        QuickActionButton(
                            title: "Add Item",
                            icon: "plus",
                            backgroundColor: BrutalistTheme.brutalistLime,
                            action: {
                                showManualEntry = true
                            }
                        )
                        
                        QuickActionButton(
                            title: "Scan",
                            icon: "qrcode.viewfinder",
                            backgroundColor: BrutalistTheme.brutalistCyan,
                            action: {
                                showScanner = true
                            }
                        )
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    // Bottom padding for tab bar
                    Spacer()
                        .frame(height: 100)
                }
            }
            .background(Color(hex: "#F5F5F5"))
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showManualEntry) {
                ManualEntryView()
            }
            .sheet(isPresented: $showScanner) {
                AeroScannerView(
                    showSuccess: $showSuccess,
                    lastScanned: Binding(
                        get: { self.lastScanned ?? "" },
                        set: { self.lastScanned = $0 }
                    )
                )
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .fridge:
                    ItemsView()
                case .fridgeView:
                    FridgeView()
                case .impactReport:
                    ImpactReportView()
                }
            }
        }
    }
    
    // MARK: - News API Network Fetch Function
    func searchFoodTrends(query: String) {
        guard !query.isEmpty else {
            self.searchResults = []
            return
        }
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let newsKey = Bundle.main.object(forInfoDictionaryKey: "NEWS_API_KEY") as? String,
              !newsKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = URL(string: "https://newsapi.org/v2/everything?q=\(encodedQuery)+food&sortBy=relevance&apiKey=\(newsKey)") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(NewsResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.searchResults = Array(decodedResponse.articles.filter { !$0.title.isEmpty }.prefix(5))
                    }
                } catch {
                    print("Error decoding trends syntax: \(error)")
                }
            }
        }
        .resume()
    }
}

// MARK: - Waste Alert Card Component (FIXED: 3D Hard-Sunk Effect)
struct WasteAlertCard: View {
    let itemCount: Int
    let onViewFridge: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrutalistTheme.spacingM) {
            HStack {
                Text("ALERT")
                    .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
                    .padding(.horizontal, BrutalistTheme.spacingM)
                    .padding(.vertical, BrutalistTheme.spacingXS)
                    .background(
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                            .fill(BrutalistTheme.brutalistWhite)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                    )
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(BrutalistTheme.brutalistWhite.opacity(0.3))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(BrutalistTheme.brutalistWhite)
                }
            }
            
            Text("\(itemCount) Items Expiring")
                .font(.system(size: BrutalistTheme.titleMedium, weight: BrutalistTheme.fontBlack))
                .foregroundColor(BrutalistTheme.brutalistWhite)
            
            Text("Act now or feel the guilt.")
                .font(.system(size: BrutalistTheme.bodyMedium))
                .foregroundColor(BrutalistTheme.brutalistWhite.opacity(0.9))
            
            HStack(spacing: -8) {
                ForEach(0..<min(itemCount, 3), id: \.self) { _ in
                    Circle()
                        .fill(BrutalistTheme.brutalistWhite.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                        )
                }
            }
            .padding(.vertical, BrutalistTheme.spacingXS)
            
            BrutalistMainButton(
                title: "VIEW FRIDGE",
                icon: "refrigerator",
                color: BrutalistTheme.brutalistWhite,
                action: onViewFridge
            )
            .padding(.top, BrutalistTheme.spacingS)
        }
        .padding(BrutalistTheme.spacingL)
        .background(
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                .fill(BrutalistTheme.brutalistRed)
        )
        .overlay(
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: 3)
        )
        .background(
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                .fill(BrutalistTheme.brutalistBlack)
                .offset(x: BrutalistTheme.shadowOffset.width, y: BrutalistTheme.shadowOffset.height)
        )
    }
}

// MARK: - Impact Chart Card Component (FIXED: Sandwich Method)
struct ImpactChartCard: View {
    let percentage: Int
    let bars: [ImpactBar]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                .fill(BrutalistTheme.brutalistBlack)
                .offset(x: 5, y: 5)
            
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                .fill(BrutalistTheme.brutalistLavender)
            
            VStack(alignment: .leading, spacing: BrutalistTheme.spacingL) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: BrutalistTheme.spacingXS) {
                        Text("\(percentage)%")
                            .font(.system(size: 64, weight: BrutalistTheme.fontBlack))
                        Text("FOOD SAVED")
                            .font(.system(size: BrutalistTheme.bodyMedium, weight: BrutalistTheme.fontBlack))
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(BrutalistTheme.brutalistBlack)
                        Image(systemName: "arrow.down")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                    }
                    .frame(width: 44, height: 44)
                }
                
                Text("\(bars.reduce(0) { $0 + $1.score }) logged food events")
                    .font(.system(size: BrutalistTheme.bodyMedium, weight: BrutalistTheme.fontSemiBold))
                    .opacity(0.7)

                HStack(alignment: .bottom, spacing: BrutalistTheme.spacingS) {
                    ForEach(bars) { bar in
                        VStack(spacing: BrutalistTheme.spacingXS) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(bar.color)
                                .frame(width: 30, height: 40 + (bar.normalized * 80))
                            Text(bar.label)
                                .font(.system(size: 10, weight: BrutalistTheme.fontBlack))
                                .foregroundColor(BrutalistTheme.brutalistBlack.opacity(0.7))
                        }
                    }
                }
            }
            .padding(BrutalistTheme.spacingL)
            .foregroundColor(BrutalistTheme.brutalistBlack)
            
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: 3)
        }
    }
}

struct ImpactBar: Identifiable {
    let id = UUID()
    let label: String
    let score: Int
    let color: Color
    var normalized: Double = 0
    
    func withNormalized(_ val: Double) -> ImpactBar {
        var copy = self
        copy.normalized = val
        return copy
    }
}

// MARK: - Quick Action Button Component (FIXED: Sandwich Method)
struct QuickActionButton: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                    .fill(BrutalistTheme.brutalistBlack)
                    .offset(x: 5, y: 5)
                
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                    .fill(backgroundColor)
                
                VStack(spacing: BrutalistTheme.spacingM) {
                    ZStack {
                        Circle()
                            .fill(BrutalistTheme.brutalistWhite)
                        Circle()
                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                        Image(systemName: icon)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                    }
                    .frame(width: 64, height: 64)
                    
                    Text(title)
                        .font(.system(size: BrutalistTheme.titleSmall, weight: BrutalistTheme.fontBlack))
                        .foregroundColor(BrutalistTheme.brutalistBlack)
                }
                .padding(.vertical, BrutalistTheme.spacingXL)
                
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let mockAuth = AuthManager(isPreviewMode: true)
    
    HomeView()
        .environmentObject(mockAuth)
        .environmentObject(HistoryStore())
        .environmentObject(ChatService())
        .environmentObject(ShoppingStore())
}


// ==========================================
// MARK: - STEP 2: NETWORK DECODABLE MODELS
// ==========================================

struct NewsResponse: Decodable {
    let articles: [Article]
}

struct Article: Identifiable, Decodable {
    var id: String { url }
    let title: String
    let url: String
    let urlToImage: String?
    
    var safeImageUrl: URL? {
        URL(string: urlToImage ?? "https://via.placeholder.com/150")
    }
}
