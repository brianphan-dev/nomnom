import CoreText
import Foundation
import SwiftUI
import Testing
@testable import NomNomDesignSystem

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

@Suite("NomNom Design System")
struct NomNomDesignSystemTests {

    // MARK: - Font Bundling & Registration

    @Test("All 4 bundled .ttf fonts exist in Bundle.module and register with CoreText")
    func bundledFontsRegisterCleanly() {
        for fileName in NNFonts.bundledFontFileNames {
            let url = NNFonts.fontURL(named: fileName)
            #expect(url != nil, "Missing bundled font \(fileName).ttf in Bundle.module")
        }

        let report1 = NNFonts.registerAll()
        let report2 = NNFonts.registerAll()

        #expect(report1.foundURLs.count == 4)
        #expect(report1.registeredCount == 4)
        #expect(report1 == report2, "registerAll() must be idempotent")

        let expectedPostScriptNames = [
            NNFonts.PostScriptName.instrumentSerifRegular,
            NNFonts.PostScriptName.instrumentSerifItalic,
            NNFonts.PostScriptName.geistRegular,
            NNFonts.PostScriptName.geistMedium,
            NNFonts.PostScriptName.geistSemiBold,
            NNFonts.PostScriptName.geistBold,
            NNFonts.PostScriptName.geistMonoRegular,
            NNFonts.PostScriptName.geistMonoMedium,
            NNFonts.PostScriptName.geistMonoSemiBold,
            NNFonts.PostScriptName.geistMonoBold,
        ]

        for name in expectedPostScriptNames {
            #expect(NNFonts.isBundled(postScriptName: name), "Expected PostScript name \(name) in bundled fonts")
            let ctFont = CTFontCreateWithName(name as CFString, 17, nil)
            let resolvedName = CTFontCopyPostScriptName(ctFont) as String
            #expect(resolvedName == name, "CoreText resolved \(resolvedName) instead of \(name)")
        }
    }

    @Test("Typography scale enforces tabular numerals and overline casing")
    func typographyScaleProperties() {
        let numericStyles: [NNTextStyle] = [.numHero, .numLg, .numMd, .numSm, .numXs]
        for style in numericStyles {
            #expect(style.isNumeric, "\(style) must be numeric")
            #expect(style.postScriptName == NNFonts.PostScriptName.geistMonoMedium)
            _ = style.font
        }

        #expect(NNTextStyle.overline.isUppercase)
        #expect(!NNTextStyle.body.isUppercase)
        #expect(NNTextStyle.display.size == 56)
        #expect(NNTextStyle.largeTitle.size == 40)
        #expect(NNTextStyle.body.size == 17)
        #expect(NNTextStyle.body.lineHeight == 22)

        for style in NNTextStyle.allCases {
            #expect(style.size > 0)
            #expect(style.lineHeight >= style.size)
            _ = style.font
        }
    }

    // MARK: - OKLCH -> sRGB Color Accuracy & Contrast Rules

    @Test("OKLCH to sRGB conversions match exact mathematical reference values")
    func oklchToSRGBConversionAccuracy() {
        func assertRGBA(
            _ actual: NNRGBA,
            expectedR: Double,
            expectedG: Double,
            expectedB: Double,
            tolerance: Double = 0.002,
            sourceLocation: SourceLocation = #_sourceLocation
        ) {
            #expect(abs(actual.red - expectedR) < tolerance, sourceLocation: sourceLocation)
            #expect(abs(actual.green - expectedG) < tolerance, sourceLocation: sourceLocation)
            #expect(abs(actual.blue - expectedB) < tolerance, sourceLocation: sourceLocation)
        }

        // Stone neutrals (cool hue 255)
        assertRGBA(NNColor.Primitives.stone100, expectedR: 0.9435, expectedG: 0.9511, expectedB: 0.9611)
        assertRGBA(NNColor.Primitives.stone950, expectedR: 0.0453, expectedG: 0.0526, expectedB: 0.0621)

        // Persimmon brand accent
        assertRGBA(NNColor.Primitives.persimmon500, expectedR: 0.9459, expectedG: 0.3811, expectedB: 0.1531)
        assertRGBA(NNColor.Primitives.persimmon400, expectedR: 0.9922, expectedG: 0.4946, expectedB: 0.2749)

        // Macros & status hues
        assertRGBA(NNColor.Primitives.blueberry500, expectedR: 0.3100, expectedG: 0.5182, expectedB: 0.7281)
        assertRGBA(NNColor.Primitives.matcha500, expectedR: 0.3643, expectedG: 0.6473, expectedB: 0.4300)
        assertRGBA(NNColor.Primitives.plum500, expectedR: 0.6469, expectedG: 0.4100, expectedB: 0.5957)
        assertRGBA(NNColor.Primitives.honey500, expectedR: 0.9053, expectedG: 0.7129, expectedB: 0.2615)
        assertRGBA(NNColor.Primitives.beet500, expectedR: 0.7374, expectedG: 0.2474, expectedB: 0.3240)

        // App icon deep green (#1f4127)
        assertRGBA(
            NNColor.Primitives.appIconGreen,
            expectedR: 31.0 / 255.0,
            expectedG: 65.0 / 255.0,
            expectedB: 39.0 / 255.0,
            tolerance: 0.0005
        )
    }

