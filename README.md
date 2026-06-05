# Aero — Smart Food Waste Reduction

Aero is an iOS app that helps you eliminate food waste by tracking your kitchen inventory, sending expiry alerts, suggesting AI-powered recipes from ingredients you already have, and visualising your sustainability impact over time.

---

## Features

- **Inventory Management** — Add items manually or by barcode scan; track expiry dates, quantities, categories, and photos
- **Barcode Scanning** — Scan any UPC/EAN barcode with VisionKit; product name, image, and nutrition data are auto-fetched from Open Food Facts
- **Expiry Tracking** — Items are automatically classified as Fresh, Expiring Soon, or Expired; you receive a system notification one day before each item expires
- **AI Recipe Suggestions** — Powered by Google Gemini 1.5 Flash; generates creative recipes based on your current inventory and filters by prep time, carbon footprint, and protein content
- **AI Chat Assistant** — Context-aware conversational AI with access to your inventory (250 requests/day quota)
- **Sustainability Impact** — Tracks consumed vs. wasted items per category; visualises CO₂ savings and food-saved percentage on the home dashboard
- **Food History & Analytics** — "Guilt vs. Pride" donut chart; clear history or archive expired items only
- **Live Food Trends** — Search trending food articles powered by NewsAPI
- **Shopping List** — Generate a shopping list for recipes missing ingredients

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | SwiftUI 5 |
| Architecture | MVVM + Combine |
| Authentication | Firebase Auth (Email/Password, Google Sign-In, Apple Sign-In) |
| AI / Chat | Google Gemini 1.5 Flash (`GoogleGenerativeAI` SDK) |
| Food Data | Open Food Facts REST API |
| News | NewsAPI |
| Barcode Scanning | VisionKit (`DataScannerViewController`) |
| Local Persistence | JSONDatabase (Documents folder) + UserDefaults fallback |
| Notifications | `UNUserNotificationCenter` |
| Design System | Custom Brutalist theme (bold borders, monospaced type, sandwich shadows) |

---

## Architecture

```
AeroApp (entry point)
    └── AppDelegate          ← Firebase init, App Check (#if DEBUG)
    └── AuthManager          ← Firebase Auth facade (email, Google, Apple)
    └── RootView             ← Routes to LoginView or main tab bar

ViewModels (ObservableObject state stores)
    ├── HistoryStore         ← Food inventory + movement history (primary store)
    ├── ChatService          ← AI chat messages + daily quota tracking
    ├── ShoppingStore        ← Shopping list state
    └── AppStateManager      ← App-wide shared state

Services (network + persistence)
    ├── AeroAIService        ← Gemini 1.5 Flash (chat, insights, recipes)
    ├── FoodAPIService       ← Open Food Facts barcode lookup
    ├── HistoryService       ← UserDefaults persistence (fallback)
    └── JSONDatabase         ← JSON file persistence (primary)

Models (pure data structs)
    ├── FoodItem             ← Inventory item model + FoodCategory / ItemStatus enums
    ├── ChatModel            ← Chat message structures
    └── SharedRecipe         ← Recipe model

Views / Recipes / Components / Themes
    └── All SwiftUI view files, reusable components, and the Brutalist design system
```

---

## Folder Structure

```
Aero/Aero/
├── App/                 AeroApp.swift, AppDelegate.swift, RootView.swift, AeroSupport.swift
├── Authentication/      AuthManager.swift, LoginView.swift, RegisterView.swift, AuthHeaderComponent.swift
├── Models/              FoodItem.swift, ChatModel.swift, SharedRecipe.swift
├── ViewModels/          HistoryStore.swift, ChatService.swift, ShoppingStore.swift, AppStateManager.swift
├── Services/            AeroAIService.swift, FoodAPIService.swift, HistoryService.swift, JSONDatabase.swift
├── Views/               HomeView, ItemsView, FridgeView, HistoryView, ChatTerminalView, AeroScannerView,
│                        ManualEntryView, SettingsView, ImpactReportView, ItemDetailView, PostActionView
├── Recipes/             RecipesView, RecipeDetailView, recipe card components, ShoppingListModalView
├── Components/          CustomTabBar, AIOrbView, AeroScannerContainer, VirtualFridgeButton
├── Themes/              BrutalistTheme.swift, BrutalistComponents.swift, BrutalistMainButton.swift
└── Audio/               FeedbackManager.swift
```

