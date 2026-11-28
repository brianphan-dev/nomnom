import Foundation
import SwiftUI
import UIKit
import NomNomCore
import NomNomDesignSystem
import NomNomShared

public struct SignInView: View {
    public let store: NomNomAppStore

    @Environment(\.nnLayoutClass) private var layoutClass
    @State private var appleCoordinator = AppleSignInCoordinator()
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    public init(store: NomNomAppStore) {
        self.store = store
    }

    public var body: some View {
        Group {
            if layoutClass.isDualPane {
                NNDualPaneContainer(showHingeHairline: true) {
                    dualPaneBrandSide
                } right: {
                    dualPaneActionSide
                }
            } else {
                compactLayout
            }
        }
        .background(NNColor.bgApp.ignoresSafeArea())
    }

    // MARK: - Compact (iPhone & iPhone Duo Folded)

    private var compactLayout: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                brandHeader
                    .padding(.top, layoutClass.isCompactCover ? NNSpacing.s3 : NNSpacing.s5)

                if !layoutClass.isCompactCover {
                    productVisualCard(compact: true)
                        .padding(.top, NNSpacing.s5)
                }

                Spacer(minLength: layoutClass.isCompactCover ? NNSpacing.s5 : NNSpacing.s6)

                heroAndPoints(heroSize: layoutClass.isCompactCover ? 38 : 44)
                    .padding(.top, NNSpacing.s2)

