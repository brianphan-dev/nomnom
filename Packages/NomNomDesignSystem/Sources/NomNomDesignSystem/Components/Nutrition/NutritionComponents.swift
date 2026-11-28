import CoreGraphics
import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - NNMealPhoto

/// Background tone for `NNMealPhoto` placeholder stripes (`.light` on cards, `.dark` over camera viewfinder).
public enum NNMealPhotoTone: Sendable, Hashable {
    case light
    case dark
}

/// Meal photo display or 135° striped mono placeholder matching `design-system/components/nutrition/MealPhoto.jsx`.
public struct NNMealPhoto: View {
    public let imageData: Data?
    public let cgImage: CGImage?
    public let size: CGFloat?
    public let cornerRadius: CGFloat
    public let label: String?
    public let tone: NNMealPhotoTone
    public let dashedBorder: Bool
    public let accessibilityLabel: String

    public init(
        imageData: Data? = nil,
        cgImage: CGImage? = nil,
        size: CGFloat? = 56,
        cornerRadius: CGFloat = NNRadius.thumb,
        label: String? = nil,
        tone: NNMealPhotoTone = .light,
        dashedBorder: Bool = false,
        accessibilityLabel: String? = nil
    ) {
        self.imageData = imageData
        self.cgImage = cgImage
        self.size = size
        self.cornerRadius = cornerRadius
        self.label = label
        self.tone = tone
        self.dashedBorder = dashedBorder
        self.accessibilityLabel = accessibilityLabel ?? label ?? "Meal photo"
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let iconDimension: CGFloat = {
            let reference = size ?? 96
            return min(32, max(18, (reference * 0.36).rounded()))
        }()

        ZStack {
            if let image = decodedImage {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderStripes
                VStack(spacing: 6) {
                    NNIconView(.image, size: iconDimension, weight: .regular, color: placeholderForeground)
                    if let label, !label.isEmpty {
                        Text(label)
                            .nnTextStyle(.overline)
                            .foregroundStyle(placeholderForeground)
                            .lineLimit(1)
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .overlay {
            if dashedBorder {
                shape
                    .inset(by: 0.75)
                    .stroke(
                        NNColor.borderStrong,
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isImage)
    }

    private var placeholderForeground: Color {
        tone == .dark ? Color.white.opacity(0.6) : NNColor.textTertiary
    }

    @ViewBuilder
    private var placeholderStripes: some View {
        ZStack {
            if tone == .dark {
                NNColor.viewfinder
            } else {
                NNColor.fill1
            }

            Canvas { context, canvasSize in
                let stripePeriod: CGFloat = 9.0
                let strokeColor: Color = tone == .dark ? Color.white.opacity(0.09) : NNColor.fill2
                let maxExtent = canvasSize.width + canvasSize.height
                var offset: CGFloat = -canvasSize.height
                while offset <= maxExtent {
                    var path = Path()
                    path.move(to: CGPoint(x: offset, y: 0))
                    path.addLine(to: CGPoint(x: offset + canvasSize.height, y: canvasSize.height))
                    context.stroke(path, with: .color(strokeColor), lineWidth: 1.0)
                    offset += stripePeriod
                }
            }
        }
    }

    private var decodedImage: Image? {
        if let cgImage {
            return Image(decorative: cgImage, scale: 1.0)
        }
        guard let imageData else { return nil }
        #if canImport(UIKit)
        guard let uiImage = UIImage(data: imageData) else { return nil }
        return Image(uiImage: uiImage)
        #elseif canImport(AppKit)
        guard let nsImage = NSImage(data: imageData) else { return nil }
        return Image(nsImage: nsImage)
        #else
        return nil
        #endif
    }
}

// MARK: - NNMacroLine

/// Text size presets for compact inline macro lines.
public enum NNMacroLineSize: Sendable, Hashable {
    case sm
    case md

    public var fontSize: CGFloat {
        self == .md ? 15 : 13
    }

    public var gap: CGFloat {
        self == .md ? 14 : 10
    }
}

/// Inline colored-letter macro summary (`P38 C58 F24`) matching `design-system/components/nutrition/MacroLine.jsx`.
public struct NNMacroLine: View {
    public let protein: Double?
    public let carbs: Double?
    public let fat: Double?
    public let size: NNMacroLineSize

    public init(
        protein: Double?,
        carbs: Double?,
        fat: Double?,
        size: NNMacroLineSize = .sm
    ) {
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.size = size
    }

    public var body: some View {
        HStack(spacing: size.gap) {
            macroItem(letter: "P", value: protein, color: NNColor.macroProteinText)
            macroItem(letter: "C", value: carbs, color: NNColor.macroCarbsText)
            macroItem(letter: "F", value: fat, color: NNColor.macroFatText)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Protein \(formattedValue(protein)), Carbs \(formattedValue(carbs)), Fat \(formattedValue(fat))"
        )
    }

    private func macroItem(letter: String, value: Double?, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(letter)
                .font(NNFont.mono(size: size.fontSize, weight: .semibold, relativeTo: .footnote))
                .foregroundStyle(color)
            Text(formattedValue(value))
                .font(NNFont.mono(size: size.fontSize, weight: .medium, relativeTo: .footnote))
                .tracking(-0.02 * size.fontSize)
                .foregroundStyle(NNColor.textPrimary)
        }
        .lineLimit(1)
    }

    private func formattedValue(_ value: Double?) -> String {
        guard let value else { return "–" }
        return String(Int(value.rounded()))
    }
}

// MARK: - NNMacroBar

/// Macronutrient category mapping label and color token (Protein=blueberry, Carbs=matcha, Fat=plum).
public enum NNMacroKind: String, Sendable, Hashable, CaseIterable {
    case protein
    case carbs
    case fat

    public var defaultLabel: String {
        switch self {
        case .protein: "Protein"
        case .carbs: "Carbs"
        case .fat: "Fat"
        }
    }

    public var progressTone: NNProgressTone {
        switch self {
        case .protein: .protein
        case .carbs: .carbs
        case .fat: .fat
        }
    }
}

/// Macro label + tabular gram count + progress bar matching `design-system/components/nutrition/MacroBar.jsx`.
public struct NNMacroBar: View {
    public let macro: NNMacroKind
    public let value: Double
    public let target: Double?
    public let label: String?
    public let compact: Bool

    public init(
        macro: NNMacroKind,
        value: Double,
        target: Double? = nil,
        label: String? = nil,
        compact: Bool = false
    ) {
        self.macro = macro
        self.value = value
        self.target = target
        self.label = label
        self.compact = compact
    }

    private var resolvedLabel: String {
        label ?? macro.defaultLabel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if compact {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(resolvedLabel)
                        .nnTextStyle(.footnote)
                        .foregroundStyle(NNColor.textSecondary)
                        .lineLimit(1)
                    Spacer(minLength: 2)
                    valueText(compact: true)
                        .lineLimit(1)
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text(resolvedLabel)
                        .nnTextStyle(.footnote)
                        .foregroundStyle(NNColor.textSecondary)
                        .lineLimit(1)
                    valueText(compact: false)
                        .lineLimit(1)
                }
            }

            NNProgressBar(
                value: value,
                max: target ?? (value > 0 ? value : 1),
                tone: macro.progressTone,
                height: 6,
                label: resolvedLabel
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func valueText(compact: Bool) -> Text {
        let primary = Text(String(Int(value.rounded())))
            .font(compact ? NNFont.numSm : NNFont.numMd)
            .foregroundStyle(NNColor.textPrimary)

        let suffixString: String = if let target, target > 0 {
            "/\(Int(target.rounded()))g"
        } else {
            "g"
        }

        let suffix = Text(suffixString)
            .font(NNFont.mono(size: 12, weight: .regular, relativeTo: .caption))
            .foregroundStyle(NNColor.textTertiary)

        return primary + suffix
    }
}

// MARK: - NNDailySummary

/// Micronutrient row rendered inside the expandable daily summary drawer.
public struct NNMicroValue: Identifiable, Sendable, Hashable {
    public let id: String
    public let label: String
    public let value: String

    public init(id: String? = nil, label: String, value: String) {
        self.id = id ?? label
        self.label = label
        self.value = value
    }
}

/// Macro progress pair passed into `NNDailySummary`.
public struct NNMacroProgress: Sendable, Hashable {
    public let value: Double
    public let target: Double?

    public init(value: Double, target: Double? = nil) {
        self.value = value
        self.target = target
    }
}

/// Today's calorie and macro card matching `design-system/components/nutrition/DailySummary.jsx`.
///
/// Going over target is calm and neutral (`"140 over"`). Nothing ever turns red.
/// Pass `compact: true` on iPhone Duo Folded (5.4").
public struct NNDailySummary: View {
    public let kcal: Double
    public let target: Double
    public let protein: NNMacroProgress
    public let carbs: NNMacroProgress
    public let fat: NNMacroProgress
    public let micros: [NNMicroValue]
    public let compact: Bool

    @State private var isExpanded: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        kcal: Double,
        target: Double = 2000,
        protein: NNMacroProgress,
        carbs: NNMacroProgress,
        fat: NNMacroProgress,
        micros: [NNMicroValue] = [],
        defaultExpanded: Bool = false,
        compact: Bool = false
    ) {
        self.kcal = kcal
        self.target = target
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.micros = micros
        self.compact = compact
        self._isExpanded = State(initialValue: defaultExpanded)
    }

    public var body: some View {
        let remaining = NNFormatting.remainingParts(consumed: kcal, target: target)
        let heroSize: CGFloat = compact ? 40 : 56

        NNCard(padding: compact ? .md : .lg) {
            VStack(alignment: .leading, spacing: compact ? 10 : 14) {
                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NNFormatting.kcal(kcal))
                            .font(NNFont.mono(size: heroSize, weight: .medium, relativeTo: .largeTitle))
                            .tracking(-0.05 * heroSize)
                            .foregroundStyle(NNColor.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        if !compact {
                            Text("of \(NNFormatting.kcalWithUnit(target))")
                                .nnTextStyle(.subhead)
                                .foregroundStyle(NNColor.textSecondary)
                        }
                    }

                    Spacer(minLength: 8)

                    (
                        Text(remaining.amount)
                            .font(NNFont.mono(size: 15, weight: .medium, relativeTo: .subheadline))
                            .tracking(-0.02 * 15)
                            .foregroundStyle(NNColor.textPrimary)
                        +
                        Text(remaining.suffix)
                            .font(NNFont.subhead)
                            .foregroundStyle(NNColor.textSecondary)
                    )
                    .lineLimit(1)
                    .padding(.bottom, 1)
                }

                NNProgressBar(
                    value: kcal,
                    max: target,
                    tone: .accent,
                    height: compact ? 8 : 10,
                    label: "Calories"
                )

                HStack(spacing: compact ? 10 : 14) {
                    NNMacroBar(macro: .protein, value: protein.value, target: protein.target, compact: compact)
                    NNMacroBar(macro: .carbs, value: carbs.value, target: carbs.target, compact: compact)
                    NNMacroBar(macro: .fat, value: fat.value, target: fat.target, compact: compact)
                }
                .padding(.top, compact ? 0 : 4)

                if !micros.isEmpty && !compact {
                    if isExpanded {
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(NNColor.borderHairline)
                                .frame(height: 1)
                                .padding(.bottom, 14)

                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 14),
                                    GridItem(.flexible(), spacing: 14),
                                    GridItem(.flexible(), spacing: 14),
                                ],
                                alignment: .leading,
                                spacing: 12
                            ) {
                                ForEach(micros) { micro in
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
                        .transition(.opacity)
                    }

                    HStack {
                        Spacer()
                        Button {
                            withAnimation(reduceMotion ? nil : NNMotion.easeStandard(duration: NNMotion.durBase)) {
                                isExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(isExpanded ? "Fewer nutrients" : "More nutrients")
                                    .font(NNFont.sans(size: 13, weight: .medium, relativeTo: .footnote))
                                    .foregroundStyle(NNColor.textSecondary)
                                NNIconView(
                                    isExpanded ? .caretUp : .caretDown,
                                    size: 11,
                                    weight: .bold,
                                    color: NNColor.textSecondary
                                )
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.top, -4)
                    .padding(.bottom, -8)
                }
            }
        }
    }
}

// MARK: - NNMealRow

/// Logged meal row matching `design-system/components/nutrition/MealRow.jsx`.
///
/// Supports offline pending AI analysis (dashed thumbnail + outlined badge) and Duo unfolded selection (`fill1`).
public struct NNMealRow: View {
    public let title: String
    public let mealType: String?
    public let time: String?
    public let kcal: Double
    public let protein: Double?
    public let carbs: Double?
    public let fat: Double?
    public let method: NNLoggingMethod
    public let photoData: Data?
    public let pending: Bool
    public let selected: Bool
    public let onTap: () -> Void

    public init(
        title: String,
        mealType: String? = nil,
        time: String? = nil,
        kcal: Double = 0,
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil,
        method: NNLoggingMethod = .photoAI,
        photoData: Data? = nil,
        pending: Bool = false,
        selected: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.mealType = mealType
        self.time = time
        self.kcal = kcal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.method = method
        self.photoData = photoData
        self.pending = pending
        self.selected = selected
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                NNMealPhoto(
                    imageData: photoData,
                    size: 56,
                    cornerRadius: NNRadius.thumb,
                    dashedBorder: pending
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .nnTextStyle(.headline)
                        .foregroundStyle(NNColor.textPrimary)
                        .lineLimit(1)

                    let meta = NNFormatting.metadataLine([mealType, time])
                    if !meta.isEmpty {
                        Text(meta)
                            .nnTextStyle(.footnote)
                            .foregroundStyle(NNColor.textSecondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        if pending {
                            NNBadge("Pending AI analysis", tone: .pending, icon: .pending)
                        } else {
                            NNBadge(method: method)
                            NNMacroLine(protein: protein, carbs: carbs, fat: fat, size: .sm)
                        }
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 0) {
                    Text(pending ? "–" : NNFormatting.kcal(kcal))
                        .nnTextStyle(.numMd)
                        .foregroundStyle(NNColor.textPrimary)
                    Text("kcal")
                        .font(NNFont.sans(size: 12, weight: .regular, relativeTo: .caption))
                        .foregroundStyle(NNColor.textTertiary)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .padding(12)
            .background(
                selected ? NNColor.fill1 : .clear,
                in: RoundedRectangle(cornerRadius: NNRadius.r20, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: NNRadius.r20, style: .continuous))
        }
        .buttonStyle(NNPressScaleButtonStyle(scale: 0.985))
    }
}

// MARK: - NNFoodItemRow

/// Expandable detected food row matching `design-system/components/nutrition/FoodItemRow.jsx`.
///
/// - Shows a honey `"Check"` badge (NO percentages) when `confidence < threshold` (`0.76`).
/// - Collapsed displays the `1×` pill (`accentSoft` / `accentText` when modified from `1`).
/// - Expanded reveals the 6 portion multiplier pills `[0.5, 0.75, 1, 1.25, 1.5, 2]` + Swap and Remove actions.
public struct NNFoodItemRow: View {
    public static let defaultPortions: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    public let name: String
    public let serving: String
    public let kcal: Double
    public let confidence: Double?
    public let multiplier: Double
    public let onMultiplier: (Double) -> Void
    public let expanded: Bool
    public let onToggle: () -> Void
    public let onSwap: (() -> Void)?
    public let onRemove: (() -> Void)?
    public let threshold: Double
    public let showSeparator: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        name: String,
        serving: String,
        kcal: Double,
        confidence: Double? = nil,
        multiplier: Double = 1.0,
        onMultiplier: @escaping (Double) -> Void,
        expanded: Bool,
        onToggle: @escaping () -> Void,
        onSwap: (() -> Void)? = nil,
        onRemove: (() -> Void)? = nil,
        threshold: Double = 0.76,
        showSeparator: Bool = false
    ) {
        self.name = name
        self.serving = serving
        self.kcal = kcal
        self.confidence = confidence
        self.multiplier = multiplier
        self.onMultiplier = onMultiplier
        self.expanded = expanded
        self.onToggle = onToggle
        self.onSwap = onSwap
        self.onRemove = onRemove
        self.threshold = threshold
        self.showSeparator = showSeparator
    }

    private var needsCheck: Bool {
        if let confidence {
            return confidence < threshold
        }
        return false
    }

    private var isChanged: Bool {
        abs(multiplier - 1.0) > 0.001
    }

    public var body: some View {
        VStack(spacing: 0) {
            if showSeparator {
                Rectangle()
                    .fill(NNColor.borderHairline)
                    .frame(height: 1)
                    .padding(.horizontal, NNSpacing.s4)
            }

            Button {
                withAnimation(reduceMotion ? nil : NNMotion.easeStandard(duration: NNMotion.durBase)) {
                    onToggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(name)
                                .nnTextStyle(.headline)
                                .foregroundStyle(NNColor.textPrimary)
                                .lineLimit(1)

                            if needsCheck {
                                NNBadge("Check", tone: .check, icon: .question)
                            }
                        }

                        Text(serving)
                            .nnTextStyle(.footnote)
                            .foregroundStyle(NNColor.textSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(NNFormatting.multiplier(multiplier))
                        .font(NNFont.mono(size: 12, weight: .medium, relativeTo: .caption))
                        .foregroundStyle(isChanged ? NNColor.accentText : NNColor.textSecondary)
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                        .background(isChanged ? NNColor.accentSoft : NNColor.fill1, in: Capsule())

                    VStack(alignment: .trailing, spacing: 0) {
                        Text(NNFormatting.kcal(kcal * multiplier))
                            .nnTextStyle(.numMd)
                            .foregroundStyle(NNColor.textPrimary)
                        Text("kcal")
                            .font(NNFont.sans(size: 12, weight: .regular, relativeTo: .caption))
                            .foregroundStyle(NNColor.textTertiary)
                    }
                    .frame(minWidth: 52, alignment: .trailing)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, NNSpacing.s4)
                .frame(minHeight: 64)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    NNSegmentedControl(
                        options: Self.defaultPortions.map { value in
                            NNSegmentOption(value: value, label: NNFormatting.multiplier(value))
                        },
                        selection: Binding(
                            get: { multiplier },
                            set: { onMultiplier($0) }
                        ),
                        size: .sm,
                        numeric: true
                    )

                    HStack(spacing: 4) {
                        if let onSwap {
                            NNButton("Swap", variant: .ghost, size: .sm, icon: .swap, action: onSwap)
                        }
                        if let onRemove {
                            NNButton("Remove", variant: .ghost, size: .sm, icon: .trash, action: onRemove)
                        }
                    }
                    .padding(.leading, -8)
                }
                .padding(.horizontal, NNSpacing.s4)
                .padding(.bottom, 14)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - NNWeekTrend

/// Single day column for `NNWeekTrend`.
public struct NNWeekDayPoint: Identifiable, Sendable, Hashable {
    public let id: String
    public let label: String
    public let kcal: Double
    public let isToday: Bool

    public init(id: String? = nil, label: String, kcal: Double, isToday: Bool = false) {
        self.id = id ?? label
        self.label = label
        self.kcal = kcal
        self.isToday = isToday
    }
}

/// 7-day calorie bar chart + dashed target line + weekly average macro bars for iPhone Duo unfolded / iPad right pane.
/// Matches `design-system/ui_kits/duo/DuoFrame.jsx` (`WeekTrend`) and `duo.css` (`.week*`).
public struct NNWeekTrend: View {
    public let dateRange: String?
    public let days: [NNWeekDayPoint]
    public let targetKcal: Double
    public let averageProtein: NNMacroProgress
    public let averageCarbs: NNMacroProgress
    public let averageFat: NNMacroProgress
    public let showHeader: Bool
    public let helperNote: String?

    public init(
        dateRange: String? = nil,
        days: [NNWeekDayPoint],
        targetKcal: Double = 2100,
        averageProtein: NNMacroProgress,
        averageCarbs: NNMacroProgress,
        averageFat: NNMacroProgress,
        showHeader: Bool = true,
        helperNote: String? = "Tap a meal on the left to see its breakdown here."
    ) {
        self.dateRange = dateRange
        self.days = days
        self.targetKcal = targetKcal
        self.averageProtein = averageProtein
        self.averageCarbs = averageCarbs
        self.averageFat = averageFat
        self.showHeader = showHeader
        self.helperNote = helperNote
    }

    private var completedDaysAverage: Double {
        let nonToday = days.filter { !$0.isToday }
        let sample = nonToday.isEmpty ? days : nonToday
        guard !sample.isEmpty else { return 0 }
        return sample.reduce(0) { $0 + $1.kcal } / Double(sample.count)
    }

    private var chartMaxKcal: Double {
        let highest = days.map(\.kcal).max() ?? 0
        return max(highest, targetKcal, 1) * 1.08
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: NNSpacing.s4) {
            if showHeader {
                NNNavBar(largeTitle: "This week", subtitle: dateRange)
            }

            VStack(alignment: .leading, spacing: NNSpacing.s4) {
                NNCard {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(NNFormatting.kcal(completedDaysAverage))
                                .nnTextStyle(.numLg)
                                .foregroundStyle(NNColor.textPrimary)
                            Text("avg kcal a day")
                                .nnTextStyle(.subhead)
                                .foregroundStyle(NNColor.textSecondary)
                        }

                        weekBarChart
                            .padding(.top, 24)
                    }
                }

                NNCard {
                    HStack(spacing: 14) {
                        NNMacroBar(macro: .protein, value: averageProtein.value, target: averageProtein.target)
                        NNMacroBar(macro: .carbs, value: averageCarbs.value, target: averageCarbs.target)
                        NNMacroBar(macro: .fat, value: averageFat.value, target: averageFat.target)
                    }
                }

                if let helperNote, !helperNote.isEmpty {
                    Text(helperNote)
                        .nnTextStyle(.subhead)
                        .foregroundStyle(NNColor.textSecondary)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, showHeader ? NNSpacing.screenMargin : 0)
        }
    }

    private var weekBarChart: some View {
        let chartHeight: CGFloat = 130
        let targetRatio = CGFloat(min(1.0, max(0.0, targetKcal / chartMaxKcal)))
        let targetOffsetFromBottom = chartHeight * targetRatio

        return VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(days) { day in
                        let barRatio = CGFloat(min(1.0, max(0.0, day.kcal / chartMaxKcal)))
                        let barHeight = max(4, chartHeight * barRatio)
                        UnevenRoundedRectangle(
                            topLeadingRadius: 10,
                            bottomLeadingRadius: 4,
                            bottomTrailingRadius: 4,
                            topTrailingRadius: 10,
                            style: .continuous
                        )
                        .fill(day.isToday ? NNColor.accent : NNColor.fill2)
                        .frame(maxWidth: .infinity)
                        .frame(height: barHeight)
                    }
                }
                .frame(height: chartHeight, alignment: .bottom)

                // Dashed target line + right-aligned target numeral
                VStack(alignment: .trailing, spacing: 3) {
                    Text(NNFormatting.kcal(targetKcal))
                        .nnTextStyle(.numXs)
                        .foregroundStyle(NNColor.textTertiary)
                    DashedHorizontalRule()
                        .stroke(
                            NNColor.borderStrong,
                            style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                        )
                        .frame(height: 1)
                }
                .offset(y: -targetOffsetFromBottom)
                .allowsHitTesting(false)
            }
            .frame(height: chartHeight, alignment: .bottom)

            HStack(spacing: 10) {
                ForEach(days) { day in
                    Text(day.label)
                        .nnTextStyle(.caption)
                        .foregroundStyle(NNColor.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

private struct DashedHorizontalRule: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
