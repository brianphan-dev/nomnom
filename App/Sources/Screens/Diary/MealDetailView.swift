import Foundation
import SwiftUI
import UIKit
import NomNomCore
import NomNomDesignSystem
import NomNomShared

public struct MealDetailView: View {
    public let store: NomNomAppStore
    public let meal: Meal
    public let embedded: Bool
    public let showCloseButton: Bool
    public let onClose: () -> Void
    public let onDeleted: () -> Void

    @State private var photoData: Data?
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteErrorMessage: String?

    public init(
        store: NomNomAppStore,
        meal: Meal,
        embedded: Bool = false,
        showCloseButton: Bool = true,
        onClose: @escaping () -> Void,
        onDeleted: @escaping () -> Void
    ) {
        self.store = store
        self.meal = meal
        self.embedded = embedded
        self.showCloseButton = showCloseButton
        self.onClose = onClose
        self.onDeleted = onDeleted
    }

    private var isPending: Bool {
        meal.aiStatus == .pending
    }

    private var totals: NutritionSnapshot {
        meal.totalNutrition
    }

    private var shouldShowPhoto: Bool {
        photoData != nil || meal.captureMethod == .photoAI || isPending
    }

    private var formattedTime: String {
        meal.eatenAt.formatted(date: .omitted, time: .shortened)
    }

