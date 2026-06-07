import SwiftUI
import FirebaseCore
import FirebaseAppCheck

@main
struct AeroApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var authManager = AuthManager()
    @StateObject private var historyStore = HistoryStore()
    @StateObject private var chatService = ChatService()
    @StateObject private var shoppingStore = ShoppingStore()
    @StateObject private var recipeVM = RecipeViewModel()

    init() {
        // App Check provider MUST be set before FirebaseApp.configure().
        // Using DebugProvider skips the DeviceCheck network call that was
        // blocking all auth requests before they even started.
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #endif

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(historyStore)
                .environmentObject(chatService)
                .environmentObject(shoppingStore)
                .environmentObject(recipeVM)
                .onChange(of: authManager.isLoggedIn) { _, isLoggedIn in
                    if isLoggedIn, let uid = authManager.user?.uid {
                        historyStore.startFirestoreSync(uid: uid)
                    } else {
                        historyStore.stopFirestoreSync()
                    }
                }
        }
    }
}
