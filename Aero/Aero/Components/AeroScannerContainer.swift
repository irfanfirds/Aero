
import SwiftUI

struct AeroScannerContainer: View {
    @EnvironmentObject var historyStore: HistoryStore
    @State private var showSuccess = false
    @State private var lastScanned = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // The actual camera feed
            AeroScannerView(showSuccess: $showSuccess, lastScanned: $lastScanned)
                .ignoresSafeArea()

            // BRUTALIST OVERLAY: Success HUD (FIXED: Sandwich Method)
            if showSuccess {
                VStack(spacing: 0) {
                    ZStack {
                        // Shadow
                        Rectangle()
                            .fill(BrutalistTheme.brutalistBlack)
                            .offset(x: 5, y: 5)
                        
                        // Fill
                        Rectangle()
                            .fill(BrutalistTheme.brutalistLime)
                        
                        // Content
                        HStack(spacing: BrutalistTheme.spacingM) {
                            Text("√ DATA_LOCKED")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                            
                            Spacer()
                            
                            Text(lastScanned.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(BrutalistTheme.brutalistBlack.opacity(0.7))
                        }
                        .padding(BrutalistTheme.spacingM)
                        
                        // Border
                        Rectangle()
                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
                .padding(.top, BrutalistTheme.spacingL)
            }
            
            // Scanner Crosshair Overlay
            ScannerOverlay()
        }
    }
}

// MARK: - Scanner Overlay Component (FIXED: Sandwich Method)
struct ScannerOverlay: View {
    var body: some View {
        ZStack {
            // Scanning Reticle (FIXED: Sandwich Method)
            ZStack {
                // Shadow
                RoundedRectangle(cornerRadius: 2)
                    .fill(BrutalistTheme.brutalistBlack.opacity(0.3))
                    .frame(width: 252, height: 152)
                    .offset(x: 1, y: 1)
                
                // Fill (dashed stroke)
                RoundedRectangle(cornerRadius: 2)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                    .frame(width: 250, height: 150)
                    .foregroundColor(.white.opacity(0.8))
                
                // Border
                RoundedRectangle(cornerRadius: 2)
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: 1)
                    .frame(width: 250, height: 150)
            }
            
            // Industrial HUD markers (FIXED: Sandwich Method)
            VStack {
                HStack {
                    ZStack {
                        // Shadow
                        Rectangle()
                            .fill(BrutalistTheme.brutalistBlack)
                            .offset(x: 2, y: 2)
                        
                        // Fill
                        Rectangle()
                            .fill(BrutalistTheme.brutalistBlack)
                        
                        // Content
                        Text("SCAN_TARGET_ACTIVE")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundColor(BrutalistTheme.brutalistWhite)
                            .padding(.horizontal, BrutalistTheme.spacingS)
                            .padding(.vertical, 4)
                        
                        // Border
                        Rectangle()
                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: 1)
                    }
                    
                    Spacer()
                }
                .padding(.top, 100)
                .padding(.leading, BrutalistTheme.spacingL)
                
                Spacer()
            }
        }
    }
}

#Preview {
    AeroScannerContainer()
        .environmentObject(HistoryStore())
}
