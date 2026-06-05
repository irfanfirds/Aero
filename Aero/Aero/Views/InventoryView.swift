import SwiftUI

struct InventoryView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @State private var showingScanner = false
    @State private var showSuccess = false
    @State private var lastScanned = ""

    var body: some View {
        NavigationView {
            List {
                if historyStore.items.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "refrigerator")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Your fridge is empty")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Button("Scan an Item") {
                            showingScanner = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(historyStore.items) { item in
                        InventoryRow(item: item)
                    }
                    .onDelete { indexSet in
                        // Ensure your HistoryStore has an items array
                        historyStore.items.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle("Aero Fridge")
            .toolbar {
                Button {
                    showingScanner = true
                } label: {
                    Image(systemName: "barcode.viewfinder")
                        .font(.title2)
                }
            }
            .sheet(isPresented: $showingScanner) {
                AeroScannerView(showSuccess: $showSuccess, lastScanned: $lastScanned)
            }
            .overlay {
                if showSuccess {
                    SuccessToast(message: lastScanned)
                        .padding(.top, 50)
                }
            }
        }
    }
}

// Fixed Row View
struct InventoryRow: View {
    let item: FoodItem
    
    var body: some View {
        HStack(spacing: 15) {
            // Check for API Data first
            if let data = item.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text(item.imageEmoji ?? "📦")
                    .font(.system(size: 30))
                    .frame(width: 50, height: 50)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // CHANGED: Fixed VCoreStack to VStack and alignment logic
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("Expires: \(item.expiryDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(item.themeColor)
            }
            
            Spacer()
            
            Text("Qty: \(item.quantity)")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().stroke(Color.gray.opacity(0.3)))
        }
        .padding(.vertical, 4)
    }
}

struct SuccessToast: View {
    let message: String
    var body: some View {
        VStack {
            Text("Added: \(message)")
                .font(.subheadline)
                .bold()
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(25)
                .shadow(radius: 10)
            Spacer()
        }
        .animation(.spring(), value: message)
    }
}
