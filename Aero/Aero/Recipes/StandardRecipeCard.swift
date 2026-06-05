//
//  StandardRecipeCard.swift
//  Aero
//
//  Created by SWITCH on 16/05/2026.
//

import SwiftUI

// MARK: - Standard Recipe Card
struct StandardRecipeCard: View {
    let title: String
    let description: String
    let highlightedIngredient: String
    let imageName: String
    let badges: [RecipeBadge]
    let time: String
    let ingredientCount: Int
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            FeedbackManager.shared.triggerClack()
            // Will redirect to recipe detail page
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Media Area Block
                ZStack(alignment: .topLeading) {
                    // Central Asset Container
                    Text("🥑🍞")
                        .font(.system(size: 64))
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .brutalistBox(cornerRadius: BrutalistTheme.cornerRadiusMedium, fillColor: Color(hex: "#E8F5E9"), shadowOffset: 2)
                        .padding(BrutalistTheme.spacingM)
                    
                    // Top Right Time Overlays
                    alignmentOverlay(alignment: .topTrailing) {
                        Text(time)
                            .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack))
                            .foregroundColor(BrutalistTheme.brutalistWhite)
                            .padding(.horizontal, BrutalistTheme.spacingM)
                            .padding(.vertical, BrutalistTheme.spacingXS)
                            .brutalistBox(cornerRadius: 8, fillColor: BrutalistTheme.brutalistBlack, shadowOffset: 1)
                    }
                    
                    // Bottom Left Badge Layout Row
                    alignmentOverlay(alignment: .bottomLeading) {
                        HStack(spacing: BrutalistTheme.spacingS) {
                            ForEach(badges.indices, id: \.self) { index in
                                Text(badges[index].text)
                                    .font(.system(size: 11, weight: BrutalistTheme.fontBlack))
                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                                    .padding(.horizontal, BrutalistTheme.spacingS)
                                    .padding(.vertical, 4)
                                    .brutalistBox(cornerRadius: 6, fillColor: badges[index].color, shadowOffset: 1)
                            }
                        }
                    }
                }
                
                // MARK: - Details Core Block
                VStack(alignment: .leading, spacing: BrutalistTheme.spacingM) {
                    Text(title)
                        .font(.system(size: BrutalistTheme.titleSmall, weight: BrutalistTheme.fontBlack))
                        .foregroundColor(BrutalistTheme.brutalistBlack)
                    
                    HStack(spacing: 4) {
                        Text("Perfect for using up that")
                            .font(.system(size: BrutalistTheme.bodySmall))
                        Text(highlightedIngredient)
                            .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack))
                            .padding(.horizontal, 4)
                            .background(BrutalistTheme.brutalistYellow)
                    }
                    
                    // Industrial Divider Line Accent
                    Rectangle()
                        .fill(BrutalistTheme.brutalistBlack)
                        .frame(height: 2)
                    
                    // Footer Row
                    HStack {
                        HStack(spacing: 4) {
                            // Pink Ingredient Indicator Circle
                            Circle()
                                .fill(Color.pink)
                                .brutalistCircleShell(shadowOffset: 1)
                            
                            // Cyan Ingredient Indicator Circle
                            Circle()
                                .fill(BrutalistTheme.brutalistCyan)
                                .brutalistCircleShell(shadowOffset: 1)
                            
                            Text("+\(ingredientCount)")
                                .font(.system(size: BrutalistTheme.bodySmall, weight: .bold))
                        }
                        
                        Spacer()
                        
                        Text("VIEW RECIPE")
                            .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack))
                    }
                }
                .padding(BrutalistTheme.spacingL)
            }
            .brutalistBox(
                cornerRadius: BrutalistTheme.cornerRadiusLarge,
                fillColor: BrutalistTheme.brutalistWhite,
                shadowOffset: isPressed ? 0 : 5
            )
            .offset(x: isPressed ? 5 : 0, y: isPressed ? 5 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Modifiers & Helper Extensions
private extension StandardRecipeCard {
    /// Helps eliminate messy nesting stack structures when aligning card corner labels
    func alignmentOverlay<Content: View>(alignment: Alignment, @ViewBuilder content: () -> Content) -> some View {
        Color.clear
            .frame(height: 180)
            .padding(BrutalistTheme.spacingM)
            .overlay(content().padding(BrutalistTheme.spacingM), alignment: alignment)
    }
}

struct BrutalistCircleModifier: ViewModifier {
    let shadowOffset: CGFloat
    
    func body(content: Content) -> some View {
        ZStack {
            Circle()
                .fill(BrutalistTheme.brutalistBlack)
                .offset(x: shadowOffset, y: shadowOffset)
            content
            Circle()
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
        }
        .frame(width: 20, height: 20)
    }
}

extension View {
    func brutalistCircleShell(shadowOffset: CGFloat) -> some View {
        self.modifier(BrutalistCircleModifier(shadowOffset: shadowOffset))
    }
}
