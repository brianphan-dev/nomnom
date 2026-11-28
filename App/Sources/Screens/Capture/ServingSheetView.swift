import SwiftUI
import NomNomShared
import NomNomCore
import NomNomDesignSystem

/// Shared serving calculator sheet for barcode lookups, label OCR items, and manual catalog search.
public struct ServingSheetView: View {
    private let store: NomNomAppStore
    private let context: ServingSelectionContext
    private let onClose: () -> Void
    private let onSaved: (Meal) -> Void

    private let servingOptions: [ServingOption]

    @State private var selectedMealType: MealType
    @State private var selectedOptionIndex: Int
    @State private var quantity: Double = 1.0
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?

    public init(
        store: NomNomAppStore,
        context: ServingSelectionContext,
        onClose: @escaping () -> Void,
        onSaved: @escaping (Meal) -> Void
    ) {
        self.store = store
        self.context = context
        self.onClose = onClose
        self.onSaved = onSaved

        let resolvedOptions: [ServingOption] = context.foodItem.servingOptions.isEmpty
            ? [ServingOption(label: "100 g", gramWeight: 100, isDefault: true)]
            : context.foodItem.servingOptions

        self.servingOptions = resolvedOptions
        self._selectedMealType = State(initialValue: context.mealType)
        self._selectedOptionIndex = State(
            initialValue: resolvedOptions.firstIndex(where: \.isDefault) ?? 0
        )
    }

    private var activeOption: ServingOption {
        let clamped = min(max(selectedOptionIndex, 0), servingOptions.count - 1)
        return servingOptions[clamped]
    }

    private var scaledNutrition: NutritionSnapshot {
        context.foodItem.nutrition(for: activeOption, quantity: quantity)
    }

    private var totalGrams: Double {
        activeOption.gramWeight * quantity
    }

    private var sourceLabel: String {
        switch context.foodItem.source {
        case .usda: "USDA"
        case .openFoodFacts: "Open Food Facts"
        case .labelOCR: "Label"
        case .custom: "Custom"
        case .aiEstimate: "AI"
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            NNSheetHeader(title: context.foodItem.name, showGrabber: true) {
                NNIconButton(
                    icon: .close,
                    label: "Close",
                    variant: .filled,
                    size: 36,
                    action: onClose
                )
            }
            .padding(.top, NNSpacing.s3)
            .padding(.horizontal, NNSpacing.screenMargin)

            ScrollView {
                VStack(alignment: .leading, spacing: NNSpacing.s4) {
                    metadataRow

                    NNSegmentedControl(
                        options: MealType.allCases.map { NNSegmentOption(value: $0, label: $0.displayName) },
                        selection: $selectedMealType,
                        size: .md
                    )

                    VStack(alignment: .leading, spacing: NNSpacing.s2) {
                        Text("Serving size")
                            .nnOverlineStyle()
                            .padding(.horizontal, 4)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: NNSpacing.s2) {
                                ForEach(Array(servingOptions.enumerated()), id: \.element.id) { index, option in
                                    NNChip(
                                        option.label,
                                        detail: servingGramDetail(for: option),
                                        selected: index == selectedOptionIndex,
                                        size: .md
                                    ) {
                                        selectedOptionIndex = index
                                    }
                                }
                            }
                        }
                    }

                    NNCard(padding: .md) {
                        HStack(spacing: NNSpacing.s3) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Quantity")
                                    .font(NNFont.sans(size: 16, weight: .medium, relativeTo: .callout))
                                    .foregroundStyle(NNColor.textPrimary)

                                Text(NNFormatting.grams(totalGrams))
                                    .nnTextStyle(.numSm)
                                    .foregroundStyle(NNColor.textSecondary)
                            }

                            Spacer(minLength: 8)

                            NNStepper(
                                value: $quantity,
                                step: 0.25,
                                in: 0.25...20.0,
                                label: "Quantity"
                            )
                        }
                    }

                    nutritionSummaryCard

