import CoreText
import Foundation
import SwiftUI

/// Bundled font registration and inspection for the nomnom typography system.
///
/// Bundles four SIL OFL `.ttf` fonts in `Bundle.module`:
/// - `InstrumentSerif-Regular.ttf` (`InstrumentSerif-Regular`)
/// - `InstrumentSerif-Italic.ttf` (`InstrumentSerif-Italic`)
/// - `Geist-Variable.ttf` (`Geist-Regular`, `Geist-Medium`, `Geist-SemiBold`, `Geist-Bold`, …)
/// - `GeistMono-Variable.ttf` (`GeistMono-Regular`, `GeistMono-Medium`, `GeistMono-SemiBold`, …)
public enum NNFonts {
    /// Expected bundled font file basenames (without `.ttf`).
    public static let bundledFontFileNames: [String] = [
        "InstrumentSerif-Regular",
        "InstrumentSerif-Italic",
        "Geist-Variable",
        "GeistMono-Variable",
    ]

    /// Exact PostScript names verified via `CTFontManagerCreateFontDescriptorsFromURL`.
    public enum PostScriptName {
        public static let instrumentSerifRegular = "InstrumentSerif-Regular"
        public static let instrumentSerifItalic = "InstrumentSerif-Italic"

        public static let geistRegular = "Geist-Regular"
        public static let geistMedium = "Geist-Medium"
        public static let geistSemiBold = "Geist-SemiBold"
        public static let geistBold = "Geist-Bold"

        public static let geistMonoRegular = "GeistMono-Regular"
        public static let geistMonoMedium = "GeistMono-Medium"
        public static let geistMonoSemiBold = "GeistMono-SemiBold"
        public static let geistMonoBold = "GeistMono-Bold"
    }

    /// Thread-safe, idempotent one-time registration result backed by `static let` (`dispatch_once`).
    private static let registrationResult: RegistrationReport = {
        var foundURLs: [URL] = []
        var registeredCount = 0
        var registeredPSNames: Set<String> = []

        for fileName in bundledFontFileNames {
            guard let url = fontURL(named: fileName) else { continue }
            foundURLs.append(url)

            var errorRef: Unmanaged<CFError>?
            let succeeded = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &errorRef)
            if succeeded {
                registeredCount += 1
            } else if let error = errorRef?.takeRetainedValue() {
                let code = CFErrorGetCode(error)
                // kCTFontManagerErrorAlreadyRegistered == 105
                if code == CTFontManagerError.alreadyRegistered.rawValue {
                    registeredCount += 1
                }
            }

            if let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor] {
                for descriptor in descriptors {
                    if let name = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String {
                        registeredPSNames.insert(name)
                    }
                }
            }
        }

        return RegistrationReport(
            foundURLs: foundURLs,
            registeredCount: registeredCount,
            availablePostScriptNames: registeredPSNames
        )
    }()

    /// Result snapshot returned by `registerAll()`.
    public struct RegistrationReport: Sendable, Hashable {
        public let foundURLs: [URL]
        public let registeredCount: Int
        public let availablePostScriptNames: Set<String>
    }

    /// Registers all four bundled nomnom fonts with CoreText for the current process.
    ///
    /// Safe and idempotent to call multiple times (at app launch, in SwiftUI previews, or in unit tests).
    @discardableResult
    public static func registerAll() -> RegistrationReport {
        registrationResult
    }

    /// Locates a bundled `.ttf` file inside `Bundle.module` regardless of SwiftPM directory flattening.
    public static func fontURL(named fileName: String) -> URL? {
        if let url = Bundle.module.url(forResource: fileName, withExtension: "ttf", subdirectory: "Fonts") {
            return url
        }
        return Bundle.module.url(forResource: fileName, withExtension: "ttf")
    }

    /// Returns whether a PostScript name was discovered in the bundled fonts.
    public static func isBundled(postScriptName: String) -> Bool {
        registrationResult.availablePostScriptNames.contains(postScriptName)
    }
}

/// Complete nomnom typography ramp matching `design-system/tokens/typography.css`.
public enum NNTextStyle: Sendable, Hashable, CaseIterable {
    // Editorial titles: Instrument Serif (regular only; italic for one emphasised phrase)
    case display
    case displayItalic
    case largeTitle
    case title1
    case title2

    // UI text: Geist (iOS Dynamic Type "Large" ramp)
    case title3
    case headline
    case body
    case callout
    case subhead
    case footnote
    case caption
    case overline

