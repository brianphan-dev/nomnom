import SwiftUI
import UIKit
import NomNomShared
import NomNomCore
import NomNomDesignSystem

/// Application settings screen for account status, sync, daily targets, preferences,
/// portable exports, and permanent account deletion.
public struct SettingsView: View {
    private let store: NomNomAppStore
    private let onClose: () -> Void
    private let onOpenImport: () -> Void

    @State private var isSyncing: Bool = false
    @State private var isSigningOut: Bool = false
    @State private var isDeletingAccount: Bool = false
    @State private var isExporting: Bool = false
    @State private var statusBannerTitle: String?
    @State private var statusBannerMessage: String?
    @State private var showDeleteDialog: Bool = false
    @State private var showRevocationNotice: Bool = false
    @State private var activeShareFile: ExportedShareFile?
    @State private var lastExportedFile: ExportedShareFile?

    public init(
        store: NomNomAppStore,
        onClose: @escaping () -> Void,
        onOpenImport: @escaping () -> Void
    ) {
        self.store = store
        self.onClose = onClose
        self.onOpenImport = onOpenImport
    }

    private var userDisplayName: String {
        if let name = store.currentUser?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty
        {
            return name
        }
        return store.isSignedIn ? "Apple Account" : "Local diary"
    }

    private var avatarInitial: String {
        if let first = userDisplayName.first {
            return String(first).lowercased()
        }
        return "n"
    }

    private var serverHostLabel: String {
        store.apiBaseURL.host ?? store.apiBaseURL.absoluteString
    }

    private var lastSyncedLabel: String {
        guard let lastSyncedAt = store.lastSyncedAt else {
            return "Not synced yet"
        }
        return "Last synced \(lastSyncedAt.formatted(date: .omitted, time: .shortened))"
    }

    private var serverStatusSubtitle: String {
        let healthPart: String
        if store.isOffline {
            healthPart = "Offline"
        } else if store.isBackendHealthy == true {
            healthPart = "Server reachable"
        } else if store.isBackendHealthy == false {
            healthPart = "Server unreachable"
        } else {
            healthPart = "Checking server\u{2026}"
        }

        let queuePart = store.queuedCount > 0
            ? "\(store.queuedCount) queued"
            : "No pending changes"

        return NNFormatting.metadataLine(healthPart, queuePart)
    }

    private var serverStatusBadge: (title: String, tone: NNBadgeTone) {
        if store.isOffline {
            return ("Offline", .neutral)
        }
        if store.isBackendHealthy == true {
            return ("Online", .positive)
        }
        if store.isBackendHealthy == false {
            return ("Offline", .neutral)
        }
        return ("Checking", .neutral)
    }

    public var body: some View {
        VStack(spacing: 0) {
            NNNavBar(
                largeTitle: "Settings",
                trailing: {
                    NNIconButton(
                        icon: .close,
                        label: "Close",
                        variant: .filled,
                        size: 36,
                        action: onClose
                    )
                }
            )
            .padding(.top, NNSpacing.s2)

            ScrollView {
                VStack(alignment: .leading, spacing: NNSpacing.s5) {
                    if let title = statusBannerTitle, let message = statusBannerMessage {
                        NNBanner(tone: .info, icon: .info, title: title, message: message)
                    }

                    accountSection
                    syncSection
                    dailyTargetsSection
                    preferencesSection
                    dataPortabilitySection
                    accountActionsSection

                    Text("nomnom 0.1 \u{00B7} No ads, no trackers")
                        .nnTextStyle(.caption)
                        .foregroundStyle(NNColor.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, NNSpacing.s1)
                }
                .padding(.horizontal, NNSpacing.screenMargin)
                .padding(.top, NNSpacing.s4)
                .padding(.bottom, NNSpacing.s8)
            }
        }
        .background(NNColor.bgApp.ignoresSafeArea())
        .task {
            _ = await store.checkBackendHealth()
        }
        .sheet(item: $activeShareFile) { file in
            ActivityShareSheet(items: [file.url])
                .presentationDetents([.medium, .large])
        }
        .nnDialog(
            isPresented: $showDeleteDialog,
            title: "Delete your account and all synced meals?",
            message: "This permanently deletes your diary, photos and synced data on every device, and revokes Sign in with Apple. Export an archive first if you want a copy.",
            actions: [
                NNDialogAction(label: "Delete account", variant: .destructive) {
                    showDeleteDialog = false
                    Task {
                        await performDeleteAccount()
                    }
                },
                NNDialogAction(label: "Keep account", variant: .secondary) {
                    showDeleteDialog = false
                },
            ]
        )
        .nnDialog(
            isPresented: $showRevocationNotice,
            title: "Account deleted",
            message: "Your diary and synced meals have been deleted. If nomnom still appears under Settings \u{00B7} Apple Account \u{00B7} Sign in with Apple, you can revoke access manually there.",
            actions: [
                NNDialogAction(label: "Done", variant: .primary) {
                    showRevocationNotice = false
                    onClose()
                },
            ]
        )
    }

