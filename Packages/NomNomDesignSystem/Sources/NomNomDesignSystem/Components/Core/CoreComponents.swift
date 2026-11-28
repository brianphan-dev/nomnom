import SwiftUI

// MARK: - Press Scale Button Style

/// Shared press-scale interaction style (`0.97` buttons/chips, `0.92` icon buttons, `0.94` shutter).
public struct NNPressScaleButtonStyle: ButtonStyle {
    public let scale: CGFloat
    public let pressedOpacity: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(scale: CGFloat = NNMotion.pressScale, pressedOpacity: Double = 1.0) {
        self.scale = scale
        self.pressedOpacity = pressedOpacity
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(
                reduceMotion ? nil : NNMotion.easeStandard(duration: NNMotion.durFast),
                value: configuration.isPressed
            )
    }
}

/// Smoothly rotating spinner used for button loading states and syncing pills.
internal struct NNSpinningIcon: View {
    let icon: NNIcon
    let size: CGFloat
    let weight: NNIconWeight
    let color: Color?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSpinning = false

    var body: some View {
        NNIconView(icon, size: size, weight: weight, color: color)
            .rotationEffect(.degrees(isSpinning && !reduceMotion ? 360 : 0))
            .animation(
                reduceMotion ? nil : .linear(duration: 1.0).repeatForever(autoreverses: false),
                value: isSpinning
            )
            .onAppear {
                isSpinning = true
            }
    }
}

// MARK: - NNButton

/// Button semantic variants from `design-system/components/core/core.css`.
public enum NNButtonVariant: Sendable, Hashable {
    /// Ink surface (`stone950` light / `stone50` dark) with inverted ink label.
    case primary
    /// Persimmon accent surface with ALWAYS-ink (`stone950`) label — never white.
    case accent
    /// Translucent ink tint (`fill1`) with primary text.
    case secondary
    /// Transparent background with primary text.
    case ghost
    /// Soft beet surface (`dangerSoft`) with beet text (`dangerText`).
    case destructive
}

/// Button vertical sizing scale matching `--control-sm/md/lg` (32 / 44 / 56pt).
public enum NNButtonSize: Sendable, Hashable {
    case sm
    case md
    case lg

    public var height: CGFloat {
        switch self {
        case .sm: NNSpacing.controlSm
        case .md: NNSpacing.controlMd
        case .lg: NNSpacing.controlLg
        }
    }

    public var horizontalPadding: CGFloat {
        switch self {
        case .sm: 14
        case .md: 20
        case .lg: 28
        }
    }

    public var fontSize: CGFloat {
        switch self {
        case .sm: 14
        case .md: 16
        case .lg: 17
        }
    }

    public var iconSize: CGFloat {
        switch self {
        case .sm: 16
        case .md: 18
        case .lg: 22
        }
    }

    public var gap: CGFloat {
        self == .sm ? 6 : 8
    }
}

/// Pill-shaped primary action button matching `design-system/components/core/Button.jsx`.
public struct NNButton<Label: View>: View {
    public let variant: NNButtonVariant
    public let size: NNButtonSize
    public let icon: NNIcon?
    public let iconRight: NNIcon?
    public let iconWeight: NNIconWeight
    public let fullWidth: Bool
    public let loading: Bool
    public let action: () -> Void
    private let label: Label

    @Environment(\.isEnabled) private var isEnabled

    public init(
        variant: NNButtonVariant = .primary,
        size: NNButtonSize = .md,
        icon: NNIcon? = nil,
        iconRight: NNIcon? = nil,
        iconWeight: NNIconWeight = .bold,
        fullWidth: Bool = false,
        loading: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.variant = variant
        self.size = size
        self.icon = icon
        self.iconRight = iconRight
        self.iconWeight = iconWeight
        self.fullWidth = fullWidth
        self.loading = loading
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: size.gap) {
                if loading {
                    NNSpinningIcon(icon: .syncing, size: size.iconSize, weight: .bold, color: foregroundColor)
                } else if let icon {
                    NNIconView(icon, size: size.iconSize, weight: iconWeight, color: foregroundColor)
                }

                label
                    .font(NNFont.sans(size: size.fontSize, weight: .semibold, relativeTo: .callout))
                    .tracking(-0.01 * size.fontSize)
                    .lineLimit(1)

                if let iconRight {
                    NNIconView(iconRight, size: size.iconSize, weight: iconWeight, color: foregroundColor)
                }
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: size.height)
            .background(backgroundColor, in: Capsule())
        }
        .buttonStyle(NNPressScaleButtonStyle(scale: NNMotion.pressScale))
        .disabled(loading || !isEnabled)
        .opacity((loading || !isEnabled) ? 0.38 : 1.0)
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary: NNColor.ink
        case .accent: NNColor.accent
        case .secondary: NNColor.fill1
        case .ghost: .clear
        case .destructive: NNColor.dangerSoft
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: NNColor.onInk
        case .accent: NNColor.onAccent
        case .secondary: NNColor.textPrimary
        case .ghost: NNColor.textPrimary
        case .destructive: NNColor.dangerText
        }
    }
}

