import SwiftUI

// MARK: - NNTextField

/// Background surface for pill-shaped text fields.
public enum NNTextFieldSurface: Sendable, Hashable {
    case fill
    case card
}

/// Height preset for `NNTextField` (`48pt` md, `56pt` lg).
public enum NNTextFieldSize: Sendable, Hashable {
    case md
    case lg

    public var height: CGFloat {
        self == .lg ? NNSpacing.controlLg : 48
    }

    public var horizontalPadding: CGFloat {
        self == .lg ? 20 : 16
    }
}

/// Pill-shaped text input matching `design-system/components/forms/TextField.jsx`.
public struct NNTextField<Trailing: View>: View {
    @Binding public var text: String
    public let placeholder: String
    public let icon: NNIcon?
    public let clearable: Bool
    public let size: NNTextFieldSize
    public let surface: NNTextFieldSurface
    private let trailing: Trailing

    @FocusState private var isFocused: Bool

    public init(
        _ placeholder: String,
        text: Binding<String>,
        icon: NNIcon? = nil,
        clearable: Bool = true,
        size: NNTextFieldSize = .md,
        surface: NNTextFieldSurface = .fill,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.clearable = clearable
        self.size = size
        self.surface = surface
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: 10) {
            if let icon {
                NNIconView(icon, size: 18, weight: .regular, color: NNColor.textTertiary)
            }

            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(NNColor.textTertiary)
            )
            .textFieldStyle(.plain)
            .nnTextStyle(.body)
            .foregroundStyle(NNColor.textPrimary)
            .focused($isFocused)

            if clearable && !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    NNIconView(.clearCircle, size: 18, weight: .fill, color: NNColor.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear")
            }

            trailing
        }
        .padding(.horizontal, size.horizontalPadding)
        .frame(height: size.height)
        .background(surface == .card ? NNColor.surfaceCard : NNColor.fill1, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(isFocused ? NNColor.ink : .clear, lineWidth: 1.5)
        }
        .animation(NNMotion.easeStandard(duration: NNMotion.durFast), value: isFocused)
    }
}

public extension NNTextField where Trailing == EmptyView {
    init(
        _ placeholder: String,
        text: Binding<String>,
        icon: NNIcon? = nil,
        clearable: Bool = true,
        size: NNTextFieldSize = .md,
        surface: NNTextFieldSurface = .fill
    ) {
        self.init(
            placeholder,
            text: text,
            icon: icon,
            clearable: clearable,
            size: size,
            surface: surface,
            trailing: { EmptyView() }
        )
    }
}

// MARK: - NNCheckbox