                actionsBlock
                    .padding(.top, layoutClass.isCompactCover ? NNSpacing.s5 : NNSpacing.s6)
            }
            .padding(.horizontal, NNSpacing.screenMargin)
            .padding(.bottom, NNSpacing.s6)
            .frame(maxWidth: 460, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Dual Pane (iPhone Duo Unfolded & iPad)

    private var dualPaneBrandSide: some View {
        VStack(alignment: .leading, spacing: NNSpacing.s5) {
            brandHeader
                .padding(.top, NNSpacing.s4)

            Spacer(minLength: 0)

            productVisualCard(compact: false)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, NNSpacing.screenMargin)
        .padding(.bottom, NNSpacing.s6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var dualPaneActionSide: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: NNSpacing.s6) {
                Spacer(minLength: NNSpacing.s6)

                heroAndPoints(heroSize: 44)

                actionsBlock
            }
            .padding(.horizontal, NNSpacing.screenMargin)
            .padding(.bottom, NNSpacing.s6)
            .frame(maxWidth: 440, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Building Blocks

    private var brandHeader: some View {
        HStack(spacing: 10) {
            NNPersimmonMark(size: 32)
            Text("nomnom")
                .font(NNFont.serif(size: 28, relativeTo: .title2))
                .tracking(-0.01 * 28)
                .foregroundStyle(NNColor.textPrimary)
        }
    }

    private func heroAndPoints(heroSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: NNSpacing.s5) {
            (
                Text("A food diary you can ")
                    .font(NNFont.serif(size: heroSize, relativeTo: .largeTitle))
                +
                Text("keep up with.")
                    .font(NNFont.serif(size: heroSize, italic: true, relativeTo: .largeTitle))
            )
            .tracking(-0.01 * heroSize)
            .foregroundStyle(NNColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                valuePoint(
                    icon: .camera,
                    text: "Snap a plate, scan a barcode, or log what you ate in seconds."
                )
                valuePoint(
                    icon: .cloudCheck,
                    text: "Works offline and syncs across your devices."
                )
                valuePoint(
                    icon: .exportArchive,
                    text: "Your history stays private and portable. Export it any time."
                )
            }
        }
    }

    private func valuePoint(icon: NNIcon, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            NNIconView(icon, size: 18, weight: .regular, color: NNColor.textPrimary)
                .padding(.top, 2)
            Text(text)
                .nnTextStyle(.subhead)
                .foregroundStyle(NNColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actionsBlock: some View {
        VStack(spacing: NNSpacing.s3) {
            if let errorMessage, !errorMessage.isEmpty {
                NNBanner(
                    tone: .check,
                    icon: .info,
                    title: "Sign in did not complete",
                    message: errorMessage
                )
            }

            NNButton(
                "Continue with Apple",
                variant: .primary,
                size: .lg,
                icon: .appleLogo,
                iconWeight: .fill,
                fullWidth: true,
                loading: isSigningIn,
                action: beginAppleSignIn
            )

            Text("No ads. No streaks. Delete your account any time.")
                .nnTextStyle(.caption)
                .foregroundStyle(NNColor.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 2)

            backendStatusPill
                .padding(.top, 2)
        }
    }

    private var backendStatusPill: some View {
        let host = store.apiBaseURL.host() ?? "api.nomnom.brianphan.dev"
        let statusLabel: String
        let dotColor: Color

        switch store.isBackendHealthy {
        case true:
            statusLabel = "Online"
            dotColor = NNColor.positive
        case false:
            statusLabel = "Offline"
            dotColor = NNColor.textTertiary
        case nil:
            statusLabel = "Checking\u{2026}"
            dotColor = NNColor.textTertiary
        }

        return Button {
            Task {
                _ = await store.checkBackendHealth()
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)

                Text(NNFormatting.metadataLine(host, statusLabel))
                    .font(NNFont.mono(size: 11, weight: .regular, relativeTo: .caption2))
                    .foregroundStyle(NNColor.textTertiary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(NNColor.fill1, in: Capsule())
        }
        .buttonStyle(NNPressScaleButtonStyle(scale: NNMotion.pressScale))
        .accessibilityLabel("Server status: \(host) \(statusLabel)")
    }

    private func productVisualCard(compact: Bool) -> some View {
        NNCard(tone: .default, padding: compact ? .md : .lg) {
            VStack(alignment: .leading, spacing: compact ? 12 : 16) {
                HStack(alignment: .center, spacing: 12) {
                    NNPersimmonMark(size: compact ? 40 : 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("A quiet food diary.")
                            .nnTextStyle(compact ? .headline : .title2)
                            .foregroundStyle(NNColor.textPrimary)
                        Text("Today \u{00B7} Synced")
                            .nnTextStyle(.footnote)
                            .foregroundStyle(NNColor.textSecondary)
                    }
                    Spacer(minLength: 0)
                    NNBadge(method: .photoAI)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("1,125")
                            .font(NNFont.mono(size: compact ? 28 : 34, weight: .medium, relativeTo: .title))
                            .tracking(-0.04 * (compact ? 28 : 34))
                            .foregroundStyle(NNColor.textPrimary)
                        Text("of 2,100 kcal")
                            .nnTextStyle(.footnote)
                            .foregroundStyle(NNColor.textSecondary)
                        Spacer(minLength: 4)
                        Text("975 left")
                            .nnTextStyle(.numSm)
                            .foregroundStyle(NNColor.textSecondary)
                    }

                    NNProgressBar(value: 1125, max: 2100, tone: .accent, height: 8, label: "Sample calories")

                    HStack(spacing: 12) {
                        NNMacroBar(macro: .protein, value: 68, target: 150, compact: false)
                        NNMacroBar(macro: .carbs, value: 122, target: 215, compact: false)
                        NNMacroBar(macro: .fat, value: 43, target: 70, compact: false)
                    }
                    .padding(.top, 2)
                }

                if !compact {
                    Rectangle()
                        .fill(NNColor.borderHairline)
                        .frame(height: 1)

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Salmon rice bowl")
                                .nnTextStyle(.headline)
                                .foregroundStyle(NNColor.textPrimary)
                            Text("Lunch \u{00B7} 12:40")
                                .nnTextStyle(.footnote)
                                .foregroundStyle(NNColor.textSecondary)
                        }
                        Spacer(minLength: 8)
                        NNMacroLine(protein: 38, carbs: 58, fat: 27, size: .sm)
                        Text("642")
                            .nnTextStyle(.numMd)
                            .foregroundStyle(NNColor.textPrimary)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Sign in with Apple Action

    private func beginAppleSignIn() {
        guard !isSigningIn else { return }
        errorMessage = nil
        isSigningIn = true

        Task {
            defer { isSigningIn = false }
            do {
                let deviceId = resolveDeviceId()
                let deviceName = UIDevice.current.name
                let result = try await appleCoordinator.signInWithResult(
                    deviceId: deviceId,
                    deviceName: deviceName
                )
                try? store.credentialStore.setAppleUserId(result.appleUserId)
                _ = try await store.signInWithApple(result.request)
                Task {
                    _ = try? await store.syncNow()
                }
            } catch AppleSignInError.cancelled {
                // User dismissed the Apple sheet intentionally.
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func resolveDeviceId() -> String {
        if let existing = try? store.credentialStore.loadCredentials().deviceId, !existing.isEmpty {
            return existing
        }
        if let generated = try? store.credentialStore.getOrCreateDeviceId(), !generated.isEmpty {
            return generated
        }
        return UUID().uuidString.lowercased()
    }
}

// MARK: - Persimmon Brand Mark

/// Vector rendering of the nomnom app icon (`design-system/assets/app-icon.svg`):
/// a persimmon seen from above on deep green (`#1f4127`).
public struct NNPersimmonMark: View {
    public let size: CGFloat

    public init(size: CGFloat = 32) {
        self.size = size
    }

    public var body: some View {
        let cornerRadius = size * 0.2237
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        Canvas { context, canvasSize in
            let scale = min(canvasSize.width, canvasSize.height) / 100.0
            context.scaleBy(x: scale, y: scale)

            // Deep green ground (#1f4127)
            context.fill(
                Path(CGRect(x: 0, y: 0, width: 100, height: 100)),
                with: .color(NNColor.appIconGreen)
            )

            // Slight 1.02 scale centered at (50, 50) matching app-icon.svg
            context.translateBy(x: 50, y: 50)
            context.scaleBy(x: 1.02, y: 1.02)
            context.translateBy(x: -50, y: -50)

            // Persimmon base shadow (#a33714)
            let shadowRect = CGRect(x: 19, y: 22, width: 62, height: 62)
            context.fill(
                Path(roundedRect: shadowRect, cornerRadius: 27),
                with: .color(Color(.sRGB, red: 0xA3 / 255.0, green: 0x37 / 255.0, blue: 0x14 / 255.0))
            )

            // Persimmon fruit body (#f16127)
            let fruitRect = CGRect(x: 19, y: 19, width: 62, height: 62)
            context.fill(
                Path(roundedRect: fruitRect, cornerRadius: 27),
                with: .color(Color(.sRGB, red: 0xF1 / 255.0, green: 0x61 / 255.0, blue: 0x27 / 255.0))
            )

            // Highlight sheen (#ffa274 at 0.75 opacity, rotated -38 deg around (35, 33))
            context.drawLayer { layer in
                layer.translateBy(x: 35, y: 33)
                layer.rotate(by: .degrees(-38))
                let sheen = Path(ellipseIn: CGRect(x: -8, y: -4.5, width: 16, height: 9))
                layer.fill(
                    sheen,
                    with: .color(Color(.sRGB, red: 0xFF / 255.0, green: 0xA2 / 255.0, blue: 0x74 / 255.0, opacity: 0.75))
                )
            }

            // Four green calyx leaves (#2b633a)
            let calyxColor = Color(.sRGB, red: 0x2B / 255.0, green: 0x63 / 255.0, blue: 0x3A / 255.0)
            let leafPath: Path = {
                var p = Path()
                p.move(to: CGPoint(x: 50, y: 51))
                p.addCurve(
                    to: CGPoint(x: 50, y: 29),
                    control1: CGPoint(x: 43, y: 45),
                    control2: CGPoint(x: 42.5, y: 36)
                )
                p.addCurve(
                    to: CGPoint(x: 50, y: 51),
                    control1: CGPoint(x: 57.5, y: 36),
                    control2: CGPoint(x: 57, y: 45)
                )
                p.closeSubpath()
                return p
            }()

            for angle in [45.0, 135.0, 225.0, 315.0] {
                context.drawLayer { layer in
                    layer.translateBy(x: 50, y: 50)
                    layer.rotate(by: .degrees(angle))
                    layer.translateBy(x: -50, y: -50)
                    layer.fill(leafPath, with: .color(calyxColor))
                }
            }

            // Center stem dot (#0c0d10)
            let stem = Path(ellipseIn: CGRect(x: 50 - 3.4, y: 50 - 3.4, width: 6.8, height: 6.8))
            context.fill(
                stem,
                with: .color(Color(.sRGB, red: 0x0C / 255.0, green: 0x0D / 255.0, blue: 0x10 / 255.0))
            )
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .accessibilityHidden(true)
    }
}
