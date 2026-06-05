import SwiftUI

/// Persistent top-of-screen identity and navigation header used across core views.
struct AuthHeaderComponent: View {
    let title: String
    var subtitle: String? = nil
    var showsBackButton: Bool = false
    var backAction: (() -> Void)? = nil
    
    // Allows passing a custom HStack of buttons (like in ItemsView)
    var trailingAction: AnyView? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if showsBackButton {
                    BrutalistBackButton(action: backAction)
                } else {
                    // Placeholder to keep the title centered
                    Color.clear
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Text(title.uppercased())
                    .font(.system(size: BrutalistTheme.titleLarge, weight: BrutalistTheme.fontBlack, design: .monospaced))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                if let actionView = trailingAction {
                    actionView
                        .frame(minWidth: 44, alignment: .trailing)
                } else {
                    // Placeholder to keep the title centered
                    Color.clear
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, BrutalistTheme.spacingL)
            .padding(.top, BrutalistTheme.spacingM)

            if let subtitle, !subtitle.isEmpty {
                VStack(alignment: .leading, spacing: BrutalistTheme.spacingXS) {
                    Divider()
                        .overlay(BrutalistTheme.brutalistBlack)
                        .padding(.vertical, BrutalistTheme.spacingS)

                    Text(subtitle)
                        .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBold, design: .monospaced))
                        .foregroundColor(BrutalistTheme.brutalistBlack.opacity(0.7))
                        .textCase(.uppercase)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, BrutalistTheme.spacingL)
            }
        }
        .padding(.bottom, BrutalistTheme.spacingM)
    }
}

// MARK: - Helper Views
struct BrutalistBackButton: View {
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(BrutalistTheme.brutalistBlack)
                .padding(10)
                .background(Color.white) // Or your theme background
                .border(BrutalistTheme.brutalistBlack, width: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AuthHeaderComponent(title: "Test", subtitle: "User", showsBackButton: false)
        .environmentObject(AuthManager())
}