                    if let errorMessage {
                        NNBanner(
                            tone: .info,
                            icon: .info,
                            title: "Couldn't log food",
                            message: errorMessage
                        )
                    }
                }
                .padding(.horizontal, NNSpacing.screenMargin)
                .padding(.top, NNSpacing.s2)
                .padding(.bottom, NNSpacing.s5)
            }

            VStack(spacing: 0) {
                NNButton(
                    "Add \(NNFormatting.kcal(scaledNutrition.caloriesKcal)) kcal",
                    variant: .accent,
                    size: .lg,
                    fullWidth: true,
                    loading: isSaving
                ) {
                    Task {
                        await saveServing()
                    }
                }
            }
            .padding(.horizontal, NNSpacing.screenMargin)
            .padding(.top, NNSpacing.s3)
            .padding(.bottom, NNSpacing.s5)
            .background(NNColor.bgApp)
        }
        .background(NNColor.bgApp.ignoresSafeArea())
    }

    // MARK: - Subviews

    private var metadataRow: some View {
        HStack(spacing: NNSpacing.s2) {
            if let brand = context.foodItem.brand,
               !brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                Text(brand)
                    .nnTextStyle(.subhead)
                    .foregroundStyle(NNColor.textSecondary)
                    .lineLimit(1)
            }

            NNBadge(sourceLabel, tone: .info)
        }
    }

    private var nutritionSummaryCard: some View {
        let totals = scaledNutrition

        return NNCard(padding: .lg) {
            VStack(alignment: .leading, spacing: NNSpacing.s4) {
                HStack(alignment: .firstTextBaseline, spacing: NNSpacing.s3) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(NNFormatting.kcal(totals.caloriesKcal))
                            .nnTextStyle(.numLg)
                            .foregroundStyle(NNColor.textPrimary)
                        Text("kcal")
                            .nnTextStyle(.subhead)
                            .foregroundStyle(NNColor.textSecondary)
                    }

                    Spacer(minLength: 8)

                    NNMacroLine(
                        protein: totals.proteinG,
                        carbs: totals.carbsG,
                        fat: totals.fatG,
                        size: .md
                    )
                }

                Rectangle()
                    .fill(NNColor.borderHairline)
                    .frame(height: 1)

                HStack(spacing: 14) {
                    NNMacroBar(
                        macro: .protein,
                        value: totals.proteinG,
                        target: Double(store.targets.proteinG)
                    )
                    NNMacroBar(
                        macro: .carbs,
                        value: totals.carbsG,
                        target: Double(store.targets.carbsG)
                    )
                    NNMacroBar(
                        macro: .fat,
                        value: totals.fatG,
                        target: Double(store.targets.fatG)
                    )
                }
            }
        }
    }

    // MARK: - Helpers & Save

    private func servingGramDetail(for option: ServingOption) -> String? {
        let lower = option.label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lower.hasSuffix("g") && lower.dropLast().trimmingCharacters(in: .whitespaces).allSatisfy(\.isNumber) {
            return nil
        }
        return "\(Int(option.gramWeight.rounded())) g"
    }

    private func formattedQuantity(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        } else if (rounded * 10).rounded() == rounded * 10 {
            return String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), rounded)
        }
        return String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), rounded)
    }

    private func saveServing() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let mealId = UUID()
        let servingText = abs(quantity - 1.0) < 0.001
            ? activeOption.label
            : "\(formattedQuantity(quantity)) \u{00D7} \(activeOption.label)"

        let item = MealEntryItem(
            mealId: mealId,
            foodItemId: context.foodItem.id,
            displayName: context.foodItem.name,
            brand: context.foodItem.brand,
            servingLabel: servingText,
            quantity: quantity,
            gramWeight: totalGrams,
            portionMultiplier: 1.0,
            confidence: nil,
            nutrition: scaledNutrition
        )

        let meal = Meal(
            id: mealId,
            localDate: store.selectedLocalDate,
            eatenAt: Date(),
            timezoneId: TimeZone.current.identifier,
            mealType: selectedMealType,
            title: context.foodItem.name,
            captureMethod: context.captureMethod,
            aiStatus: .none,
            items: [item]
        )

        do {
            try await store.logMeal(meal)

            var updatedFood = context.foodItem
            updatedFood.lastUsedAt = Date()
            try? await store.store.saveFoodItem(updatedFood, enqueueSync: false)

            Task {
                if store.isSignedIn && !store.isOffline {
                    _ = try? await store.syncNow()
                }
            }

            onSaved(meal)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