    public var body: some View {
        VStack(spacing: 0) {
            NNNavBar(
                largeTitle: meal.title,
                subtitle: NNFormatting.metadataLine(meal.mealType.displayName, formattedTime),
                leading: {
                    if showCloseButton {
                        NNIconButton(
                            icon: .close,
                            label: "Close",
                            variant: .filled,
                            size: 36,
                            iconSize: 16,
                            weight: .bold,
                            action: onClose
                        )
                    }
                },
                trailing: {
                    if isPending {
                        NNBadge("Pending AI analysis", tone: .pending, icon: .pending)
                    } else {
                        NNBadge(method: meal.captureMethod.nnLoggingMethod)
                    }
                }
            )
            .padding(.top, NNSpacing.s2)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: NNSpacing.s4) {
                    if shouldShowPhoto {
                        NNMealPhoto(
                            imageData: photoData,
                            size: nil,
                            cornerRadius: NNRadius.card,
                            label: photoData == nil ? "Meal photo" : nil,
                            tone: .light,
                            dashedBorder: isPending
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: embedded ? 148 : 196)
                        .clipShape(RoundedRectangle(cornerRadius: NNRadius.card, style: .continuous))
                    }

                    if isPending {
                        NNBanner(
                            tone: .neutral,
                            icon: .cloudOffline,
                            title: "Saved on this device",
                            message: "We'll analyse this photo as soon as you're back online. Nothing else to do."
                        )
                    } else {
                        nutritionSummaryCard
                        itemsBreakdownSection

                        if !microValues.isEmpty {
                            micronutrientsSection
                        }
                    }

                    if let notes = meal.notes?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !notes.isEmpty
                    {
                        notesSection(notes)
                    }

                    if let deleteErrorMessage, !deleteErrorMessage.isEmpty {
                        NNBanner(
                            tone: .check,
                            icon: .info,
                            title: "Could not delete meal",
                            message: deleteErrorMessage
                        )
                    }

                    NNButton(
                        "Delete meal",
                        variant: .destructive,
                        size: .md,
                        icon: .trash,
                        fullWidth: true,
                        loading: isDeleting
                    ) {
                        showDeleteConfirmation = true
                    }
                    .padding(.top, NNSpacing.s2)
                }
                .padding(.horizontal, NNSpacing.screenMargin)
                .padding(.top, NNSpacing.s4)
                .padding(.bottom, NNSpacing.s8)
            }
        }
        .background(NNColor.bgApp.ignoresSafeArea())
        .task(id: meal.id) {
            loadMealPhoto()
        }
        .nnDialog(
            isPresented: $showDeleteConfirmation,
            title: "Delete this meal?",
            message: "This removes \"\(meal.title)\" from your diary on this device and across sync.",
            actions: [
                NNDialogAction(label: "Delete meal", variant: .destructive) {
                    confirmDelete()
                },
                NNDialogAction(label: "Cancel", variant: .secondary) {
                    showDeleteConfirmation = false
                },
            ]
        )
    }

    // MARK: - Sections

    private var nutritionSummaryCard: some View {
        NNCard {
            VStack(alignment: .leading, spacing: NNSpacing.s4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(NNFormatting.kcal(totals.caloriesKcal))
                        .nnTextStyle(.numLg)
                        .foregroundStyle(NNColor.textPrimary)
                    Text("kcal")
                        .nnTextStyle(.subhead)
                        .foregroundStyle(NNColor.textSecondary)
                }

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

    private var itemsBreakdownSection: some View {
        VStack(alignment: .leading, spacing: NNSpacing.s2) {
            HStack {
                Text("Items")
                    .nnOverlineStyle()
                Spacer()
                if !meal.items.isEmpty {
                    Text("\(meal.items.count)")
                        .nnOverlineStyle()
                }
            }
            .padding(.horizontal, NNSpacing.s1)

            NNCard(padding: .none) {
                if meal.items.isEmpty {
                    Text("No itemized breakdown recorded.")
                        .nnTextStyle(.subhead)
                        .foregroundStyle(NNColor.textSecondary)
                        .padding(NNSpacing.s4)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(meal.items.enumerated()), id: \.element.id) { index, item in
                            itemRow(item, showSeparator: index > 0)
                        }
                    }
                }
            }
        }
    }

    private func itemRow(_ item: MealEntryItem, showSeparator: Bool) -> some View {
        let scaledBaseKcal = item.nutrition.scaled(by: item.portionMultiplier).caloriesKcal
        let hasCustomMultiplier = abs(item.portionMultiplier - 1.0) > 0.001
        let includedExtras = item.ingredients.filter { $0.isOptionalEstimate && $0.isIncluded }

        return VStack(alignment: .leading, spacing: 0) {
            if showSeparator {
                Rectangle()
                    .fill(NNColor.borderHairline)
                    .frame(height: 1)
                    .padding(.horizontal, NNSpacing.s4)
            }

            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayName)
                        .font(NNFont.sans(size: 16, weight: .medium, relativeTo: .callout))
                        .tracking(-0.01 * 16)
                        .foregroundStyle(NNColor.textPrimary)

                    let subtitle = itemSubtitle(for: item)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .nnTextStyle(.footnote)
                            .foregroundStyle(NNColor.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if hasCustomMultiplier {
                    Text(NNFormatting.multiplier(item.portionMultiplier))
                        .font(NNFont.mono(size: 12, weight: .medium, relativeTo: .caption))
                        .foregroundStyle(NNColor.accentText)
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                        .background(NNColor.accentSoft, in: Capsule())
                }

                VStack(alignment: .trailing, spacing: 0) {
                    Text(NNFormatting.kcal(scaledBaseKcal))
                        .nnTextStyle(.numSm)
                        .foregroundStyle(NNColor.textPrimary)
                    Text("kcal")
                        .font(NNFont.sans(size: 11, weight: .regular, relativeTo: .caption2))
                        .foregroundStyle(NNColor.textTertiary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, NNSpacing.s4)

            if !includedExtras.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sauces and oils")
                        .nnOverlineStyle()

                    ForEach(includedExtras) { extra in
                        HStack(spacing: 8) {
                            Text(extraLabel(for: extra))
                                .nnTextStyle(.footnote)
                                .foregroundStyle(NNColor.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("+\(NNFormatting.kcalWithUnit(extra.nutrition.caloriesKcal))")
                                .nnTextStyle(.numXs)
                                .foregroundStyle(NNColor.textSecondary)
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    NNColor.fill1,
                    in: RoundedRectangle(cornerRadius: NNRadius.r16, style: .continuous)
                )
                .padding(.horizontal, NNSpacing.s4)
                .padding(.bottom, NNSpacing.s3)
            }
        }
    }

    private var micronutrientsSection: some View {
        VStack(alignment: .leading, spacing: NNSpacing.s2) {
            Text("Nutrients")
                .nnOverlineStyle()
                .padding(.horizontal, NNSpacing.s1)

            NNCard {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14),
                    ],
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(microValues) { micro in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(micro.label)
                                .nnTextStyle(.footnote)
                                .foregroundStyle(NNColor.textSecondary)
                            Text(micro.value)
                                .nnTextStyle(.numSm)
                                .foregroundStyle(NNColor.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: NNSpacing.s2) {
            Text("Notes")
                .nnOverlineStyle()
                .padding(.horizontal, NNSpacing.s1)

            NNCard {
                Text(notes)
                    .nnTextStyle(.subhead)
                    .foregroundStyle(NNColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Formatting & Actions

    private func itemSubtitle(for item: MealEntryItem) -> String {
        let gramsPart: String? = item.gramWeight.map { grams in
            NNFormatting.grams(grams * item.portionMultiplier)
        }
        return NNFormatting.metadataLine(item.brand, item.servingLabel, gramsPart)
    }

    private func extraLabel(for extra: IngredientEstimate) -> String {
        let gramsPart = extra.estimatedGrams.map { NNFormatting.grams($0) }
        return NNFormatting.metadataLine(extra.name, gramsPart)
    }

    private var microValues: [NNMicroValue] {
        var list: [NNMicroValue] = []
        if let fiber = totals.fiberG {
            list.append(NNMicroValue(label: "Fiber", value: NNFormatting.grams(fiber)))
        }
        if let sugar = totals.sugarG {
            list.append(NNMicroValue(label: "Sugar", value: NNFormatting.grams(sugar)))
        }
        if let sodium = totals.sodiumMg {
            list.append(NNMicroValue(label: "Sodium", value: "\(NNFormatting.kcal(sodium)) mg"))
        }
        if let satFat = totals.saturatedFatG {
            list.append(NNMicroValue(label: "Sat. fat", value: NNFormatting.grams(satFat)))
        }
        if let potassium = totals.potassiumMg {
            list.append(NNMicroValue(label: "Potassium", value: "\(NNFormatting.kcal(potassium)) mg"))
        }
        if let iron = totals.ironMg {
            list.append(NNMicroValue(label: "Iron", value: "\(NNFormatting.kcal(iron)) mg"))
        }
        return list
    }

    private func loadMealPhoto() {
        if let image = AppPhotoStorage.loadUIImage(forMealId: meal.id) {
            photoData = image.jpegData(compressionQuality: 0.9)
        } else {
            photoData = nil
        }
    }

    private func confirmDelete() {
        guard !isDeleting else { return }
        showDeleteConfirmation = false
        isDeleting = true
        deleteErrorMessage = nil

        Task {
            defer { isDeleting = false }
            do {
                try await store.deleteMeal(id: meal.id)
                AppPhotoStorage.deletePhoto(forMealId: meal.id)
                if store.isSignedIn, !store.isOffline {
                    Task {
                        _ = try? await store.syncNow()
                    }
                }
                onDeleted()
            } catch {
                deleteErrorMessage = error.localizedDescription
            }
        }
    }
}