public extension NNButton where Label == Text {
    init(
        _ title: String,
        variant: NNButtonVariant = .primary,
        size: NNButtonSize = .md,
        icon: NNIcon? = nil,
        iconRight: NNIcon? = nil,
        iconWeight: NNIconWeight = .bold,
        fullWidth: Bool = false,
        loading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            variant: variant,
            size: size,
            icon: icon,
            iconRight: iconRight,
            iconWeight: iconWeight,
            fullWidth: fullWidth,
            loading: loading,
            action: action,
            label: { Text(title) }
        )
    }
}

// MARK: - NNIconButton

/// Surface styles for circular `NNIconButton` controls.
public enum NNIconButtonVariant: Sendable, Hashable {
    case plain
    case ghost
    case filled
    case ink
    case accent
    case glass
}

/// Circular icon-only button matching `design-system/components/core/IconButton.jsx`.
public struct NNIconButton: View {
    public let icon: NNIcon
    public let accessibilityLabel: String
    public let variant: NNIconButtonVariant
    public let size: CGFloat
    public let iconSize: CGFloat
    public let weight: NNIconWeight
    public let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    public init(
        icon: NNIcon,
        label: String,
        variant: NNIconButtonVariant = .plain,
        size: CGFloat = NNSpacing.tapMin,
        iconSize: CGFloat? = nil,
        weight: NNIconWeight = .regular,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.accessibilityLabel = label
        self.variant = variant
        self.size = size
        self.iconSize = iconSize ?? (size * 0.5).rounded()
        self.weight = weight
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            NNIconView(icon, size: iconSize, weight: weight, color: foregroundColor)
                .frame(width: size, height: size)
                .background {
                    if variant == .glass {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(Circle().fill(NNColor.glassFill))
                    } else {
                        Circle().fill(backgroundColor)
                    }
                }
        }
        .buttonStyle(NNPressScaleButtonStyle(scale: NNMotion.iconPressScale))
        .accessibilityLabel(accessibilityLabel)
        .opacity(isEnabled ? 1.0 : 0.38)
    }

    private var backgroundColor: Color {
        switch variant {
        case .plain, .ghost: .clear
        case .filled: NNColor.fill1
        case .ink: NNColor.ink
        case .accent: NNColor.accent
        case .glass: NNColor.glassFill
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .plain, .ghost, .filled: NNColor.textPrimary
        case .ink: NNColor.onInk
        case .accent: NNColor.onAccent
        case .glass: NNColor.onPhoto
        }
    }
}

// MARK: - NNBadge

/// Semantic badge tone matching `design-system/components/core/Badge.jsx`.
public enum NNBadgeTone: Sendable, Hashable {
    case neutral
    case accent
    case check
    case positive
    case info
    case pending
}

/// Capture / import provenance tag shown on meal rows and detail headers.
public enum NNLoggingMethod: String, Sendable, Hashable, CaseIterable {
    case photoAI = "photo_ai"
    case barcode = "barcode"
    case labelOCR = "label_ocr"
    case manual = "manual"
    case imported = "imported"

    public var label: String {
        switch self {
        case .photoAI: "Photo AI"
        case .barcode: "Barcode"
        case .labelOCR: "Label"
        case .manual: "Manual"
        case .imported: "Imported"
        }
    }

    public var icon: NNIcon {
        switch self {
        case .photoAI: .sparkle
        case .barcode: .barcode
        case .labelOCR: .scan
        case .manual: .manual
        case .imported: .importHistory
        }
    }
}

/// Compact 22pt pill badge matching `design-system/components/core/Badge.jsx`.
public struct NNBadge: View {
    public let title: String
    public let tone: NNBadgeTone
    public let icon: NNIcon?

    public init(_ title: String, tone: NNBadgeTone = .neutral, icon: NNIcon? = nil) {
        self.title = title
        self.tone = tone
        self.icon = icon
    }

    public init(method: NNLoggingMethod, tone: NNBadgeTone = .neutral) {
        self.title = method.label
        self.tone = tone
        self.icon = method.icon
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon {
                NNIconView(icon, size: 11, weight: .bold, color: foregroundColor)
            }
            Text(title)
                .nnTextStyle(.caption)
                .lineLimit(1)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background {
            if tone == .pending {
                Capsule()
                    .strokeBorder(NNColor.borderStrong, lineWidth: 1)
            } else {
                Capsule().fill(backgroundColor)
            }
        }
    }

    private var backgroundColor: Color {
        switch tone {
        case .neutral: NNColor.fill1
        case .accent: NNColor.accentSoft
        case .check: NNColor.checkSoft
        case .positive: NNColor.positiveSoft
        case .info: NNColor.infoSoft
        case .pending: .clear
        }
    }

