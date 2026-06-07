import SwiftUI
import PhotosUI

struct ManualEntryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var historyStore: HistoryStore

    @State private var name: String = ""
    @State private var shelfLife: Double = 7
    @State private var selectedCategory: FoodCategory = .pantry

    // Image Selection States
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil

    @State private var animatePills = false

    // Nutrition States
    @State private var nutriCalories: String = ""
    @State private var nutriFat: String = ""
    @State private var nutriCarbs: String = ""
    @State private var nutriProtein: String = ""
    @State private var isLookingUpNutrition: Bool = false
    @State private var nutritionStatus: NutritionLookupStatus = .idle

    enum NutritionLookupStatus {
        case idle, found, notFound
    }

    var body: some View {
        VStack(spacing: 0) {
            // HEADER (Sandwich Method)
            ZStack {
                Rectangle().fill(BrutalistTheme.brutalistBlack).offset(x: 0, y: 2)
                Rectangle().fill(BrutalistTheme.brutalistBlack)
                HStack {
                    Text("NEW_INVENTORY_ENTRY")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                    Spacer()
                    Button("CLOSE") { dismiss() }
                        .font(.system(size: 12, weight: .black))
                }
                .padding()
                .foregroundColor(.white)
            }
            .frame(height: 60)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {

                    // PHOTO PICKER
                    VStack(alignment: .leading) {
                        Text("DATA_VISUAL:")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(BrutalistTheme.brutalistBlack)

                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack {
                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                    .fill(BrutalistTheme.brutalistBlack)
                                    .offset(x: 4, y: 4)

                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                    .fill(BrutalistTheme.brutalistWhite)

                                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall))
                                } else {
                                    VStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 30))
                                        Text("IMPORT_IMAGE")
                                            .font(.system(size: 12, weight: .black, design: .monospaced))
                                    }
                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                                }

                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                            }
                            .frame(height: 150)
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                    }

                    // IDENTIFIER FIELD (onSubmit triggers nutrition lookup)
                    VStack(alignment: .leading) {
                        Text("IDENTIFIER:")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(BrutalistTheme.brutalistBlack)

                        TextField("E.G. ORGANIC_KALE", text: $name)
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                            .padding(BrutalistTheme.spacingM)
                            .submitLabel(.search)
                            .onSubmit { lookupNutrition(for: name) }
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall).fill(BrutalistTheme.brutalistBlack).offset(x: 4, y: 4)
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall).fill(BrutalistTheme.brutalistWhite)
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall).stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                }
                            )
                    }

                    // CATEGORY PICKER
                    VStack(alignment: .leading) {
                        Text("CATEGORY:")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                        ScrollView(.horizontal, showsIndicators: false) {
                            let categories = Array(FoodCategory.allCases.enumerated())
                            HStack(spacing: BrutalistTheme.spacingS) {
                                ForEach(categories, id: \.element) { index, category in
                                    Button(action: {
                                        FeedbackManager.shared.triggerClack()
                                        selectedCategory = category
                                    }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium).fill(BrutalistTheme.brutalistBlack).offset(x: 3, y: 3)
                                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium).fill(selectedCategory == category ? BrutalistTheme.brutalistBlack : BrutalistTheme.brutalistWhite)
                                            Text(category.rawValue.uppercased())
                                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                                .foregroundColor(selectedCategory == category ? BrutalistTheme.brutalistWhite : BrutalistTheme.brutalistBlack)
                                                .padding(.horizontal, BrutalistTheme.spacingM).padding(.vertical, BrutalistTheme.spacingS)
                                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium).stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .offset(y: animatePills ? 0 : 20)
                                    .opacity(animatePills ? 1 : 0)
                                    .animation(
                                        .interpolatingSpring(stiffness: 120, damping: 12)
                                        .delay(Double(index) * 0.05),
                                        value: animatePills
                                    )
                                }
                            }
                            .padding(.vertical, BrutalistTheme.spacingXS)
                        }
                    }

                    // SHELF LIFE SLIDER
                    VStack(alignment: .leading) {
                        HStack {
                            Text("EST_SHELF_LIFE:")
                                .font(.system(size: 10, weight: .black))
                            Spacer()
                            Text("\(Int(shelfLife))_DAYS")
                                .font(.system(size: 14, weight: .black))
                        }
                        Slider(value: $shelfLife, in: 1...30, step: 1)
                            .tint(BrutalistTheme.brutalistBlack)
                    }

                    // NUTRITION SECTION
                    nutritionSection

                    // COMMIT BUTTON
                    Button(action: commitItem) {
                        ZStack {
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium).fill(BrutalistTheme.brutalistBlack).offset(x: 5, y: 5)
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium).fill(BrutalistTheme.brutalistYellow)
                            Text("COMMIT_TO_SYSTEM")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                                .frame(maxWidth: .infinity)
                                .padding(BrutalistTheme.spacingM)
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium).stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(25)
                .onAppear { animatePills = true }
            }
        }
        .background(Color(hex: "#F5F5F5"))
    }

    // MARK: - Nutrition Section

    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("NUTRITION (PER 100G):")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(BrutalistTheme.brutalistBlack)

                Spacer()

                if isLookingUpNutrition {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: BrutalistTheme.brutalistBlack))
                        .scaleEffect(0.7)
                } else if nutritionStatus == .found {
                    Text("MATCH FOUND")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(BrutalistTheme.brutalistLime)
                        .cornerRadius(4)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(BrutalistTheme.brutalistBlack, lineWidth: 1))
                } else if nutritionStatus == .notFound {
                    Text("NO MATCH")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(BrutalistTheme.brutalistBlack)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(BrutalistTheme.brutalistCream)
                        .cornerRadius(4)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(BrutalistTheme.brutalistBlack, lineWidth: 1))
                }
            }

            Text("Type name + return to auto-fill, or enter values manually.")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(BrutalistTheme.brutalistBlack.opacity(0.5))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                NutritionInputField(label: "CALORIES (kcal)", text: $nutriCalories, placeholder: "e.g. 250")
                NutritionInputField(label: "FAT (g)", text: $nutriFat, placeholder: "e.g. 10.5")
                NutritionInputField(label: "CARBS (g)", text: $nutriCarbs, placeholder: "e.g. 30.0")
                NutritionInputField(label: "PROTEIN (g)", text: $nutriProtein, placeholder: "e.g. 5.0")
            }
        }
    }

    // MARK: - Actions

    private func lookupNutrition(for foodName: String) {
        let trimmed = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isLookingUpNutrition = true
        nutritionStatus = .idle

        FoodAPIService.shared.searchByName(trimmed) { nutrients in
            isLookingUpNutrition = false
            guard let n = nutrients else {
                nutritionStatus = .notFound
                return
            }
            nutritionStatus = .found
            if let kcal = n.energyKcal { nutriCalories = String(Int(kcal)) }
            if let fat  = n.fat        { nutriFat      = String(format: "%.1f", fat) }
            if let carb = n.carbohydrates { nutriCarbs = String(format: "%.1f", carb) }
            if let prot = n.proteins   { nutriProtein  = String(format: "%.1f", prot) }
        }
    }

    private func commitItem() {
        FeedbackManager.shared.triggerClack()
        let expiry = Calendar.current.date(byAdding: .day, value: Int(shelfLife), to: Date()) ?? Date()

        let kcal = Double(nutriCalories.trimmingCharacters(in: .whitespaces))
        let fat  = Double(nutriFat.trimmingCharacters(in: .whitespaces))
        let carb = Double(nutriCarbs.trimmingCharacters(in: .whitespaces))
        let prot = Double(nutriProtein.trimmingCharacters(in: .whitespaces))
        let parsedNutrients: Nutriments? = (kcal != nil || fat != nil || carb != nil || prot != nil)
            ? Nutriments(energyKcal: kcal, fat: fat, carbohydrates: carb, proteins: prot, fiber: nil, sugars: nil, sodium: nil)
            : nil

        historyStore.addItem(FoodItem(
            name: name,
            category: selectedCategory,
            expiryDate: expiry,
            quantity: "1",
            imageEmoji: "📦",
            imageData: selectedImageData,
            nutrients: parsedNutrients
        ))
        dismiss()
    }
}

// MARK: - Nutrition Input Field

private struct NutritionInputField: View {
    let label: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundColor(BrutalistTheme.brutalistBlack.opacity(0.6))

            ZStack {
                RoundedRectangle(cornerRadius: 4).fill(BrutalistTheme.brutalistBlack).offset(x: 2, y: 2)
                RoundedRectangle(cornerRadius: 4).fill(BrutalistTheme.brutalistWhite)
                RoundedRectangle(cornerRadius: 4).stroke(BrutalistTheme.brutalistBlack, lineWidth: 1.5)

                TextField(placeholder, text: $text)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
        }
    }
}

#Preview {
    let mockStore = HistoryStore()
    return ManualEntryView()
        .environmentObject(mockStore)
}
