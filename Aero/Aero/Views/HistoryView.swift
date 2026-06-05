//
//  HistoryView.swift
//  Aero
//
//  Created by SWITCH on 07/01/2026.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @State private var showClearAllConfirm = false
    @State private var showClearPastConfirm = false
    
    private var currentMonthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM ''yy"
        return formatter.string(from: Date()).uppercased()
    }
    
    var consumedPercentage: Int {
        Int(historyStore.consumedPercentage * 100)
    }
    
    var wastedPercentage: Int {
        Int(historyStore.wastedPercentage * 100)
    }
    
    var performanceMessage: String {
        if consumedPercentage >= 80 {
            return "Excellent!"
        } else if consumedPercentage >= 65 {
            return "Good!"
        } else if consumedPercentage >= 50 {
            return "Okay"
        } else {
            return "Improve"
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: BrutalistTheme.spacingXL) {
                // MARK: - Header
                AuthHeaderComponent(title: "History", subtitle: "Performance analysis")
                
                // MARK: - Clear History Card
                ZStack {
                    
                    // Shadow
                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                        .fill(BrutalistTheme.brutalistBlack)
                        .offset(x: 5, y: 5)
                    // Fill
                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                        .fill(BrutalistTheme.brutalistWhite)

                    VStack(alignment: .leading, spacing: BrutalistTheme.spacingM) {
                        HStack {
                            Text("HISTORY CONTROL")
                                .font(.system(size: BrutalistTheme.titleSmall, weight: BrutalistTheme.fontBlack))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                            Spacer()
                        }

                        HStack(spacing: BrutalistTheme.spacingM) {
                            // Clear Past
                            Button(action: { showClearPastConfirm = true }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .fill(BrutalistTheme.brutalistBlack)
                                        .offset(x: 3, y: 3)
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .fill(BrutalistTheme.brutalistCyan)
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                                    HStack(spacing: 8) {
                                        Image(systemName: "clock.arrow.circlepath")
                                        Text("CLEAR PAST")
                                    }
                                    .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack))
                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                                    .padding(.horizontal, BrutalistTheme.spacingM)
                                    .padding(.vertical, BrutalistTheme.spacingS)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Clear All
                            Button(role: .destructive, action: { showClearAllConfirm = true }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .fill(BrutalistTheme.brutalistBlack)
                                        .offset(x: 3, y: 3)
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .fill(BrutalistTheme.brutalistRed)
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                                    HStack(spacing: 8) {
                                        Image(systemName: "trash")
                                        Text("CLEAR ALL")
                                    }
                                    .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack))
                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                                    .padding(.horizontal, BrutalistTheme.spacingM)
                                    .padding(.vertical, BrutalistTheme.spacingS)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(BrutalistTheme.spacingL)
                    
                    // Border
                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                        .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                }
                .padding(.horizontal, BrutalistTheme.spacingL)
                
                // MARK: - Guilt vs Pride Card
                GuiltVsPrideCard(
                    consumedPercentage: consumedPercentage,
                    wastedPercentage: wastedPercentage,
                    message: performanceMessage,
                    monthLabel: currentMonthLabel
                )
                .padding(.horizontal, BrutalistTheme.spacingL)
                
                // MARK: - Waste Sources Card
                WasteSourcesCard()
                    .padding(.horizontal, BrutalistTheme.spacingL)
                
                // Bottom padding for tab bar
                Spacer()
                    .frame(height: 100)
            }
        }
        .background(Color(hex: "#F5F5F5"))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) { showClearAllConfirm = true } label: {
                        Label("Clear All History", systemImage: "trash")
                    }
                    Button { showClearPastConfirm = true } label: {
                        Label("Clear Past (Expired)", systemImage: "clock.arrow.circlepath")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog("Are you sure?", isPresented: $showClearAllConfirm, titleVisibility: .visible) {
            Button("Clear All History", role: .destructive) {
                historyStore.clearHistory()
            }
            Button("Cancel", role: .cancel) { }
        }
        .confirmationDialog("Clear past (expired) items?", isPresented: $showClearPastConfirm, titleVisibility: .visible) {
            Button("Clear Past", role: .destructive) {
                historyStore.clearPastHistory()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

// MARK: - Guilt vs Pride Card Component (FIXED: Badges Use Sandwich Method)
struct GuiltVsPrideCard: View {
    let consumedPercentage: Int
    let wastedPercentage: Int
    let message: String
    let monthLabel: String
    
    var body: some View {
        ZStack {
            // Shadow
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                .fill(BrutalistTheme.brutalistBlack)
                .offset(x: 5, y: 5)
            
            // Fill
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                .fill(BrutalistTheme.brutalistLavender)
            
            // Content
            VStack(alignment: .leading, spacing: BrutalistTheme.spacingL) {
                HStack {
                    VStack(alignment: .leading, spacing: BrutalistTheme.spacingS) {
                        Text("GUILT\nVS. PRIDE")
                            .font(.system(size: 28, weight: BrutalistTheme.fontBlack))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                            .lineSpacing(-5)
                        
                        // WEEKLY BREAKDOWN Badge (FIXED: Sandwich Method)
                        ZStack {
                            // Shadow
                            RoundedRectangle(cornerRadius: 6)
                                .fill(BrutalistTheme.brutalistBlack)
                                .offset(x: 1, y: 1)
                            
                            // Fill
                            RoundedRectangle(cornerRadius: 6)
                                .fill(BrutalistTheme.brutalistBlack)
                            
                            // Content
                            Text("WEEKLY BREAKDOWN")
                                .font(.system(size: 10, weight: BrutalistTheme.fontBlack))
                                .foregroundColor(BrutalistTheme.brutalistWhite)
                                .padding(.horizontal, BrutalistTheme.spacingS)
                                .padding(.vertical, 4)
                            
                            // Border
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                        }
                    }
                    
                    Spacer()
                    
                    // Current month badge
                    ZStack {
                        // Shadow
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                            .fill(BrutalistTheme.brutalistBlack)
                            .offset(x: 1, y: 1)
                        
                        // Fill
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                            .fill(BrutalistTheme.brutalistWhite)
                        
                        // Content
                        Text(monthLabel)
                            .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                            .padding(.horizontal, BrutalistTheme.spacingM)
                            .padding(.vertical, BrutalistTheme.spacingS)
                        
                        // Border
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                    }
                    
                    Circle()
                        .stroke(BrutalistTheme.brutalistBlack.opacity(0.2), lineWidth: 3)
                        .frame(width: 60, height: 60)
                        .offset(x: 20, y: -20)
                }
                
                DonutChart(
                    consumedPercentage: Double(consumedPercentage) / 100.0,
                    wastedPercentage: Double(wastedPercentage) / 100.0,
                    message: message
                )
                .frame(height: 240)
                .padding(.vertical, BrutalistTheme.spacingM)
                
                HStack(spacing: BrutalistTheme.spacingM) {
                    StatBox(color: BrutalistTheme.brutalistLime, label: "CONSUMED", percentage: consumedPercentage)
                    StatBox(color: BrutalistTheme.brutalistRed, label: "WASTED", percentage: wastedPercentage)
                }
            }
            .padding(BrutalistTheme.spacingL)
            
            // Border
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
        }
    }
}

// MARK: - Donut Chart Component
struct DonutChart: View {
    let consumedPercentage: Double
    let wastedPercentage: Double
    let message: String
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: wastedPercentage)
                .stroke(
                    BrutalistTheme.brutalistRed,
                    style: StrokeStyle(lineWidth: 40, lineCap: .butt)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
            
            Circle()
                .trim(from: wastedPercentage, to: 1.0)
                .stroke(
                    BrutalistTheme.brutalistLime,
                    style: StrokeStyle(lineWidth: 40, lineCap: .butt)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
            
            Circle()
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: 3)
                .frame(width: 180, height: 180)
            
            Circle()
                .fill(BrutalistTheme.brutalistLavender)
                .frame(width: 100, height: 100)
            
            Circle()
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: 3)
                .frame(width: 100, height: 100)
            
            Text(message)
                .font(.system(size: 24, weight: BrutalistTheme.fontBlack))
                .foregroundColor(BrutalistTheme.brutalistBlack)
        }
    }
}