    @Test("Critical rule: text on persimmon (onAccent) is ALWAYS ink stone950 with high contrast, NEVER white")
    func onAccentIsAlwaysInkWithHighContrast() {
        let onAccentLight = NNColor.SemanticPairs.onAccent.light
        let onAccentDark = NNColor.SemanticPairs.onAccent.dark
        let stone950 = NNColor.Primitives.stone950

        #expect(onAccentLight == stone950)
        #expect(onAccentDark == stone950)

        // Must never be white
        #expect(onAccentLight.relativeLuminance < 0.02)

        // WCAG contrast against light persimmon500 and dark persimmon400
        let lightContrast = onAccentLight.contrastRatio(with: NNColor.SemanticPairs.accent.light)
        let darkContrast = onAccentDark.contrastRatio(with: NNColor.SemanticPairs.accent.dark)
        let whiteContrastLight = NNColor.Primitives.stone0.contrastRatio(with: NNColor.SemanticPairs.accent.light)

        #expect(lightContrast >= 5.5, "Expected >= 5.5:1 contrast on light accent, got \(lightContrast)")
        #expect(darkContrast >= 7.0, "Expected >= 7.0:1 contrast on dark accent, got \(darkContrast)")
        #expect(lightContrast > whiteContrastLight, "Ink must outperform white on persimmon")
    }

    @Test("Semantic light and dark pairs adapt cleanly across themes")
    func adaptiveSemanticPairs() {
        #expect(NNColor.SemanticPairs.bgApp.light == NNColor.Primitives.stone100)
        #expect(NNColor.SemanticPairs.bgApp.dark == NNColor.Primitives.stone950)
        #expect(NNColor.SemanticPairs.surfaceCard.light == NNColor.Primitives.stone0)
        #expect(NNColor.SemanticPairs.surfaceCard.dark == NNColor.Primitives.stone900)
        #expect(NNColor.SemanticPairs.textPrimary.light == NNColor.Primitives.stone950)
        #expect(NNColor.SemanticPairs.textPrimary.dark == NNColor.Primitives.stone50)
        #expect(NNColor.SemanticPairs.ink.light == NNColor.Primitives.stone950)
        #expect(NNColor.SemanticPairs.ink.dark == NNColor.Primitives.stone50)
        #expect(NNColor.SemanticPairs.onInk.light == NNColor.Primitives.stone0)
        #expect(NNColor.SemanticPairs.onInk.dark == NNColor.Primitives.stone950)
        #expect(NNColor.SemanticPairs.accent.light == NNColor.Primitives.persimmon500)
        #expect(NNColor.SemanticPairs.accent.dark == NNColor.Primitives.persimmon400)
    }

    // MARK: - Formatting & Content Fundamentals

