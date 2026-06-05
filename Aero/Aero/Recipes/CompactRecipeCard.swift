import SwiftUI


// MARK: - Compact Recipe Card (FIXED: Proper Margins & Proportions)
struct CompactRecipeCard: View {
    let title: String
    let badge: RecipeBadge
    let imageName: String
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            FeedbackManager.shared.triggerClack()
            // Will redirect to recipe detail page
        }) {
            ZStack {
                // Shadow (moves when pressed)
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                    .fill(BrutalistTheme.brutalistBlack)
                    .offset(
                        x: isPressed ? 0 : 5,
                        y: isPressed ? 0 : 5
                    )
                
                // Fill
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                    .fill(BrutalistTheme.brutalistWhite)
                
                // Content with proper spacing (FIXED: Margins)
                HStack(spacing: BrutalistTheme.spacingM) {
                    // Image area (FIXED: Sandwich Method with proper margins)
                    ZStack {
                        // Shadow
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                            .fill(BrutalistTheme.brutalistBlack)
                            .offset(x: 2, y: 2)
                        
                        // Fill
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                            .fill(Color(hex: "#FFF8DC"))
                        
                        // Content
                        Text("🥗")
                            .font(.system(size: 48))
                        
                        // Border
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                    }
                    .frame(width: 120, height: 120)
                    .clipped()
                    
                    // Content area with proper padding (FIXED: Margins)
                    HStack {
                        VStack(alignment: .leading, spacing: BrutalistTheme.spacingS) {
                            Text(title)
                                .font(.system(size: BrutalistTheme.bodyLarge, weight: BrutalistTheme.fontBlack))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                                .lineLimit(2)
                            
                            // Badge (FIXED: Sandwich Method)
                            ZStack {
                                // Shadow
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(BrutalistTheme.brutalistBlack)
                                    .offset(x: 1, y: 1)
                                
                                // Fill
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(badge.color)
                                
                                // Content
                                Text(badge.text)
                                    .font(.system(size: 10, weight: BrutalistTheme.fontBlack))
                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                                    .padding(.horizontal, BrutalistTheme.spacingS)
                                    .padding(.vertical, 4)
                                
                                // Border
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                            }
                        }
                        
                        Spacer()
                        
                        // Arrow button (FIXED: Sandwich Method)
                        ZStack {
                            // Shadow
                            Circle()
                                .fill(BrutalistTheme.brutalistBlack)
                                .frame(width: 42, height: 42)
                                .offset(x: 2, y: 2)
                            
                            // Fill
                            Circle()
                                .fill(BrutalistTheme.brutalistBlack)
                                .frame(width: 40, height: 40)
                            
                            // Content
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(BrutalistTheme.brutalistWhite)
                            
                            // Border
                            Circle()
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                .frame(width: 40, height: 40)
                        }
                    }
                    .padding(BrutalistTheme.spacingM)
                }
                .padding(BrutalistTheme.spacingM)
                
                // Border
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
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
