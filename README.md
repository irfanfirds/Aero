# Aero — Smart Food Waste Reduction

Aero is an iOS app that helps you eliminate food waste by tracking your kitchen inventory, sending expiry alerts, suggesting AI-powered recipes from ingredients you already have, and visualising your sustainability impact over time. Data syncs across devices in real time via Firestore.

---

## Features

- **Inventory Management** — Add items manually or by barcode scan; track expiry dates, quantities, categories, and photos
- **Barcode Scanning** — Scan any UPC/EAN barcode with VisionKit; product name, image, and nutrition data are auto-fetched from Open Food Facts
- **Expiry Tracking** — Items are automatically classified as Fresh, Expiring Soon, or Expired; you receive a system notification one day before each item expires
- **AI Recipe Suggestions** — Powered by Google Gemini 2.5 Flash; generates creative recipes based on your current inventory with smart retry and fallback logic
- **AI Chat Assistant** — Context-aware conversational AI with access to your inventory (500 requests/day quota)
- **Sustainability Impact** — Tracks consumed vs. wasted items per category; visualises CO₂ savings and food-saved percentage on the home dashboard
- **Food History & Analytics** — "Guilt vs. Pride" donut chart; clear history or archive expired items only
- **Live Food Trends** — Search trending food articles powered by NewsAPI
- **Shopping List** — Generate a shopping list for recipes with missing ingredients
- **Cross-Device Sync** — All inventory, history, and photos sync in real time via Firestore; data persists across reinstalls and devices

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | SwiftUI 5 |
| Architecture | MVVM + Combine |
| Authentication | Firebase Auth (Email/Password, Google Sign-In, Apple Sign-In) |
| Cloud Sync | Firebase Firestore (free Spark plan) |
| AI / Chat | Google Gemini 2.5 Flash + 2.5 Flash Lite fallback (`GoogleGenerativeAI` SDK) |
| Food Data | Open Food Facts REST API |
| News | NewsAPI |
| Barcode Scanning | VisionKit (`DataScannerViewController`) |
| Local Persistence | JSONDatabase (Documents folder) + UserDefaults fallback |
| Photo Storage | JPEG compressed to Base64, stored inside Firestore documents |
| Notifications | `UNUserNotificationCenter` |
| Design System | Custom Brutalist theme (bold borders, monospaced type, sandwich shadows) |

---

## Architecture

```
AeroApp (entry point)
    └── AppDelegate          ← Firebase init, Google Sign-In URL handling
    └── AuthManager          ← Firebase Auth facade (email, Google, Apple)
    └── RootView             ← Routes to LoginView or main tab bar

ViewModels (ObservableObject state stores)
    ├── HistoryStore         ← Food inventory + movement history + Firestore sync coordinator
    ├── ChatService          ← AI chat messages + daily quota tracking
    ├── ShoppingStore        ← Shopping list state
    └── RecipeViewModel      ← Recipe generation state

Services (network + persistence)
    ├── AeroAIService        ← Gemini 2.5 Flash (chat, insights, recipes) with retry + fallback
    ├── FirestoreService     ← Firestore real-time sync (items, movements, photos as Base64)
    ├── FoodAPIService       ← Open Food Facts barcode lookup
    ├── HistoryService       ← UserDefaults persistence (fallback)
    └── JSONDatabase         ← JSON file persistence (primary local store)

Models (pure data structs)
    ├── FoodItem             ← Inventory item model + FoodCategory / ItemStatus enums
    ├── ChatModel            ← Chat message structures
    └── SharedRecipe         ← Recipe model
```

---

## Folder Structure