    @Test("NNFormatting enforces nomnom numeral, unit, multiplier, and calm neutral copy rules")
    func formattingRules() {
        #expect(NNFormatting.kcal(1118) == "1,118")
        #expect(NNFormatting.kcal(1118.4) == "1,118")
        #expect(NNFormatting.kcal(1118.6) == "1,119")
        #expect(NNFormatting.kcal(0) == "0")
        #expect(NNFormatting.kcalWithUnit(612) == "612 kcal")

        #expect(NNFormatting.grams(14) == "14 g")
        #expect(NNFormatting.grams(14.2) == "14 g")
        #expect(NNFormatting.gramsCompact(62, target: 120) == "62/120g")
        #expect(NNFormatting.gramsCompact(38) == "38g")

        #expect(NNFormatting.multiplier(0.5) == "0.5×")
        #expect(NNFormatting.multiplier(0.75) == "0.75×")
        #expect(NNFormatting.multiplier(1.0) == "1×")
        #expect(NNFormatting.multiplier(1.25) == "1.25×")
        #expect(NNFormatting.multiplier(1.5) == "1.5×")
        #expect(NNFormatting.multiplier(2.0) == "2×")
        #expect(!NNFormatting.multiplier(1.5).contains("x"))

        let leftCopy = NNFormatting.remainingText(consumed: 1780, target: 2100)
        let overCopy = NNFormatting.remainingText(consumed: 2240, target: 2100)
        let exactCopy = NNFormatting.remainingText(consumed: 2100, target: 2100)
        #expect(leftCopy == "320 left")
        #expect(overCopy == "140 over")
        #expect(exactCopy == "0 left")

        let macroLine = NNFormatting.macroCompact(p: 38, c: 58, f: 24)
        #expect(macroLine == "P38 C58 F24")
        #expect(NNFormatting.macroCompact(p: nil, c: 12, f: nil) == "P– C12 F–")

        #expect(NNFormatting.metadataLine(["Lunch", "12:40"]) == "Lunch · 12:40")
        #expect(NNFormatting.metadataLine("Lunch", "12:40") == "Lunch · 12:40")
        #expect(NNFormatting.metadataLine(["Lunch", nil, "", "  ", "12:40"]) == "Lunch · 12:40")
        #expect(NNFormatting.saveButtonTitle(kcal: 697) == "Save 697 kcal to diary")
        #expect(NNFormatting.extrasSummary(count: 3, addedKcal: 122) == "3 · +122")
        #expect(NNFormatting.syncOfflineLabel(queued: 2) == "Offline · 2 queued")
        #expect(NNFormatting.syncOfflineLabel(queued: nil) == "Offline · Queued")

        // Verify calm tone: zero exclamation marks, zero emoji across generated copy
        let allSamples = [
            leftCopy,
            overCopy,
            exactCopy,
            macroLine,
            NNFormatting.saveButtonTitle(kcal: 697),
            NNFormatting.syncOfflineLabel(queued: 3),
        ]
        for text in allSamples {
            #expect(!text.contains("!"), "Copy must never include exclamation marks: \(text)")
            for scalar in text.unicodeScalars {
                #expect(!scalar.properties.isEmojiPresentation, "Copy must never include emoji: \(text)")
            }
        }
    }

    // MARK: - SF Symbols Validation

