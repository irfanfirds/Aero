import SwiftUI

enum TabItem: String, CaseIterable, Identifiable {
    case home = "Home"
    case items = "Items"
    case recipes = "Recipes"
    case history = "History"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .items: return "qrcode.viewfinder"
        case .recipes: return "xmark"
        case .history: return "chart.bar.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    
    var body: some View {
        HStack(spacing: BrutalistTheme.spacingL) {
            ForEach(TabItem.allCases) { tab in
                TabBarButton(
                    icon: tab.icon,
                    isSelected: selectedTab == tab,
                    action: {
                        selectedTab = tab
                    }
                )
            }
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressing = false
    
    var body: some View {
        ZStack {
            // THE SHADOW LAYER (Moves with the button to create "Clack")
            Circle()
                .fill(BrutalistTheme.brutalistBlack)
                .frame(width: 56, height: 56)
                .offset(
                    x: (isSelected || isPressing) ? 0 : BrutalistTheme.shadowOffset.width,
                    y: (isSelected || isPressing) ? 0 : BrutalistTheme.shadowOffset.height
                )
            
            // THE BUTTON LAYER
            Circle()
                .fill(isSelected ? BrutalistTheme.brutalistYellow : BrutalistTheme.brutalistWhite)
                .frame(width: 56, height: 56)
                .overlay(
                    Circle()
                        .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                )
                // Moves DOWN when pressed/selected to meet the shadow
                .offset(
                    x: (isSelected || isPressing) ? BrutalistTheme.shadowOffset.width : 0,
                    y: (isSelected || isPressing) ? BrutalistTheme.shadowOffset.height : 0
                )
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(BrutalistTheme.brutalistBlack)
                        .offset(
                            x: (isSelected || isPressing) ? BrutalistTheme.shadowOffset.width : 0,
                            y: (isSelected || isPressing) ? BrutalistTheme.shadowOffset.height : 0
                        )
                )
        }
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressing {
                        isPressing = true
                        // INSTANT VIBRATION AND SOUND
                        FeedbackManager.shared.triggerClack()
                    }
                }
                .onEnded { _ in
                    isPressing = false
                    action()
                }
        )
    }
}

#Preview {
    VStack {
        Spacer()
        CustomTabBar(selectedTab: .constant(.home))
            .padding()
    }
}
