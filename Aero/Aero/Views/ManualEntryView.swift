import SwiftUI
import PhotosUI // 1. Necessary for the picker

struct ManualEntryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var historyStore: HistoryStore

    @State private var name: String = ""
    @State private var shelfLife: Double = 7
    @State private var selectedCategory: FoodCategory = .pantry
    
    // 2. Image Selection States
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    @State private var animatePills = false

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
                    
                    // PHOTO PICKER (NEW: DATA_VISUAL BLOCK)
                    VStack(alignment: .leading) {
                        Text("DATA_VISUAL:")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack {
                                // Shadow
                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                    .fill(BrutalistTheme.brutalistBlack)
                                    .offset(x: 4, y: 4)
                                
                                // Fill
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
                                
                                // Border
                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                            }
                            .frame(height: 150)
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                    }

                    // IDENTIFIER FIELD
                    VStack(alignment: .leading) {
                        Text("IDENTIFIER:")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                        
                        TextField("E.G. ORGANIC_KALE", text: $name)
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                            .padding(BrutalistTheme.spacingM)
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
                    
                    // COMMIT BUTTON
                    Button(action: {
                        FeedbackManager.shared.triggerClack()
                        let expiry = Calendar.current.date(byAdding: .day, value: Int(shelfLife), to: Date()) ?? Date()
                        
                        // 3. Passing imageData to the system
                        historyStore.addItem(FoodItem(
                            name: name,
                            category: selectedCategory,
                            expiryDate: expiry,
                            quantity: "1",
                            imageEmoji: "📦", // Fallback emoji
                            imageData: selectedImageData // Custom image
                        ))
                        dismiss()
                    }) {
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
}

#Preview {
    // 1. Create a dummy store for the preview environment
    let mockStore = HistoryStore()
    
    // 2. Inject it into the view
    return ManualEntryView()
        .environmentObject(mockStore)
}