    @Test("Every NNIcon maps to a valid, non-empty native SF Symbol with zero emoji")
    func iconSymbolsAreValid() {
        #expect(!NNIcon.allCases.isEmpty)

        for icon in NNIcon.allCases {
            let regular = icon.systemName
            let filled = icon.filledSystemName

            #expect(!regular.isEmpty, "Icon \(icon) has empty systemName")
            #expect(!filled.isEmpty, "Icon \(icon) has empty filledSystemName")
            #expect(!regular.contains(" "), "Icon \(icon) systemName contains whitespace")

            for scalar in (regular + filled).unicodeScalars {
                #expect(!scalar.properties.isEmojiPresentation, "Icon \(icon) must not use emoji")
            }

            #if canImport(AppKit)
            #expect(
                NSImage(systemSymbolName: regular, accessibilityDescription: nil) != nil,
                "Invalid macOS SF Symbol '\(regular)' for NNIcon.\(icon)"
            )
            #expect(
                NSImage(systemSymbolName: filled, accessibilityDescription: nil) != nil,
                "Invalid macOS filled SF Symbol '\(filled)' for NNIcon.\(icon)"
            )
            #elseif canImport(UIKit)
            #expect(
                UIImage(systemName: regular) != nil,
                "Invalid iOS SF Symbol '\(regular)' for NNIcon.\(icon)"
            )
            #expect(
                UIImage(systemName: filled) != nil,
                "Invalid iOS filled SF Symbol '\(filled)' for NNIcon.\(icon)"
            )
            #endif
        }
    }

    // MARK: - Layout Tokens & Component Construction

    @Test("Spacing, radius, motion tokens, and component presets match spec")
    @MainActor
    func layoutAndComponentSanity() {
        #expect(NNSpacing.half == 2)
        #expect(NNSpacing.s1 == 4)
        #expect(NNSpacing.screenMargin == 20)
        #expect(NNSpacing.tapMin == 44)
        #expect(NNSpacing.controlSm == 32)
        #expect(NNSpacing.controlMd == 44)
        #expect(NNSpacing.controlLg == 56)
        #expect(NNSpacing.shutter == 72)
        #expect(NNSpacing.duoHingeClearance == 20)

        #expect(NNRadius.thumb == 16)
        #expect(NNRadius.banner == 20)
        #expect(NNRadius.card == 28)
        #expect(NNRadius.sheet == 36)

        #expect(NNMotion.durFast == 0.12)
        #expect(NNMotion.durBase == 0.22)
        #expect(NNMotion.durSheet == 0.42)
        #expect(NNMotion.pressScale == 0.97)
        #expect(NNFoodItemRow.defaultPortions == [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])

        // Smoke-instantiate all component families to validate public API signatures
        _ = NNButton("Save 697 kcal to diary", variant: .accent, size: .lg, fullWidth: true) {}
        _ = NNIconButton(icon: .settings, label: "Settings", variant: .filled) {}
        _ = NNBadge(method: .photoAI)
        _ = NNChip("light oil", selected: true) {}
        _ = NNCard { Text("Card") }
        _ = NNTextField("Search foods", text: .constant(""), icon: .search)
        _ = NNCheckbox(isChecked: .constant(false), label: "Olive oil", description: "2 tsp", trailing: "+80", dimUnchecked: true)
        _ = NNSwitch(isOn: .constant(true), label: "Apple Health")
        _ = NNStepper(value: .constant(1.5))
        _ = NNSegmentedControl(
            options: [NNSegmentOption(value: 1, label: "Photo AI", icon: .sparkle), NNSegmentOption(value: 2, label: "Barcode", icon: .barcode)],
            selection: .constant(1),
            tone: .dark
        )
        _ = NNSyncPill(status: .offline(queued: 2))
        _ = NNProgressBar(value: 1125, max: 2100, tone: .accent)
        _ = NNBanner(tone: .info, icon: .info, title: "Title", message: "Body")
        _ = NNDialog(title: "Delete your account?", message: "Permanent action.", actions: [NNDialogAction(label: "Delete", variant: .destructive) {}])
        _ = NNSheetHeader(title: "Dark chocolate almond bar")
        _ = NNSheetContainer(title: "Serving") { Text("Body") } footer: { NNButton("Add", variant: .accent) {} }
        _ = NNNavBar(largeTitle: "Today", subtitle: "Friday, 27 November")
        _ = NNListRow(icon: .appleHealth, title: "Apple Health", subtitle: "Write meals to Health")
        _ = NNCaptureDock(compact: true, onBarcode: {}, onSnap: {}, onManual: {})
        _ = NNMealPhoto(label: "captured photo")
        _ = NNMacroLine(protein: 38, carbs: 58, fat: 24)
        _ = NNMacroBar(macro: .protein, value: 62, target: 120)
        _ = NNDailySummary(
            kcal: 2240,
            target: 2100,
            protein: .init(value: 104, target: 120),
            carbs: .init(value: 212, target: 240),
            fat: .init(value: 66, target: 70),
            micros: [NNMicroValue(label: "Fiber", value: "14 g")]
        )
        _ = NNMealRow(title: "Salmon rice bowl", mealType: "Lunch", time: "12:40", kcal: 642, method: .photoAI) {}
        _ = NNFoodItemRow(
            name: "Broccolini",
            serving: "1 cup (~90g)",
            kcal: 40,
            confidence: 0.71,
            multiplier: 1.0,
            onMultiplier: { _ in },
            expanded: true,
            onToggle: {}
        )
        _ = NNWeekTrend(
            dateRange: "21 – 27 November",
            days: [
                NNWeekDayPoint(label: "Sat", kcal: 1840),
                NNWeekDayPoint(label: "Fri", kcal: 1125, isToday: true),
            ],
            targetKcal: 2100,
            averageProtein: .init(value: 104, target: 120),
            averageCarbs: .init(value: 212, target: 240),
            averageFat: .init(value: 66, target: 70)
        )
        _ = Text("Analyzing").modifier(NNShimmer())
    }
}
