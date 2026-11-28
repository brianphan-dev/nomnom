import SwiftUI

// MARK: - NNSyncPill

/// Sync status displayed in the Today navigation bar leading slot.
public enum NNSyncStatus: Sendable, Hashable {
    case synced
    case syncing
    case offline(queued: Int? = nil)
}

/// Compact 28pt sync status pill matching `design-system/components/feedback/SyncPill.jsx`.
public struct NNSyncPill: View {
    public let status: NNSyncStatus
    public let action: (() -> Void)?

    public init(status: NNSyncStatus = .synced, action: (() -> Void)? = nil) {
        self.status = status
        self.action = action
    }

    public var body: some View {
        if let action {
            Button(action: action) {
                pillContent
            }
            .buttonStyle(NNPressScaleButtonStyle(scale: NNMotion.pressScale))
        } else {
            pillContent
        }
    }

    private var pillContent: some View {
        HStack(spacing: 6) {
            switch status {
            case .synced:
                NNIconView(.cloudCheck, size: 13, weight: .bold, color: NNColor.positiveText)
            case .syncing:
                NNSpinningIcon(icon: .syncing, size: 13, weight: .bold, color: NNColor.textSecondary)
            case .offline:
                NNIconView(.cloudOffline, size: 13, weight: .bold, color: NNColor.textSecondary)
            }

            Text(labelText)
                .nnTextStyle(.caption)
                .foregroundStyle(NNColor.textSecondary)
                .lineLimit(1)
        }
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .frame(height: 28)
        .background {
            if case .offline = status {
                Capsule().strokeBorder(NNColor.borderStrong, lineWidth: 1)
            } else {
                Capsule().fill(NNColor.fill1)
            }
        }
    }

    private var labelText: String {
        switch status {
        case .synced: "Synced"
        case .syncing: "Syncing\u{2026}"
        case .offline(let queued): NNFormatting.syncOfflineLabel(queued: queued)
        }
    }
}

// MARK: - NNProgressBar

/// Semantic fill colors for `NNProgressBar`.
public enum NNProgressTone: Sendable, Hashable {
    case accent
    case protein
    case carbs
    case fat
    case neutral

    public var fillColor: Color {
        switch self {
        case .accent: NNColor.accent
        case .protein: NNColor.macroProtein
        case .carbs: NNColor.macroCarbs
        case .fat: NNColor.macroFat
        case .neutral: NNColor.ink
        }
    }
}

/// Animated capsule progress bar (`420ms` `easeOut`) matching `design-system/components/feedback/ProgressBar.jsx`.
public struct NNProgressBar: View {
    public let value: Double
    public let max: Double
    public let tone: NNProgressTone
    public let height: CGFloat
    public let label: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        value: Double,
        max: Double = 100,
        tone: NNProgressTone = .accent,
        height: CGFloat = 6,
        label: String? = nil
    ) {
        self.value = value
        self.max = max
        self.tone = tone
        self.height = height
        self.label = label
    }

    private var fraction: CGFloat {
        guard max > 0 else { return 0 }
        return CGFloat(min(1.0, Swift.max(0.0, value / max)))
    }

    public var body: some View {
        GeometryReader { proxy in
            let fillWidth = proxy.size.width * fraction
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(NNColor.fill2)

                Capsule()
                    .fill(tone.fillColor)
                    .frame(width: fillWidth)
                    .animation(
                        reduceMotion ? nil : NNMotion.easeOut(duration: NNMotion.durSheet),
                        value: fraction
                    )
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? "Progress")
        .accessibilityValue("\(Int((fraction * 100).rounded())) percent")
    }
}

// MARK: - NNBanner

/// Semantic tone for inline informational banners (no red alert state in nomnom).
public enum NNBannerTone: Sendable, Hashable {
    case neutral
    case check
    case info
    case accent
}

/// Calm inline status banner matching `design-system/components/feedback/Banner.jsx`.
public struct NNBanner<Action: View>: View {
    public let tone: NNBannerTone
    public let icon: NNIcon?
    public let title: String?
    public let message: String
    private let action: Action

