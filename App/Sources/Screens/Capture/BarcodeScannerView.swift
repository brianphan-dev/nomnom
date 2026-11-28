import SwiftUI
import UIKit
import Vision
import VisionKit
import NomNomShared
import NomNomDesignSystem

// MARK: - Barcode Scanner View

/// Hardware-aware VisionKit barcode scanner (`EAN-13`, `EAN-8`, `UPC-E`, `Code-128`) with a
/// calm Simulator / manual-entry fallback and quick-test UPC chips.
public struct BarcodeScannerView: View {
    public let isScanning: Bool
    public let isLookingUp: Bool
    public let onDetectedBarcode: (String) -> Void
    public let onOpenLabelEntry: () -> Void

    @State private var manualCode: String = ""
    @State private var preferManualEntry: Bool = false
    @State private var scanLineDown: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let quickTestCodes: [(code: String, label: String)] = [
        ("3017620422003", "Nutella"),
        ("0011110838056", "Sample UPC"),
    ]

    public init(
        isScanning: Bool = true,
        isLookingUp: Bool = false,
        onDetectedBarcode: @escaping (String) -> Void,
        onOpenLabelEntry: @escaping () -> Void
    ) {
        self.isScanning = isScanning
        self.isLookingUp = isLookingUp
        self.onDetectedBarcode = onDetectedBarcode
        self.onOpenLabelEntry = onOpenLabelEntry
    }

    private var isLiveScannerSupported: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return DataScannerViewController.isSupported && DataScannerViewController.isAvailable
        #endif
    }

    public var body: some View {
        ZStack {
            NNColor.viewfinder
                .ignoresSafeArea()

            if isLiveScannerSupported && !preferManualEntry {
                liveScannerContent
            } else {
                manualFallbackContent
            }
        }
    }

    // MARK: - Live VisionKit Scanner

    private var liveScannerContent: some View {
        ZStack {
            VisionKitBarcodeRepresentable(
                isScanning: isScanning && !isLookingUp,
                onDetected: { code in
                    onDetectedBarcode(code)
                }
            )
            .ignoresSafeArea()

            VStack(spacing: NNSpacing.s4) {
                Spacer(minLength: 120)

                reticleView(width: 268, height: 164)

                HStack(spacing: 6) {
                    if isLookingUp {
                        ProgressView()
                            .controlSize(.small)
                            .tint(NNColor.onPhoto)
                        Text("Looking up barcode\u{2026}")
                    } else {
                        Text("Point at a barcode")
                    }
                }
                .nnTextStyle(.caption)
                .foregroundStyle(NNColor.onPhoto)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().fill(Color.black.opacity(0.35)))
                .environment(\.colorScheme, .dark)

                HStack(spacing: NNSpacing.s2) {
                    NNChip(
                        "Scan nutrition label",
                        icon: .scan,
                        size: .sm,
                        tone: .glass,
                        action: onOpenLabelEntry
                    )
                    NNChip(
                        "Type code",
                        icon: .manual,
                        size: .sm,
                        tone: .glass
                    ) {
                        preferManualEntry = true
                    }
                }

                Spacer(minLength: 88)
            }
            .padding(.horizontal, NNSpacing.screenMargin)
        }
    }

    // MARK: - Simulator & Manual Entry Fallback

    private var manualFallbackContent: some View {
        ScrollView {
            VStack(spacing: NNSpacing.s5) {
                Spacer(minLength: 112)

                reticleView(width: 248, height: 116)

                Text(isLiveScannerSupported ? "Enter a UPC or EAN barcode" : "Simulator preview · enter a barcode")
                    .nnTextStyle(.caption)
                    .foregroundStyle(NNColor.onPhoto)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().fill(Color.black.opacity(0.35)))
                    .environment(\.colorScheme, .dark)

                NNCard(padding: .md) {
                    VStack(alignment: .leading, spacing: NNSpacing.s3) {
                        Text("Barcode lookup")
                            .nnOverlineStyle()

                        NNTextField(
                            "Type or paste UPC / EAN",
                            text: $manualCode,
                            icon: .barcode,
                            clearable: true,
                            surface: .fill
                        )
                        .keyboardType(.numberPad)
                        .submitLabel(.search)
                        .onSubmit {
                            submitManualCode()
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: NNSpacing.s2) {
                                ForEach(Self.quickTestCodes, id: \.code) { preset in
                                    NNChip(
                                        preset.code,
                                        detail: preset.label,
                                        selected: manualCode.trimmingCharacters(in: .whitespacesAndNewlines) == preset.code,
                                        size: .sm
                                    ) {
                                        manualCode = preset.code
                                        onDetectedBarcode(preset.code)
                                    }
                                }
                            }
                        }

                        NNButton(
                            isLookingUp ? "Looking up\u{2026}" : "Look up barcode",
                            variant: .accent,
                            size: .md,
                            icon: .search,
                            fullWidth: true,
                            loading: isLookingUp
                        ) {
                            submitManualCode()
                        }
                        .disabled(manualCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                HStack(spacing: NNSpacing.s2) {
                    NNChip(
                        "Scan nutrition label",
                        icon: .scan,
                        size: .sm,
                        tone: .glass,
                        action: onOpenLabelEntry
                    )
                    if isLiveScannerSupported {
                        NNChip(
                            "Use camera",
                            icon: .camera,
                            size: .sm,
                            tone: .glass
                        ) {
                            preferManualEntry = false
                        }
                    }
                }

                Spacer(minLength: 48)
            }
            .padding(.horizontal, NNSpacing.screenMargin)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func reticleView(width: CGFloat, height: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: NNRadius.card, style: .continuous)
        return ZStack {
            shape
                .fill(Color.black.opacity(0.18))
            shape
                .strokeBorder(NNColor.onPhoto.opacity(0.9), lineWidth: 2.5)

            Capsule()
                .fill(NNColor.accent)
                .frame(height: 2)
                .padding(.horizontal, 18)
                .offset(y: reduceMotion ? 0 : (scanLineDown ? height * 0.28 : -height * 0.28))
                .animation(
                    reduceMotion
                        ? nil
                        : NNMotion.easeStandard(duration: 1.6).repeatForever(autoreverses: true),
                    value: scanLineDown
                )
        }
        .frame(width: width, height: height)
        .onAppear {
            if !reduceMotion {
                scanLineDown = true
            }
        }
    }

    private func submitManualCode() {
        let cleaned = manualCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, !isLookingUp else { return }
        onDetectedBarcode(cleaned)
    }
}

// MARK: - VisionKit DataScannerViewController Wrapper

private struct VisionKitBarcodeRepresentable: UIViewControllerRepresentable {
    let isScanning: Bool
    let onDetected: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDetected: onDetected)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType> = [
            .barcode(symbologies: [.ean13, .ean8, .upce, .code128]),
        ]
        let scanner = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        if isScanning {
            try? scanner.startScanning()
        }
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        context.coordinator.onDetected = onDetected
        if isScanning {
            if !uiViewController.isScanning {
                context.coordinator.resetDebounce()
                try? uiViewController.startScanning()
            }
        } else {
            if uiViewController.isScanning {
                uiViewController.stopScanning()
            }
        }
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        if uiViewController.isScanning {
            uiViewController.stopScanning()
        }
    }

    @MainActor
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onDetected: (String) -> Void
        private var lastCode: String?
        private var lastDetectedAt: Date = .distantPast

        init(onDetected: @escaping (String) -> Void) {
            self.onDetected = onDetected
        }

        func resetDebounce() {
            lastCode = nil
            lastDetectedAt = .distantPast
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            handleRecognized(addedItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didTapOn item: RecognizedItem
        ) {
            handleRecognized([item])
        }

        private func handleRecognized(_ items: [RecognizedItem]) {
            for item in items {
                guard case let .barcode(barcode) = item,
                      let payload = barcode.payloadStringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !payload.isEmpty
                else {
                    continue
                }

                let now = Date()
                if payload == lastCode && now.timeIntervalSince(lastDetectedAt) < 2.0 {
                    return
                }
                lastCode = payload
                lastDetectedAt = now
                onDetected(payload)
                return
            }
        }
    }
}

