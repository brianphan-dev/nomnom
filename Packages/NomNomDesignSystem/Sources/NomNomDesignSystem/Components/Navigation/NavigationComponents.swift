import SwiftUI

// MARK: - NNNavBar

/// Screen header supporting Instrument Serif large titles, centered bar titles, subtitle, and leading/trailing chrome.
/// Matches `design-system/components/navigation/NavBar.jsx`.
public struct NNNavBar<Leading: View, Trailing: View>: View {
    public let title: String?
    public let largeTitle: String?
    public let subtitle: String?
    private let leading: Leading
    private let trailing: Trailing

    public init(
        title: String? = nil,
        largeTitle: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.largeTitle = largeTitle
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        leading
                    }
                    .frame(minWidth: NNSpacing.tapMin, alignment: .leading)

                    Spacer(minLength: 8)

                    HStack(spacing: 8) {
                        trailing
                    }
                    .frame(minWidth: NNSpacing.tapMin, alignment: .trailing)
                }

                if let title, !title.isEmpty {
                    Text(title)
                        .nnTextStyle(.headline)
                        .foregroundStyle(NNColor.textPrimary)
                        .lineLimit(1)
                        .allowsHitTesting(false)
                }
            }
            .frame(minHeight: NNSpacing.tapMin)

            if let largeTitle, !largeTitle.isEmpty {
                Text(largeTitle)
                    .nnTextStyle(.largeTitle)
                    .foregroundStyle(NNColor.textPrimary)
                    .padding(.top, 4)
            }

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .nnTextStyle(.subhead)
                    .foregroundStyle(NNColor.textSecondary)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, NNSpacing.screenMargin)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

public extension NNNavBar where Leading == EmptyView, Trailing == EmptyView {
    init(title: String? = nil, largeTitle: String? = nil, subtitle: String? = nil) {
        self.init(
            title: title,
            largeTitle: largeTitle,
            subtitle: subtitle,
            leading: { EmptyView() },
            trailing: { EmptyView() }
        )
    }
}

public extension NNNavBar where Trailing == EmptyView {
    init(
        title: String? = nil,
        largeTitle: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder leading: () -> Leading
    ) {
        self.init(
            title: title,
            largeTitle: largeTitle,
            subtitle: subtitle,
            leading: leading,
            trailing: { EmptyView() }
        )
    }
}

public extension NNNavBar where Leading == EmptyView {
    init(
        title: String? = nil,
        largeTitle: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(
            title: title,
            largeTitle: largeTitle,
            subtitle: subtitle,
            leading: { EmptyView() },
            trailing: trailing
        )
    }
}

// MARK: - NNListRow

/// Semantic tone for `NNListRow` (`.default` stone or `.destructive` beet).
public enum NNListRowTone: Sendable, Hashable {
    case `default`
    case destructive
}

/// Settings / detail list row matching `design-system/components/navigation/ListRow.jsx`.
public struct NNListRow<Trailing: View>: View {
    public let icon: NNIcon?
    public let title: String
    public let subtitle: String?
    public let value: String?
    public let monospacedValue: Bool
    public let chevron: Bool
    public let tone: NNListRowTone
    public let showSeparator: Bool
    public let action: (() -> Void)?
    private let trailing: Trailing

    public init(
        icon: NNIcon? = nil,
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        monospacedValue: Bool = false,
        chevron: Bool = false,
        tone: NNListRowTone = .default,
        showSeparator: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.monospacedValue = monospacedValue
        self.chevron = chevron
        self.tone = tone
        self.showSeparator = showSeparator
        self.action = action
        self.trailing = trailing()
    }

