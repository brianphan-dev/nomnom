import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Pure sRGB color components converted from the nomnom OKLCH palette.
public struct NNRGBA: Sendable, Hashable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = min(max(red, 0.0), 1.0)
        self.green = min(max(green, 0.0), 1.0)
        self.blue = min(max(blue, 0.0), 1.0)
        self.alpha = min(max(alpha, 0.0), 1.0)
    }

    /// Converts CSS Color 4 OKLCH `(L, C, H°)` directly to gamma-encoded sRGB using Björn Ottosson's Oklab matrices.
    public static func oklch(l: Double, c: Double, h: Double, alpha: Double = 1.0) -> NNRGBA {
        let radians = h * .pi / 180.0
        let a = c * cos(radians)
        let b = c * sin(radians)

        let lPrime = l + 0.3963377774 * a + 0.2158037573 * b
        let mPrime = l - 0.1055613458 * a - 0.0638541728 * b
        let sPrime = l - 0.0894841775 * a - 1.2914855480 * b

        let l3 = lPrime * lPrime * lPrime
        let m3 = mPrime * mPrime * mPrime
        let s3 = sPrime * sPrime * sPrime

        let rLin = +4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3
        let gLin = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3
        let bLin = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3

        return NNRGBA(
            red: Self.linearToSRGB(rLin),
            green: Self.linearToSRGB(gLin),
            blue: Self.linearToSRGB(bLin),
            alpha: alpha
        )
    }

    /// Constructs an sRGB color from a 24-bit RGB hex integer (e.g., `0x1F4127`).
    public static func hex(_ rgb: UInt32, alpha: Double = 1.0) -> NNRGBA {
        NNRGBA(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0,
            alpha: alpha
        )
    }

    /// WCAG 2.1 relative luminance (`0.0` black to `1.0` white).
    public var relativeLuminance: Double {
        let r = Self.sRGBToLinear(red)
        let g = Self.sRGBToLinear(green)
        let b = Self.sRGBToLinear(blue)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// WCAG 2.1 contrast ratio against another opaque color (`1.0` to `21.0`).
    public func contrastRatio(with other: NNRGBA) -> Double {
        let l1 = relativeLuminance
        let l2 = other.relativeLuminance
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// SwiftUI `Color` in the standard sRGB color space.
    public var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    private static func linearToSRGB(_ u: Double) -> Double {
        let clamped = min(max(u, 0.0), 1.0)
        if clamped <= 0.0031308 {
            return 12.92 * clamped
        }
        return 1.055 * pow(clamped, 1.0 / 2.4) - 0.055
    }

    private static func sRGBToLinear(_ u: Double) -> Double {
        if u <= 0.04045 {
            return u / 12.92
        }
        return pow((u + 0.055) / 1.055, 2.4)
    }
}

/// Complete nomnom color token system derived directly from `design-system/tokens/colors.css`.
///
/// Visual rules:
/// - Stone (cool neutral, hue 255) carries almost every surface and text token.
/// - Persimmon is the single brand accent; text on persimmon (`onAccent`) is ALWAYS `stone950` ink, NEVER white.
/// - Protein = blueberry, Carbs = matcha, Fat = plum.
/// - Honey is only for AI "Check" warnings; beet is only for destructive actions. There is no red alert state.
public enum NNColor {
    /// Raw sRGB primitives converted mathematically from the OKLCH specifications.
    public enum Primitives {
        // MARK: Stone (cool neutral, hue 255)
        public static let stone0 = NNRGBA(red: 1.0, green: 1.0, blue: 1.0)
        public static let stone50 = NNRGBA.oklch(l: 0.985, c: 0.002, h: 255)
        public static let stone100 = NNRGBA.oklch(l: 0.962, c: 0.004, h: 255)
        public static let stone200 = NNRGBA.oklch(l: 0.92, c: 0.006, h: 255)
        public static let stone300 = NNRGBA.oklch(l: 0.865, c: 0.008, h: 255)
        public static let stone400 = NNRGBA.oklch(l: 0.72, c: 0.01, h: 255)
        public static let stone500 = NNRGBA.oklch(l: 0.55, c: 0.012, h: 255)
        public static let stone600 = NNRGBA.oklch(l: 0.45, c: 0.012, h: 255)
        public static let stone700 = NNRGBA.oklch(l: 0.36, c: 0.012, h: 255)
        public static let stone800 = NNRGBA.oklch(l: 0.28, c: 0.01, h: 255)
        public static let stone900 = NNRGBA.oklch(l: 0.21, c: 0.008, h: 255)
        public static let stone950 = NNRGBA.oklch(l: 0.16, c: 0.006, h: 255)

        // MARK: Persimmon (brand accent)
        public static let persimmon50 = NNRGBA.oklch(l: 0.97, c: 0.02, h: 52)
        public static let persimmon100 = NNRGBA.oklch(l: 0.94, c: 0.045, h: 50)
        public static let persimmon200 = NNRGBA.oklch(l: 0.88, c: 0.085, h: 48)
        public static let persimmon300 = NNRGBA.oklch(l: 0.8, c: 0.13, h: 46)
        public static let persimmon400 = NNRGBA.oklch(l: 0.73, c: 0.17, h: 43)
        public static let persimmon500 = NNRGBA.oklch(l: 0.67, c: 0.19, h: 40)
        public static let persimmon600 = NNRGBA.oklch(l: 0.59, c: 0.18, h: 38)
        public static let persimmon700 = NNRGBA.oklch(l: 0.49, c: 0.15, h: 37)
        public static let persimmon800 = NNRGBA.oklch(l: 0.4, c: 0.115, h: 37)
        public static let persimmon900 = NNRGBA.oklch(l: 0.32, c: 0.08, h: 38)

        // MARK: Macro + status hues
        public static let blueberry100 = NNRGBA.oklch(l: 0.94, c: 0.03, h: 250)
        public static let blueberry500 = NNRGBA.oklch(l: 0.6, c: 0.1, h: 250)
        public static let blueberry700 = NNRGBA.oklch(l: 0.45, c: 0.1, h: 250)

        public static let matcha100 = NNRGBA.oklch(l: 0.95, c: 0.04, h: 150)
        public static let matcha500 = NNRGBA.oklch(l: 0.66, c: 0.11, h: 150)
        public static let matcha700 = NNRGBA.oklch(l: 0.45, c: 0.09, h: 150)

        public static let plum100 = NNRGBA.oklch(l: 0.95, c: 0.03, h: 335)
        public static let plum500 = NNRGBA.oklch(l: 0.6, c: 0.1, h: 335)
        public static let plum700 = NNRGBA.oklch(l: 0.45, c: 0.1, h: 335)

        public static let honey100 = NNRGBA.oklch(l: 0.95, c: 0.06, h: 92)
        public static let honey500 = NNRGBA.oklch(l: 0.8, c: 0.14, h: 85)
        public static let honey700 = NNRGBA.oklch(l: 0.47, c: 0.09, h: 70)

        public static let beet100 = NNRGBA.oklch(l: 0.95, c: 0.03, h: 15)
        public static let beet500 = NNRGBA.oklch(l: 0.55, c: 0.16, h: 15)
        public static let beet700 = NNRGBA.oklch(l: 0.45, c: 0.14, h: 15)

        /// Deep green ground (`#1f4127`) reserved exclusively for the app icon.
        public static let appIconGreen = NNRGBA.hex(0x1F4127)
    }

    /// Light and dark RGBA pairs backing every semantic token (useful for inspection and contrast testing).
    public struct AdaptivePair: Sendable, Hashable {
        public let light: NNRGBA
        public let dark: NNRGBA

        public init(light: NNRGBA, dark: NNRGBA) {
            self.light = light
            self.dark = dark
        }

        public init(fixed: NNRGBA) {
            self.light = fixed
            self.dark = fixed
        }
    }

    /// Exact light/dark `NNRGBA` pairs for every semantic token in `tokens/colors.css`.
    public enum SemanticPairs {
        public static let bgApp = AdaptivePair(light: Primitives.stone100, dark: Primitives.stone950)
        public static let surfaceCard = AdaptivePair(light: Primitives.stone0, dark: Primitives.stone900)
        public static let surfaceChrome = AdaptivePair(
            light: NNRGBA.oklch(l: 1.0, c: 0.0, h: 0.0, alpha: 0.78),
            dark: NNRGBA.oklch(l: 0.21, c: 0.008, h: 255, alpha: 0.78)
        )
        public static let fill1 = AdaptivePair(
            light: NNRGBA.oklch(l: 0.21, c: 0.008, h: 255, alpha: 0.06),
            dark: NNRGBA.oklch(l: 1.0, c: 0.0, h: 0.0, alpha: 0.08)
        )
        public static let fill2 = AdaptivePair(
            light: NNRGBA.oklch(l: 0.21, c: 0.008, h: 255, alpha: 0.11),
            dark: NNRGBA.oklch(l: 1.0, c: 0.0, h: 0.0, alpha: 0.15)
        )
        public static let textPrimary = AdaptivePair(light: Primitives.stone950, dark: Primitives.stone50)
        public static let textSecondary = AdaptivePair(light: Primitives.stone600, dark: Primitives.stone400)
        public static let textTertiary = AdaptivePair(
            light: Primitives.stone500,
            dark: NNRGBA.oklch(l: 0.62, c: 0.01, h: 255)
        )
        public static let borderHairline = AdaptivePair(
            light: Primitives.stone200,
            dark: NNRGBA.oklch(l: 0.3, c: 0.01, h: 255)
        )
        public static let borderStrong = AdaptivePair(
            light: Primitives.stone300,
            dark: NNRGBA.oklch(l: 0.4, c: 0.012, h: 255)
        )
        public static let ink = AdaptivePair(light: Primitives.stone950, dark: Primitives.stone50)
        public static let inkHover = AdaptivePair(light: Primitives.stone800, dark: Primitives.stone200)
        public static let onInk = AdaptivePair(light: Primitives.stone0, dark: Primitives.stone950)

        public static let accent = AdaptivePair(light: Primitives.persimmon500, dark: Primitives.persimmon400)
        public static let accentHover = AdaptivePair(light: Primitives.persimmon400, dark: Primitives.persimmon300)
        public static let accentSoft = AdaptivePair(
            light: Primitives.persimmon100,
            dark: NNRGBA.oklch(l: 0.32, c: 0.07, h: 40)
        )
        public static let accentText = AdaptivePair(light: Primitives.persimmon700, dark: Primitives.persimmon300)
        /// Text on persimmon is ALWAYS ink (`stone950`), NEVER white.
        public static let onAccent = AdaptivePair(fixed: Primitives.stone950)

        public static let macroProtein = AdaptivePair(
            light: Primitives.blueberry500,
            dark: NNRGBA.oklch(l: 0.7, c: 0.1, h: 250)
        )
        public static let macroProteinSoft = AdaptivePair(
            light: Primitives.blueberry100,
            dark: NNRGBA.oklch(l: 0.3, c: 0.05, h: 250)
        )
        public static let macroProteinText = AdaptivePair(
            light: Primitives.blueberry700,
            dark: NNRGBA.oklch(l: 0.8, c: 0.08, h: 250)
        )

        public static let macroCarbs = AdaptivePair(
            light: Primitives.matcha500,
            dark: NNRGBA.oklch(l: 0.74, c: 0.11, h: 150)
        )
        public static let macroCarbsSoft = AdaptivePair(
            light: Primitives.matcha100,
            dark: NNRGBA.oklch(l: 0.3, c: 0.05, h: 150)
        )
        public static let macroCarbsText = AdaptivePair(
            light: Primitives.matcha700,
            dark: NNRGBA.oklch(l: 0.82, c: 0.09, h: 150)
        )

        public static let macroFat = AdaptivePair(
            light: Primitives.plum500,
            dark: NNRGBA.oklch(l: 0.7, c: 0.1, h: 335)
        )
        public static let macroFatSoft = AdaptivePair(
            light: Primitives.plum100,
            dark: NNRGBA.oklch(l: 0.3, c: 0.05, h: 335)
        )
        public static let macroFatText = AdaptivePair(
            light: Primitives.plum700,
            dark: NNRGBA.oklch(l: 0.8, c: 0.08, h: 335)
        )

        public static let check = AdaptivePair(fixed: Primitives.honey500)
        public static let checkSoft = AdaptivePair(
            light: Primitives.honey100,
            dark: NNRGBA.oklch(l: 0.34, c: 0.06, h: 85)
        )
        public static let checkText = AdaptivePair(
            light: Primitives.honey700,
            dark: NNRGBA.oklch(l: 0.86, c: 0.12, h: 88)
        )

        public static let positive = AdaptivePair(
            light: Primitives.matcha500,
            dark: NNRGBA.oklch(l: 0.74, c: 0.11, h: 150)
        )
        public static let positiveSoft = AdaptivePair(
            light: Primitives.matcha100,
            dark: NNRGBA.oklch(l: 0.3, c: 0.05, h: 150)
        )
        public static let positiveText = AdaptivePair(
            light: Primitives.matcha700,
            dark: NNRGBA.oklch(l: 0.82, c: 0.09, h: 150)
        )

        public static let info = AdaptivePair(
            light: Primitives.blueberry500,
            dark: NNRGBA.oklch(l: 0.7, c: 0.1, h: 250)
        )
        public static let infoSoft = AdaptivePair(
            light: Primitives.blueberry100,
            dark: NNRGBA.oklch(l: 0.3, c: 0.05, h: 250)
        )
        public static let infoText = AdaptivePair(
            light: Primitives.blueberry700,
            dark: NNRGBA.oklch(l: 0.8, c: 0.08, h: 250)
        )

        public static let danger = AdaptivePair(
            light: Primitives.beet500,
            dark: NNRGBA.oklch(l: 0.68, c: 0.15, h: 15)
        )
        public static let dangerSoft = AdaptivePair(
            light: Primitives.beet100,
            dark: NNRGBA.oklch(l: 0.3, c: 0.07, h: 15)
        )
        public static let dangerText = AdaptivePair(
            light: Primitives.beet700,
            dark: NNRGBA.oklch(l: 0.82, c: 0.1, h: 15)
        )

        public static let scrim = AdaptivePair(
            light: NNRGBA.oklch(l: 0.16, c: 0.006, h: 255, alpha: 0.45),
            dark: NNRGBA(red: 0, green: 0, blue: 0, alpha: 0.6)
        )
        public static let onPhoto = AdaptivePair(fixed: Primitives.stone0)
        public static let glassFill = AdaptivePair(fixed: NNRGBA(red: 1, green: 1, blue: 1, alpha: 0.18))
        public static let viewfinder = AdaptivePair(fixed: NNRGBA.oklch(l: 0.19, c: 0.008, h: 255))
    }

    // MARK: Primitive SwiftUI Colors
    public static let stone0 = Primitives.stone0.swiftUIColor
    public static let stone50 = Primitives.stone50.swiftUIColor
    public static let stone100 = Primitives.stone100.swiftUIColor
    public static let stone200 = Primitives.stone200.swiftUIColor
    public static let stone300 = Primitives.stone300.swiftUIColor
    public static let stone400 = Primitives.stone400.swiftUIColor
    public static let stone500 = Primitives.stone500.swiftUIColor
    public static let stone600 = Primitives.stone600.swiftUIColor
    public static let stone700 = Primitives.stone700.swiftUIColor
    public static let stone800 = Primitives.stone800.swiftUIColor
    public static let stone900 = Primitives.stone900.swiftUIColor
    public static let stone950 = Primitives.stone950.swiftUIColor

    public static let persimmon50 = Primitives.persimmon50.swiftUIColor
    public static let persimmon100 = Primitives.persimmon100.swiftUIColor
    public static let persimmon200 = Primitives.persimmon200.swiftUIColor
    public static let persimmon300 = Primitives.persimmon300.swiftUIColor
    public static let persimmon400 = Primitives.persimmon400.swiftUIColor
    public static let persimmon500 = Primitives.persimmon500.swiftUIColor
    public static let persimmon600 = Primitives.persimmon600.swiftUIColor
    public static let persimmon700 = Primitives.persimmon700.swiftUIColor
    public static let persimmon800 = Primitives.persimmon800.swiftUIColor
    public static let persimmon900 = Primitives.persimmon900.swiftUIColor

    public static let blueberry100 = Primitives.blueberry100.swiftUIColor
    public static let blueberry500 = Primitives.blueberry500.swiftUIColor
    public static let blueberry700 = Primitives.blueberry700.swiftUIColor

    public static let matcha100 = Primitives.matcha100.swiftUIColor
    public static let matcha500 = Primitives.matcha500.swiftUIColor
    public static let matcha700 = Primitives.matcha700.swiftUIColor

    public static let plum100 = Primitives.plum100.swiftUIColor
    public static let plum500 = Primitives.plum500.swiftUIColor
    public static let plum700 = Primitives.plum700.swiftUIColor

    public static let honey100 = Primitives.honey100.swiftUIColor
    public static let honey500 = Primitives.honey500.swiftUIColor
    public static let honey700 = Primitives.honey700.swiftUIColor

    public static let beet100 = Primitives.beet100.swiftUIColor
    public static let beet500 = Primitives.beet500.swiftUIColor
    public static let beet700 = Primitives.beet700.swiftUIColor

    /// Deep green app icon ground (`#1f4127`). Not used as a UI surface token.
    public static let appIconGreen = Primitives.appIconGreen.swiftUIColor

    // MARK: Adaptive Semantic SwiftUI Colors
    public static let bgApp = adaptive(SemanticPairs.bgApp)
    public static let surfaceCard = adaptive(SemanticPairs.surfaceCard)
    public static let surfaceChrome = adaptive(SemanticPairs.surfaceChrome)
    public static let fill1 = adaptive(SemanticPairs.fill1)
    public static let fill2 = adaptive(SemanticPairs.fill2)

    public static let textPrimary = adaptive(SemanticPairs.textPrimary)
    public static let textSecondary = adaptive(SemanticPairs.textSecondary)
    public static let textTertiary = adaptive(SemanticPairs.textTertiary)

    public static let borderHairline = adaptive(SemanticPairs.borderHairline)
    public static let borderStrong = adaptive(SemanticPairs.borderStrong)

    public static let ink = adaptive(SemanticPairs.ink)
    public static let inkHover = adaptive(SemanticPairs.inkHover)
    public static let onInk = adaptive(SemanticPairs.onInk)

    public static let accent = adaptive(SemanticPairs.accent)
    public static let accentHover = adaptive(SemanticPairs.accentHover)
    public static let accentSoft = adaptive(SemanticPairs.accentSoft)
    public static let accentText = adaptive(SemanticPairs.accentText)
    /// Text on persimmon is ALWAYS ink (`stone950`), NEVER white.
    public static let onAccent = adaptive(SemanticPairs.onAccent)

    public static let macroProtein = adaptive(SemanticPairs.macroProtein)
    public static let macroProteinSoft = adaptive(SemanticPairs.macroProteinSoft)
    public static let macroProteinText = adaptive(SemanticPairs.macroProteinText)

    public static let macroCarbs = adaptive(SemanticPairs.macroCarbs)
    public static let macroCarbsSoft = adaptive(SemanticPairs.macroCarbsSoft)
    public static let macroCarbsText = adaptive(SemanticPairs.macroCarbsText)

    public static let macroFat = adaptive(SemanticPairs.macroFat)
    public static let macroFatSoft = adaptive(SemanticPairs.macroFatSoft)
    public static let macroFatText = adaptive(SemanticPairs.macroFatText)

    public static let check = adaptive(SemanticPairs.check)
    public static let checkSoft = adaptive(SemanticPairs.checkSoft)
    public static let checkText = adaptive(SemanticPairs.checkText)

    public static let positive = adaptive(SemanticPairs.positive)
    public static let positiveSoft = adaptive(SemanticPairs.positiveSoft)
    public static let positiveText = adaptive(SemanticPairs.positiveText)

    public static let info = adaptive(SemanticPairs.info)
    public static let infoSoft = adaptive(SemanticPairs.infoSoft)
    public static let infoText = adaptive(SemanticPairs.infoText)

    public static let danger = adaptive(SemanticPairs.danger)
    public static let dangerSoft = adaptive(SemanticPairs.dangerSoft)
    public static let dangerText = adaptive(SemanticPairs.dangerText)

    public static let scrim = adaptive(SemanticPairs.scrim)
    public static let onPhoto = adaptive(SemanticPairs.onPhoto)
    public static let glassFill = adaptive(SemanticPairs.glassFill)
    public static let viewfinder = adaptive(SemanticPairs.viewfinder)

    /// Elevated control pill background (matches `[data-theme="dark"] .nn-seg__item.is-selected`).
    public static let segmentSelectedFill = adaptive(
        light: Primitives.stone0,
        dark: SemanticPairs.fill2.dark
    )

    /// Creates a dynamic SwiftUI `Color` that adapts automatically between Light and Dark appearances.
    public static func adaptive(_ pair: AdaptivePair) -> Color {
        adaptive(light: pair.light, dark: pair.dark)
    }

    /// Creates a dynamic SwiftUI `Color` from separate light and dark `NNRGBA` values.
    public static func adaptive(light: NNRGBA, dark: NNRGBA) -> Color {
        #if canImport(UIKit)
        return Color(
            uiColor: UIColor { traits in
                let rgba = traits.userInterfaceStyle == .dark ? dark : light
                return UIColor(
                    red: CGFloat(rgba.red),
                    green: CGFloat(rgba.green),
                    blue: CGFloat(rgba.blue),
                    alpha: CGFloat(rgba.alpha)
                )
            }
        )
        #elseif canImport(AppKit)
        return Color(
            nsColor: NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                let rgba = isDark ? dark : light
                return NSColor(
                    srgbRed: CGFloat(rgba.red),
                    green: CGFloat(rgba.green),
                    blue: CGFloat(rgba.blue),
                    alpha: CGFloat(rgba.alpha)
                )
            }
        )
        #else
        return light.swiftUIColor
        #endif
    }
}