```
Aero/Aero/
├── App/                 AeroApp.swift, AppDelegate.swift, RootView.swift, AeroSupport.swift
├── Authentication/      AuthManager.swift, LoginView.swift, RegisterView.swift
├── Models/              FoodItem.swift, ChatModel.swift, SharedRecipe.swift
├── ViewModels/          HistoryStore.swift, ChatService.swift, ShoppingStore.swift, RecipeViewModel.swift
├── Services/            AeroAIService.swift, FirestoreService.swift, FoodAPIService.swift,
│                        HistoryService.swift, JSONDatabase.swift
├── Views/               HomeView, ItemsView, FridgeView, HistoryView, ChatTerminalView,
│                        AeroScannerView, ManualEntryView, SettingsView, ImpactReportView,
│                        ItemDetailView, PostActionView
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
- A Firebase project (free Spark plan is sufficient — no Blaze/pay-as-you-go required)
- A Google AI Studio account (free Gemini API key)
- A NewsAPI account (free plan for development)

---

### 1. Clone the repository

```bash
git clone https://github.com/irfanfirds/Aero.git
cd Aero
```

---

### 2. Set up Firebase

1. Go to [Firebase Console](https://console.firebase.google.com) → **Create a new project**
2. Add an **iOS app** — use the same bundle ID as in the Xcode project (check Xcode → target → General → Bundle Identifier)
3. Download `GoogleService-Info.plist` and place it at `Aero/GoogleService-Info.plist`

> `GoogleService-Info.plist` is **gitignored** — it is never committed. Every developer manages their own copy locally.

4. Enable **Authentication** → Sign-in method → turn on:
   - Email/Password
   - Google
   - Apple

5. Create **Firestore Database**:
   - Build → Firestore Database → **Create database**
   - Choose **Production mode**
   - Select region: `asia-southeast1` (or nearest to you)

6. Set **Firestore Security Rules** (Rules tab):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

7. **Disable App Check enforcement**:
   - App Check → **APIs** tab *(not the Apps tab)*
   - Cloud Firestore → 3-dot menu → **Disable enforcement**
   - Firebase Authentication → 3-dot menu → **Disable enforcement**

---

### 3. Configure API keys

API keys are stored in a local file that is **never committed to git**.

Create `APIKeys.plist` inside `Aero/Aero/` with this structure:

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

- **Gemini API key** → [Google AI Studio](https://aistudio.google.com) (free)
- **NewsAPI key** → [NewsAPI.org](https://newsapi.org) (free dev plan)

In Xcode: right-click the `Aero` group → **Add Files to "Aero"** → select `APIKeys.plist` → make sure the target checkbox is ticked.

---

### 4. Configure Google Sign-In URL scheme

1. Open `Aero/Aero/Info.plist`
2. Under `CFBundleURLTypes → CFBundleURLSchemes`, replace the existing value with the `REVERSED_CLIENT_ID` from your own `GoogleService-Info.plist` (looks like `com.googleusercontent.apps.XXXXXXX`)

---

### 5. Build and run

Open `Aero/Aero.xcodeproj` in Xcode, select a simulator or connected device (iOS 17+), and press **Run** (⌘R).

---

## For Collaborators (Multiple Developers)

Each developer must set up their **own** Firebase project and local config files. These files are gitignored and never shared via the repo:

| File | Location | How to get it |
|------|----------|---------------|
| `GoogleService-Info.plist` | `Aero/` | Download from your own Firebase Console iOS app |
| `APIKeys.plist` | `Aero/Aero/` | Create manually with your own API keys |

**Bundle ID:** The Xcode project has a default bundle ID. Register an iOS app in your Firebase project using that exact bundle ID, then download the matching `GoogleService-Info.plist`.

If you want to use a different bundle ID:
1. Change it locally in Xcode → target → General → Bundle Identifier
2. Register an iOS app in your Firebase project with the new bundle ID
3. Download the matching `GoogleService-Info.plist`
4. **Do not push the bundle ID change** — it stays local on your machine only

---

## Configuration Reference

| Key | File | Description |
|-----|------|-------------|
| `GEMINI_API_KEY` | `APIKeys.plist` *(gitignored)* | Google Gemini API key from AI Studio |
| `NEWS_API_KEY` | `APIKeys.plist` *(gitignored)* | NewsAPI key for live food trend search |
| `GoogleService-Info.plist` | `Aero/` *(gitignored)* | Firebase project configuration — each developer uses their own |
| `REVERSED_CLIENT_ID` | `Info.plist → CFBundleURLSchemes` | Google OAuth redirect URL (copied from your `GoogleService-Info.plist`) |

---

## AI Reliability

The AI layer uses a three-layer resilience strategy:

1. **Model fallback** — If `gemini-2.5-flash` returns a 503 (high demand), the app automatically retries then switches to `gemini-2.5-flash-lite` which runs on separate infrastructure
2. **Exponential backoff** — Three attempts at 0s → 1s → 3s before falling back to the lite model
3. **Response caching** — Sustainability insights and recipe results are cached in memory by ingredient list; identical requests return instantly without consuming quota

Daily quota is 500 requests per device, tracked in `UserDefaults` and reset each day.

---

## Cross-Device Sync

All data syncs via Firestore using the free Spark plan:

- **On login** — Firestore listener attaches and merges remote data with local data
- **On logout** — Listener detaches; local data remains on device
- **New device / reinstall** — Firestore restores full inventory and history on login
- **Photos** — Compressed to 150×150px JPEG at 40% quality (~15–25 KB), stored as Base64 inside the Firestore document. Visible in Firebase Console as the `image` field. If Firestore quota is full, photo sync is silently skipped — item text data always syncs first
- **Offline** — Firestore offline persistence queues writes and syncs when connectivity returns

---

## Authentication Flow

1. **Register** — Creates a Firebase account, sends a verification email, and signs the user out. The user cannot access the app until they verify their email
2. **Login (Email/Password)** — Checks `isEmailVerified` before granting access. Unverified accounts are blocked with a clear error message
3. **Login (Google / Apple)** — OAuth tokens are inherently verified; no email verification step is required
4. **Persistent Session** — Firebase persists the session on-device; users stay logged in across app launches

---

## Known Limitations

- **Gemini quota** — 500 requests/day per device via `UserDefaults`. Uninstalling the app resets the counter
- **NewsAPI in production** — Free plan only allows requests from `localhost`. A paid plan or server-side proxy is required for App Store distribution
- **Open Food Facts** — Coverage varies by region; not all barcodes return product data
- **Firestore photo storage** — Photos are stored as Base64 strings inside Firestore documents. They are not viewable as images in the Firebase Console — only as raw strings in the `image` field. Total Firestore free tier is 1 GB; at ~20 KB per photo, this supports approximately 50,000 photos before hitting the limit. If the limit is reached, photos stop syncing but all item text data continues to sync normally

---

## License

MIT
