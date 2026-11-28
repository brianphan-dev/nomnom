import SwiftUI
import NomNomShared
import NomNomCore
import NomNomDesignSystem

/// AI meal estimate review screen supporting per-item portion multipliers, collapsible sauces/oils,
/// calm Atwater validation notes, and adaptive dual-pane layout on iPhone Duo unfolded and iPad.
public struct ReviewView: View {
    private let store: NomNomAppStore
    private let onBack: () -> Void
    private let onSaved: (Meal) -> Void

    @State private var draft: ReviewDraft
    @State private var expandedItemID: UUID?
    @State private var isSaucesExpanded: Bool = false
    @State private var isSaving: Bool = false
    @State private var saveErrorMessage: String?
    @State private var showAddItemSheet: Bool = false

    @Environment(\.nnLayoutClass) private var layoutClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        store: NomNomAppStore,
        draft: ReviewDraft,
        onBack: @escaping () -> Void,
        onSaved: @escaping (Meal) -> Void
    ) {
        self.store = store
        self._draft = State(initialValue: draft)
        self._expandedItemID = State(initialValue: draft.items.first(where: \.needsCheck)?.id)
        self.onBack = onBack
        self.onSaved = onSaved
    }

    private var combinedWarnings: [String] {
        var messages: [String] = []
        var seen = Set<String>()

        for warning in draft.warnings {
            let trimmed = warning.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, seen.insert(trimmed).inserted {
                messages.append(trimmed)
            }
        }

        let total = draft.totalNutrition
        if total.caloriesKcal > 0 || total.proteinG > 0 || total.carbsG > 0 || total.fatG > 0 {
            let validation = AtwaterValidator.validate(total)
            for warning in validation.warnings where seen.insert(warning).inserted {
                messages.append(warning)
            }
        }

        return messages
    }

    private var canSave: Bool {
        !draft.items.isEmpty || draft.includedSauceCount > 0
    }

    public var body: some View {
        Group {
            if layoutClass.isDualPane {
                dualPaneLayout
            } else {
                singleColumnLayout
            }
        }
        .background(NNColor.bgApp.ignoresSafeArea())
        .sheet(isPresented: $showAddItemSheet) {
            ReviewAddItemSheet(store: store) { addedItem in
                draft.items.append(addedItem)
                expandedItemID = addedItem.id
                showAddItemSheet = false
            } onClose: {
                showAddItemSheet = false
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Single-Column Layout (iPhone & Duo Folded)

    private var singleColumnLayout: some View {
        VStack(spacing: 0) {
            reviewNavBar
                .padding(.top, NNSpacing.s2)

            ScrollView {
                VStack(alignment: .leading, spacing: NNSpacing.s4) {
                    if let photoData = draft.photoJPEGData {
                        NNMealPhoto(
                            imageData: photoData,
                            size: nil,
                            cornerRadius: NNRadius.card
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 164)
                    }

                    reviewHeaderSection

                    if !combinedWarnings.isEmpty {
                        warningsBanner
                    }

                    if let saveErrorMessage {
                        NNBanner(
                            tone: .info,
                            icon: .info,
                            title: "Couldn't save meal",
                            message: saveErrorMessage
                        )
                    }

                    reviewItemsSection

                    if !draft.sauces.isEmpty {
                        reviewSaucesSection
                    }
                }
                .padding(.horizontal, NNSpacing.screenMargin)
                .padding(.top, NNSpacing.s4)
                .padding(.bottom, NNSpacing.s6)
            }
            .scrollDismissesKeyboard(.interactively)

            saveFooterBar
        }
    }

    // MARK: - Adaptive Dual-Pane Layout (iPhone Duo Unfolded & iPad)

    private var dualPaneLayout: some View {
        NNDualPaneContainer {
            VStack(spacing: 0) {
                reviewNavBar
                    .padding(.top, NNSpacing.s2)

                ScrollView {
                    VStack(alignment: .leading, spacing: NNSpacing.s4) {
                        if let photoData = draft.photoJPEGData {
                            NNMealPhoto(
                                imageData: photoData,
                                size: nil,
                                cornerRadius: NNRadius.card
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 168)
                        }

                        reviewHeaderSection

                        if !combinedWarnings.isEmpty {
                            warningsBanner
                        }

                        if let saveErrorMessage {
                            NNBanner(
                                tone: .info,
                                icon: .info,
                                title: "Couldn't save meal",
                                message: saveErrorMessage
                            )
                        }

                        if !draft.sauces.isEmpty {
                            reviewSaucesSection
                        }
                    }
                    .padding(.horizontal, NNSpacing.screenMargin)
                    .padding(.top, NNSpacing.s4)
                    .padding(.bottom, NNSpacing.s6)
                }
                .scrollDismissesKeyboard(.interactively)

                saveFooterBar
            }
        } right: {
            ScrollView {
                VStack(alignment: .leading, spacing: NNSpacing.s4) {
                    reviewItemsSection
                }
                .padding(.horizontal, NNSpacing.screenMargin)
                .padding(.top, NNSpacing.s5)
                .padding(.bottom, NNSpacing.s8)
            }
        }
    }

    // MARK: - Subsections

    private var reviewNavBar: some View {
        NNNavBar(
            title: "Review",
            leading: {
                NNIconButton(
                    icon: .back,
                    label: "Back",
                    variant: .filled,
                    size: 36,
                    iconSize: 16,
                    weight: .bold,
                    action: onBack
                )
            },
            trailing: {
                if draft.captureMethod == .photoAI {
                    NNButton("Retake", variant: .ghost, size: .sm, action: onBack)
                }
            }
        )
    }

    private var reviewHeaderSection: some View {
        let totals = draft.totalNutrition

        return VStack(alignment: .leading, spacing: NNSpacing.s3) {
            HStack(spacing: NNSpacing.s2) {
                TextField(
                    "",
                    text: $draft.title,
                    prompt: Text("Meal title").foregroundStyle(NNColor.textTertiary)
                )
                .font(NNFont.title1)
                .tracking(-0.01 * NNTextStyle.title1.size)
                .foregroundStyle(NNColor.textPrimary)
                .textFieldStyle(.plain)
                .accessibilityLabel("Meal title")

                NNIconView(.manual, size: 17, weight: .regular, color: NNColor.textTertiary)
            }

            NNSegmentedControl(
                options: MealType.allCases.map { NNSegmentOption(value: $0, label: $0.displayName) },
                selection: $draft.mealType,
                size: .md
            )

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
            .padding(.horizontal, 4)
        }
    }

    private var warningsBanner: some View {
        NNBanner(
            tone: .info,
            icon: .info,
            title: "Estimate note",
            message: combinedWarnings.joined(separator: " ")
        )
    }

    private var reviewItemsSection: some View {
        VStack(alignment: .leading, spacing: NNSpacing.s2) {
            HStack {
                Text("On the plate")
                    .nnOverlineStyle()
                Spacer()
                Text("Tap to adjust")
                    .nnOverlineStyle()
            }
            .padding(.horizontal, 4)

            if draft.items.isEmpty {
                NNCard(tone: .outline, padding: .md) {
                    Text("No items remaining on this plate. Add an item below or return to capture.")
                        .nnTextStyle(.subhead)
                        .foregroundStyle(NNColor.textSecondary)
                }
            } else {
                NNCard(padding: .none) {
                    VStack(spacing: 0) {
                        ForEach(Array(draft.items.enumerated()), id: \.element.id) { index, item in
                            NNFoodItemRow(
                                name: item.displayName,
                                serving: item.portionSubtitle,
                                kcal: item.baseNutrition.caloriesKcal,
                                confidence: item.confidence,
                                multiplier: item.portionMultiplier,
                                onMultiplier: { newMultiplier in
                                    updateMultiplier(for: item.id, multiplier: newMultiplier)
                                },
                                expanded: expandedItemID == item.id,
                                onToggle: {
                                    expandedItemID = (expandedItemID == item.id) ? nil : item.id
                                },
                                onRemove: {
                                    removeItem(id: item.id)
                                },
                                showSeparator: index > 0
                            )
                        }
                    }
                }
            }

            HStack(spacing: NNSpacing.s2) {
                NNButton("Add missing item", variant: .secondary, size: .sm, icon: .plus) {
                    showAddItemSheet = true
                }
            }
            .padding(.top, 4)
        }
    }

    private var reviewSaucesSection: some View {
        NNCard(padding: .none) {
            VStack(spacing: 0) {
                Button {
                    withAnimation(reduceMotion ? nil : NNMotion.easeStandard(duration: NNMotion.durBase)) {
                        isSaucesExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text("Sauces, oils & seasonings")
                            .nnTextStyle(.headline)
                            .foregroundStyle(NNColor.textPrimary)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        Text(
                            NNFormatting.extrasSummary(
                                count: draft.includedSauceCount,
                                addedKcal: draft.includedSauceKcal
                            )
                        )
                        .nnTextStyle(.numSm)
                        .foregroundStyle(NNColor.textSecondary)

                        NNIconView(
                            isSaucesExpanded ? .caretUp : .caretDown,
                            size: 13,
                            weight: .bold,
                            color: NNColor.textTertiary
                        )
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, NNSpacing.s4)
                    .frame(minHeight: 56)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sauces, oils and seasonings")

                if isSaucesExpanded {
                    Rectangle()
                        .fill(NNColor.borderHairline)
                        .frame(height: 1)
                        .padding(.horizontal, NNSpacing.s4)

                    VStack(spacing: 0) {
                        ForEach(draft.sauces) { sauce in
                            NNCheckbox(
                                isChecked: bindingForSauce(id: sauce.id),
                                label: sauce.name,
                                description: sauce.estimatedGrams.map { "~\(NNFormatting.grams($0))" },
                                trailing: "+\(NNFormatting.kcal(sauce.nutrition.caloriesKcal))",
                                dimUnchecked: true
                            )
                        }
                    }
                    .padding(.horizontal, NNSpacing.s4)
                    .padding(.vertical, NNSpacing.s2)
                    .transition(.opacity)
                }
            }
        }
    }

    private var saveFooterBar: some View {
        VStack(spacing: 0) {
            NNButton(
                NNFormatting.saveButtonTitle(kcal: draft.totalNutrition.caloriesKcal),
                variant: .accent,
                size: .lg,
                fullWidth: true,
                loading: isSaving,
                action: {
                    Task {
                        await saveMeal()
                    }
                }
            )
            .disabled(!canSave)
        }
        .padding(.horizontal, NNSpacing.screenMargin)
        .padding(.top, NNSpacing.s3)
        .padding(.bottom, NNSpacing.s4)
        .background(NNColor.bgApp)
    }

    // MARK: - State Mutations

    private func updateMultiplier(for id: UUID, multiplier: Double) {
        guard let idx = draft.items.firstIndex(where: { $0.id == id }) else { return }
        draft.items[idx].portionMultiplier = multiplier
    }

    private func removeItem(id: UUID) {
        withAnimation(reduceMotion ? nil : NNMotion.easeStandard(duration: NNMotion.durBase)) {
            draft.items.removeAll { $0.id == id }
            if expandedItemID == id {
                expandedItemID = nil
            }
        }
    }

    private func bindingForSauce(id: UUID) -> Binding<Bool> {
        Binding(
            get: {
                draft.sauces.first(where: { $0.id == id })?.isIncluded ?? false
            },
            set: { newValue in
                guard let idx = draft.sauces.firstIndex(where: { $0.id == id }) else { return }
                draft.sauces[idx].isIncluded = newValue
            }
        )
    }

    private func saveMeal() async {
        guard !isSaving, canSave else { return }
        isSaving = true
        saveErrorMessage = nil
        defer { isSaving = false }

        let meal = draft.toMeal(localDate: store.selectedLocalDate, eatenAt: Date())
        if let photoData = draft.photoJPEGData {
            AppPhotoStorage.savePhoto(photoData, forMealId: meal.id)
        }

        do {
            try await store.logMeal(meal)
            Task {
                if store.isSignedIn && !store.isOffline {
                    _ = try? await store.syncNow()
                }
            }
            onSaved(meal)
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

// MARK: - Add Missing Item Sheet

private struct ReviewAddItemSheet: View {
    let store: NomNomAppStore
    let onAdd: (ReviewItemDraft) -> Void
    let onClose: () -> Void

    @State private var query: String = ""
    @State private var results: [FoodItem] = []

    var body: some View {
        VStack(spacing: 0) {
            NNSheetHeader(title: "Add missing item", showGrabber: true) {
                NNIconButton(icon: .close, label: "Close", variant: .filled, size: 36, action: onClose)
            }
            .padding(.top, NNSpacing.s3)
            .padding(.horizontal, NNSpacing.screenMargin)

            ScrollView {
                VStack(alignment: .leading, spacing: NNSpacing.s4) {
                    NNTextField(
                        "Search foods",
                        text: $query,
                        icon: .search,
                        clearable: true,
                        surface: .card
                    )

                    if results.isEmpty {
                        Text("No matching foods found in your catalog.")
                            .nnTextStyle(.subhead)
                            .foregroundStyle(NNColor.textSecondary)
                            .padding(.horizontal, 4)
                    } else {
                        NNCard(padding: .none) {
                            VStack(spacing: 0) {
                                ForEach(Array(results.enumerated()), id: \.element.id) { index, food in
                                    let serving = food.servingOptions.first(where: \.isDefault)
                                        ?? food.servingOptions.first
                                        ?? ServingOption(label: "100 g", gramWeight: 100, isDefault: true)
                                    let nutrition = food.nutrition(for: serving, quantity: 1.0)
                                    NNListRow(
                                        title: food.name,
                                        subtitle: NNFormatting.metadataLine(food.brand, serving.label),
                                        value: NNFormatting.kcalWithUnit(nutrition.caloriesKcal),
                                        monospacedValue: true,
                                        chevron: true,
                                        showSeparator: index > 0,
                                        action: {
                                            let item = ReviewItemDraft(
                                                displayName: food.name,
                                                servingLabel: serving.label,
                                                gramWeight: serving.gramWeight,
                                                portionMultiplier: 1.0,
                                                confidence: 1.0,
                                                baseNutrition: nutrition
                                            )
                                            onAdd(item)
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, NNSpacing.screenMargin)
                .padding(.vertical, NNSpacing.s3)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(NNColor.bgApp.ignoresSafeArea())
        .task(id: query) {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                try? await Task.sleep(for: .milliseconds(180))
                guard !Task.isCancelled else { return }
            }
            if let matches = try? await store.searchFoods(trimmed) {
                guard !Task.isCancelled else { return }
                results = matches
            }
        }
    }
}
