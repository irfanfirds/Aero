//
//  FilterPill.swift
//  Aero
//
//  Created by SWITCH on 16/05/2026.
//

import SwiftUI

// MARK: - Filter Pill Component
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    // Compute colors dynamically based on selection state
    private var fillColor: Color {
        isSelected ? BrutalistTheme.brutalistBlack : BrutalistTheme.brutalistWhite
    }
    
    private var textColor: Color {
        isSelected ? BrutalistTheme.brutalistWhite : BrutalistTheme.brutalistBlack
    }
    
    var body: some View {
        Button(action: {
            FeedbackManager.shared.triggerClack()
            action()
        }) {
            Text(title)
                .font(.system(size: BrutalistTheme.bodyMedium, weight: BrutalistTheme.fontBold))
                .foregroundColor(textColor)
                .padding(.horizontal, BrutalistTheme.spacingM)
                .padding(.vertical, BrutalistTheme.spacingS)
                // Leverage our modular modifier layout structure
                .brutalistBox(
                    cornerRadius: BrutalistTheme.cornerRadiusMedium,
                    fillColor: fillColor,
                    shadowOffset: isPressed ? 0 : 4
                )
                .offset(x: isPressed ? 4 : 0, y: isPressed ? 4 : 0)
                .fixedSize() // Prevents text truncation during scroll layout calculations
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