// MARK: - Nutrition Facts Label Entry Sheet

/// Inline Label OCR / Nutrition Facts manual entry fallback when a barcode is unavailable or not found.
public struct NutritionLabelEntrySheet: View {
    public let initialBarcode: String?
    public let onClose: () -> Void
    public let onCreateFood: (FoodItem) -> Void

    @State private var productName: String = ""
    @State private var brandName: String = ""
    @State private var servingLabel: String = "1 serving"
    @State private var servingGramsText: String = "100"
    @State private var caloriesText: String = ""
    @State private var proteinText: String = ""
    @State private var carbsText: String = ""
    @State private var fatText: String = ""

    public init(
        initialBarcode: String? = nil,
        onClose: @escaping () -> Void,
        onCreateFood: @escaping (FoodItem) -> Void
    ) {
        self.initialBarcode = initialBarcode
        self.onClose = onClose
        self.onCreateFood = onCreateFood
    }

    private var servingGrams: Double {
        parseDouble(servingGramsText) ?? 0
    }

    private var calories: Double {
        parseDouble(caloriesText) ?? 0
    }

    private var protein: Double {
        parseDouble(proteinText) ?? 0
    }

    private var carbs: Double {
        parseDouble(carbsText) ?? 0
    }

    private var fat: Double {
        parseDouble(fatText) ?? 0
    }

    private var perServingSnapshot: NutritionSnapshot {
        NutritionSnapshot(
            caloriesKcal: max(0, calories),
            proteinG: max(0, protein),
            carbsG: max(0, carbs),
            fatG: max(0, fat)
        )
    }

    private var validationWarnings: [String] {
        guard calories > 0 || protein > 0 || carbs > 0 || fat > 0 else { return [] }
        let result = AtwaterValidator.validate(
            perServingSnapshot,
            gramWeight: servingGrams > 0 ? servingGrams : nil
        )
        return result.warnings
    }

