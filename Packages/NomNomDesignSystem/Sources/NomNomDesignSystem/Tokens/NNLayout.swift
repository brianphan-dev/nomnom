import SwiftUI

/// 4pt spacing grid, control heights, and device clearances from `design-system/tokens/spacing.css`.
public enum NNSpacing {
    public static let half: CGFloat = 2
    public static let s1: CGFloat = 4
    public static let s2: CGFloat = 8
    public static let s3: CGFloat = 12
    public static let s4: CGFloat = 16
    public static let s5: CGFloat = 20
    public static let s6: CGFloat = 24
    public static let s8: CGFloat = 32
    public static let s10: CGFloat = 40
    public static let s12: CGFloat = 48
    public static let s16: CGFloat = 64

    public static let screenMargin: CGFloat = 20
    public static let tapMin: CGFloat = 44
    public static let controlSm: CGFloat = 32
    public static let controlMd: CGFloat = 44
    public static let controlLg: CGFloat = 56
    public static let shutter: CGFloat = 72
    public static let shutterCompact: CGFloat = 60
    /// Minimum interactive exclusion distance from the hinge on iPhone Duo unfolded.
    public static let duoHingeClearance: CGFloat = 20
    /// Floating offset of the capture dock above the bottom safe edge on Today.
    public static let dockBottomOffset: CGFloat = 26
}

/// Corner radii scale from `design-system/tokens/spacing.css`.
///
/// Nested radii step down by padding (a 28pt card with 8pt padding holds 20pt rows).
public enum NNRadius {
    public static let r8: CGFloat = 8
    public static let r12: CGFloat = 12
    public static let r16: CGFloat = 16
    public static let r20: CGFloat = 20
    public static let r28: CGFloat = 28
    public static let r36: CGFloat = 36

    public static let thumb: CGFloat = r16
    public static let banner: CGFloat = r20
    public static let card: CGFloat = r28
    public static let sheet: CGFloat = r36
}

/// Short, quiet motion tokens matching `design-system/tokens/spacing.css`.
///
/// No bounces, no confetti, no celebratory animation. Always respects `accessibilityReduceMotion`.
public enum NNMotion {
    public static let durFast: Double = 0.12
    public static let durBase: Double = 0.22
    public static let durSheet: Double = 0.42

    public static let pressScale: CGFloat = 0.97
    public static let iconPressScale: CGFloat = 0.92
    public static let shutterPressScale: CGFloat = 0.94

    /// iOS-style decelerate (`cubic-bezier(0.32, 0.72, 0, 1)`) for sheets, switches, and progress bars.
    public static var easeOut: Animation {
        easeOut(duration: durSheet)
    }

    /// Standard ease (`cubic-bezier(0.4, 0, 0.2, 1)`) for presses, fades, and subtle state changes.
    public static var easeStandard: Animation {
        easeStandard(duration: durBase)
    }

    public static func easeOut(duration: Double = durSheet) -> Animation {
        .timingCurve(0.32, 0.72, 0.0, 1.0, duration: duration)
    }

    public static func easeStandard(duration: Double = durBase) -> Animation {
        .timingCurve(0.4, 0.0, 0.2, 1.0, duration: duration)
    }
}

/// Elevation shadows: nomnom is flat by default. Only three things cast shadows:
/// switch/segment knobs (`.knob`), floating chrome like CaptureDock/Dialog (`.float`), and bottom sheets (`.sheet`).
public enum NNShadow: Sendable, Hashable {
    case knob
    case float
    case sheet

    fileprivate static let shadowBase = NNRGBA.oklch(l: 0.2, c: 0.01, h: 255)
}

public struct NNShadowModifier: ViewModifier {
    public let style: NNShadow

    public init(_ style: NNShadow) {
        self.style = style
    }

    public func body(content: Content) -> some View {
        switch style {
        case .knob:
            content.shadow(
                color: NNShadow.shadowBase.withAlpha(0.22).swiftUIColor,
                radius: 2,
                x: 0,
                y: 1
            )
        case .float:
            content
                .shadow(
                    color: NNShadow.shadowBase.withAlpha(0.06).swiftUIColor,
                    radius: 1.5,
                    x: 0,
                    y: 1
                )
                .shadow(
                    color: NNShadow.shadowBase.withAlpha(0.22).swiftUIColor,
                    radius: 16,
                    x: 0,
                    y: 10
                )
        case .sheet:
            content.shadow(
                color: NNShadow.shadowBase.withAlpha(0.20).swiftUIColor,
                radius: 20,
                x: 0,
                y: -8
            )
        }
    }
}

private extension NNRGBA {
    func withAlpha(_ newAlpha: Double) -> NNRGBA {
        NNRGBA(red: red, green: green, blue: blue, alpha: newAlpha)
    }
}

/// Subtle horizontal shimmer for the AI analysing placeholder state, respecting `accessibilityReduceMotion`.
public struct NNShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1.0

    public let baseColor: Color
    public let highlightColor: Color

    public init(baseColor: Color = NNColor.fill1, highlightColor: Color = NNColor.fill2) {
        self.baseColor = baseColor
        self.highlightColor = highlightColor
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                if reduceMotion {
                    baseColor
                } else {
                    GeometryReader { proxy in
                        let width = max(proxy.size.width, 1)
                        LinearGradient(
                            stops: [
                                .init(color: baseColor, location: 0.0),
                                .init(color: highlightColor, location: 0.5),
                                .init(color: baseColor, location: 1.0),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: width * 2)
                        .offset(x: phase * width)
                        .onAppear {
                            phase = -1.0
                            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                                phase = 1.0
                            }
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
            .clipped()
    }
}

/// Alias for `NNShimmerModifier` matching design system naming.
public typealias NNShimmer = NNShimmerModifier

public extension View {
    /// Applies one of the three sanctioned nomnom elevation shadows.
    func nnShadow(_ shadow: NNShadow) -> some View {
        modifier(NNShadowModifier(shadow))
    }

    /// Applies the calm nomnom analysing shimmer (automatically suppressed under Reduce Motion).
    func nnShimmer(
        baseColor: Color = NNColor.fill1,
        highlightColor: Color = NNColor.fill2
    ) -> some View {
        modifier(NNShimmerModifier(baseColor: baseColor, highlightColor: highlightColor))
    }
}