    // Tabular numerals: Geist Mono (every calorie, gram, multiplier, table cell)
    case numHero
    case numLg
    case numMd
    case numSm
    case numXs

    /// Nominal point size at Dynamic Type Large.
    public var size: CGFloat {
        switch self {
        case .display, .displayItalic: 56
        case .largeTitle: 40
        case .title1: 32
        case .title2: 26
        case .title3: 20
        case .headline: 17
        case .body: 17
        case .callout: 16
        case .subhead: 15
        case .footnote: 13
        case .caption: 12
        case .overline: 11
        case .numHero: 56
        case .numLg: 28
        case .numMd: 17
        case .numSm: 13
        case .numXs: 11
        }
    }

    /// Target line height in points.
    public var lineHeight: CGFloat {
        switch self {
        case .display, .displayItalic: 56
        case .largeTitle: 44
        case .title1: 36
        case .title2: 30
        case .title3: 25
        case .headline: 22
        case .body: 22
        case .callout: 21
        case .subhead: 20
        case .footnote: 18
        case .caption: 16
        case .overline: 13
        case .numHero: 56
        case .numLg: 32
        case .numMd: 22
        case .numSm: 18
        case .numXs: 13
        }
    }

    /// Tracking in points (`em * size`) matching CSS `--tracking-*` tokens.
    public var tracking: CGFloat {
        switch self {
        case .display, .displayItalic, .largeTitle, .title1, .title2:
            -0.01 * size
        case .title3, .headline, .body, .callout, .subhead, .footnote:
            -0.01 * size
        case .caption:
            0
        case .overline:
            0.08 * size
        case .numHero:
            -0.05 * size
        case .numLg, .numMd, .numSm, .numXs:
            -0.02 * size
        }
    }

    /// Whether this style is strictly tabular numerals.
    public var isNumeric: Bool {
        switch self {
        case .numHero, .numLg, .numMd, .numSm, .numXs: true
        default: false
        }
    }

    /// Whether this style uses uppercase text transformation (`.overline`).
    public var isUppercase: Bool {
        self == .overline
    }

    /// PostScript font name for this style.
    public var postScriptName: String {
        switch self {
        case .display, .largeTitle, .title1, .title2:
            NNFonts.PostScriptName.instrumentSerifRegular
        case .displayItalic:
            NNFonts.PostScriptName.instrumentSerifItalic
        case .title3, .headline:
            NNFonts.PostScriptName.geistSemiBold
        case .body, .callout, .subhead, .footnote:
            NNFonts.PostScriptName.geistRegular
        case .caption:
            NNFonts.PostScriptName.geistMedium
        case .overline, .numHero, .numLg, .numMd, .numSm, .numXs:
            NNFonts.PostScriptName.geistMonoMedium
        }
    }

    /// Dynamic Type scaling anchor.
    public var relativeTextStyle: Font.TextStyle {
        switch self {
        case .display, .displayItalic, .largeTitle, .numHero: .largeTitle
        case .title1, .numLg: .title
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .body, .numMd: .body
        case .callout: .callout
        case .subhead: .subheadline
        case .footnote, .numSm: .footnote
        case .caption: .caption
        case .overline, .numXs: .caption2
        }
    }

    /// Resolved SwiftUI `Font` using bundled nomnom fonts with clean system fallbacks.
    public var font: Font {
        _ = NNFonts.registerAll()
        let base: Font
        if NNFonts.isBundled(postScriptName: postScriptName) {
            base = .custom(postScriptName, size: size, relativeTo: relativeTextStyle)
        } else {
            base = fallbackFont
        }
        return isNumeric ? base.monospacedDigit() : base
    }

    private var fallbackFont: Font {
        switch self {
        case .display, .largeTitle, .title1, .title2:
            .system(size: size, weight: .regular, design: .serif)
        case .displayItalic:
            .system(size: size, weight: .regular, design: .serif).italic()
        case .title3, .headline:
            .system(size: size, weight: .semibold, design: .default)
        case .body, .callout, .subhead, .footnote:
            .system(size: size, weight: .regular, design: .default)
        case .caption:
            .system(size: size, weight: .medium, design: .default)
        case .overline, .numHero, .numLg, .numMd, .numSm, .numXs:
            .system(size: size, weight: .medium, design: .monospaced)
        }
    }
}

