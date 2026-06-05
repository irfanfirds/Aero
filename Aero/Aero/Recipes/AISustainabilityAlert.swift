import SwiftUI

// MARK: - AI Sustainability Alert Component
struct AISustainabilityAlert: View {
    let result: SustainabilityResponse?
    let isLoading: Bool
    let onOpenChat: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrutalistTheme.spacingM) {
            // MARK: - Header Badges
            HStack(spacing: BrutalistTheme.spacingS) {
                // Gemini Badge
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                    Text("GEMINI AI")
                        .font(.system(size: 11, weight: BrutalistTheme.fontBlack))
                }
                .foregroundColor(BrutalistTheme.brutalistWhite)
                .padding(.horizontal, BrutalistTheme.spacingS)
                .padding(.vertical, 4)
                .brutalistBox(cornerRadius: 6, fillColor: BrutalistTheme.brutalistBlack, shadowOffset: 1)
                
                // Sustainability Review Badge
                Text("SUSTAINABILITY REVIEW")
                    .font(.system(size: 11, weight: BrutalistTheme.fontBlack))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
                    .padding(.horizontal, BrutalistTheme.spacingS)
                    .padding(.vertical, 4)
                    .brutalistBox(cornerRadius: 6, fillColor: BrutalistTheme.brutalistYellow, shadowOffset: 1)
                
                Spacer()
                
                // Decorative Accents
                HStack(spacing: 2) {
                    ForEach(0..<3) { _ in
                        Image(systemName: "sparkle")
                            .font(.system(size: 14))
                            .foregroundColor(BrutalistTheme.brutalistBlack.opacity(0.3))
                    }
                }
            }
            
            // MARK: - Info Text Section
            VStack(alignment: .leading, spacing: BrutalistTheme.spacingXS) {
                Text(isLoading ? "ANALYZING INVENTORY..." : (result?.alertTitle ?? "Inventory Stable"))
                    .font(.system(size: BrutalistTheme.titleSmall, weight: BrutalistTheme.fontBlack))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
                    .opacity(isLoading ? 0.5 : 1.0)
                
                Text("Saving these items prevents \(result?.co2Saved ?? "0.0kg") CO2e. Match found:")
                    .font(.system(size: BrutalistTheme.bodySmall))
                    .foregroundColor(BrutalistTheme.brutalistBlack.opacity(0.8))
            }
            
            // MARK: - Action Button
            AlertActionButton(
                title: isLoading ? "SCANNING RECIPES..." : (result?.recommendedRecipe ?? "No matches"),
                isLoading: isLoading,
                action: onOpenChat
            )
        }
        .padding(BrutalistTheme.spacingL)
        // Wraps the main outer shell in your Sandwich UI structure automatically
        .brutalistBox(cornerRadius: BrutalistTheme.cornerRadiusLarge, fillColor: BrutalistTheme.brutalistYellow, shadowOffset: 5)
    }
}

// MARK: - Sub-Components (Clean Refactoring Blocks)
private struct AlertActionButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            FeedbackManager.shared.triggerClack()
            action()
        }) {
            HStack {
                Text(title)
                    .font(.system(size: BrutalistTheme.bodyLarge, weight: BrutalistTheme.fontBlack))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
            }
            .padding(BrutalistTheme.spacingM)
            .brutalistBox(
                cornerRadius: BrutalistTheme.cornerRadiusMedium,
                fillColor: BrutalistTheme.brutalistWhite,
                shadowOffset: isPressed ? 0 : 4
            )
            .offset(x: isPressed ? 4 : 0, y: isPressed ? 4 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isLoading { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Reusable Brutalist Sandwich Modifier
struct BrutalistBoxModifier: ViewModifier {
    let cornerRadius: CGFloat
    let fillColor: Color
    let shadowOffset: CGFloat
    
    func body(content: Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(BrutalistTheme.brutalistBlack)
                .offset(x: shadowOffset, y: shadowOffset)
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(fillColor)
            
            content
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
        }
    }
}

extension View {
    func brutalistBox(cornerRadius: CGFloat, fillColor: Color, shadowOffset: CGFloat) -> some View {
        self.modifier(BrutalistBoxModifier(cornerRadius: cornerRadius, fillColor: fillColor, shadowOffset: shadowOffset))
    }
}
