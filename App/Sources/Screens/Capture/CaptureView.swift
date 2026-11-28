import PhotosUI
import SwiftUI
import UIKit
import NomNomShared
import NomNomCore
import NomNomDesignSystem

/// Unified capture experience supporting Photo AI, Barcode + Label fallback, and Manual search / text AI estimation.
public struct CaptureView: View {
    private let store: NomNomAppStore
    private let onClose: () -> Void
    private let onOpenReview: (ReviewDraft) -> Void
    private let onSelectFood: (ServingSelectionContext) -> Void
    private let onSavedPendingMeal: (Meal) -> Void

    @State private var mode: CaptureMode
    @State private var selectedMealType: MealType = .defaultForCurrentTime()
    @State private var cameraController = CameraCaptureController()

    // Photo AI state
    @State private var selectedHints: [String] = []
    @State private var pickedPhotoItem: PhotosPickerItem?
    @State private var capturedPreviewJPEG: Data?
    @State private var isAnalyzingPhoto: Bool = false
    @State private var photoErrorMessage: String?
    @State private var isSavingPending: Bool = false

    // Barcode & Label OCR state
    @State private var isLookingUpBarcode: Bool = false
    @State private var barcodeBannerTitle: String?
    @State private var barcodeBannerMessage: String?
    @State private var lastSearchedBarcode: String?
    @State private var showLabelEntrySheet: Bool = false

    // Manual search & text AI state
    @State private var searchQuery: String = ""
    @State private var searchResults: [FoodItem] = []
    @State private var isSearchingFoods: Bool = false
    @State private var isEstimatingText: Bool = false
    @State private var manualErrorMessage: String?

    private static let hintPresets: [String] = [
        "light oil",
        "half rice",
        "no sauce",
        "shared plate",
    ]

    public init(
        store: NomNomAppStore,
        initialMode: CaptureMode,
        onClose: @escaping () -> Void,
        onOpenReview: @escaping (ReviewDraft) -> Void,
        onSelectFood: @escaping (ServingSelectionContext) -> Void,
        onSavedPendingMeal: @escaping (Meal) -> Void
    ) {
        self.store = store
        self._mode = State(initialValue: initialMode)
        self.onClose = onClose
        self.onOpenReview = onOpenReview
        self.onSelectFood = onSelectFood
        self.onSavedPendingMeal = onSavedPendingMeal
    }

    private var isDarkChrome: Bool {
        mode != .manual
    }

    private var activeHint: String? {
        let ordered = Self.hintPresets.filter { selectedHints.contains($0) }
        return ordered.isEmpty ? nil : ordered.joined(separator: ", ")
    }

    private var modeOptions: [NNSegmentOption<CaptureMode>] {
        [
            NNSegmentOption(value: .photo, label: CaptureMode.photo.label, icon: .sparkle),
            NNSegmentOption(value: .barcode, label: CaptureMode.barcode.label, icon: .barcode),
            NNSegmentOption(value: .manual, label: CaptureMode.manual.label, icon: .manual),
        ]
    }

