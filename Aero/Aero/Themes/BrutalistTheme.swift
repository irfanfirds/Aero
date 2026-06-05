//
//  BrutalistTheme.swift
//  Aero
//
//  Created by SWITCH on 07/01/2026.
//

import SwiftUI

struct BrutalistTheme {
    // MARK: - Colors
    static let brutalistRed = Color(hex: "#FF5252")
    static let brutalistCyan = Color(hex: "#00F0FF")
    static let brutalistYellow = Color(hex: "#FFDE03")
    static let brutalistWhite = Color(hex: "#FFFFFF")
    static let brutalistBlack = Color.black
    static let brutalistLavender = Color(hex: "#D4C5F9")
    static let brutalistLime = Color(hex: "#D4FF00")
    static let brutalistPeach = Color(hex: "#FFDAB9")
    static let brutalistCream = Color(hex: "#FFF8DC")
    static let brutalistLightCyan = Color(hex: "#E0FBFF")
    
    // MARK: - Typography
    static let fontBlack: Font.Weight = .black
    static let fontBold: Font.Weight = .bold
    static let fontSemiBold: Font.Weight = .semibold
    static let fontMedium: Font.Weight = .medium
    
    // Title sizes
    static let titleHuge: CGFloat = 48
    static let titleLarge: CGFloat = 34
    static let titleMedium: CGFloat = 24
    static let titleSmall: CGFloat = 20
    
    // Body sizes
    static let bodyLarge: CGFloat = 17
    static let bodyMedium: CGFloat = 15
    static let bodySmall: CGFloat = 13
    static let caption: CGFloat = 11
    
    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    
    // MARK: - Border & Shadow
    static let borderWidth: CGFloat = 3
    static let shadowOffset: CGSize = CGSize(width: 5, height: 5)
    static let shadowRadius: CGFloat = 0
    
    // MARK: - Corner Radius
    static let cornerRadiusSmall: CGFloat = 12
    static let cornerRadiusMedium: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 24
    static let cornerRadiusCircle: CGFloat = 999
}

// MARK: - Brutalist Card Modifier
struct BrutalistCardModifier: ViewModifier {
    var backgroundColor: Color = BrutalistTheme.brutalistWhite
    var borderColor: Color = BrutalistTheme.brutalistBlack
    var shadowColor: Color = BrutalistTheme.brutalistBlack
    var cornerRadius: CGFloat = BrutalistTheme.cornerRadiusMedium
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            // THE BORDER (Perfectly aligned on top)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: BrutalistTheme.borderWidth)
            )
            // THE SOLID SHADOW (Layered behind)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(shadowColor)
                    .offset(x: BrutalistTheme.shadowOffset.width, y: BrutalistTheme.shadowOffset.height)
            )
    }
}

// MARK: - View Extension
extension View {
    func brutalistCard(
        backgroundColor: Color = BrutalistTheme.brutalistWhite,
        borderColor: Color = BrutalistTheme.brutalistBlack,
        shadowColor: Color = BrutalistTheme.brutalistBlack,
        cornerRadius: CGFloat = BrutalistTheme.cornerRadiusMedium
    ) -> some View {
        self.modifier(BrutalistCardModifier(
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            shadowColor: shadowColor,
            cornerRadius: cornerRadius
        ))
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Brutalist Key Button Style (Mechanical Sink Effect) 
struct BrutalistKeyStyle: ButtonStyle {
    var color: Color = BrutalistTheme.brutalistWhite
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // REMOVED fixed padding - Button label controls its own size
            .background(color)
            .cornerRadius(BrutalistTheme.cornerRadiusSmall)
            .overlay(
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
            )
            // THE SINK LOGIC
            .offset(
                x: configuration.isPressed ? BrutalistTheme.shadowOffset.width : 0,
                y: configuration.isPressed ? BrutalistTheme.shadowOffset.height : 0
            )
            .shadow(
                color: configuration.isPressed ? Color.clear : BrutalistTheme.brutalistBlack,
                radius: BrutalistTheme.shadowRadius,
                x: configuration.isPressed ? 0 : BrutalistTheme.shadowOffset.width,
                y: configuration.isPressed ? 0 : BrutalistTheme.shadowOffset.height
            )
            // Snappy mechanical animation
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: configuration.isPressed)
            // Added Haptic Feedback
            .sensoryFeedback(.impact(weight: .medium), trigger: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BrutalistKeyStyle {
    static var brutalistKey: BrutalistKeyStyle { BrutalistKeyStyle() }
    static func brutalistKey(color: Color) -> BrutalistKeyStyle {
        BrutalistKeyStyle(color: color)
    }
}

// MARK: - Dotted Pattern Background Component
struct DottedPatternBackground: View {
    var dotColor: Color = BrutalistTheme.brutalistBlack.opacity(0.1)
    var spacing: CGFloat = 20
    
    var body: some View {
        Canvas { context, size in
            for x in stride(from: 0, to: size.width, by: spacing) {
                for y in stride(from: 0, to: size.height, by: spacing) {
                    let rect = CGRect(x: x, y: y, width: 2, height: 2)
                    context.fill(Path(ellipseIn: rect), with: .color(dotColor))
                }
            }
        }
        .ignoresSafeArea()
    }
}