    // MARK: - Sections

    private var accountSection: some View {
        NNCard(padding: .md) {
            HStack(spacing: NNSpacing.s3) {
                Text(avatarInitial)
                    .font(NNFont.serif(size: 24))
                    .foregroundStyle(NNColor.onInk)
                    .frame(width: 48, height: 48)
                    .background(NNColor.ink, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(userDisplayName)
                        .nnTextStyle(.headline)
                        .foregroundStyle(NNColor.textPrimary)

                    HStack(spacing: 6) {
                        if store.isSignedIn {
                            NNIconView(.appleLogo, size: 12, weight: .fill, color: NNColor.textSecondary)
                            Text("Signed in with Apple")
                                .nnTextStyle(.footnote)
                                .foregroundStyle(NNColor.textSecondary)
                        } else {
                            Text("Not signed in")
                                .nnTextStyle(.footnote)
                                .foregroundStyle(NNColor.textSecondary)
                        }

                        if store.currentUser?.isPrivateEmail == true {
                            NNBadge("Hide My Email", tone: .neutral)
                        }
                    }

                    if let email = store.currentUser?.email, !email.isEmpty {
                        Text(email)
                            .nnTextStyle(.footnote)
                            .foregroundStyle(NNColor.textTertiary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var syncSection: some View {
        let badge = serverStatusBadge
        return VStack(alignment: .leading, spacing: NNSpacing.s2) {
            HStack {
                Text("Sync")
                    .nnOverlineStyle()
                Spacer()
                Text(lastSyncedLabel)
                    .nnOverlineStyle()
            }
            .padding(.horizontal, 4)

            NNCard(padding: .none) {
                NNListRow(
                    icon: store.isOffline ? .cloudOffline : .cloudCheck,
                    title: serverHostLabel,
                    subtitle: serverStatusSubtitle,
                    trailing: {
                        NNBadge(badge.title, tone: badge.tone)
                    }
                )
            }

            NNButton(
                isSyncing ? "Syncing\u{2026}" : "Sync now",
                variant: .secondary,
                size: .md,
                icon: .syncing,
                fullWidth: true,
                loading: isSyncing
            ) {
                Task {
                    await performSyncNow()
                }
            }
            .disabled(!store.isSignedIn)
        }
    }

    private var dailyTargetsSection: some View {
        VStack(alignment: .leading, spacing: NNSpacing.s2) {
            Text("Daily targets")
                .nnOverlineStyle()
                .padding(.horizontal, 4)

            NNCard(padding: .none) {
                VStack(spacing: 0) {
                    targetRow(
                        title: "Calories",
                        subtitle: "Daily energy target",
                        value: Binding(
                            get: { Double(store.targets.caloriesKcal) },
                            set: { store.targets.caloriesKcal = Int($0.rounded()) }
                        ),
                        step: 50,
                        range: 1000...5000,
                        showSeparator: false
                    ) { value in
                        NNFormatting.kcal(value)
                    }

                    targetRow(
                        title: "Protein",
                        subtitle: "Grams per day",
                        value: Binding(
                            get: { Double(store.targets.proteinG) },
                            set: { store.targets.proteinG = Int($0.rounded()) }
                        ),
                        step: 5,
                        range: 30...350,
                        showSeparator: true
                    ) { value in
                        "\(Int(value.rounded())) g"
                    }

                    targetRow(
                        title: "Carbs",
                        subtitle: "Grams per day",
                        value: Binding(
                            get: { Double(store.targets.carbsG) },
                            set: { store.targets.carbsG = Int($0.rounded()) }
                        ),
                        step: 5,
                        range: 20...600,
                        showSeparator: true
                    ) { value in
                        "\(Int(value.rounded())) g"
                    }

                    targetRow(
                        title: "Fat",
                        subtitle: "Grams per day",
                        value: Binding(
                            get: { Double(store.targets.fatG) },
                            set: { store.targets.fatG = Int($0.rounded()) }
                        ),
                        step: 5,
                        range: 20...250,
                        showSeparator: true
                    ) { value in
                        "\(Int(value.rounded())) g"
                    }
                }
            }
        }
    }

    private func targetRow(
        title: String,
        subtitle: String,
        value: Binding<Double>,
        step: Double,
        range: ClosedRange<Double>,
        showSeparator: Bool,
        formatter: @escaping (Double) -> String
    ) -> some View {
        NNListRow(
            title: title,
            subtitle: subtitle,
            showSeparator: showSeparator,
            trailing: {
                NNStepper(
                    value: value,
                    step: step,
                    in: range,
                    label: title,
                    formatter: formatter
                )
            }
        )
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: NNSpacing.s2) {
            Text("Preferences")
                .nnOverlineStyle()
                .padding(.horizontal, 4)

            NNCard(padding: .none) {
                VStack(spacing: 0) {
                    NNListRow(
                        icon: .camera,
                        title: "Open to camera",
                        subtitle: "Start on the viewfinder instead of Today",
                        trailing: {
                            NNSwitch(
                                isOn: Binding(
                                    get: { store.openToCamera },
                                    set: { store.openToCamera = $0 }
                                ),
                                label: "Open to camera"
                            )
                        }
                    )

                    NNListRow(
                        icon: .appleHealth,
                        title: "Apple Health sync",
                        subtitle: "Write logged meals and macros to Health",
                        showSeparator: true,
                        trailing: {
                            NNSwitch(
                                isOn: Binding(
                                    get: { store.healthKitEnabled },
                                    set: { enabled in
                                        Task {
                                            await toggleHealthKit(enabled)
                                        }
                                    }
                                ),
                                label: "Apple Health sync"
                            )
                        }
                    )

                    NNListRow(
                        icon: .markdown,
                        title: "Obsidian daily notes",
                        subtitle: "Include daily Markdown frontmatter exports",
                        showSeparator: true,
                        trailing: {
                            NNSwitch(
                                isOn: Binding(
                                    get: { store.obsidianSyncEnabled },
                                    set: { store.obsidianSyncEnabled = $0 }
                                ),
                                label: "Obsidian daily notes"
                            )
                        }
                    )
                }
            }
        }
    }

    private var dataPortabilitySection: some View {
        VStack(alignment: .leading, spacing: NNSpacing.s2) {
            Text("Data & portability")
                .nnOverlineStyle()
                .padding(.horizontal, 4)

            NNCard(padding: .none) {
                VStack(spacing: 0) {
                    NNListRow(
                        icon: .importHistory,
                        title: "Import history",
                        subtitle: "MyFitnessPal CSV or Apple Health",
                        chevron: true,
                        action: onOpenImport
                    )

                    NNListRow(
                        icon: .archiveBox,
                        title: "Export JSON archive",
                        subtitle: "Full diary, foods, and metadata",
                        value: ".json",
                        monospacedValue: true,
                        chevron: true,
                        showSeparator: true,
                        action: {
                            Task { await exportJSONArchive() }
                        }
                    )

                    NNListRow(
                        icon: .markdown,
                        title: "Export Obsidian Markdown",
                        subtitle: "Daily note for \(store.selectedLocalDate)",
                        value: ".md",
                        monospacedValue: true,
                        chevron: true,
                        showSeparator: true,
                        action: {
                            Task { await exportObsidianNote() }
                        }
                    )

                    NNListRow(
                        icon: .exportArchive,
                        title: "Export CSV",
                        subtitle: "Meal totals spreadsheet",
                        value: ".csv",
                        monospacedValue: true,
                        chevron: true,
                        showSeparator: true,
                        action: {
                            Task { await exportMealsCSV() }
                        }
                    )
                }
            }

            if let lastExportedFile {
                NNCard(tone: .sunken, padding: .md) {
                    HStack(spacing: NNSpacing.s3) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ready to share")
                                .nnTextStyle(.footnote)
                                .foregroundStyle(NNColor.textSecondary)
                            Text(lastExportedFile.filename)
                                .nnTextStyle(.numSm)
                                .foregroundStyle(NNColor.textPrimary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        ShareLink(item: lastExportedFile.url) {
                            HStack(spacing: 6) {
                                NNIconView(.exportArchive, size: 14, weight: .bold, color: NNColor.textPrimary)
                                Text("Share")
                                    .font(NNFont.sans(size: 14, weight: .semibold, relativeTo: .callout))
                                    .foregroundStyle(NNColor.textPrimary)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: NNSpacing.controlSm)
                            .background(NNColor.surfaceCard, in: Capsule())
                        }
                    }
                }
            }
        }
    }

    private var accountActionsSection: some View {
        NNCard(padding: .none) {
            VStack(spacing: 0) {
                NNListRow(
                    icon: .signOut,
                    title: isSigningOut ? "Signing out\u{2026}" : "Sign out",
                    action: {
                        Task {
                            await performSignOut()
                        }
                    }
                )

                NNListRow(
                    icon: .trash,
                    title: isDeletingAccount ? "Deleting account\u{2026}" : "Delete account",
                    tone: .destructive,
                    showSeparator: true,
                    action: {
                        showDeleteDialog = true
                    }
                )
            }
        }
    }

    // MARK: - Actions

    private func performSyncNow() async {
        guard !isSyncing else { return }
        isSyncing = true
        statusBannerTitle = nil
        statusBannerMessage = nil
        defer { isSyncing = false }

        _ = await store.checkBackendHealth()

        do {
            let report = try await store.syncNow()
            statusBannerTitle = "Sync complete"
            statusBannerMessage = "Pushed \(report.pushedCount) and pulled \(report.pulledMealCount) meals."
        } catch {
            statusBannerTitle = "Sync paused"
            statusBannerMessage = error.localizedDescription
        }
    }

    private func toggleHealthKit(_ enabled: Bool) async {
        statusBannerTitle = nil
        statusBannerMessage = nil

        if !enabled {
            store.healthKitEnabled = false
            return
        }

        do {
            try await store.healthKitService.requestAuthorization()
            store.healthKitEnabled = true
        } catch {
            store.healthKitEnabled = false
            statusBannerTitle = "Apple Health unavailable"
            statusBannerMessage = error.localizedDescription
        }
    }

    private func exportJSONArchive() async {
        guard !isExporting else { return }
        isExporting = true
        defer { isExporting = false }

        do {
            let data = try await store.exportDiaryJSON()
            let filename = "nomnom-diary-\(store.selectedLocalDate).json"
            try presentExportFile(data: data, filename: filename)
        } catch {
            statusBannerTitle = "Export failed"
            statusBannerMessage = error.localizedDescription
        }
    }

    private func exportObsidianNote() async {
        guard !isExporting else { return }
        isExporting = true
        defer { isExporting = false }

        do {
            let markdown = try await store.exportObsidianMarkdown()
            let data = Data(markdown.utf8)
            let filename = "nomnom-\(store.selectedLocalDate).md"
            try presentExportFile(data: data, filename: filename)
        } catch {
            statusBannerTitle = "Export failed"
            statusBannerMessage = error.localizedDescription
        }
    }

    private func exportMealsCSV() async {
        guard !isExporting else { return }
        isExporting = true
        defer { isExporting = false }

        do {
            let csv = try await store.exportMealsCSV()
            let data = Data(csv.utf8)
            let filename = "nomnom-meals-\(store.selectedLocalDate).csv"
            try presentExportFile(data: data, filename: filename)
        } catch {
            statusBannerTitle = "Export failed"
            statusBannerMessage = error.localizedDescription
        }
    }

    private func presentExportFile(data: Data, filename: String) throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("nomnom-exports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)

        let exported = ExportedShareFile(url: url, filename: filename)
        lastExportedFile = exported
        activeShareFile = exported
    }

    private func performSignOut() async {
        guard !isSigningOut else { return }
        isSigningOut = true
        statusBannerTitle = nil
        statusBannerMessage = nil
        defer { isSigningOut = false }

        do {
            try await store.signOut()
            onClose()
        } catch {
            statusBannerTitle = "Couldn't sign out"
            statusBannerMessage = error.localizedDescription
        }
    }

    private func performDeleteAccount() async {
        guard !isDeletingAccount else { return }
        isDeletingAccount = true
        statusBannerTitle = nil
        statusBannerMessage = nil
        defer { isDeletingAccount = false }

        do {
            try await store.deleteAccount()
            showRevocationNotice = true
        } catch {
            statusBannerTitle = "Couldn't delete account"
            statusBannerMessage = error.localizedDescription
        }
    }
}

// MARK: - Share Sheet Helper

private struct ExportedShareFile: Identifiable, Sendable {
    let id = UUID()
    let url: URL
    let filename: String
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [URL]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