    public var body: some View {
        VStack(spacing: 0) {
            if showSeparator {
                Rectangle()
                    .fill(NNColor.borderHairline)
                    .frame(height: 1)
                    .padding(.horizontal, NNSpacing.s4)
            }

            if let action {
                Button(action: action) {
                    rowContent
                }
                .buttonStyle(NNListRowButtonStyle())
            } else {
                rowContent
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            if let icon {
                NNIconView(icon, size: 16, weight: .regular, color: iconForegroundColor)
                    .frame(width: 32, height: 32)
                    .background(iconBackgroundColor, in: Circle())
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(NNFont.sans(size: 16, weight: .medium, relativeTo: .callout))
                    .tracking(-0.01 * 16)
                    .foregroundStyle(tone == .destructive ? NNColor.dangerText : NNColor.textPrimary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .nnTextStyle(.footnote)
                        .foregroundStyle(NNColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let value, !value.isEmpty {
                if monospacedValue {
                    Text(value)
                        .nnTextStyle(.numSm)
                        .foregroundStyle(NNColor.textSecondary)
                } else {
                    Text(value)
                        .nnTextStyle(.subhead)
                        .foregroundStyle(NNColor.textSecondary)
                }
            }

            trailing

            if chevron {
                NNIconView(.chevronRight, size: 13, weight: .bold, color: NNColor.textTertiary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, NNSpacing.s4)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }

    private var iconBackgroundColor: Color {
        tone == .destructive ? NNColor.dangerSoft : NNColor.fill1
    }

    private var iconForegroundColor: Color {
        tone == .destructive ? NNColor.dangerText : NNColor.textPrimary
    }
}

private struct NNListRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? NNColor.fill2 : .clear)
            .animation(NNMotion.easeStandard(duration: NNMotion.durFast), value: configuration.isPressed)
    }
}

public extension NNListRow where Trailing == EmptyView {
    init(
        icon: NNIcon? = nil,
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        monospacedValue: Bool = false,
        chevron: Bool = false,
        tone: NNListRowTone = .default,
        showSeparator: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.init(
            icon: icon,
            title: title,
            subtitle: subtitle,
            value: value,
            monospacedValue: monospacedValue,
            chevron: chevron,
            tone: tone,
            showSeparator: showSeparator,
            action: action,
            trailing: { EmptyView() }
        )
    }
}

// MARK: - NNCaptureDock

/// Floating translucent pill capture dock matching `design-system/components/navigation/CaptureDock.jsx`.
///
/// The MVP has no tab bar: the bottom of Today belongs to the 72pt persimmon shutter flanked by Barcode and Manual.
/// Pass `compact: true` on iPhone Duo Folded (5.4") for the 60pt shutter and 52pt side targets.
public struct NNCaptureDock: View {
    public let compact: Bool
    public let onBarcode: () -> Void
    public let onSnap: () -> Void
    public let onManual: () -> Void

    public init(
        compact: Bool = false,
        onBarcode: @escaping () -> Void,
        onSnap: @escaping () -> Void,
        onManual: @escaping () -> Void
    ) {
        self.compact = compact
        self.onBarcode = onBarcode
        self.onSnap = onSnap
        self.onManual = onManual
    }

    public var body: some View {
        let sideHeight: CGFloat = compact ? 52 : 64
        let shutterSize: CGFloat = compact ? NNSpacing.shutterCompact : NNSpacing.shutter
        let cameraIconSize: CGFloat = compact ? 24 : 28

        HStack(spacing: 4) {
            sideButton(icon: .barcode, label: "Barcode", height: sideHeight, action: onBarcode)

            Button(action: onSnap) {
                NNIconView(.camera, size: cameraIconSize, weight: .fill, color: NNColor.onAccent)
                    .frame(width: shutterSize, height: shutterSize)
                    .background(NNColor.accent, in: Circle())
            }
            .buttonStyle(NNPressScaleButtonStyle(scale: NNMotion.shutterPressScale))
            .padding(.horizontal, 8)
            .accessibilityLabel("Snap plate")

            sideButton(icon: .manual, label: "Manual", height: sideHeight, action: onManual)
        }
        .padding(compact ? 6 : 8)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(NNColor.surfaceChrome))
        }
        .nnShadow(.float)
    }

    private func sideButton(
        icon: NNIcon,
        label: String,
        height: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                NNIconView(icon, size: 22, weight: .regular, color: NNColor.textPrimary)
                Text(label)
                    .nnTextStyle(.caption)
                    .foregroundStyle(NNColor.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .contentShape(Capsule())
        }
        .buttonStyle(NNPressScaleButtonStyle(scale: NNMotion.pressScale))
    }
}
