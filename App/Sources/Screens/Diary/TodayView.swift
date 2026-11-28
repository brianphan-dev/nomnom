import Foundation
import SwiftUI
import UIKit
import NomNomCore
import NomNomDesignSystem
import NomNomShared

public struct TodayView: View {
    public let store: NomNomAppStore
    public let selectedMealId: UUID?
    public let onSelectMeal: (Meal) -> Void
    public let onOpenCapture: (CaptureMode) -> Void
    public let onOpenSettings: () -> Void
    public let onOpenImport: () -> Void

    @Environment(\.nnLayoutClass) private var layoutClass
    @State private var showDatePicker = false
    @State private var mealPhotoData: [UUID: Data] = [:]

    public init(
        store: NomNomAppStore,
        selectedMealId: UUID? = nil,
        onSelectMeal: @escaping (Meal) -> Void,
        onOpenCapture: @escaping (CaptureMode) -> Void,
        onOpenSettings: @escaping () -> Void,
        onOpenImport: @escaping () -> Void
    ) {
        self.store = store
        self.selectedMealId = selectedMealId
        self.onSelectMeal = onSelectMeal
        self.onOpenCapture = onOpenCapture
        self.onOpenSettings = onOpenSettings
        self.onOpenImport = onOpenImport
    }

    private var sortedMeals: [Meal] {
        store.todayMeals.sorted { $0.eatenAt > $1.eatenAt }
    }

    public var body: some View {
        VStack(spacing: 0) {
            NNNavBar(
                largeTitle: headerTitle,
                subtitle: layoutClass.isCompactCover ? nil : headerSubtitle,
                leading: {
                    NNSyncPill(status: mapSyncStatus(from: store)) {
                        Task {
                            _ = try? await store.syncNow()
                        }
                    }
                },
                trailing: {
                    NNIconButton(
                        icon: .calendar,
                        label: "Pick a date",
                        variant: .filled,
                        size: 36
                    ) {
                        showDatePicker = true
                    }

                    NNIconButton(
                        icon: .settings,
                        label: "Settings",
                        variant: .filled,
                        size: 36,
                        action: onOpenSettings
                    )
                }
            )
            .padding(.top, NNSpacing.s2)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: NNSpacing.s4) {
                    NNDailySummary(
                        kcal: store.todayTotals.caloriesKcal,
                        target: Double(store.targets.caloriesKcal),
                        protein: NNMacroProgress(
                            value: store.todayTotals.proteinG,
                            target: Double(store.targets.proteinG)
                        ),
                        carbs: NNMacroProgress(
                            value: store.todayTotals.carbsG,
                            target: Double(store.targets.carbsG)
                        ),
                        fat: NNMacroProgress(
                            value: store.todayTotals.fatG,
                            target: Double(store.targets.fatG)
                        ),
                        micros: dailyMicros,
                        compact: layoutClass.isCompactCover
                    )

                    mealsSection
                }
                .padding(.horizontal, NNSpacing.screenMargin)
                .padding(.top, NNSpacing.s4)
                .padding(.bottom, layoutClass.isCompactCover ? 116 : 140)
            }
            .refreshable {
                guard store.isSignedIn, !store.isOffline else { return }
                _ = try? await store.syncNow()
            }
        }
        .background(NNColor.bgApp.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            VStack(spacing: NNSpacing.s2) {
                if let remaining = store.quotaRemaining, remaining <= 3 {
                    quotaPill(remaining: remaining)
                }

                NNCaptureDock(
                    compact: layoutClass.isCompactCover,
                    onBarcode: { onOpenCapture(.barcode) },
                    onSnap: { onOpenCapture(.photo) },
                    onManual: { onOpenCapture(.manual) }
                )
            }
            .padding(.horizontal, NNSpacing.screenMargin)
            .padding(.bottom, layoutClass.isCompactCover ? NNSpacing.s5 : NNSpacing.dockBottomOffset)
        }
        .task(id: sortedMeals.map(\.id)) {
            await loadMealPhotos(for: sortedMeals)
        }
        .sheet(isPresented: $showDatePicker) {
            DiaryDatePickerSheet(
                selectedDate: store.selectedDate,
                onSelectDate: { date in
                    showDatePicker = false
                    Task {
                        try? await store.selectDate(date)
                    }
                },
                onClose: {
                    showDatePicker = false
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Meals Section

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: NNSpacing.s2) {
            HStack(alignment: .firstTextBaseline) {
                Text("Meals")
                    .nnOverlineStyle()
                Spacer()
                if !sortedMeals.isEmpty {
                    Text("\(sortedMeals.count) logged")
                        .nnOverlineStyle()
                }
            }
            .padding(.horizontal, NNSpacing.s1)

            if sortedMeals.isEmpty {
                NNCard(tone: .outline, padding: .lg) {
                    VStack(alignment: .leading, spacing: NNSpacing.s2) {
                        Text("Nothing logged yet")
                            .nnTextStyle(.title2)
                            .foregroundStyle(NNColor.textPrimary)

                        Text("Tap the shutter below to photograph a meal, scan a barcode, or search.")
                            .nnTextStyle(.subhead)
                            .foregroundStyle(NNColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        NNButton(
                            "Import history",
                            variant: .secondary,
                            size: .sm,
                            icon: .importHistory,
                            action: onOpenImport
                        )
                        .padding(.top, NNSpacing.s2)
                    }
                }
            } else {
                NNCard(padding: .custom(NNSpacing.s2)) {
                    VStack(spacing: 0) {
                        ForEach(sortedMeals) { meal in
                            let isPending = meal.aiStatus == .pending
                            let totals = meal.totalNutrition
                            NNMealRow(
                                title: meal.title,
                                mealType: meal.mealType.displayName,
                                time: meal.eatenAt.formatted(date: .omitted, time: .shortened),
                                kcal: totals.caloriesKcal,
                                protein: isPending ? nil : totals.proteinG,
                                carbs: isPending ? nil : totals.carbsG,
                                fat: isPending ? nil : totals.fatG,
                                method: meal.captureMethod.nnLoggingMethod,
                                photoData: mealPhotoData[meal.id],
                                pending: isPending,
                                selected: layoutClass.isDualPane && selectedMealId == meal.id,
                                onTap: { onSelectMeal(meal) }
                            )
                        }
                    }
                }
            }
        }
    }

    private func quotaPill(remaining: Int) -> some View {
        let label = remaining == 1
            ? "1 photo scan left today"
            : "\(remaining) photo scans left today"

        return HStack(spacing: 6) {
            NNIconView(.sparkle, size: 12, weight: .bold, color: NNColor.textSecondary)
            Text(label)
                .nnTextStyle(.caption)
                .foregroundStyle(NNColor.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(NNColor.surfaceChrome))
        }
    }

    // MARK: - Date & Nutrient Formatting

    private var headerTitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(store.selectedDate) {
            return "Today"
        }
        if calendar.isDateInYesterday(store.selectedDate) {
            return "Yesterday"
        }
        if calendar.isDateInTomorrow(store.selectedDate) {
            return "Tomorrow"
        }
        return store.selectedDate.formatted(
            .dateTime.weekday(.abbreviated).month(.abbreviated).day()
        )
    }

    private var headerSubtitle: String {
        store.selectedDate.formatted(
            .dateTime.weekday(.wide).month(.wide).day()
        )
    }

    private var dailyMicros: [NNMicroValue] {
        guard !sortedMeals.isEmpty else { return [] }
        let totals = store.todayTotals
        var values: [NNMicroValue] = []

        if let fiber = totals.fiberG {
            values.append(NNMicroValue(label: "Fiber", value: NNFormatting.grams(fiber)))
        }
        if let sugar = totals.sugarG {
            values.append(NNMicroValue(label: "Sugar", value: NNFormatting.grams(sugar)))
        }
        if let sodium = totals.sodiumMg {
            values.append(NNMicroValue(label: "Sodium", value: "\(NNFormatting.kcal(sodium)) mg"))
        }
        if let satFat = totals.saturatedFatG {
            values.append(NNMicroValue(label: "Sat. fat", value: NNFormatting.grams(satFat)))
        }
        if let potassium = totals.potassiumMg {
            values.append(NNMicroValue(label: "Potassium", value: "\(NNFormatting.kcal(potassium)) mg"))
        }
        if let iron = totals.ironMg {
            values.append(NNMicroValue(label: "Iron", value: "\(NNFormatting.kcal(iron)) mg"))
        }

        return values
    }

    @MainActor
    private func loadMealPhotos(for meals: [Meal]) async {
        let activeIDs = Set(meals.map(\.id))
        var updated = mealPhotoData.filter { activeIDs.contains($0.key) }

        for meal in meals where updated[meal.id] == nil {
            if let image = AppPhotoStorage.loadUIImage(forMealId: meal.id),
               let data = image.jpegData(compressionQuality: 0.85)
            {
                updated[meal.id] = data
            }
        }

        mealPhotoData = updated
    }
}