    public var body: some View {
        ZStack(alignment: .top) {
            modeBackgroundContent

            VStack(spacing: 0) {
                topChromeBar

                switch mode {
                case .photo:
                    photoOverlayControls
                case .barcode:
                    Spacer(minLength: 0)
                    if let title = barcodeBannerTitle, let message = barcodeBannerMessage {
                        barcodeAlertOverlay(title: title, message: message)
                    }
                case .manual:
                    manualModeContent
                }
            }
        }
        .background(isDarkChrome ? NNColor.viewfinder.ignoresSafeArea() : NNColor.bgApp.ignoresSafeArea())
        .onChange(of: pickedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await handlePickedLibraryItem(newItem)
            }
        }
        .onChange(of: mode) { _, _ in
            barcodeBannerTitle = nil
            barcodeBannerMessage = nil
            photoErrorMessage = nil
            manualErrorMessage = nil
        }
        .sheet(isPresented: $showLabelEntrySheet) {
            NutritionLabelEntrySheet(
                initialBarcode: lastSearchedBarcode,
                onClose: { showLabelEntrySheet = false },
                onCreateFood: { createdItem in
                    showLabelEntrySheet = false
                    Task {
                        try? await store.store.saveFoodItem(createdItem, enqueueSync: true)
                        onSelectFood(
                            ServingSelectionContext(
                                foodItem: createdItem,
                                mealType: selectedMealType,
                                captureMethod: .labelOCR
                            )
                        )
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Background Content per Mode

    @ViewBuilder
    private var modeBackgroundContent: some View {
        switch mode {
        case .photo:
            if let capturedPreviewJPEG,
               (isAnalyzingPhoto || photoErrorMessage != nil),
               let uiImage = UIImage(data: capturedPreviewJPEG)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.32).ignoresSafeArea())
            } else {
                CameraPreviewView(controller: cameraController)
            }
        case .barcode:
            BarcodeScannerView(
                isScanning: mode == .barcode && !isLookingUpBarcode && !showLabelEntrySheet,
                isLookingUp: isLookingUpBarcode,
                onDetectedBarcode: { code in
                    Task {
                        await handleBarcodeLookup(code)
                    }
                },
                onOpenLabelEntry: {
                    showLabelEntrySheet = true
                }
            )
        case .manual:
            NNColor.bgApp.ignoresSafeArea()
        }
    }

    // MARK: - Top Bar

    private var topChromeBar: some View {
        VStack(spacing: NNSpacing.s3) {
            HStack(spacing: NNSpacing.s3) {
                NNIconButton(
                    icon: .close,
                    label: "Close",
                    variant: isDarkChrome ? .glass : .filled,
                    size: 40,
                    action: onClose
                )

                Spacer(minLength: 0)

                if mode == .manual {
                    Text("Add manually")
                        .nnTextStyle(.headline)
                        .foregroundStyle(NNColor.textPrimary)
                }

                Spacer(minLength: 0)

                if mode == .photo && !cameraController.isSimulatorFallback && !isAnalyzingPhoto {
                    NNIconButton(
                        icon: cameraController.isFlashEnabled ? .flash : .flashOff,
                        label: cameraController.isFlashEnabled ? "Turn flash off" : "Turn flash on",
                        variant: .glass,
                        size: 40,
                        weight: cameraController.isFlashEnabled ? .fill : .regular
                    ) {
                        cameraController.toggleFlash()
                    }
                } else {
                    Color.clear
                        .frame(width: 40, height: 40)
                }
            }

            if !isAnalyzingPhoto {
                NNSegmentedControl(
                    options: modeOptions,
                    selection: $mode,
                    size: .md,
                    tone: isDarkChrome ? .dark : .default
                )
            }
        }
        .padding(.horizontal, NNSpacing.screenMargin)
        .padding(.top, NNSpacing.s2)
        .padding(.bottom, NNSpacing.s2)
    }

    // MARK: - Photo AI Overlay Controls

    private var photoOverlayControls: some View {
        VStack(spacing: NNSpacing.s3) {
            Spacer(minLength: 0)

            if isAnalyzingPhoto {
                analyzingPlateCard
            } else {
                if let photoErrorMessage {
                    photoFailureBanner(message: photoErrorMessage)
                } else if store.isOffline {
                    NNBanner(
                        tone: .neutral,
                        icon: .cloudOffline,
                        message: "Offline \u{00B7} photo will be saved as pending AI analysis"
                    )
                    .environment(\.colorScheme, .dark)
                    .padding(.horizontal, NNSpacing.screenMargin)
                } else if let remaining = store.quotaRemaining, remaining <= 3 {
                    quotaPill(remaining: remaining)
                }

                hintChipsRow

                shutterControlRow
            }
        }
        .padding(.bottom, NNSpacing.s6)
    }

    private func quotaPill(remaining: Int) -> some View {
        let suffix = remaining == 1 ? " scan left today" : " scans left today"
        return (
            Text("\(remaining)")
                .font(NNFont.mono(size: 12, weight: .semibold, relativeTo: .caption))
            + Text(suffix)
                .font(NNFont.caption)
        )
        .foregroundStyle(NNColor.onPhoto)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().fill(Color.black.opacity(0.4)))
        .environment(\.colorScheme, .dark)
    }