---

## Getting Started

### Prerequisites

- Xcode 16 or later
- iOS 17+ device or simulator
- A Firebase project (free Spark plan is sufficient)
- A Google AI Studio account (free Gemini API key)
- A NewsAPI account (free plan for development)

### 1. Clone the repository

```bash
git clone https://github.com/your-username/Aero.git
cd Aero
```

### 2. Set up Firebase

1. Go to the [Firebase Console](https://console.firebase.google.com) and create a new project.
2. Add an iOS app with bundle ID `com.aero.app` (or your chosen bundle ID).
3. Enable **Authentication** → Sign-in providers → turn on **Email/Password** and **Google**.
4. Download the generated `GoogleService-Info.plist`.
5. Place it at `Aero/Aero/GoogleService-Info.plist` (replace the existing placeholder file).

### 3. Configure API keys

API keys are stored in a local file that is **not committed to git** to keep them private.

1. Create a file named `APIKeys.plist` inside `Aero/Aero/` with the following structure:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GEMINI_API_KEY</key>
    <string>YOUR_GEMINI_KEY_HERE</string>
    <key>NEWS_API_KEY</key>
    <string>YOUR_NEWS_API_KEY_HERE</string>
</dict>
</plist>
```

2. Get your **Gemini API key** from [Google AI Studio](https://aistudio.google.com) and paste it in.
3. Get your **NewsAPI key** from [NewsAPI.org](https://newsapi.org) and paste it in.
4. In Xcode, right-click the `Aero` folder → **Add Files to "Aero"** → select `APIKeys.plist`.

> `APIKeys.plist` is gitignored and will never be committed. If you are a collaborator, request this file privately from the project owner.

### 5. Configure Google Sign-In URL scheme

1. Open `Aero/Aero/Info.plist` in Xcode.
2. Under `CFBundleURLTypes`, find the entry with `CFBundleURLSchemes`.
3. Replace the existing value with the `REVERSED_CLIENT_ID` from your `GoogleService-Info.plist` (looks like `com.googleusercontent.apps.XXXXXXX`).

### 6. Build and run

Open `Aero/Aero.xcodeproj` in Xcode, select a simulator or connected device (iOS 17+), and press **Run** (⌘R).

---

## Configuration Reference

| Key | File | Description |
|-----|------|-------------|
| `GEMINI_API_KEY` | `APIKeys.plist` *(gitignored)* | Google Gemini API key from AI Studio |
| `NEWS_API_KEY` | `APIKeys.plist` *(gitignored)* | NewsAPI key for live food trend search |
| `GoogleService-Info.plist` | `Aero/Aero/` | Firebase project configuration file |
| `REVERSED_CLIENT_ID` | `Info.plist` → `CFBundleURLSchemes` | Google OAuth redirect URL (from `GoogleService-Info.plist`) |

---

## Authentication Flow

1. **Register** — Creates a Firebase account, sends a verification email, and signs the user out. The user cannot access the app until they verify their email.
2. **Login (Email/Password)** — Checks `isEmailVerified` before granting access. Unverified accounts are blocked with a clear error message.
3. **Login (Google / Apple)** — OAuth tokens are inherently verified; no email verification step is required.
4. **Persistent Session** — Firebase persists the session on-device; users stay logged in across app launches.

---

## Known Limitations

- **Gemini quota** — Free-tier API keys have a 250 requests/day limit enforced per device via `UserDefaults`. Uninstalling and reinstalling the app resets the counter.
- **NewsAPI in production** — NewsAPI free plan only allows requests from `localhost`. For a production release you will need a paid NewsAPI plan or a server-side proxy.
- **Open Food Facts** — Coverage varies by region; not all barcodes return product data.
- **Image storage** — Item photos are stored as binary `Data` inside `FoodItem`. Large inventories with many photos may increase local storage usage.

---

## License

MIT
