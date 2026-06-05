import SwiftUI

/// A standardized high-impact button for the Aero ecosystem.
/// Implements the 'Sandwich Method' (Shadow -> Fill -> Border) for visual consistency.
struct BrutalistMainButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            // Trigger haptic feedback manually if not in the style
            FeedbackManager.shared.triggerClack()
            action()
        }) {
            HStack(spacing: BrutalistTheme.spacingS) {
                Text(title.uppercased())
                    .font(.system(size: 16, weight: BrutalistTheme.fontBlack, design: .monospaced))
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
            }
            .foregroundColor(BrutalistTheme.brutalistBlack)
            .padding(.horizontal, BrutalistTheme.spacingM)
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            // MARK: - THE SANDWICH METHOD IMPLEMENTATION
            .background(
                ZStack {
                    // 1. Bottom Layer: The Shadow
                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                        .fill(BrutalistTheme.brutalistBlack)
                        .offset(x: 4, y: 4)
                    
                    // 2. Middle Layer: The Fill (The "Meat")
                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                        .fill(color)
                    
                    // 3. Top Layer: The Border (The "Cover")
                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                        .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                }
            )
        }
        // Use a simple interaction style so it "sinks" when tapped
        .buttonStyle(BrutalistSinkingStyle())
    }
}

// Custom style to handle the mechanical press movement
struct BrutalistSinkingStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Moves the button 2 pixels down/right to simulate a mechanical press
            .offset(x: configuration.isPressed ? 2 : 0, y: configuration.isPressed ? 2 : 0)
            .animation(.spring(response: 0.1, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 30) {
        BrutalistMainButton(title: "Scan Item", icon: "barcode.viewfinder", color: BrutalistTheme.brutalistYellow) {
            print("Scan tapped")
        }
        
        BrutalistMainButton(title: "View Fridge", icon: "refrigerator", color: BrutalistTheme.brutalistWhite) {
            print("Fridge tapped")
        }
    }
    .padding(40)
    .background(Color(hex: "#F5F5F5"))
}