// MARK: - Calendar Date Picker Sheet

private struct DiaryDatePickerSheet: View {
    @State private var draftDate: Date
    let onSelectDate: (Date) -> Void
    let onClose: () -> Void

    init(
        selectedDate: Date,
        onSelectDate: @escaping (Date) -> Void,
        onClose: @escaping () -> Void
    ) {
        self._draftDate = State(initialValue: selectedDate)
        self.onSelectDate = onSelectDate
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NNSpacing.s4) {
            NNSheetHeader(title: "Choose a date") {
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

            HStack(spacing: NNSpacing.s2) {
                NNButton("Previous day", variant: .secondary, size: .sm, fullWidth: true) {
                    if let prev = Calendar.current.date(byAdding: .day, value: -1, to: draftDate) {
                        draftDate = prev
                        onSelectDate(prev)
                    }
                }

                NNButton("Today", variant: .secondary, size: .sm) {
                    let today = Date()
                    draftDate = today
                    onSelectDate(today)
                }

                NNButton("Next day", variant: .secondary, size: .sm, fullWidth: true) {
                    if let next = Calendar.current.date(byAdding: .day, value: 1, to: draftDate) {
                        draftDate = next
                        onSelectDate(next)
                    }
                }
            }

            NNCard(padding: .md) {
                DatePicker(
                    "Diary date",
                    selection: $draftDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(NNColor.ink)
                .labelsHidden()
            }

            NNButton("View day", variant: .primary, size: .md, fullWidth: true) {
                onSelectDate(draftDate)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, NNSpacing.s3)
        .padding(.horizontal, NNSpacing.screenMargin)
        .padding(.bottom, NNSpacing.s5)
        .background(NNColor.bgApp.ignoresSafeArea())
    }
}
