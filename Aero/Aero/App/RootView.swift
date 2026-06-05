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
    @State private var showClearAllConfirm = false
    @State private var showClearPastConfirm = false
    
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
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if selectedTab == .history {
                            Menu {
                                Button(role: .destructive) { showClearAllConfirm = true } label: {
                                    Label("Clear All History", systemImage: "trash")
                                }
                                Button { showClearPastConfirm = true } label: {
                                    Label("Clear Past (Expired)", systemImage: "clock.arrow.circlepath")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }
                .confirmationDialog("Are you sure?", isPresented: $showClearAllConfirm, titleVisibility: .visible) {
                    Button("Clear All History", role: .destructive) {
                        historyStore.clearHistory()
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .confirmationDialog("Clear past (expired) items?", isPresented: $showClearPastConfirm, titleVisibility: .visible) {
                    Button("Clear Past", role: .destructive) {
                        historyStore.clearPastHistory()
                    }
                    Button("Cancel", role: .cancel) { }
                }
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
