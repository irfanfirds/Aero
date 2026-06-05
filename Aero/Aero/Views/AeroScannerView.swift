import SwiftUI
import VisionKit
import Vision

// MARK: - Scan Mode
enum ScanMode {
    case barcode  // Default — barcode only, no text interference
    case text     // Fallback — for expiry/label text scanning
}

// MARK: - Scan Success Overlay
struct ScanSuccessOverlay: View {
    let itemName: String
    @State private var checkScale: CGFloat = 0.3
    @State private var checkOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.6
    @State private var ringOpacity: Double = 0.8
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    // Expanding ring
                    Circle()
                        .stroke(Color(hex: "#DFFF00"), lineWidth: 4)
                        .frame(width: 120, height: 120)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Filled circle
                    Circle()
                        .fill(Color.black)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "#DFFF00"), lineWidth: 3)
                        )

                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 44, weight: .black))
                        .foregroundColor(Color(hex: "#DFFF00"))
                        .scaleEffect(checkScale)
                        .opacity(checkOpacity)
                }

                // Item name
                VStack(spacing: 6) {
                    Text("ITEM ADDED")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(Color(hex: "#DFFF00"))
                        .tracking(3)

                    Text(itemName.uppercased())
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineLimit(2)
                }
                .opacity(textOpacity)
            }
        }
        .onAppear {
            // Ring expands and fades
            withAnimation(.easeOut(duration: 0.5)) {
                ringScale = 1.4
                ringOpacity = 0
            }
            // Checkmark pops in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55).delay(0.1)) {
                checkScale = 1.0
                checkOpacity = 1
            }
            // Text fades in
            withAnimation(.easeIn(duration: 0.3).delay(0.25)) {
                textOpacity = 1
            }
        }
    }
}

// MARK: - Main Scanner View
struct AeroScannerView: UIViewControllerRepresentable {
    @EnvironmentObject var historyStore: HistoryStore
    @Binding var showSuccess: Bool
    @Binding var lastScanned: String
    @Environment(\.dismiss) var dismiss

    // Default to barcode-only to prevent text interference
    var scanMode: ScanMode = .barcode

    // MARK: - Recognized data types based on mode
    private var recognizedTypes: Set<DataScannerViewController.RecognizedDataType> {
        switch scanMode {
        case .barcode:
            // Barcode ONLY — suppresses all text detection
            return [
                .barcode(symbologies: [
                    .ean13, .ean8, .upce, .code128,
                    .code39, .code93, .qr, .dataMatrix,
                    .pdf417, .itf14, .aztec
                ])
            ]
        case .text:
            return [.text()]
        }
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let viewController = DataScannerViewController(
            recognizedDataTypes: recognizedTypes,
            qualityLevel: .accurate,          // Higher quality for barcode accuracy
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false, // Save battery, not needed for barcodes
            isHighlightingEnabled: true
        )
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        guard DataScannerViewController.isSupported,
              DataScannerViewController.isAvailable else { return }
        if !uiViewController.isScanning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                try? uiViewController.startScanning()
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Coordinator
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: AeroScannerView
        private var hasScanned = false // Debounce — prevent double-fire

        init(_ parent: AeroScannerView) { self.parent = parent }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didTapOn item: RecognizedItem
        ) {
            guard !hasScanned else { return } // Ignore taps after first scan
            hasScanned = true
            dataScanner.stopScanning()        // Stop immediately after first hit

            switch item {

            // MARK: - Barcode
            case .barcode(let barcode):
                let codeValue = barcode.payloadStringValue ?? ""
                guard !codeValue.isEmpty else {
                    hasScanned = false
                    try? dataScanner.startScanning()
                    return
                }

                DispatchQueue.main.async {
                    self.parent.lastScanned = "Identifying Product..."
                    withAnimation { self.parent.showSuccess = true }
                }

                FoodAPIService.shared.fetchProductInfo(barcode: codeValue) { info in
                    FeedbackManager.shared.triggerClack()

                    let finalName = info.name ?? "Product: \(codeValue)"
                    let category  = AeroScannerView.detectCategory(from: finalName)
                    let expiry    = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

                    if let imagePath = info.imageUrl {
                        FoodAPIService.shared.downloadImage(from: imagePath) { imageData in
                            let newItem = FoodItem(
                                name: finalName,
                                category: category,
                                expiryDate: expiry,
                                imageData: imageData,
                                barcode: codeValue,
                                nutrients: info.nutrients
                            )
                            self.saveAndDismiss(item: newItem, displayName: finalName)
                        }
                    } else {
                        let newItem = FoodItem(
                            name: finalName,
                            category: category,
                            expiryDate: expiry,
                            imageData: nil,
                            barcode: codeValue,
                            nutrients: info.nutrients
                        )
                        self.saveAndDismiss(item: newItem, displayName: finalName)
                    }
                }

            // MARK: - Text (only active in .text mode)
            case .text(let text):
                let transcript = text.transcript
                let expiry   = AeroScannerView.parseExpiryDate(from: transcript)
                    ?? Calendar.current.date(byAdding: .day, value: 7, to: Date())!
                let name     = AeroScannerView.extractLikelyName(from: transcript)
                let category = AeroScannerView.detectCategory(from: name)
                let newItem  = FoodItem(name: name, category: category, expiryDate: expiry)
                saveAndDismiss(item: newItem, displayName: name)

            @unknown default:
                hasScanned = false
            }
        }