// MARK: - Stat Box Component (FIXED: Color Rectangle Uses Sandwich Method)
struct StatBox: View {
    let color: Color
    let label: String
    let percentage: Int
    
    var body: some View {
        ZStack {
            // Shadow
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .fill(BrutalistTheme.brutalistBlack)
                .offset(x: 4, y: 4)
            
            // Fill
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .fill(BrutalistTheme.brutalistWhite)
            
            // Content
            VStack(alignment: .leading, spacing: BrutalistTheme.spacingS) {
                HStack(spacing: BrutalistTheme.spacingXS) {
                    // Color Rectangle (FIXED: Sandwich Method)
                    ZStack {
                        // Shadow
                        Rectangle()
                            .fill(BrutalistTheme.brutalistBlack)
                            .frame(width: 18, height: 18)
                            .offset(x: 1, y: 1)
                        
                        // Fill
                        Rectangle()
                            .fill(color)
                            .frame(width: 16, height: 16)
                        
                        // Border
                        Rectangle()
                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                            .frame(width: 16, height: 16)
                    }
                    
                    Text(label)
                        .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBold))
                        .foregroundColor(BrutalistTheme.brutalistBlack)
                }
                
                Text("\(percentage)%")
                    .font(.system(size: 32, weight: BrutalistTheme.fontBlack))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BrutalistTheme.spacingM)
            