/// Direct `Font` helpers for nomnom text styles and custom sizes.
public enum NNFont {
    public static var display: Font { NNTextStyle.display.font }
    public static var displayItalic: Font { NNTextStyle.displayItalic.font }
    public static var largeTitle: Font { NNTextStyle.largeTitle.font }
    public static var title1: Font { NNTextStyle.title1.font }
    public static var title2: Font { NNTextStyle.title2.font }
    public static var title3: Font { NNTextStyle.title3.font }
    public static var headline: Font { NNTextStyle.headline.font }
    public static var body: Font { NNTextStyle.body.font }
    public static var callout: Font { NNTextStyle.callout.font }
    public static var subhead: Font { NNTextStyle.subhead.font }
    public static var footnote: Font { NNTextStyle.footnote.font }
    public static var caption: Font { NNTextStyle.caption.font }
    public static var overline: Font { NNTextStyle.overline.font }

    public static var numHero: Font { NNTextStyle.numHero.font }
    public static var numLg: Font { NNTextStyle.numLg.font }
    public static var numMd: Font { NNTextStyle.numMd.font }
    public static var numSm: Font { NNTextStyle.numSm.font }
    public static var numXs: Font { NNTextStyle.numXs.font }

    /// Instrument Serif at an explicit size (regular or italic).
    public static func serif(
        size: CGFloat,
        italic: Bool = false,
        relativeTo textStyle: Font.TextStyle = .title
    ) -> Font {
        _ = NNFonts.registerAll()
        let ps = italic ? NNFonts.PostScriptName.instrumentSerifItalic : NNFonts.PostScriptName.instrumentSerifRegular
        if NNFonts.isBundled(postScriptName: ps) {
            return .custom(ps, size: size, relativeTo: textStyle)
        }
        let fallback = Font.system(size: size, weight: .regular, design: .serif)
        return italic ? fallback.italic() : fallback
    }

    /// Geist sans-serif at an explicit size and weight.
    public static func sans(
        size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        _ = NNFonts.registerAll()
        let ps: String
        switch weight {
        case .semibold: ps = NNFonts.PostScriptName.geistSemiBold
        case .bold, .heavy, .black: ps = NNFonts.PostScriptName.geistBold
        case .medium: ps = NNFonts.PostScriptName.geistMedium
        default: ps = NNFonts.PostScriptName.geistRegular
        }
        if NNFonts.isBundled(postScriptName: ps) {
            return .custom(ps, size: size, relativeTo: textStyle)
        }
        return .system(size: size, weight: weight, design: .default)
    }

    /// Geist Mono tabular numeral font at an explicit size and weight.
    public static func mono(
        size: CGFloat,
        weight: Font.Weight = .medium,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        _ = NNFonts.registerAll()
        let ps: String
        switch weight {
        case .regular, .light, .thin, .ultraLight: ps = NNFonts.PostScriptName.geistMonoRegular
        case .semibold: ps = NNFonts.PostScriptName.geistMonoSemiBold
        case .bold, .heavy, .black: ps = NNFonts.PostScriptName.geistMonoBold
        default: ps = NNFonts.PostScriptName.geistMonoMedium
        }
        let base: Font = NNFonts.isBundled(postScriptName: ps)
            ? .custom(ps, size: size, relativeTo: textStyle)
            : .system(size: size, weight: weight, design: .monospaced)
        return base.monospacedDigit()
    }
}

/// View modifier that applies a complete `NNTextStyle` (font, tracking, line spacing, tabular numerals, uppercase).
public struct NNTextStyleModifier: ViewModifier {
    public let style: NNTextStyle

    public init(_ style: NNTextStyle) {
        self.style = style
    }

    public func body(content: Content) -> some View {
        let extraLeading = max(0, style.lineHeight - style.size)
        content
            .font(style.font)
            .tracking(style.tracking)
            .lineSpacing(extraLeading)
            .textCase(style.isUppercase ? .uppercase : nil)
    }
}

public extension View {
    /// Applies the nomnom typography token (`font`, `tracking`, `lineSpacing`, and `textCase` for overlines).
    func nnTextStyle(_ style: NNTextStyle) -> some View {
        modifier(NNTextStyleModifier(style))
    }

    /// Convenience helper for section overlines (`11pt` Geist Mono uppercase in `textTertiary`).
    func nnOverlineStyle() -> some View {
        self
            .nnTextStyle(.overline)
            .foregroundStyle(NNColor.textTertiary)
    }
}
