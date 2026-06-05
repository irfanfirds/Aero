import SwiftUI

struct ImpactReportView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @Environment(\.dismiss) private var dismiss

    private var currentMonthLabel: String {
        let formatter = DateFormatter()
        // FIX: Properly escape the single quote by enclosing it, or use a clean string literal format
        formatter.dateFormat = "MMM ''yyyy"
        // An even cleaner, error-proof way in modern iOS is:
        // return Date().formatted(.dateTime.month(.abbreviated).year(.twoDigits)).uppercased()
        
        return formatter.string(from: Date()).uppercased()
    }

    private var consumedPercentage: Int {
        Int(historyStore.consumedPercentage * 100)
    }

    private var wastedPercentage: Int {
        Int(historyStore.wastedPercentage * 100)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: BrutalistTheme.spacingL) {
                
                // MARK: - Live Updating Header
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    AuthHeaderComponent(
                        title: "Impact Report",
                        // FIX: Changed date: .none to date: .omitted
                        subtitle: "\(context.date.formatted(date: .long, time: .omitted).uppercased())\nTIME: \(context.date.formatted(date: .omitted, time: .standard))",
                        showsBackButton: true,
                        backAction: { dismiss() }
                    )
                }

                GuiltVsPrideCard(
                    consumedPercentage: consumedPercentage,
                    wastedPercentage: wastedPercentage,
                    message: performanceMessage,
                    monthLabel: currentMonthLabel
                )
                .padding(.horizontal, BrutalistTheme.spacingL)

                VStack(spacing: BrutalistTheme.spacingM) {
                    ForEach(FoodCategory.allCases, id: \.self) { category in
                        ImpactCategoryRow(
                            category: category,
                            activeCount: historyStore.activeCount(for: category),
                            consumedCount: historyStore.movementCount(for: category, status: .consumed),
                            wastedCount: historyStore.movementCount(for: category, status: .wasted)
                        )
                    }
                }
                .padding(.horizontal, BrutalistTheme.spacingL)

                Spacer()
                    .frame(height: 80)
            }
        }
        .background(Color(hex: "#F5F5F5"))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var performanceMessage: String {
        if consumedPercentage >= 80 { return "Excellent!" }
        if consumedPercentage >= 65 { return "Good!" }
        if consumedPercentage >= 50 { return "Okay" }
        return "Improve"
    }
}

private struct ImpactCategoryRow: View {
    let category: FoodCategory
    let activeCount: Int
    let consumedCount: Int
    let wastedCount: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .fill(BrutalistTheme.brutalistBlack)
                .offset(x: BrutalistTheme.shadowOffset.width, y: BrutalistTheme.shadowOffset.height)

            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .fill(BrutalistTheme.brutalistWhite)

            VStack(alignment: .leading, spacing: BrutalistTheme.spacingS) {
                Text(category.rawValue.uppercased())
                    .font(.system(size: BrutalistTheme.bodyLarge, weight: BrutalistTheme.fontBlack))
                    .foregroundColor(BrutalistTheme.brutalistBlack)

                HStack {
                    Text("IN FRIDGE: \(activeCount)")
                    Spacer()
                    Text("CONSUMED: \(consumedCount)")
                    Spacer()
                    Text("WASTED: \(wastedCount)")
                }
                .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBold))
                .foregroundColor(BrutalistTheme.brutalistBlack)
            }
            .padding(BrutalistTheme.spacingM)

            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
        }
    }
}

#Preview {
    NavigationStack {
        ImpactReportView()
            .environmentObject(HistoryStore())
    }
}
