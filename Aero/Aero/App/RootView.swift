//
//  RootView.swift
//  Aero
//
//  Created by SWITCH on 07/01/2026.
//

import SwiftUI

struct RootView: View {
    // 1. Observe the central AuthManager state
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var historyStore: HistoryStore
    @EnvironmentObject var chatService: ChatService
    
    @State private var selectedTab: TabItem = .home
    
    var body: some View {
        Group {
            // 2. Drive the view layout using AuthManager's verified published property
            if authManager.isLoggedIn {
                // If true, show the main part of your app
                ZStack(alignment: .bottom) {
                    // Background
                    Color(hex: "#F5F5F5")
                        .ignoresSafeArea()
                    
                    // Main Content
                    Group {
                        switch selectedTab {
                        case .home:
                            HomeView()
                        case .items:
                            ItemsView()
                        case .recipes:
                            RecipesScreen()
                        case .history:
                            HistoryView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.all, edges: .bottom)
                    
                    CustomTabBar(selectedTab: $selectedTab)
                        .padding(.bottom, 16)
                        .padding(.horizontal)
                }
                .animation(.spring(), value: selectedTab)
            } else {
                // If false, show the login/registration screen
                LoginView()
            }
        }
        .environmentObject(historyStore)
    }
}

extension HistoryStore {
    // Clears all history entries using the store's real purge API
    func clearHistory() {
        clearAllData()
    }

    // Archives/removes only expired items by leveraging existing markAs logic
    func clearPastHistory() {
        let now = Date()
        let expired = foodItems.filter { $0.expiryDate < now }
        guard !expired.isEmpty else { return }
        for item in expired {
            // Move to history as wasted, matching performExpiredSweep semantics
            markAs(item, status: .wasted)
        }
    }
}

#Preview {
    let mockAuth = AuthManager(isPreviewMode: true)
    
    RootView()
        .environmentObject(mockAuth)
        .environmentObject(HistoryStore())
        .environmentObject(ChatService())
        .environmentObject(ShoppingStore())
}