/// Circular checkbox row matching `design-system/components/forms/Checkbox.jsx`.
///
/// Set `dimUnchecked: true` for optional sauces, oils, and seasonings so unchecking dims and strikes them through.
public struct NNCheckbox: View {
    @Binding public var isChecked: Bool
    public let label: String
    public let description: String?
    public let trailing: String?
    public let dimUnchecked: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        isChecked: Binding<Bool>,
        label: String,
        description: String? = nil,
        trailing: String? = nil,
        dimUnchecked: Bool = false
    ) {
        self._isChecked = isChecked
        self.label = label
        self.description = description
        self.trailing = trailing
        self.dimUnchecked = dimUnchecked
    }

    public var body: some View {
        let shouldDim = dimUnchecked && !isChecked
        Button {
            withAnimation(reduceMotion ? nil : NNMotion.easeStandard(duration: NNMotion.durFast)) {
                isChecked.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    if isChecked {
                        Circle().fill(NNColor.ink)
                        NNIconView(.check, size: 12, weight: .bold, color: NNColor.onInk)
                    } else {
                        Circle().strokeBorder(NNColor.borderStrong, lineWidth: 1.5)
                    }
                }
                .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .nnTextStyle(.callout)
                        .foregroundStyle(shouldDim ? NNColor.textTertiary : NNColor.textPrimary)
                        .strikethrough(shouldDim, color: NNColor.textTertiary)
                    if let description, !description.isEmpty {
                        Text(description)
                            .nnTextStyle(.footnote)
                            .foregroundStyle(NNColor.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let trailing, !trailing.isEmpty {
                    Text(trailing)
                        .nnTextStyle(.numSm)
                        .foregroundStyle(shouldDim ? NNColor.textTertiary : NNColor.textSecondary)
                        .strikethrough(shouldDim, color: NNColor.textTertiary)
                }
            }
            .frame(minHeight: NNSpacing.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(NNPressScaleButtonStyle(scale: 0.985))
        .opacity(isEnabled ? 1.0 : 0.38)
        .accessibilityAddTraits(isChecked ? [.isSelected] : [])
    }
}

// MARK: - NNSwitch

/// Ink-track toggle switch matching `design-system/components/forms/Switch.jsx` (`51×31pt`, `27pt` knob).
public struct NNSwitch: View {
    @Binding public var isOn: Bool
    public let accessibilityLabel: String

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(isOn: Binding<Bool>, label: String = "Toggle") {
        self._isOn = isOn
        self.accessibilityLabel = label
    }

    public var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : NNMotion.easeOut(duration: NNMotion.durBase)) {
                isOn.toggle()
            }
        } label: {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(isOn ? NNColor.ink : NNColor.fill2)
                    .frame(width: 51, height: 31)

                Circle()
                    .fill(isOn ? NNColor.onInk : NNColor.stone0)
                    .frame(width: 27, height: 27)
                    .nnShadow(.knob)
                    .offset(x: isOn ? 22 : 2)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1.0 : 0.38)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - NNStepper

/// Pill numeric stepper matching `design-system/components/forms/Stepper.jsx` (`44pt` height).
public struct NNStepper: View {
    @Binding public var value: Double
    public let step: Double
    public let range: ClosedRange<Double>
    public let accessibilityLabel: String
    public let formatter: (Double) -> String

    public init(
        value: Binding<Double>,
        step: Double = 0.5,
        in range: ClosedRange<Double> = 0...99,
        label: String = "Quantity",
        formatter: ((Double) -> String)? = nil
    ) {
        self._value = value
        self.step = step
        self.range = range
        self.accessibilityLabel = label
        self.formatter = formatter ?? { number in
            let rounded = (number * 100).rounded() / 100
            if rounded == rounded.rounded() {
                return String(Int(rounded))
            } else if (rounded * 10).rounded() == rounded * 10 {
                return String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), rounded)
            }
            return String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), rounded)
        }
    }

    public var body: some View {
        let canDecrease = value > range.lowerBound
        let canIncrease = value < range.upperBound

        HStack(spacing: 0) {
            Button {
                update(value - step)
            } label: {
                NNIconView(.minus, size: 15, weight: .bold, color: NNColor.textPrimary)
                    .frame(width: NNSpacing.controlMd, height: NNSpacing.controlMd)
                    .contentShape(Circle())
            }
            .buttonStyle(NNPressScaleButtonStyle(scale: 0.90))
            .disabled(!canDecrease)
            .opacity(canDecrease ? 1.0 : 0.3)
            .accessibilityLabel("Decrease \(accessibilityLabel)")

            Text(formatter(value))
                .nnTextStyle(.numMd)
                .foregroundStyle(NNColor.textPrimary)
                .frame(minWidth: 44)
                .multilineTextAlignment(.center)

            Button {
                update(value + step)
            } label: {
                NNIconView(.plus, size: 15, weight: .bold, color: NNColor.textPrimary)
                    .frame(width: NNSpacing.controlMd, height: NNSpacing.controlMd)
                    .contentShape(Circle())
            }
            .buttonStyle(NNPressScaleButtonStyle(scale: 0.90))
            .disabled(!canIncrease)
            .opacity(canIncrease ? 1.0 : 0.3)
            .accessibilityLabel("Increase \(accessibilityLabel)")
        }
        .frame(height: NNSpacing.controlMd)
        .background(NNColor.fill1, in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    private func update(_ candidate: Double) {
        let clamped = min(range.upperBound, max(range.lowerBound, (candidate * 100.0).rounded() / 100.0))
        value = clamped
    }
}

// MARK: - NNSegmentedControl

/// Option descriptor for `NNSegmentedControl`.
public struct NNSegmentOption<Value: Hashable & Sendable>: Identifiable, Sendable {
    public let value: Value
    public let label: String
    public let icon: NNIcon?

    public var id: Value { value }

    public init(value: Value, label: String, icon: NNIcon? = nil) {
        self.value = value
        self.label = label
        self.icon = icon
    }
}

/// Height preset for `NNSegmentedControl` (`30pt` sm for portion multipliers, `38pt` md for tabs/modes).
public enum NNSegmentedControlSize: Sendable, Hashable {
    case sm
    case md

    public var itemHeight: CGFloat {
        self == .sm ? 30 : 38
    }

    public var horizontalPadding: CGFloat {
        self == .sm ? 6 : 12
    }

    public var fontSize: CGFloat {
        self == .sm ? 13 : 15
    }

    public var iconSize: CGFloat {
        self == .sm ? 13 : 15
    }
}

/// Surface tone for `NNSegmentedControl` (default light/dark stone, or translucent `.dark` glass over camera).
public enum NNSegmentedControlTone: Sendable, Hashable {
    case `default`
    case dark
}

/// Pill segmented control matching `design-system/components/forms/SegmentedControl.jsx`.
public struct NNSegmentedControl<Value: Hashable & Sendable>: View {
    public let options: [NNSegmentOption<Value>]
    @Binding public var selection: Value
    public let size: NNSegmentedControlSize
    public let tone: NNSegmentedControlTone
    public let fullWidth: Bool
    public let numeric: Bool

    @Namespace private var thumbNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        options: [NNSegmentOption<Value>],
        selection: Binding<Value>,
        size: NNSegmentedControlSize = .md,
        tone: NNSegmentedControlTone = .default,
        fullWidth: Bool = true,
        numeric: Bool = false
    ) {
        self.options = options
        self._selection = selection
        self.size = size
        self.tone = tone
        self.fullWidth = fullWidth
        self.numeric = numeric
    }

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(options) { option in
                let isSelected = option.value == selection
                Button {
                    withAnimation(reduceMotion ? nil : NNMotion.easeOut(duration: NNMotion.durBase)) {
                        selection = option.value
                    }
                } label: {
                    HStack(spacing: 6) {
                        if let icon = option.icon {
                            NNIconView(
                                icon,
                                size: size.iconSize,
                                weight: isSelected ? .bold : .regular,
                                color: textColor(isSelected: isSelected)
                            )
                        }
                        Text(option.label)
                            .font(itemFont(isSelected: isSelected))
                            .tracking(numeric ? -0.02 * size.fontSize : -0.01 * size.fontSize)
                            .lineLimit(1)
                    }
                    .foregroundStyle(textColor(isSelected: isSelected))
                    .padding(.horizontal, size.horizontalPadding)
                    .frame(maxWidth: fullWidth ? .infinity : nil)
                    .frame(height: size.itemHeight)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(selectedFillColor)
                                .nnShadow(.knob)
                                .matchedGeometryEffect(id: "nn-seg-knob", in: thumbNamespace)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(3)
        .background {
            if tone == .dark {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().fill(NNColor.glassFill))
            } else {
                Capsule().fill(NNColor.fill1)
            }
        }
    }

    private func itemFont(isSelected: Bool) -> Font {
        if numeric {
            return NNFont.mono(size: 13, weight: isSelected ? .semibold : .medium, relativeTo: .footnote)
        }
        return NNFont.sans(
            size: size.fontSize,
            weight: isSelected ? .semibold : .medium,
            relativeTo: size == .sm ? .footnote : .subheadline
        )
    }

    private var selectedFillColor: Color {
        switch tone {
        case .default: NNColor.segmentSelectedFill
        case .dark: NNColor.stone0
        }
    }

    private func textColor(isSelected: Bool) -> Color {
        switch tone {
        case .default:
            isSelected ? NNColor.textPrimary : NNColor.textSecondary
        case .dark:
            isSelected ? NNColor.stone950 : Color.white.opacity(0.82)
        }
    }
}