    public init(
        tone: NNBannerTone = .neutral,
        icon: NNIcon? = nil,
        title: String? = nil,
        message: String,
        @ViewBuilder action: () -> Action
    ) {
        self.tone = tone
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action()
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let icon {
                NNIconView(icon, size: 19, weight: .regular, color: iconColor)
                    .padding(.top, 1)
            }

            VStack(alignment: .leading, spacing: 2) {
                if let title, !title.isEmpty {
                    Text(title)
                        .font(NNFont.sans(size: 15, weight: .semibold, relativeTo: .subheadline))
                        .tracking(-0.01 * 15)
                        .foregroundStyle(titleColor)
                }
                if !message.isEmpty {
                    Text(message)
                        .nnTextStyle(.footnote)
                        .foregroundStyle(bodyColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            action
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            backgroundColor,
            in: RoundedRectangle(cornerRadius: NNRadius.banner, style: .continuous)
        )
    }

    private var backgroundColor: Color {
        switch tone {
        case .neutral: NNColor.fill1
        case .check: NNColor.checkSoft
        case .info: NNColor.infoSoft
        case .accent: NNColor.accentSoft
        }
    }

    private var iconColor: Color {
        switch tone {
        case .neutral: NNColor.textSecondary
        case .check: NNColor.checkText
        case .info: NNColor.infoText
        case .accent: NNColor.accentText
        }
    }

    private var titleColor: Color {
        switch tone {
        case .neutral: NNColor.textPrimary
        case .check: NNColor.checkText
        case .info: NNColor.infoText
        case .accent: NNColor.accentText
        }
    }

    private var bodyColor: Color {
        tone == .neutral ? NNColor.textSecondary : NNColor.textPrimary
    }
}

public extension NNBanner where Action == EmptyView {
    init(
        tone: NNBannerTone = .neutral,
        icon: NNIcon? = nil,
        title: String? = nil,
        message: String
    ) {
        self.init(tone: tone, icon: icon, title: title, message: message, action: { EmptyView() })
    }
}

// MARK: - NNDialog

/// Action descriptor for `NNDialog` stacked pill buttons.
public struct NNDialogAction: Identifiable {
    public let id: String
    public let label: String
    public let variant: NNButtonVariant
    public let action: () -> Void

    public init(
        id: String? = nil,
        label: String,
        variant: NNButtonVariant = .secondary,
        action: @escaping () -> Void
    ) {
        self.id = id ?? label
        self.label = label
        self.variant = variant
        self.action = action
    }
}

/// Centered editorial confirmation dialog matching `design-system/components/feedback/Dialog.jsx`.
public struct NNDialog: View {
    public let title: String
    public let message: String?
    public let actions: [NNDialogAction]
    public let onDismiss: (() -> Void)?

    public init(
        title: String,
        message: String? = nil,
        actions: [NNDialogAction],
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.actions = actions
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            NNColor.scrim
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss?()
                }

            VStack(spacing: 0) {
                Text(title)
                    .nnTextStyle(.title2)
                    .foregroundStyle(NNColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                if let message, !message.isEmpty {
                    Text(message)
                        .nnTextStyle(.subhead)
                        .foregroundStyle(NNColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                }

                VStack(spacing: 8) {
                    ForEach(actions) { item in
                        NNButton(item.label, variant: item.variant, fullWidth: true, action: item.action)
                    }
                }
                .padding(.top, 20)
            }
            .padding(.top, 24)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: 300)
            .background(
                NNColor.surfaceCard,
                in: RoundedRectangle(cornerRadius: NNRadius.card, style: .continuous)
            )
            .nnShadow(.float)
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
    }
}

public extension View {
    /// Presents an `NNDialog` centered over the current view hierarchy.
    func nnDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        actions: [NNDialogAction]
    ) -> some View {
        overlay {
            if isPresented.wrappedValue {
                NNDialog(
                    title: title,
                    message: message,
                    actions: actions,
                    onDismiss: { isPresented.wrappedValue = false }
                )
            }
        }
        .animation(NNMotion.easeStandard(duration: NNMotion.durBase), value: isPresented.wrappedValue)
    }
}

// MARK: - NNSheetHeader & NNSheetContainer

/// Bottom sheet grabber + Instrument Serif title header matching `design-system/components/feedback/Sheet.jsx`.
public struct NNSheetHeader<Trailing: View>: View {
    public let title: String?
    public let showGrabber: Bool
    private let trailing: Trailing

    public init(
        title: String? = nil,
        showGrabber: Bool = true,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.showGrabber = showGrabber
        self.trailing = trailing()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showGrabber {
                HStack {
                    Spacer()
                    Capsule()
                        .fill(NNColor.fill2)
                        .frame(width: 36, height: 5)
                    Spacer()
                }
                .padding(.bottom, 12)
            }

            if title != nil || Trailing.self != EmptyView.self {
                HStack(alignment: .center, spacing: 12) {
                    if let title {
                        Text(title)
                            .nnTextStyle(.title2)
                            .foregroundStyle(NNColor.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Spacer(minLength: 0)
                    }
                    trailing
                }
                .padding(.bottom, 8)
            }
        }
    }
}

public extension NNSheetHeader where Trailing == EmptyView {
    init(title: String? = nil, showGrabber: Bool = true) {
        self.init(title: title, showGrabber: showGrabber, trailing: { EmptyView() })
    }
}

/// Complete 36pt top-rounded bottom sheet surface with grabber, title, body, and pinned footer.
public struct NNSheetContainer<Content: View, Footer: View>: View {
    public let title: String?
    public let showGrabber: Bool
    private let content: Content
    private let footer: Footer

    public init(
        title: String? = nil,
        showGrabber: Bool = true,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.showGrabber = showGrabber
        self.content = content()
        self.footer = footer()
    }

    public var body: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: NNRadius.sheet,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: NNRadius.sheet,
            style: .continuous
        )
        VStack(alignment: .leading, spacing: 0) {
            NNSheetHeader(title: title, showGrabber: showGrabber)
            content
            if Footer.self != EmptyView.self {
                footer
                    .padding(.top, 16)
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, NNSpacing.screenMargin)
        .padding(.bottom, NNSpacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NNColor.surfaceCard, in: shape)
        .nnShadow(.sheet)
    }
}

public extension NNSheetContainer where Footer == EmptyView {
    init(
        title: String? = nil,
        showGrabber: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.init(title: title, showGrabber: showGrabber, content: content, footer: { EmptyView() })
    }
}