    private var canSubmit: Bool {
        !productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && servingGrams > 0
            && calories >= 0
            && !caloriesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        VStack(spacing: 0) {
            NNSheetHeader(title: "Nutrition label", showGrabber: true) {
                NNIconButton(icon: .close, label: "Close", variant: .filled, size: 36, action: onClose)
            }
            .padding(.top, NNSpacing.s3)
            .padding(.horizontal, NNSpacing.screenMargin)

            ScrollView {
                VStack(alignment: .leading, spacing: NNSpacing.s4) {
                    if let initialBarcode, !initialBarcode.isEmpty {
                        HStack(spacing: NNSpacing.s2) {
                            NNBadge("Barcode \(initialBarcode)", tone: .neutral, icon: .barcode)
                            NNBadge("Label", tone: .info, icon: .scan)
                        }
                    }

                    NNCard(padding: .md) {
                        VStack(alignment: .leading, spacing: NNSpacing.s3) {
                            Text("Product")
                                .nnOverlineStyle()

                            NNTextField("Product name", text: $productName, clearable: true, surface: .fill)
                            NNTextField("Brand (optional)", text: $brandName, clearable: true, surface: .fill)

                            HStack(spacing: NNSpacing.s2) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Serving label")
                                        .nnTextStyle(.footnote)
                                        .foregroundStyle(NNColor.textSecondary)
                                    NNTextField("1 bar", text: $servingLabel, clearable: false, surface: .fill)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Serving (g)")
                                        .nnTextStyle(.footnote)
                                        .foregroundStyle(NNColor.textSecondary)
                                    NNTextField("100", text: $servingGramsText, clearable: false, surface: .fill)
                                        .keyboardType(.decimalPad)
                                }
                                .frame(width: 112)
                            }
                        }
                    }

                    NNCard(padding: .md) {
                        VStack(alignment: .leading, spacing: NNSpacing.s3) {
                            Text("Per serving")
                                .nnOverlineStyle()

                            HStack(spacing: NNSpacing.s2) {
                                numericField(title: "Calories (kcal)", placeholder: "240", text: $caloriesText)
                                numericField(title: "Protein (g)", placeholder: "12", text: $proteinText)
                            }

                            HStack(spacing: NNSpacing.s2) {
                                numericField(title: "Carbs (g)", placeholder: "26", text: $carbsText)
                                numericField(title: "Fat (g)", placeholder: "9", text: $fatText)
                            }
                        }
                    }

                    if !validationWarnings.isEmpty {
                        NNBanner(
                            tone: .info,
                            icon: .info,
                            title: "Check label numbers",
                            message: validationWarnings.joined(separator: " ")
                        )
                    }
                }
                .padding(.horizontal, NNSpacing.screenMargin)
                .padding(.vertical, NNSpacing.s3)
            }
            .scrollDismissesKeyboard(.interactively)

            VStack(spacing: 0) {
                NNButton(
                    canSubmit
                        ? "Continue · \(NNFormatting.kcalWithUnit(calories))"
                        : "Enter label values",
                    variant: .accent,
                    size: .lg,
                    fullWidth: true,
                    action: createFoodItem
                )
                .disabled(!canSubmit)
            }
            .padding(.horizontal, NNSpacing.screenMargin)
            .padding(.top, NNSpacing.s3)
            .padding(.bottom, NNSpacing.s5)
        }
        .background(NNColor.bgApp.ignoresSafeArea())
    }

    private func numericField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .nnTextStyle(.footnote)
                .foregroundStyle(NNColor.textSecondary)
            NNTextField(placeholder, text: text, clearable: false, surface: .fill)
                .keyboardType(.decimalPad)
        }
    }

    private func parseDouble(_ raw: String) -> Double? {
        let cleaned = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty, let value = Double(cleaned), value.isFinite else {
            return nil
        }
        return value
    }

    private func createFoodItem() {
        let trimmedName = productName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, servingGrams > 0 else { return }

        let trimmedBrand = brandName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedServing = servingLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedServingLabel = trimmedServing.isEmpty ? "\(Int(servingGrams.rounded())) g" : trimmedServing

        let per100g = perServingSnapshot.scaled(by: 100.0 / servingGrams)
        var options: [ServingOption] = [
            ServingOption(label: resolvedServingLabel, gramWeight: servingGrams, isDefault: true),
        ]
        if abs(servingGrams - 100.0) > 0.5 {
            options.append(ServingOption(label: "100 g", gramWeight: 100, isDefault: false))
        }

        let now = Date()
        let item = FoodItem(
            name: trimmedName,
            brand: trimmedBrand.isEmpty ? nil : trimmedBrand,
            barcode: initialBarcode?.trimmingCharacters(in: .whitespacesAndNewlines),
            source: .labelOCR,
            nutritionPer100g: per100g,
            servingOptions: options,
            lastUsedAt: now,
            createdAt: now,
            updatedAt: now
        )
        onCreateFood(item)
    }
}
