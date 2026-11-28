import SwiftUI

/// Visual weight for nomnom SF Symbols matching the three Phosphor weights (`regular`, `bold`, `fill`).
public enum NNIconWeight: Sendable, Hashable {
    case regular
    case bold
    case fill
}

/// Complete SF Symbols vocabulary mapping every Phosphor icon in `design-system/` to native Apple iconography.
///
/// Zero emoji. Zero unicode glyph icons.
public enum NNIcon: String, Sendable, Hashable, CaseIterable {
    // Capture & logging modes
    case camera
    case barcode
    case manual
    case sparkle
    case scan

    // Validation & status
    case check
    case checkCircle
    case question
    case pending
    case info

    // Sync & connectivity
    case cloudCheck
    case syncing
    case cloudOffline

    // Data & integrations
    case importHistory
    case exportArchive
    case appleHealth
    case archiveBox
    case markdown

    // Editing & actions
    case trash
    case swap
    case plus
    case minus
    case search
    case clearCircle
    case chatText

    // Navigation & chrome
    case settings
    case calendar
    case close
    case back
    case chevronRight
    case caretUp
    case caretDown
    case signOut

    // Camera viewfinder controls
    case mic
    case photoLibrary
    case flash
    case flashOff
    case flashlight
    case image

    // Devices & brand
    case devicePhone
    case deviceDuo
    case devicePad
    case appleLogo

    /// Native SF Symbol name (regular / outlined form).
    public var systemName: String {
        switch self {
        case .camera: "camera"
        case .barcode: "barcode"
        case .manual: "pencil"
        case .sparkle: "sparkles"
        case .scan: "viewfinder"
        case .check: "checkmark"
        case .checkCircle: "checkmark.circle"
        case .question: "questionmark.circle"
        case .pending: "clock"
        case .info: "info.circle"
        case .cloudCheck: "checkmark.icloud"
        case .syncing: "arrow.2.circlepath"
        case .cloudOffline: "icloud.slash"
        case .importHistory: "square.and.arrow.down"
        case .exportArchive: "square.and.arrow.up"
        case .appleHealth: "waveform.path.ecg"
        case .archiveBox: "doc.zipper"
        case .markdown: "doc.text"
        case .trash: "trash"
        case .swap: "arrow.left.arrow.right"
        case .plus: "plus"
        case .minus: "minus"
        case .search: "magnifyingglass"
        case .clearCircle: "xmark.circle.fill"
        case .chatText: "text.bubble"
        case .settings: "gearshape"
        case .calendar: "calendar"
        case .close: "xmark"
        case .back: "chevron.left"
        case .chevronRight: "chevron.right"
        case .caretUp: "chevron.up"
        case .caretDown: "chevron.down"
        case .signOut: "rectangle.portrait.and.arrow.right"
        case .mic: "mic"
        case .photoLibrary: "photo.on.rectangle.angled"
        case .flash: "bolt"
        case .flashOff: "bolt.slash"
        case .flashlight: "flashlight.off.fill"
        case .image: "photo"
        case .devicePhone: "iphone"
        case .deviceDuo: "rectangle.split.2x1"
        case .devicePad: "ipad"
        case .appleLogo: "apple.logo"
        }
    }

    /// Filled SF Symbol variant when rendered with `.fill` weight.
    public var filledSystemName: String {
        switch self {
        case .camera: "camera.fill"
        case .checkCircle: "checkmark.circle.fill"
        case .question: "questionmark.circle.fill"
        case .pending: "clock.fill"
        case .info: "info.circle.fill"
        case .cloudCheck: "checkmark.icloud.fill"
        case .cloudOffline: "icloud.slash.fill"
        case .trash: "trash.fill"
        case .chatText: "text.bubble.fill"
        case .settings: "gearshape.fill"
        case .mic: "mic.fill"
        case .flash: "bolt.fill"
        case .flashOff: "bolt.slash.fill"
        case .image: "photo.fill"
        default: systemName
        }
    }

    /// Resolves the appropriate SF Symbol name for a requested weight.
    public func resolvedSystemName(for weight: NNIconWeight) -> String {
        weight == .fill ? filledSystemName : systemName
    }
}

/// Renders an `NNIcon` using SF Symbols with exact sizing and weight semantics.
public struct NNIconView: View {
    public let icon: NNIcon
    public let size: CGFloat
    public let weight: NNIconWeight
    public let color: Color?

    public init(
        _ icon: NNIcon,
        size: CGFloat = 20,
        weight: NNIconWeight = .regular,
        color: Color? = nil
    ) {
        self.icon = icon
        self.size = size
        self.weight = weight
        self.color = color
    }

    public var body: some View {
        let fontWeight: Font.Weight = switch weight {
        case .regular: .regular
        case .bold: .semibold
        case .fill: .regular
        }

        let image = Image(systemName: icon.resolvedSystemName(for: weight))
            .font(.system(size: size, weight: fontWeight))
            .imageScale(.medium)
            .accessibilityHidden(true)

        if let color {
            image.foregroundStyle(color)
        } else {
            image
        }
    }
}
