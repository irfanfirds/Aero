import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // 👑 1. Centralized Environment Pipeline
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var historyStore: HistoryStore
    
    // 2. Local AppStorage Properties for User Profile Card
    @AppStorage("username") private var username: String = "Alex Morgan"
    @AppStorage("userHandle") private var userHandle: String = "@aero_manifesto"
    @AppStorage("displayName") private var displayName: String = "Alex Morgan"
    @AppStorage("dietaryRules") private var dietaryRules: String = "Vegetarian, No Nuts"
    @AppStorage("veganMode") private var veganMode: Bool = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("clackSoundsEnabled") private var clackSoundsEnabled: Bool = true
    @AppStorage("hapticIntensity") private var hapticIntensity: String = "Medium"
    
    @State private var showNameAlert = false
    @State private var newName = ""
    
    let dietaryOptions = [
        "Vegetarian, No Nuts",
        "Vegan",
        "Gluten-Free",
        "Keto",
        "Paleo",
        "No Restrictions"
    ]
    
    let hapticOptions = ["Light", "Medium", "Heavy"]
    
    // Safe initials calculation
    var userInitials: String {
        let components = displayName.components(separatedBy: " ")
        let filtered = components.filter { !$0.isEmpty }
        
        if filtered.count >= 2 {
            return (String(filtered[0].prefix(1)) + String(filtered[1].prefix(1))).uppercased()
        } else if let first = filtered.first {
            return String(first.prefix(2)).uppercased()
        }
        return "???"
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: BrutalistTheme.spacingXL) {
                // Settings Header Core Component View Layout
                AuthHeaderComponent(
                    title: "Settings",
                    subtitle: "Account profile: \(displayName.isEmpty ? "Guest" : displayName)",
                    showsBackButton: true,
                    backAction: {
                        FeedbackManager.shared.triggerClack()
                        dismiss()
                    }
                )
                
                // MARK: - Profile Section (FIXED: Margins)
                VStack(spacing: BrutalistTheme.spacingM) {
                    // Profile Avatar with Edit Badge (FIXED: Sandwich Method)
                    ZStack(alignment: .bottomTrailing) {
                        // Main Avatar (FIXED: Sandwich Method)
                        ZStack {
                            // Shadow
                            Circle()
                                .fill(BrutalistTheme.brutalistBlack)
                                .frame(width: 120, height: 120)
                                .offset(x: 5, y: 5)
                            
                            // Fill
                            Circle()
                                .fill(BrutalistTheme.brutalistYellow)
                                .frame(width: 120, height: 120)
                            
                            // Content
                            Text(userInitials)
                                .font(.system(size: 48, weight: BrutalistTheme.fontBlack))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                            
                            // Border
                            Circle()
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                .frame(width: 120, height: 120)
                        }
                        
                        // Edit Badge (FIXED: Sandwich Method)
                        Button(action: {
                            FeedbackManager.shared.triggerClack()
                            newName = displayName
                            showNameAlert = true
                        }) {
                            ZStack {
                                // Shadow
                                Circle()
                                    .fill(BrutalistTheme.brutalistBlack)
                                    .frame(width: 36, height: 36)
                                    .offset(x: 4, y: 4)
                                
                                // Fill
                                Circle()
                                    .fill(BrutalistTheme.brutalistCyan)
                                    .frame(width: 36, height: 36)
                                
                                // Content
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                                
                                // Border
                                Circle()
                                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                    .frame(width: 36, height: 36)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .offset(x: -8, y: -8)
                    }
                    
                    // Name
                    Text(displayName.isEmpty ? "No Name" : displayName)
                        .font(.system(size: BrutalistTheme.titleMedium, weight: BrutalistTheme.fontBlack))
                        .foregroundColor(BrutalistTheme.brutalistBlack)
                    
                    // Handle
                    Text(userHandle)
                        .font(.system(size: BrutalistTheme.bodyMedium))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, BrutalistTheme.spacingL)
                .padding(.horizontal, BrutalistTheme.spacingL)
                
                // MARK: - Preferences Section (FIXED: Margins)
                VStack(alignment: .leading, spacing: BrutalistTheme.spacingL) {
                    // Section Header
                    HStack(spacing: BrutalistTheme.spacingS) {
                        Rectangle()
                            .fill(BrutalistTheme.brutalistBlack)
                            .frame(width: 4, height: 20)
                        
                        Text("PREFERENCES")
                            .font(.system(size: BrutalistTheme.bodyLarge, weight: BrutalistTheme.fontBlack))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    // Settings Cards (FIXED: Sandwich Method)
                    VStack(spacing: BrutalistTheme.spacingM) {
                        SettingsCard(
                            icon: "person.text.rectangle.fill",
                            iconColor: BrutalistTheme.brutalistCyan,
                            backgroundColor: BrutalistTheme.brutalistLightCyan,
                            label: "DISPLAY NAME",
                            value: displayName.isEmpty ? "No Name" : displayName,
                            hasChevron: true,
                            action: {
                                newName = displayName
                                showNameAlert = true
                            }
                        )
                        
                        SettingsMenuCard(
                            icon: "fork.knife",
                            iconColor: BrutalistTheme.brutalistYellow,
                            backgroundColor: BrutalistTheme.brutalistCream,
                            label: "DIETARY RULES",
                            selectedValue: $dietaryRules,
                            options: dietaryOptions
                        )
                        
                        SettingsToggleCard(
                            icon: "leaf.fill",
                            iconColor: .green,
                            backgroundColor: BrutalistTheme.brutalistWhite,
                            label: "Vegan Mode",
                            isOn: $veganMode
                        )
                        
                        SettingsToggleCard(
                            icon: "bell.fill",
                            iconColor: BrutalistTheme.brutalistCyan,
                            backgroundColor: BrutalistTheme.brutalistWhite,
                            label: "Notifications",
                            isOn: $notificationsEnabled
                        )
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)
                }
                
                // MARK: - App Feedback Section (FIXED: Margins)
                VStack(alignment: .leading, spacing: BrutalistTheme.spacingL) {
                    // Section Header
                    HStack(spacing: BrutalistTheme.spacingS) {
                        Rectangle()
                            .fill(BrutalistTheme.brutalistBlack)
                            .frame(width: 4, height: 20)
                        
                        Text("APP FEEDBACK")
                            .font(.system(size: BrutalistTheme.bodyLarge, weight: BrutalistTheme.fontBlack))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    VStack(spacing: BrutalistTheme.spacingM) {
                        SettingsToggleCard(
                            icon: "speaker.wave.2.fill",
                            iconColor: BrutalistTheme.brutalistYellow,
                            backgroundColor: BrutalistTheme.brutalistWhite,
                            label: "Clack Sounds",
                            isOn: $clackSoundsEnabled
                        )
                        
                        SettingsSegmentedCard(
                            icon: "hand.tap.fill",
                            iconColor: BrutalistTheme.brutalistCyan,
                            backgroundColor: BrutalistTheme.brutalistWhite,
                            label: "Haptic Intensity",
                            selectedValue: $hapticIntensity,
                            options: hapticOptions
                        )
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)
                }
                
                // MARK: - Log Out Button (FIXED: Sandwich Method)
                Button(action: {
                    FeedbackManager.shared.triggerClack()
                    historyStore.clearAllData()
                    username = ""
                    displayName = ""
                    userHandle = "@aero_manifesto"
                    dietaryRules = "Vegetarian, No Nuts"
                    veganMode = false
                    notificationsEnabled = true
                    clackSoundsEnabled = true
                    hapticIntensity = "Medium"
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        authManager.logout()
                    }
                }) {
                    ZStack {
                        // Shadow
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                            .fill(BrutalistTheme.brutalistBlack)
                            .offset(x: 5, y: 5)
                        
                        // Fill
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                            .fill(BrutalistTheme.brutalistRed)
                        
                        // Content
                        HStack(spacing: BrutalistTheme.spacingM) {
                            Image(systemName: "arrow.right.square.fill")
                                .font(.system(size: 20, weight: .bold))
                            
                            Text("LOG OUT")
                                .font(.system(size: BrutalistTheme.bodyLarge, weight: BrutalistTheme.fontBlack))
                        }
                        .foregroundColor(BrutalistTheme.brutalistWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BrutalistTheme.spacingL)
                        .padding(.horizontal, BrutalistTheme.spacingM)
                        
                        // Border
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, BrutalistTheme.spacingL)
                .padding(.top, BrutalistTheme.spacingM)
                
                // Bottom padding for tab bar
                Spacer()
                    .frame(height: 100)
            }
        }
        .background(Color(hex: "#F5F5F5"))
        .alert("Edit Display Name", isPresented: $showNameAlert) {
            TextField("Name", text: $newName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                displayName = newName
                if username == displayName {
                    username = newName
                }
            }
        }
    }
}

// MARK: - Settings Card Component (FIXED: Sandwich Method)
struct SettingsCard: View {
    let icon: String
    let iconColor: Color
    let backgroundColor: Color
    let label: String
    let value: String
    let hasChevron: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            FeedbackManager.shared.triggerClack()
            action()
        }) {
            ZStack {
                // Shadow (moves when pressed)
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                    .fill(BrutalistTheme.brutalistBlack)
                    .offset(
                        x: isPressed ? 0 : 5,
                        y: isPressed ? 0 : 5
                    )
                
                // Fill
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                    .fill(backgroundColor)
                
                // Content
                HStack(spacing: BrutalistTheme.spacingM) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(iconColor)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                            )
                        
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(BrutalistTheme.brutalistWhite)
                    }
                    
                    VStack(alignment: .leading, spacing: BrutalistTheme.spacingXS) {
                        Text(label)
                            .font(.system(size: BrutalistTheme.bodySmall, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text(value)
                            .font(.system(size: BrutalistTheme.bodyLarge, weight: BrutalistTheme.fontBlack))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                    }
                    
                    Spacer()
                    
                    if hasChevron {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                    }
                }
                .padding(BrutalistTheme.spacingM)
                
                // Border
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
            }
            .offset(
                x: isPressed ? 5 : 0,
                y: isPressed ? 5 : 0
            )
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
        }
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

