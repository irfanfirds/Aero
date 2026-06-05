import SwiftUI

// MARK: - UNIFIED BRUTALIST CARD (FIXED: Correct Layer Order)
struct BrutalistCard<Content: View>: View {
    let backgroundColor: Color
    let content: Content

    init(backgroundColor: Color = BrutalistTheme.brutalistWhite, @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(BrutalistTheme.spacingM)
            // 1. Apply the fill and the SHAPE together to ensure clipping
            .background(
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                    .fill(backgroundColor)
            )
            // 2. Add the border OVER the background
            .overlay(
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
            )
            // 3. Add the shadow behind everything
            .background(
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                    .fill(BrutalistTheme.brutalistBlack)
                    .offset(x: BrutalistTheme.shadowOffset.width, y: BrutalistTheme.shadowOffset.height)
            )
    }
}

// MARK: - UNIFIED BUTTON STYLE (3D Mechanical Sandwich Fix)
struct BrutalistButtonStyle: ButtonStyle {
    // Dynamic background property with a safe brutalist fallback color
    var bgColor: Color = BrutalistTheme.brutalistYellow

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(BrutalistTheme.brutalistBlack)
            .frame(maxWidth: .infinity)
            .padding(.vertical, BrutalistTheme.spacingL)
            .padding(.horizontal, BrutalistTheme.spacingM)
            .background(
                ZStack {
                    // Constant Shadow background (Stays locked in place)
                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                        .fill(BrutalistTheme.brutalistBlack)
                        .offset(x: 5, y: 5)
                    
                    // Face fill layer shifts back on press down interactions
                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                        .fill(bgColor)
                        .offset(x: configuration.isPressed ? 3 : 0, y: configuration.isPressed ? 3 : 0)
                    
                    // Outer crisp border overlay moves with the face fill
                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                        .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                        .offset(x: configuration.isPressed ? 3 : 0, y: configuration.isPressed ? 3 : 0)
                }
            )
            // Shift structural content elements down slightly for complete 3D touch translation
            .offset(x: configuration.isPressed ? 2 : 0, y: configuration.isPressed ? 2 : 0)
            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Button Style Extension
extension ButtonStyle where Self == BrutalistButtonStyle {
    /// Standard fallback button style defaults to Brutalist Yellow theme.
    static var brutalistButton: BrutalistButtonStyle { BrutalistButtonStyle() }
    
    /// Custom button style generator to load any brutalist theme color variations.
    static func brutalistKey(color: Color) -> BrutalistButtonStyle {
        BrutalistButtonStyle(bgColor: color)
    }
}
