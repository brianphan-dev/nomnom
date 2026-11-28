import SwiftUI
import UIKit
import NomNomDesignSystem

/// Responsive device layout class for iPhone, iPhone Duo (folded 5.4" cover & unfolded 7.6" inner), and iPad.
public enum NNLayoutClass: Equatable, Sendable {
    /// Standard single-column iPhone layout.
    case phone
    /// iPhone Duo folded 5.4" cover display (~466 x 678 pt): compact summary + compact capture dock.
    case duoFolded
    /// Dual-pane layout: iPhone Duo unfolded 7.6" inner display (~890 x 626 pt) or iPad.
    case dualPane(isDuoUnfolded: Bool)

    public var isDualPane: Bool {
        if case .dualPane = self { return true }
        return false
    }

    public var isCompactCover: Bool {
        self == .duoFolded
    }

    public var isDuoUnfolded: Bool {
        if case let .dualPane(isDuo) = self { return isDuo }
        return false
    }

    /// Computes layout class on the main actor using the current `UIDevice` idiom.
    @MainActor
    public static func resolve(
        size: CGSize,
        horizontalSizeClass: UserInterfaceSizeClass?
    ) -> NNLayoutClass {
        resolve(
            size: size,
            horizontalSizeClass: horizontalSizeClass,
            idiom: UIDevice.current.userInterfaceIdiom
        )
    }

    /// Computes layout class from container geometry, horizontal size class, and explicit device idiom.
    ///
    /// - iPhone Duo unfolded (890 x 626 pt) and iPad (width >= 700 pt or regular width): `.dualPane`
    /// - iPhone Duo folded (466 x 678 pt — short/wide compact cover): `.duoFolded`
    /// - Standard iPhone portrait (e.g. 393 x 852 or 402 x 874 pt): `.phone`
    public static func resolve(
        size: CGSize,
        horizontalSizeClass: UserInterfaceSizeClass?,
        idiom: UIUserInterfaceIdiom
    ) -> NNLayoutClass {
        let width = max(size.width, 1)
        let height = max(size.height, 1)

        if width >= 640 || (idiom == .pad && horizontalSizeClass == .regular && width >= 620) {
            let isDuoUnfolded = (idiom == .phone) || (width >= 640 && width <= 960 && height <= 720)
            return .dualPane(isDuoUnfolded: isDuoUnfolded)
        }

        // iPhone Duo cover screen is distinctly wider & shorter than standard portrait iPhones
        // (PRD / design system spec: 466 x 678 pt, aspect ~0.687 vs standard iPhone ~0.46).
        let aspectRatio = width / height
        if height <= 720 && aspectRatio >= 0.56 {
            return .duoFolded
        }

        return .phone
    }
}

/// Environment key propagating the current `NNLayoutClass` down the SwiftUI hierarchy.
private struct NNLayoutClassKey: EnvironmentKey {
    static let defaultValue: NNLayoutClass = .phone
}

public extension EnvironmentValues {
    var nnLayoutClass: NNLayoutClass {
        get { self[NNLayoutClassKey.self] }
        set { self[NNLayoutClassKey.self] = newValue }
    }
}

/// Dual-pane split container honoring the design system's 20pt hinge clearance rule on each side
/// (40pt total exclusion gutter around the center fold on iPhone Duo unfolded, mirrored cleanly on iPad).
public struct NNDualPaneContainer<Left: View, Right: View>: View {
    private let leftRatio: CGFloat
    private let showHingeHairline: Bool
    private let left: Left
    private let right: Right

    public init(
        leftRatio: CGFloat = 0.5,
        showHingeHairline: Bool = true,
        @ViewBuilder left: () -> Left,
        @ViewBuilder right: () -> Right
    ) {
        self.leftRatio = leftRatio
        self.showHingeHairline = showHingeHairline
        self.left = left()
        self.right = right()
    }

    public var body: some View {
        GeometryReader { proxy in
            let totalWidth = max(proxy.size.width, 1)
            let hingeClearance = NNSpacing.duoHingeClearance
            let centerDividerWidth: CGFloat = 1
            let usableWidth = max(totalWidth - centerDividerWidth, 1)
            let leftWidth = usableWidth * leftRatio
            let rightWidth = usableWidth - leftWidth

            HStack(spacing: 0) {
                left
                    .padding(.trailing, hingeClearance)
                    .frame(width: leftWidth, height: proxy.size.height, alignment: .top)
                    .clipped()

                if showHingeHairline {
                    Rectangle()
                        .fill(NNColor.borderHairline)
                        .frame(width: centerDividerWidth)
                        .ignoresSafeArea(edges: .vertical)
                } else {
                    Color.clear.frame(width: centerDividerWidth)
                }

                right
                    .padding(.leading, hingeClearance)
                    .frame(width: rightWidth, height: proxy.size.height, alignment: .top)
                    .clipped()
            }
            .background(NNColor.bgApp.ignoresSafeArea())
        }
    }
}