        // Also fires on auto-detected items (not just taps)
        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            guard !hasScanned else { return }

            // Auto-process first barcode detected (no tap needed)
            if let barcode = addedItems.compactMap({ item -> RecognizedItem.Barcode? in
                if case .barcode(let b) = item { return b }
                return nil
            }).first {
                hasScanned = true
                dataScanner.stopScanning()

                let codeValue = barcode.payloadStringValue ?? ""
                guard !codeValue.isEmpty else {
                    hasScanned = false
                    try? dataScanner.startScanning()
                    return
                }

                DispatchQueue.main.async {
                    self.parent.lastScanned = "Identifying Product..."
                    withAnimation { self.parent.showSuccess = true }
                }

                FoodAPIService.shared.fetchProductInfo(barcode: codeValue) { info in
                    FeedbackManager.shared.triggerClack()

                    let finalName = info.name ?? "Product: \(codeValue)"
                    let category  = AeroScannerView.detectCategory(from: finalName)
                    let expiry    = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

                    if let imagePath = info.imageUrl {
                        FoodAPIService.shared.downloadImage(from: imagePath) { imageData in
                            let newItem = FoodItem(
                                name: finalName,
                                category: category,
                                expiryDate: expiry,
                                imageData: imageData,
                                barcode: codeValue,
                                nutrients: info.nutrients
                            )
                            self.saveAndDismiss(item: newItem, displayName: finalName)
                        }
                    } else {
                        let newItem = FoodItem(
                            name: finalName,
                            category: category,
                            expiryDate: expiry,
                            imageData: nil,
                            barcode: codeValue,
                            nutrients: info.nutrients
                        )
                        self.saveAndDismiss(item: newItem, displayName: finalName)
                    }
                }
            }
        }

        private func saveAndDismiss(item: FoodItem, displayName: String) {
            DispatchQueue.main.async {
                self.parent.lastScanned = displayName
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    self.parent.showSuccess = true
                }
                self.parent.historyStore.addItem(item)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation { self.parent.showSuccess = false }
                    self.parent.dismiss()
                }
            }
        }
    }
}

// MARK: - Full Scanner Screen (wraps camera + overlay)
struct AeroScannerScreen: View {
    @EnvironmentObject var historyStore: HistoryStore
    @Environment(\.dismiss) var dismiss
    @State private var showSuccess = false
    @State private var lastScanned = ""
    @State private var scanMode: ScanMode = .barcode

