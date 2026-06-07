import SwiftUI
import PhotosUI

struct ItemDetailView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @Environment(\.dismiss) var dismiss
    
    // The original item passed from the list
    let item: FoodItem
    
    // --- EDIT STATES ---
    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var editedShelfLife: Double = 7
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var editedImageData: Data? = nil

    var body: some View {
        VStack(spacing: 0) {
            // HEADER
            ZStack {
                Rectangle().fill(BrutalistTheme.brutalistBlack).offset(y: 2)
                Rectangle().fill(BrutalistTheme.brutalistBlack)
                HStack {
                    Text(isEditing ? "EDIT_MODE_ACTIVE" : "ITEM_SPECIFICATIONS")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                    
                    Spacer()
                    
                    // The Toggle Button
                    Button(isEditing ? "SAVE" : "EDIT") {
                        FeedbackManager.shared.triggerClack()
                        if isEditing {
                            saveChanges()
                        }
                        isEditing.toggle()
                    }
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(isEditing ? BrutalistTheme.brutalistYellow : .white)
                }
                .padding()
                .foregroundColor(.white)
            }
            .frame(height: 60)

            ScrollView {
                VStack(spacing: 30) {
                    // 1. HERO IMAGE (Sandwich Method)
                    // 1. HERO IMAGE (Sandwich Method)
                    ZStack {
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                            .fill(BrutalistTheme.brutalistBlack)
                            .offset(x: 6, y: 6)
                        
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                            .fill(BrutalistTheme.brutalistWhite)
                        
                        // REMOVE 'disabled' from inside the PhotosPicker arguments
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Group {
                                if let data = editedImageData ?? item.imageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Text(item.imageEmoji ?? "📦")
                                        .font(.system(size: 80))
                                }
                            }
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium))
                            .overlay(
                                Group {
                                    if isEditing {
                                        Color.black.opacity(0.3)
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.white)
                                            .font(.title)
                                    }
                                }
                            )
                        }
                        // ADD 'disabled' as a modifier here
                        .disabled(!isEditing)
                        
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: 3)
                    }
                    .frame(height: 250)
                    .padding(.horizontal, 25)
                    .padding(.top, 20)

                    // 2. DATA POINTS / EDIT FIELDS
                    VStack(alignment: .leading, spacing: 25) {
                        if isEditing {
                            // --- EDIT MODE UI ---
                            BrutalistEditField(label: "IDENTIFIER", text: $editedName)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ADJUST_SHELF_LIFE: \(Int(editedShelfLife))_DAYS")
                                    .font(.system(size: 10, weight: .black))
                                Slider(value: $editedShelfLife, in: 1...30, step: 1)
                                    .tint(BrutalistTheme.brutalistBlack)
                            }
                            
                            // 3. PURGE BUTTON (Only in Edit Mode)
                            Button(action: purgeItem) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4).fill(BrutalistTheme.brutalistBlack).offset(x: 3, y: 3)
                                    RoundedRectangle(cornerRadius: 4).fill(Color.red)
                                    Text("PURGE_FROM_SYSTEM")
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundColor(.white)
                                        .padding()
                                    RoundedRectangle(cornerRadius: 4).stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                                }
                            }
                            .padding(.top, 20)
                            
                        } else {
                            // --- DISPLAY MODE UI ---
                            DetailRow(label: "IDENTIFIER", value: item.name.uppercased())
                            DetailRow(label: "CATEGORY", value: item.category.rawValue.uppercased())
                            DetailRow(label: "STATUS", value: item.status.rawValue.uppercased(), color: statusColor)

                            if let nutrients = item.nutrients {
                                NutritionCardView(nutrients: nutrients)
                            }
                        }
                    }
                    .padding(.horizontal, 25)
                    
                    if !isEditing {
                        Button("BACK_TO_INVENTORY") { dismiss() }
                            .font(.system(size: 12, weight: .black))
                            .padding(.top, 10)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color(hex: "#F5F5F5"))
        .navigationBarBackButtonHidden(true)
        .onAppear {
            editedName = item.name
            editedImageData = item.imageData
            let diff = Calendar.current.dateComponents([.day], from: Date(), to: item.expiryDate).day ?? 7
            editedShelfLife = Double(max(1, diff))
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    editedImageData = data
                }
            }
        }
    }

    // MARK: - Logic Functions

    private func saveChanges() {
        let newExpiry = Calendar.current.date(byAdding: .day, value: Int(editedShelfLife), to: Date()) ?? Date()
        
        historyStore.updateItem(
            id: item.id,
            newName: editedName,
            newExpiry: newExpiry,
            newImage: editedImageData
        )
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func purgeItem() {
        FeedbackManager.shared.triggerClack()
        historyStore.deleteItem(id: item.id)
        dismiss()
    }

    var statusColor: Color {
        switch item.status {
        case .fresh: return .green
        case .expiring: return .yellow
        case .expired: return .red
        default: return BrutalistTheme.brutalistBlack
        }
    }
}

// MARK: - Supporting Components

struct BrutalistEditField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label + ":")
                .font(.system(size: 10, weight: .black))
            
            TextField("", text: $text)
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .textInputAutocapitalization(.characters)
                .padding(12)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 4).fill(BrutalistTheme.brutalistBlack).offset(x: 2, y: 2)
                        RoundedRectangle(cornerRadius: 4).fill(BrutalistTheme.brutalistWhite)
                        RoundedRectangle(cornerRadius: 4).stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                    }
                )
        }
    }
}

// MARK: - Nutrition Card

struct NutritionCardView: View {
    let nutrients: Nutriments

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NUTRITION:")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(BrutalistTheme.brutalistBlack.opacity(0.7))

            Text("PER 100G")
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundColor(BrutalistTheme.brutalistBlack.opacity(0.4))

            ZStack {
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                    .fill(BrutalistTheme.brutalistBlack)
                    .offset(x: 4, y: 4)

                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                    .fill(BrutalistTheme.brutalistWhite)

                LazyVGrid(columns: columns, spacing: 1) {
                    NutritionMacroCell(label: "CALORIES", value: nutrients.caloriesDisplay, color: BrutalistTheme.brutalistYellow)
                    NutritionMacroCell(label: "FAT",      value: nutrients.fatDisplay,      color: BrutalistTheme.brutalistLavender)
                    NutritionMacroCell(label: "CARBS",    value: nutrients.carbsDisplay,    color: BrutalistTheme.brutalistCyan)
                    NutritionMacroCell(label: "PROTEIN",  value: nutrients.proteinsDisplay, color: BrutalistTheme.brutalistLime)
                    NutritionMacroCell(label: "FIBER",    value: nutrients.fiberDisplay,    color: Color(hex: "#D4E8C2"))
                    NutritionMacroCell(label: "SUGARS",   value: nutrients.sugarsDisplay,   color: BrutalistTheme.brutalistCream)
                }
                .padding(6)

                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
            }
        }
    }
}

private struct NutritionMacroCell: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
            RoundedRectangle(cornerRadius: 4)
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: 1.5)
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundColor(BrutalistTheme.brutalistBlack.opacity(0.6))
                Text(value)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
                    .minimumScaleFactor(0.6)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let label: String
    let value: String
    var color: Color = BrutalistTheme.brutalistBlack
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label + ":")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(BrutalistTheme.brutalistBlack.opacity(0.7))
            
            Text(value)
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundColor(color)
        }
    }
}
