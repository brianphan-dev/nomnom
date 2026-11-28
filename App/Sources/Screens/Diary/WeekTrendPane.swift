import Foundation
import SwiftUI
import NomNomCore
import NomNomDesignSystem

public struct WeekTrendPane: View {
    public let store: NomNomAppStore

    public init(store: NomNomAppStore) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            NNNavBar(
                largeTitle: "This week",
                subtitle: dateRangeSubtitle
            )
            .padding(.top, NNSpacing.s2)

            ScrollView(showsIndicators: false) {
                NNWeekTrend(
                    dateRange: dateRangeSubtitle,
                    days: weekDayPoints,
                    targetKcal: Double(store.targets.caloriesKcal),
                    averageProtein: NNMacroProgress(
                        value: macroAverages.protein,
                        target: Double(store.targets.proteinG)
                    ),
                    averageCarbs: NNMacroProgress(
                        value: macroAverages.carbs,
                        target: Double(store.targets.carbsG)
                    ),
                    averageFat: NNMacroProgress(
                        value: macroAverages.fat,
                        target: Double(store.targets.fatG)
                    ),
                    showHeader: false,
                    helperNote: "Tap a meal on the left to see its breakdown here."
                )
                .padding(.horizontal, NNSpacing.screenMargin)
                .padding(.top, NNSpacing.s4)
                .padding(.bottom, NNSpacing.s8)
            }
        }
        .background(NNColor.bgApp.ignoresSafeArea())
    }

    // MARK: - Derived 7-Day Trend Data

    private var effectivePoints: [DayCaloriePoint] {
        if !store.weekCalories.isEmpty {
            return store.weekCalories
        }

        let calendar = Calendar.current
        let anchorStart = calendar.startOfDay(for: store.selectedDate)
        return (-6...0).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: anchorStart) else {
                return nil
            }
            return DayCaloriePoint(
                localDate: NomNomAppStore.localDateString(for: date),
                date: date,
                caloriesKcal: 0,
                proteinG: 0,
                carbsG: 0,
                fatG: 0,
                mealCount: 0
            )
        }
    }

    private var weekDayPoints: [NNWeekDayPoint] {
        let points = effectivePoints
        let lastIndex = points.count - 1
        return points.enumerated().map { index, point in
            NNWeekDayPoint(
                id: point.localDate,
                label: point.date.formatted(.dateTime.weekday(.abbreviated)),
                kcal: point.caloriesKcal,
                isToday: index == lastIndex
            )
        }
    }

    private var macroAverages: (protein: Double, carbs: Double, fat: Double) {
        let points = effectivePoints
        let priorCompleted = points.dropLast().filter { $0.mealCount > 0 }
        let loggedAny = points.filter { $0.mealCount > 0 }
        let sample = priorCompleted.isEmpty ? loggedAny : Array(priorCompleted)
        guard !sample.isEmpty else {
            return (0, 0, 0)
        }

        let divisor = Double(sample.count)
        let protein = sample.reduce(0.0) { $0 + $1.proteinG } / divisor
        let carbs = sample.reduce(0.0) { $0 + $1.carbsG } / divisor
        let fat = sample.reduce(0.0) { $0 + $1.fatG } / divisor
        return (protein, carbs, fat)
    }

    private var dateRangeSubtitle: String? {
        guard let first = effectivePoints.first?.date,
              let last = effectivePoints.last?.date
        else {
            return nil
        }

        let calendar = Calendar.current
        let firstMonth = calendar.component(.month, from: first)
        let lastMonth = calendar.component(.month, from: last)
        let firstDay = calendar.component(.day, from: first)
        let lastDay = calendar.component(.day, from: last)

        if firstMonth == lastMonth {
            let monthName = last.formatted(.dateTime.month(.wide))
            return "\(firstDay) \u{2013} \(lastDay) \(monthName)"
        }

        let startLabel = first.formatted(.dateTime.day().month(.abbreviated))
        let endLabel = last.formatted(.dateTime.day().month(.abbreviated))
        return "\(startLabel) \u{2013} \(endLabel)"
    }
}
