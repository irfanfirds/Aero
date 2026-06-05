//
//  MissingItemsRecipeCard.swift
//  Aero
//
//  Created by SWITCH on 16/05/2026.
//

import SwiftUI

// MARK: - Missing Items Recipe Card
struct MissingItemsRecipeCard: View {
    let title: String
    let missingItems: [String]
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // MARK: - Media / Pattern Block
            ZStack(alignment: .topLeading) {
                // Background Concentric Circle Pattern Container
                patternBackground
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .brutalistBox(cornerRadius: BrutalistTheme.cornerRadiusMedium, fillColor: Color(hex: "#9E9E9E"), shadowOffset: 2)
                    .padding(BrutalistTheme.spacingM)
                
                // Absolute Badge Overlay
                Color.clear
                    .frame(height: 180)
                    .padding(BrutalistTheme.spacingM)
                    .overlay(
                        Text("MISSING ITEMS")
                            .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack))
                            .foregroundColor(BrutalistTheme.brutalistWhite)
                            .padding(.horizontal, BrutalistTheme.spacingM)
                            .padding(.vertical, BrutalistTheme.spacingS)
                            .brutalistBox(cornerRadius: BrutalistTheme.cornerRadiusSmall, fillColor: BrutalistTheme.brutalistRed, shadowOffset: 1),
                        alignment: .topLeading
                    )
                    .padding(BrutalistTheme.spacingM)
            }
            
            // MARK: - Content Info Block
            VStack(alignment: .leading, spacing: BrutalistTheme.spacingM) {
                Text(title)
                    .font(.system(size: BrutalistTheme.titleSmall, weight: BrutalistTheme.fontBlack))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
                
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(BrutalistTheme.brutalistRed)
                    Text("Missing: \(missingItems.joined(separator: ", "))")
                        .font(.system(size: BrutalistTheme.bodySmall, weight: .medium))
                        .foregroundColor(BrutalistTheme.brutalistRed)
                }
                
                // Action Button Integration
                ShoppingActionButton(action: {
                    // Redirect logic to shopping list goes here
                })
            }
            .padding(BrutalistTheme.spacingL)
        }
        // Base card shell layout container wrapper
        .brutalistBox(cornerRadius: BrutalistTheme.cornerRadiusLarge, fillColor: BrutalistTheme.brutalistWhite, shadowOffset: 5)
    }
    
    // Abstract Brutalist Concentric Circle Canvas
    private var patternBackground: some View {
        ZStack {
            ForEach(0..<5) { index in
                Circle()
                    .stroke(Color.black.opacity(0.1), lineWidth: 20)
                    .frame(width: CGFloat(80 + index * 40))
            }
        }
        .clipped() // Restricts circles from leaking past container constraints
    }
}

// MARK: - Sub-Components (Self-Contained Actions)
private struct ShoppingActionButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            FeedbackManager.shared.triggerClack()
            action()
        }) {
            HStack {
                Text("ADD TO SHOPPING LIST")
                    .font(.system(size: BrutalistTheme.bodyMedium, weight: BrutalistTheme.fontBlack))
                    .foregroundColor(BrutalistTheme.brutalistWhite)
                Image(systemName: "cart.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(BrutalistTheme.brutalistWhite)
            }
            .frame(maxWidth: .infinity)
            .padding(BrutalistTheme.spacingM)
            .brutalistBox(
                cornerRadius: BrutalistTheme.cornerRadiusMedium,
                fillColor: BrutalistTheme.brutalistBlack,
                shadowOffset: isPressed ? 0 : 4
            )
            .offset(x: isPressed ? 4 : 0, y: isPressed ? 4 : 0)
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