    private var hintChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NNSpacing.s2) {
                ForEach(Self.hintPresets, id: \.self) { hint in
                    let isSelected = selectedHints.contains(hint)
                    NNChip(
                        hint,
                        selected: isSelected,
                        size: .sm,
                        tone: .glass
                    ) {
                        toggleHint(hint)
                    }
                }
            }
            .padding(.horizontal, NNSpacing.screenMargin)
        }
    }

    private var shutterControlRow: some View {
        HStack(spacing: 0) {
            PhotosPicker(selection: $pickedPhotoItem, matching: .images, photoLibrary: .shared()) {
                NNIconView(.photoLibrary, size: 22, weight: .regular, color: NNColor.onPhoto)
                    .frame(width: 48, height: 48)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(Circle().fill(NNColor.glassFill))
                    }
                    .environment(\.colorScheme, .dark)
            }
            .buttonStyle(NNPressScaleButtonStyle(scale: NNMotion.iconPressScale))
            .accessibilityLabel("Photo library")
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                Task {
                    await captureFromCamera()
                }
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(NNColor.onPhoto, lineWidth: 3.5)
                        .frame(width: NNSpacing.shutter, height: NNSpacing.shutter)

                    Circle()
                        .fill(NNColor.accent)
                        .frame(width: NNSpacing.shutter - 12, height: NNSpacing.shutter - 12)
                }
                .contentShape(Circle())
            }
            .buttonStyle(NNPressScaleButtonStyle(scale: NNMotion.shutterPressScale))
            .disabled(isAnalyzingPhoto || isSavingPending)
            .accessibilityLabel("Take photo")

            Menu {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    Button {
                        selectedMealType = mealType
                    } label: {
                        if mealType == selectedMealType {
                            Label(mealType.displayName, systemImage: "checkmark")
                        } else {
                            Text(mealType.displayName)
                        }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(selectedMealType.displayName)
                        .font(NNFont.sans(size: 13, weight: .medium, relativeTo: .footnote))
                        .foregroundStyle(NNColor.onPhoto)
                        .lineLimit(1)
                    NNIconView(.caretDown, size: 11, weight: .bold, color: NNColor.onPhoto.opacity(0.8))
                }
                .padding(.horizontal, 12)
                .frame(minHeight: NNSpacing.tapMin)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(Capsule().fill(NNColor.glassFill))
                }
                .environment(\.colorScheme, .dark)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityLabel("Meal type: \(selectedMealType.displayName)")
        }
        .padding(.horizontal, NNSpacing.screenMargin)
        .padding(.top, NNSpacing.s1)
    }

    private var analyzingPlateCard: some View {
        VStack(alignment: .leading, spacing: NNSpacing.s3) {
            HStack(spacing: NNSpacing.s2) {
                NNIconView(.sparkle, size: 18, weight: .fill, color: NNColor.accent)
                Text("Analysing plate")
                    .nnTextStyle(.headline)
                    .foregroundStyle(NNColor.onPhoto)
            }

            shimmerBar(widthFraction: 0.78)
            shimmerBar(widthFraction: 0.56)
            shimmerBar(widthFraction: 0.66)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: NNRadius.card, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: NNRadius.card, style: .continuous)
                        .fill(Color.black.opacity(0.45))
                )
        }
        .environment(\.colorScheme, .dark)
        .padding(.horizontal, NNSpacing.screenMargin)
    }

    private func shimmerBar(widthFraction: CGFloat) -> some View {
        GeometryReader { proxy in
            Capsule()
                .fill(Color.white.opacity(0.14))
                .nnShimmer(
                    baseColor: Color.white.opacity(0.10),
                    highlightColor: Color.white.opacity(0.28)
                )
                .clipShape(Capsule())
                .frame(width: proxy.size.width * widthFraction)
        }
        .frame(height: 14)
    }

    private func photoFailureBanner(message: String) -> some View {
        VStack(alignment: .leading, spacing: NNSpacing.s3) {
            NNBanner(
                tone: .info,
                icon: .info,
                title: "Couldn't analyse plate",
                message: message
            )

            HStack(spacing: NNSpacing.s2) {
                NNButton(
                    "Save as pending",
                    variant: .secondary,
                    size: .sm,
                    icon: .pending,
                    fullWidth: true,
                    loading: isSavingPending
                ) {
                    Task {
                        if let jpeg = capturedPreviewJPEG {
                            await savePendingPhotoMeal(jpegData: jpeg)
                        }
                    }
                }

                NNButton(
                    "Estimate manually",
                    variant: .primary,
                    size: .sm,
                    icon: .manual,
                    fullWidth: true
                ) {
                    photoErrorMessage = nil
                    capturedPreviewJPEG = nil
                    mode = .manual
                }
            }
        }
        .padding(NNSpacing.s3)
        .background(
            NNColor.surfaceCard,
            in: RoundedRectangle(cornerRadius: NNRadius.card, style: .continuous)
        )
        .nnShadow(.float)
        .padding(.horizontal, NNSpacing.screenMargin)
    }

    // MARK: - Barcode Alert Overlay

    private func barcodeAlertOverlay(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: NNSpacing.s3) {
            NNBanner(
                tone: .info,
                icon: .info,
                title: title,
                message: message
            )

            HStack(spacing: NNSpacing.s2) {
                NNButton(
                    "Enter nutrition label",
                    variant: .accent,
                    size: .sm,
                    icon: .scan,
                    fullWidth: true
                ) {
                    barcodeBannerTitle = nil
                    barcodeBannerMessage = nil
                    showLabelEntrySheet = true
                }

                NNButton("Dismiss", variant: .secondary, size: .sm) {
                    barcodeBannerTitle = nil
                    barcodeBannerMessage = nil
                }
            }
        }
        .padding(NNSpacing.s3)
        .background(
            NNColor.surfaceCard,
            in: RoundedRectangle(cornerRadius: NNRadius.card, style: .continuous)
        )
        .nnShadow(.float)
        .padding(.horizontal, NNSpacing.screenMargin)
        .padding(.bottom, NNSpacing.s6)
    }

    // MARK: - Manual Mode

    private var manualModeContent: some View {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        return ScrollView {
            VStack(alignment: .leading, spacing: NNSpacing.s4) {
                NNSegmentedControl(
                    options: MealType.allCases.map { NNSegmentOption(value: $0, label: $0.displayName) },
                    selection: $selectedMealType,
                    size: .sm
                )

                NNTextField(
                    "Search foods or describe a meal",
                    text: $searchQuery,
                    icon: .search,
                    clearable: true,
                    surface: .card
                )
                .submitLabel(.search)

                if !trimmedQuery.isEmpty {
                    estimateWithAIButton(query: trimmedQuery)
                }

                if let manualErrorMessage {
                    NNBanner(
                        tone: .info,
                        icon: .info,
                        title: "Couldn't estimate meal",
                        message: manualErrorMessage
                    )
                }

                VStack(alignment: .leading, spacing: NNSpacing.s2) {
                    HStack {
                        Text(trimmedQuery.isEmpty ? "Recent & staples" : "Results")
                            .nnOverlineStyle()
                        Spacer()
                        if isSearchingFoods {
                            ProgressView()
                                .controlSize(.mini)
                        }
                    }
                    .padding(.horizontal, 4)

                    if searchResults.isEmpty {
                        NNCard(tone: .outline, padding: .md) {
                            VStack(alignment: .leading, spacing: NNSpacing.s2) {
                                Text(
                                    trimmedQuery.isEmpty
                                        ? "No saved foods yet."
                                        : "No saved foods match. Use Estimate with AI above, or enter a nutrition label."
                                )
                                .nnTextStyle(.subhead)
                                .foregroundStyle(NNColor.textSecondary)

                                NNButton("Enter nutrition label", variant: .secondary, size: .sm, icon: .scan) {
                                    lastSearchedBarcode = nil
                                    showLabelEntrySheet = true
                                }
                            }
                        }
                    } else {
                        NNCard(padding: .none) {
                            VStack(spacing: 0) {
                                ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, item in
                                    let serving = defaultServing(for: item)
                                    let servingKcal = item.nutrition(for: serving, quantity: 1.0).caloriesKcal
                                    NNListRow(
                                        title: item.name,
                                        subtitle: NNFormatting.metadataLine(item.brand, serving.label),
                                        value: NNFormatting.kcalWithUnit(servingKcal),
                                        monospacedValue: true,
                                        chevron: true,
                                        showSeparator: index > 0,
                                        action: {
                                            onSelectFood(
                                                ServingSelectionContext(
                                                    foodItem: item,
                                                    mealType: selectedMealType,
                                                    captureMethod: .manualDB
                                                )
                                            )
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, NNSpacing.screenMargin)
            .padding(.top, NNSpacing.s2)
            .padding(.bottom, NNSpacing.s8)
        }
        .scrollDismissesKeyboard(.interactively)
        .task(id: searchQuery) {
            await performDebouncedSearch(query: searchQuery)
        }
    }

    private func estimateWithAIButton(query: String) -> some View {
        Button {
            Task {
                await estimateTextMeal(query)
            }
        } label: {
            HStack(spacing: NNSpacing.s3) {
                NNIconView(.sparkle, size: 22, weight: .fill, color: NNColor.accentText)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isEstimatingText ? "Estimating\u{2026}" : "Estimate \"\(query)\" with AI")
                        .nnTextStyle(.headline)
                        .foregroundStyle(NNColor.textPrimary)
                        .lineLimit(1)

                    Text("Break down items, portions, and macros from your description")
                        .nnTextStyle(.footnote)
                        .foregroundStyle(NNColor.textSecondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isEstimatingText {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    NNIconView(.chevronRight, size: 14, weight: .bold, color: NNColor.accentText)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, NNSpacing.s4)
            .background(
                NNColor.accentSoft,
                in: RoundedRectangle(cornerRadius: NNRadius.card, style: .continuous)
            )
        }
        .buttonStyle(NNPressScaleButtonStyle(scale: 0.985))
        .disabled(isEstimatingText)
    }

    // MARK: - Actions

    private func toggleHint(_ hint: String) {
        if let index = selectedHints.firstIndex(of: hint) {
            selectedHints.remove(at: index)
        } else {
            selectedHints.append(hint)
        }
    }

    private func captureFromCamera() async {
        guard !isAnalyzingPhoto, !isSavingPending else { return }
        photoErrorMessage = nil
        let jpeg = await cameraController.capturePhoto()
        await processCapturedJPEG(jpeg)
    }

    private func handlePickedLibraryItem(_ item: PhotosPickerItem) async {
        defer { pickedPhotoItem = nil }
        guard let rawData = try? await item.loadTransferable(type: Data.self),
              !rawData.isEmpty
        else {
            photoErrorMessage = "Could not load the selected photo."
            return
        }

        let jpegData: Data
        if let uiImage = UIImage(data: rawData),
           let converted = uiImage.jpegData(compressionQuality: 0.85)
        {
            jpegData = converted
        } else {
            jpegData = rawData
        }

        await processCapturedJPEG(jpegData)
    }

    private func processCapturedJPEG(_ jpegData: Data) async {
        capturedPreviewJPEG = jpegData
        photoErrorMessage = nil

        if store.isOffline {
            await savePendingPhotoMeal(jpegData: jpegData)
            return
        }

        isAnalyzingPhoto = true
        defer { isAnalyzingPhoto = false }

        do {
            let response = try await store.analyzePhoto(
                jpegData: jpegData,
                hint: activeHint,
                mealTypeHint: selectedMealType
            )
            var draft = ReviewDraft.from(
                response: response,
                photoJPEGData: jpegData,
                captureMethod: .photoAI,
                hint: activeHint
            )
            if response.suggestedMealType == nil {
                draft.mealType = selectedMealType
            }
            onOpenReview(draft)
        } catch {
            photoErrorMessage = error.localizedDescription
        }
    }

    private func savePendingPhotoMeal(jpegData: Data) async {
        guard !isSavingPending else { return }
        isSavingPending = true
        defer { isSavingPending = false }

        let mealId = UUID()
        AppPhotoStorage.savePhoto(jpegData, forMealId: mealId)

        let meal = Meal(
            id: mealId,
            localDate: store.selectedLocalDate,
            eatenAt: Date(),
            timezoneId: TimeZone.current.identifier,
            mealType: selectedMealType,
            title: "Pending plate",
            notes: activeHint,
            captureMethod: .photoAI,
            aiStatus: .pending,
            items: []
        )

        do {
            try await store.logMeal(meal)
            onSavedPendingMeal(meal)
        } catch {
            photoErrorMessage = error.localizedDescription
        }
    }

    private func handleBarcodeLookup(_ code: String) async {
        let cleaned = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, !isLookingUpBarcode else { return }

        lastSearchedBarcode = cleaned
        barcodeBannerTitle = nil
        barcodeBannerMessage = nil
        isLookingUpBarcode = true
        defer { isLookingUpBarcode = false }

        do {
            let result = try await store.lookupBarcode(cleaned)
            if result.found, let item = result.foodItem {
                onSelectFood(
                    ServingSelectionContext(
                        foodItem: item,
                        mealType: selectedMealType,
                        captureMethod: .barcode
                    )
                )
            } else {
                barcodeBannerTitle = "Not found in database"
                barcodeBannerMessage = "No product matched barcode \(cleaned). Enter the nutrition label to log it now."
            }
        } catch {
            barcodeBannerTitle = "Couldn't look up barcode"
            barcodeBannerMessage = error.localizedDescription
        }
    }

    private func performDebouncedSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
        }

        isSearchingFoods = true
        defer { isSearchingFoods = false }

        do {
            let matches = try await store.searchFoods(trimmed)
            guard !Task.isCancelled else { return }
            searchResults = matches
        } catch {
            guard !Task.isCancelled else { return }
            searchResults = []
        }
    }

    private func estimateTextMeal(_ description: String) async {
        guard !isEstimatingText else { return }
        manualErrorMessage = nil
        isEstimatingText = true
        defer { isEstimatingText = false }

        do {
            let response = try await store.estimateTextMeal(description, mealTypeHint: selectedMealType)
            var draft = ReviewDraft.from(
                response: response,
                photoJPEGData: nil,
                captureMethod: .manualAI,
                hint: description
            )
            if response.suggestedMealType == nil {
                draft.mealType = selectedMealType
            }
            onOpenReview(draft)
        } catch {
            manualErrorMessage = error.localizedDescription
        }
    }

    private func defaultServing(for item: FoodItem) -> ServingOption {
        if let explicit = item.servingOptions.first(where: \.isDefault) {
            return explicit
        }
        if let first = item.servingOptions.first {
            return first
        }
        return ServingOption(label: "100 g", gramWeight: 100, isDefault: true)
    }
}