    private var foregroundColor: Color {
        switch tone {
        case .neutral, .pending: NNColor.textSecondary
        case .accent: NNColor.accentText
        case .check: NNColor.checkText
        case .positive: NNColor.positiveText
        case .info: NNColor.infoText
        }
    }
}

// MARK: - NNChip

/// Sizing for pill selection chips (`30 / 36 / 44pt`).
public enum NNChipSize: Sendable, Hashable {
    case sm
    case md
    case lg

    public var height: CGFloat {
        switch self {
        case .sm: 30
        case .md: 36
        case .lg: NNSpacing.controlMd
        }
    }

    public var horizontalPadding: CGFloat {
        switch self {
        case .sm: 12
        case .md: 14
        case .lg: 18
        }
    }

    public var fontSize: CGFloat {
        switch self {
        case .sm: 13
        case .md: 15
        case .lg: 16
        }
    }
}

/// Visual tone for `NNChip` (standard stone outline vs translucent glass over camera viewfinder).
public enum NNChipTone: Sendable, Hashable {
    case `default`
    case glass
}

/// Toggleable pill chip matching `design-system/components/core/Chip.jsx`.
public struct NNChip: View {
    public let title: String
    public let detail: String?
    public let selected: Bool
    public let icon: NNIcon?
    public let size: NNChipSize
    public let tone: NNChipTone
    public let action: () -> Void

    public init(
        _ title: String,
        detail: String? = nil,
        selected: Bool = false,
        icon: NNIcon? = nil,
        size: NNChipSize = .md,
        tone: NNChipTone = .default,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.detail = detail
        self.selected = selected
        self.icon = icon
        self.size = size
        self.tone = tone
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    NNIconView(icon, size: size == .sm ? 14 : 16, weight: .regular, color: foregroundColor)
                }
                Text(title)
                    .font(NNFont.sans(size: size.fontSize, weight: .medium, relativeTo: .subheadline))
                    .tracking(-0.01 * size.fontSize)
                if let detail {
                    Text(detail)
                        .font(NNFont.sans(size: size.fontSize, weight: .regular, relativeTo: .subheadline))
                        .opacity(0.6)
                }
            }
            .foregroundStyle(foregroundColor)
            .lineLimit(1)
            .padding(.horizontal, size.horizontalPadding)
            .frame(height: size.height)
            .background {
                chipBackground
            }
        }
        .buttonStyle(NNPressScaleButtonStyle(scale: NNMotion.pressScale))
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    @ViewBuilder
    private var chipBackground: some View {
        switch tone {
        case .default:
            if selected {
                Capsule().fill(NNColor.ink)
            } else {
                Capsule().strokeBorder(NNColor.borderStrong, lineWidth: 1)
            }
        case .glass:
            if selected {
                Capsule().fill(NNColor.stone0)
            } else {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().fill(NNColor.glassFill))
            }
        }
    }

    private var foregroundColor: Color {
        switch tone {
        case .default:
            selected ? NNColor.onInk : NNColor.textPrimary
        case .glass:
            selected ? NNColor.stone950 : NNColor.onPhoto
        }
    }
}

// MARK: - NNCard

/// Surface tones for flat 28pt `NNCard` containers.
public enum NNCardTone: Sendable, Hashable {
    /// White (light) / `stone900` (dark), flat — no border, no shadow.
    case `default`
    /// Subtle tinted inset fill (`fill1`).
    case sunken
    /// Transparent with 1pt hairline border (empty states).
    case outline
    /// Soft persimmon tint (`accentSoft`).
    case accent

    /// Alias matching CSS `.nn-card--surface`.
    public static var surface: NNCardTone { .default }
}

/// Padding presets matching `Card.jsx` (`none = 0`, `md = 16`, `lg = 20`).
public enum NNCardPadding: Sendable, Hashable {
    case none
    case md
    case lg
    case custom(CGFloat)

    public var points: CGFloat {
        switch self {
        case .none: 0
        case .md: NNSpacing.s4
        case .lg: NNSpacing.s5
        case .custom(let value): value
        }
    }
}

/// Flat 28pt continuous-corner card matching `design-system/components/core/Card.jsx`.
public struct NNCard<Content: View>: View {
    public let tone: NNCardTone
    public let padding: NNCardPadding
    private let content: Content

    public init(
        tone: NNCardTone = .default,
        padding: NNCardPadding = .lg,
        @ViewBuilder content: () -> Content
    ) {
        self.tone = tone
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: NNRadius.card, style: .continuous)
        content
            .padding(padding.points)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                switch tone {
                case .default:
                    shape.fill(NNColor.surfaceCard)
                case .sunken:
                    shape.fill(NNColor.fill1)
                case .outline:
                    shape.strokeBorder(NNColor.borderHairline, lineWidth: 1)
                case .accent:
                    shape.fill(NNColor.accentSoft)
                }
            }
            .clipShape(shape)
    }
}
