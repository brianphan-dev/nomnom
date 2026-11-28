import Foundation
import SwiftUI
import NomNomCore
import NomNomDesignSystem
import NomNomShared

@main
struct NomNomApp: App {
    @State private var store: NomNomAppStore
    private let credentialMonitor = AppleCredentialStateMonitor()
    private let isPreviewSignedIn: Bool

    init() {
        _ = NNFonts.registerAll()
        let previewFlag = Self.isPreviewSignedInLaunch()
        self.isPreviewSignedIn = previewFlag
        _store = State(initialValue: Self.makeStore(previewSignedIn: previewFlag))
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .task {
                    await bootstrapAndSync()
                }
                .task {
                    await monitorAppleCredentialRevocation()
                }
        }
    }

    @MainActor
    private func bootstrapAndSync() async {
        try? await store.bootstrap(startReachability: true)
        _ = await store.checkBackendHealth()

        guard store.isSignedIn, !isPreviewSignedIn else { return }

        await verifyAppleCredentialState()

        if store.isSignedIn, !store.isOffline {
            Task {
                _ = try? await store.syncNow()
            }
        }
    }

    @MainActor
    private func verifyAppleCredentialState() async {
        guard let appleUserId = store.credentialStore.appleUserId,
              !appleUserId.isEmpty
        else {
            return
        }

        if let state = try? await credentialMonitor.checkCredentialState(forUserID: appleUserId),
           state == .revoked || state == .notFound
        {
            try? await store.signOut()
        }
    }

    @MainActor
    private func monitorAppleCredentialRevocation() async {
        guard !isPreviewSignedIn else { return }
        for await _ in credentialMonitor.revocationStream() {
            guard store.isSignedIn else { continue }
            try? await store.signOut()
        }
    }

    private static func isPreviewSignedInLaunch() -> Bool {
        let env = ProcessInfo.processInfo.environment
        return ProcessInfo.processInfo.arguments.contains("--ui-preview-signed-in")
            || env["NOMNOM_UI_PREVIEW_SIGNED_IN"] == "1"
    }

    private static func resolvedAPIBaseURL() -> URL {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, let url = URL(string: trimmed) {
                return url
            }
        }
        return NomNomAPIClient.defaultBaseURL
    }

    @MainActor
    private static func makeStore(previewSignedIn: Bool) -> NomNomAppStore {
        let baseURL = resolvedAPIBaseURL()

        if previewSignedIn, let previewStore = try? makePreviewSignedInStore(baseURL: baseURL) {
            return previewStore
        }

        if let liveStore = try? NomNomAppStore.makeLive(baseURL: baseURL) {
            return liveStore
        }

        // Safe in-memory fallback only if Application Support / SQLite disk initialization fails.
        do {
            let localStore = try LocalDiaryStore.inMemory()
            let credentialStore = KeychainStore()
            let apiClient = NomNomAPIClient(baseURL: baseURL, credentialStore: credentialStore)
            return NomNomAppStore(
                store: localStore,
                apiClient: apiClient,
                credentialStore: credentialStore,
                apiBaseURL: baseURL,
                userDefaults: .standard
            )
        } catch {
            fatalError("Failed to initialize nomnom local store: \(error.localizedDescription)")
        }
    }

    @MainActor
    private static func makePreviewSignedInStore(baseURL: URL) throws -> NomNomAppStore {
        let localStore = try LocalDiaryStore.inMemory()
        let previewCredentials = InMemoryCredentialStore(
            initialValues: [
                .accessToken: "ui-preview-access-token",
                .refreshToken: "ui-preview-refresh-token",
                .userId: UUID().uuidString,
                .deviceId: "ui-preview-device",
                .displayName: "Preview",
                .email: "preview@nomnom.local",
                .isPrivateEmail: "true",
            ]
        )
        let apiClient = NomNomAPIClient(baseURL: baseURL, credentialStore: previewCredentials)
        return NomNomAppStore(
            store: localStore,
            apiClient: apiClient,
            credentialStore: previewCredentials,
            apiBaseURL: baseURL,
            userDefaults: nil
        )
    }
}