    var body: some View {
        ZStack {
            // Camera layer
            AeroScannerView(
                showSuccess: $showSuccess,
                lastScanned: $lastScanned,
                scanMode: scanMode
            )
            .environmentObject(historyStore)
            .ignoresSafeArea()

            // Success overlay
            if showSuccess {
                ScanSuccessOverlay(itemName: lastScanned)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(10)
            }

            // Top controls
            if !showSuccess {
                VStack {
                    HStack {
                        // Close button
                        Button(action: { dismiss() }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 44, height: 44)
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundColor(.white)
                            }
                        }

                        Spacer()

                        // Mode toggle pill
                        HStack(spacing: 0) {
                            ForEach(["Barcode", "Text"], id: \.self) { mode in
                                let isActive = (mode == "Barcode") == (scanMode == .barcode)
                                Button(action: {
                                    scanMode = (mode == "Barcode") ? .barcode : .text
                                }) {
                                    Text(mode)
                                        .font(.system(size: 12, weight: .black, design: .monospaced))
                                        .foregroundColor(isActive ? .black : .white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(isActive ? Color(hex: "#DFFF00") : Color.clear)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    Spacer()

                    // Bottom hint
                    Text(scanMode == .barcode ? "Point at a barcode to scan" : "Tap on text to capture")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                        .padding(.bottom, 48)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSuccess)
    }
}

// MARK: - Logic Helpers
extension AeroScannerView {

    static func detectCategory(from name: String) -> FoodCategory {
        let lowerName = name.lowercased()
        let mapping: [FoodCategory: [String]] = [
            .fruits:     ["apple", "banana", "mango", "orange", "berry", "grape", "pear", "durian", "pineapple"],
            .vegetables: ["carrot", "onion", "tomato", "cabbage", "broccoli", "potato", "garlic", "spinach", "cucumber", "chili"],
            .dairy:      ["milk", "cheese", "yogurt", "butter", "cream", "curd", "margarine"],
            .meat:       ["chicken", "beef", "meat", "lamb", "steak", "sausage", "nugget", "turkey", "fish", "seafood", "prawn"],
            .produce:    ["egg", "bread", "bakery", "flour", "rice", "pasta", "noodle"]
        ]
        var bestCategory: FoodCategory = .pantry
        var highestScore = 0
        for (category, keywords) in mapping {
            let score = keywords.filter { lowerName.contains($0) }.count
            if score > highestScore {
                highestScore = score
                bestCategory = category
            }
        }
        return bestCategory
    }

    static func parseExpiryDate(from text: String) -> Date? {
        parseAnyDate(in: text.uppercased())
    }

    static func parseAnyDate(in text: String) -> Date? {
        let formats  = ["yyyy-MM-dd", "MM/dd/yyyy", "dd/MM/yyyy", "MMM d, yyyy"]
        let patterns = [#"\b\d{4}-\d{2}-\d{2}\b"#, #"\b\d{2}[/-]\d{2}[/-]\d{2,4}\b"#]
        let candidates = regexMatches(in: text, patterns: patterns)
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for candidate in candidates {
            for format in formats {
                df.dateFormat = format
                if let d = df.date(from: candidate) { return d }
            }
        }
        return nil
    }

    static func extractLikelyName(from text: String) -> String {
        var s = text.uppercased()
        for marker in ["EXP", "EXPIRES", "BEST BY", "BB"] {
            s = s.replacingOccurrences(of: marker, with: " ")
        }
        let tokens = s.split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count >= 2 }
        return tokens.first ?? text
    }

    static func regexMatches(in text: String, patterns: [String]) -> [String] {
        patterns.flatMap { pattern -> [String] in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            return regex.matches(in: text, range: range).compactMap { match in
                Range(match.range, in: text).map { String(text[$0]) }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AeroScannerScreen()
        .environmentObject(HistoryStore())
}