// MARK: - Settings Menu Card Component (FIXED: Sandwich Method)
struct SettingsMenuCard: View {
    let icon: String
    let iconColor: Color
    let backgroundColor: Color
    let label: String
    @Binding var selectedValue: String
    let options: [String]
    
    var body: some View {
        ZStack {
            // Shadow
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .fill(BrutalistTheme.brutalistBlack)
                .offset(x: 5, y: 5)
            
            // Fill
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .fill(backgroundColor)
            
            // Content
            HStack(spacing: BrutalistTheme.spacingM) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(BrutalistTheme.brutalistWhite)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: BrutalistTheme.spacingXS) {
                    Text(label)
                        .font(.system(size: BrutalistTheme.bodySmall, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Menu {
                        ForEach(options, id: \.self) { option in
                            Button(action: {
                                selectedValue = option
                            }) {
                                HStack {
                                    Text(option)
                                    if selectedValue == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedValue)
                                .font(.system(size: BrutalistTheme.bodyLarge, weight: BrutalistTheme.fontBlack))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(BrutalistTheme.spacingM)
            
            // Border
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
        }
    }
}

// MARK: - Settings Toggle Card Component (FIXED: Sandwich Method)
struct SettingsToggleCard: View {
    let icon: String
    let iconColor: Color
    let backgroundColor: Color
    let label: String
    @Binding var isOn: Bool
    
    var body: some View {
        ZStack {
            // Shadow
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .fill(BrutalistTheme.brutalistBlack)
                .offset(x: 5, y: 5)
            
            // Fill
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .fill(backgroundColor)
            
            // Content
            HStack(spacing: BrutalistTheme.spacingM) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(BrutalistTheme.brutalistWhite)
                }
                
                // Label
                Text(label)
                    .font(.system(size: BrutalistTheme.bodyLarge, weight: BrutalistTheme.fontBlack))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
                
                Spacer()
                
                // Toggle Switch
                Toggle("", isOn: $isOn)
                    .toggleStyle(BrutalistToggleStyle())
            }
            .padding(BrutalistTheme.spacingM)
            
            // Border
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
        }
    }
}

// MARK: - Settings Segmented Card Component (FIXED: Sandwich Method)
struct SettingsSegmentedCard: View {
    let icon: String
    let iconColor: Color
    let backgroundColor: Color
    let label: String
    @Binding var selectedValue: String
    let options: [String]
    
    var body: some View {
        ZStack {
            // Shadow
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .fill(BrutalistTheme.brutalistBlack)
                .offset(x: 5, y: 5)
            
            // Fill
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .fill(backgroundColor)
            
            // Content
            HStack(spacing: BrutalistTheme.spacingM) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(BrutalistTheme.brutalistWhite)
                }
                
                // Label and Segmented Picker
                VStack(alignment: .leading, spacing: BrutalistTheme.spacingS) {
                    Text(label)
                        .font(.system(size: BrutalistTheme.bodyLarge, weight: BrutalistTheme.fontBlack))
                        .foregroundColor(BrutalistTheme.brutalistBlack)
                    
                    // Custom Segmented Picker
                    HStack(spacing: BrutalistTheme.spacingXS) {
                        ForEach(options, id: \.self) { option in
                            Button(action: {
                                selectedValue = option
                                FeedbackManager.shared.triggerClack()
                            }) {
                                Text(option)
                                    .font(.system(size: BrutalistTheme.bodySmall, weight: selectedValue == option ? BrutalistTheme.fontBlack : .medium))
                                    .foregroundColor(selectedValue == option ? BrutalistTheme.brutalistWhite : BrutalistTheme.brutalistBlack)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, BrutalistTheme.spacingS)
                                    .background(selectedValue == option ? BrutalistTheme.brutalistBlack : Color.clear)
                                    .cornerRadius(BrutalistTheme.cornerRadiusSmall)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Spacer()
            }
            .padding(BrutalistTheme.spacingM)
            
            // Border
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
        }
    }
}

// MARK: - Brutalist Toggle Style
struct BrutalistToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            FeedbackManager.shared.triggerClack()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                configuration.isOn.toggle()
            }
        }) {
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                // Track
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ? BrutalistTheme.brutalistBlack : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                    )
                
                // Thumb
                Circle()
                    .fill(BrutalistTheme.brutalistWhite)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                    )
                    .padding(3)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct SettingsPreviewContainer: View {
        @StateObject private var previewAuth = AuthManager(isPreviewMode: true)
        @StateObject private var history = HistoryStore()
        @StateObject private var chat = ChatService()
        @StateObject private var shopping = ShoppingStore()
        
        var body: some View {
            Group {
                if previewAuth.isLoggedIn {
                    SettingsView()
                } else {
                    ZStack {
                        Color(hex: "#F5F5F5").ignoresSafeArea()
                        VStack(spacing: 16) {
                            Text("OUT OF SERVICE")
                                .font(.system(size: 24, weight: .black))
                            Text("Log Out Flow Triggered Successfully!")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button(action: {
                                withAnimation { previewAuth.isLoggedIn = true }
                            }) {
                                Text("RESET PREVIEW STATE")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.black)
                            }
                            .padding(.top, 12)
                        }
                    }
                }
            }
            .environmentObject(previewAuth)
            .environmentObject(history)
            .environmentObject(chat)
            .environmentObject(shopping)
        }
    }
    
    return SettingsPreviewContainer()
}