            // Border
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
        }
    }
}

// MARK: - Waste Sources Card Component (FIXED: Info Button No Double Shadows)
struct WasteSourcesCard: View {
    @EnvironmentObject var historyStore: HistoryStore
    
    var body: some View {
        ZStack {
            // Shadow
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                .fill(BrutalistTheme.brutalistBlack)
                .offset(x: 5, y: 5)
            
            // Fill
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                .fill(BrutalistTheme.brutalistWhite)
            
            // Content
            VStack(alignment: .leading, spacing: BrutalistTheme.spacingL) {
                HStack {
                    Text("WASTE SOURCES")
                        .font(.system(size: BrutalistTheme.titleSmall, weight: BrutalistTheme.fontBlack))
                        .foregroundColor(BrutalistTheme.brutalistBlack)
                    
                    Spacer()
                    
                    // Info Button (FIXED: No Double Shadows)
                    Button(action: {
                        FeedbackManager.shared.triggerClack()
                    }) {
                        ZStack {
                            // Shadow
                            Circle()
                                .fill(BrutalistTheme.brutalistBlack)
                                .frame(width: 40, height: 40)
                                .offset(x: 3, y: 3)
                            
                            // Fill
                            Circle()
                                .fill(BrutalistTheme.brutalistCyan)
                                .frame(width: 40, height: 40)
                            
                            // Content
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                            
                            // Border (Sandwich Method)
                            ZStack {
                                // Shadow for border ring
                                Circle()
                                    .fill(BrutalistTheme.brutalistBlack)
                                    .frame(width: 40, height: 40)
                                    .offset(x: 1, y: 1)
                                    .opacity(0.0001) // keep layout without visible duplicate shadow

                                // Transparent fill to preserve layout
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 40, height: 40)

                                // Visible border stroke
                                Circle()
                                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                    .frame(width: 40, height: 40)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .sensoryFeedback(.impact(weight: .medium), trigger: historyStore.foodItems.count)
                }
                
                VStack(alignment: .leading, spacing: BrutalistTheme.spacingM) {
                    WasteSourceRow(category: "Vegetables", percentage: historyStore.percentageForCategory(.vegetables), color: .green)
                    WasteSourceRow(category: "Fruits", percentage: historyStore.percentageForCategory(.fruits), color: .orange)
                    WasteSourceRow(category: "Dairy", percentage: historyStore.percentageForCategory(.dairy), color: .blue)
                    WasteSourceRow(category: "Meat", percentage: historyStore.percentageForCategory(.meat), color: BrutalistTheme.brutalistRed)
                    WasteSourceRow(category: "Pantry", percentage: historyStore.percentageForCategory(.pantry), color: .orange)
                }
            }
            .padding(BrutalistTheme.spacingL)
            
            // Border
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
        }
    }
}

// MARK: - Waste Source Row Component (FIXED: Progress Bars Use Sandwich Method)
struct WasteSourceRow: View {
    let category: String
    let percentage: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrutalistTheme.spacingXS) {
            HStack {
                Text(category)
                    .font(.system(size: BrutalistTheme.bodyMedium, weight: BrutalistTheme.fontBold))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
                
                Spacer()
                
                Text("\(percentage)%")
                    .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
            }
            
            // Progress Bar (FIXED: Sandwich Method)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background Bar (FIXED: Sandwich Method)
                    ZStack {
                        // Shadow
                        Rectangle()
                            .fill(BrutalistTheme.brutalistBlack)
                            .frame(height: 26)
                            .offset(x: 1, y: 1)
                        
                        // Fill
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 24)
                        
                        // Border
                        Rectangle()
                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                            .frame(height: 24)
                    }
                    
                    // Progress Fill (FIXED: Sandwich Method)
                    ZStack {
                        // Shadow
                        Rectangle()
                            .fill(BrutalistTheme.brutalistBlack)
                            .frame(
                                width: geometry.size.width * CGFloat(percentage) / 100,
                                height: 26
                            )
                            .offset(x: 1, y: 1)
                        
                        // Fill
                        Rectangle()
                            .fill(color)
                            .frame(
                                width: geometry.size.width * CGFloat(percentage) / 100,
                                height: 24
                            )
                        
                        // Border
                        Rectangle()
                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                            .frame(
                                width: geometry.size.width * CGFloat(percentage) / 100,
                                height: 24
                            )
                    }
                }
            }
            .frame(height: 24)
        }
    }
}

#Preview {
    let mockAuth = AuthManager(isPreviewMode: true)
    return RootView()
        .environmentObject(mockAuth)
        .environmentObject(HistoryStore())
        .environmentObject(ChatService())
}

