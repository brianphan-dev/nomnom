import Foundation
import NomNomShared
import os

#if canImport(Network)
import Network
#endif

// MARK: - Sync Status & Reports

public enum SyncStatus: Sendable, Equatable {
    case synced
    case syncing
    case offline
    case error(String)

    public var displayLabel: String {
        switch self {
        case .synced: "Synced"
        case .syncing: "Syncing..."
        case .offline: "Offline"
        case let .error(message): "Sync Error: \(message)"
        }
    }
}

public struct SyncSnapshot: Sendable, Equatable {
    public var status: SyncStatus
    public var queuedCount: Int
    public var lastSyncedAt: Date?
    public var lastSyncSeq: Int64

    public init(
        status: SyncStatus = .synced,
        queuedCount: Int = 0,
        lastSyncedAt: Date? = nil,
        lastSyncSeq: Int64 = 0
    ) {
        self.status = status
        self.queuedCount = queuedCount
        self.lastSyncedAt = lastSyncedAt
        self.lastSyncSeq = lastSyncSeq
    }
}

public struct SyncReport: Sendable, Equatable {
    public var pushedCount: Int
    public var pulledMealCount: Int
    public var pulledFoodItemCount: Int
    public var pulledPhotoAssetCount: Int
    public var latestSyncSeq: Int64
    public var syncedAt: Date

    public init(
        pushedCount: Int,
        pulledMealCount: Int,
        pulledFoodItemCount: Int,
        pulledPhotoAssetCount: Int,
        latestSyncSeq: Int64,
        syncedAt: Date
    ) {
        self.pushedCount = pushedCount
        self.pulledMealCount = pulledMealCount
        self.pulledFoodItemCount = pulledFoodItemCount
        self.pulledPhotoAssetCount = pulledPhotoAssetCount
        self.latestSyncSeq = latestSyncSeq
        self.syncedAt = syncedAt
    }
}

public enum SyncEngineError: Error, Sendable, Equatable, LocalizedError {
    case rejectedMutations(count: Int, message: String?)

    public var errorDescription: String? {
        switch self {
        case let .rejectedMutations(count, message):
            if let message, !message.isEmpty {
                return "\(count) mutation(s) rejected by server: \(message)"
            }
            return "\(count) mutation(s) rejected by server."
        }
    }
}

// MARK: - Sync Engine Actor

/// Coordinates atomic outbox push and cursor-based delta pull between `LocalDiaryStore` and `NomNomAPIClient`.
public actor SyncEngine {
    private let store: LocalDiaryStore
    private let apiClient: any NomNomAPIClientProtocol
    private let credentialStore: any SessionCredentialStore
    private let pushBatchSize: Int
    private let pullPageLimit: Int
    private let decoder: JSONDecoder

    private var status: SyncStatus = .synced
    private var queuedCount: Int = 0
    private var lastSyncedAt: Date?
    private var lastSyncSeq: Int64 = 0
    private var inFlightSyncTask: Task<SyncReport, Error>?
    private var observers: [UUID: AsyncStream<SyncSnapshot>.Continuation] = [:]

    public init(
        store: LocalDiaryStore,
        apiClient: any NomNomAPIClientProtocol,
        credentialStore: any SessionCredentialStore,
        pushBatchSize: Int = 50,
        pullPageLimit: Int = 200
    ) {
        self.store = store
        self.apiClient = apiClient
        self.credentialStore = credentialStore
        self.pushBatchSize = max(1, pushBatchSize)
        self.pullPageLimit = max(1, pullPageLimit)
        self.decoder = NomNomJSON.makeDecoder()
    }

    public func currentSnapshot() -> SyncSnapshot {
        SyncSnapshot(
            status: status,
            queuedCount: queuedCount,
            lastSyncedAt: lastSyncedAt,
            lastSyncSeq: lastSyncSeq
        )
    }

    /// Reads local outbox count and sync cursor metadata from SQLite without performing network I/O.
    @discardableResult
    public func refreshLocalState() async throws -> SyncSnapshot {
        queuedCount = try await store.pendingOutboxCount()
        lastSyncSeq = try await store.lastSyncSeq()
        lastSyncedAt = try await store.lastSyncedAt()
        let snapshot = currentSnapshot()
        broadcast(snapshot)
        return snapshot
    }

    /// Updates reachability state reflected by the sync engine.
    public func setOffline(_ isOffline: Bool) {
        if isOffline {
            if status != .syncing {
                status = .offline
                broadcast(currentSnapshot())
            }
        } else if status == .offline {
            status = .synced
            broadcast(currentSnapshot())
        }
    }

    /// Emits `SyncSnapshot` updates whenever sync state changes.
    public func snapshots() -> AsyncStream<SyncSnapshot> {
        let id = UUID()
        let initial = currentSnapshot()
        return AsyncStream { continuation in
            continuation.yield(initial)
            self.observers[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeObserver(id: id) }
            }
        }
    }

    private func removeObserver(id: UUID) {
        observers.removeValue(forKey: id)
    }

    private func broadcast(_ snapshot: SyncSnapshot) {
        for continuation in observers.values {
            continuation.yield(snapshot)
        }
    }

    /// Pushes all queued local mutations with idempotency keys, then pulls remote deltas
    /// until `hasMore == false`. Concurrent calls coalesce onto the active sync run.
    @discardableResult
    public func syncNow() async throws -> SyncReport {
        if let existingTask = inFlightSyncTask {
            return try await existingTask.value
        }

        let task = Task<SyncReport, Error> {
            defer { self.inFlightSyncTask = nil }
            return try await self.performSync()
        }
        inFlightSyncTask = task
        return try await task.value
    }

    private func performSync() async throws -> SyncReport {
        queuedCount = try await store.pendingOutboxCount()
        lastSyncSeq = try await store.lastSyncSeq()
        lastSyncedAt = try await store.lastSyncedAt()
        status = .syncing
        broadcast(currentSnapshot())

        do {
            let deviceId = try credentialStore.getOrCreateDeviceId()
            var totalPushed = 0

            // Phase 1: Drain local outbox in chronological batches.
            while true {
                let batchRecords = try await store.pendingOutboxMutations(limit: pushBatchSize)
                if batchRecords.isEmpty {
                    break
                }

                let mutations = try batchRecords.map { try $0.toSyncMutation(decoder: decoder) }
                let pushRequest = SyncPushRequest(deviceId: deviceId, mutations: mutations)
                let pushResponse = try await apiClient.pushSync(pushRequest)

                var completedIds: [UUID] = []
                var rejectedAcks: [SyncMutationAck] = []

                if pushResponse.results.isEmpty {
                    // Defensive fallback: if server acknowledged all without per-item details.
                    if pushResponse.acceptedCount >= batchRecords.count {
                        completedIds = batchRecords.map(\.id)
                    }
                } else {
                    for ack in pushResponse.results {
                        switch ack.status {
                        case .applied, .duplicate, .conflict:
                            completedIds.append(ack.mutationId)
                        case .rejected:
                            rejectedAcks.append(ack)
                        }
                    }
                }

                if !completedIds.isEmpty {
                    try await store.markOutboxCompleted(ids: completedIds)
                    totalPushed += completedIds.count
                    queuedCount = try await store.pendingOutboxCount()
                    broadcast(currentSnapshot())
                }

                if !rejectedAcks.isEmpty {
                    throw SyncEngineError.rejectedMutations(
                        count: rejectedAcks.count,
                        message: rejectedAcks.first?.errorMessage
                    )
                }

                if completedIds.isEmpty {
                    break
                }
            }

            // Phase 2: Pull remote changes sequentially until hasMore == false.
            var cursor = try await store.lastSyncSeq()
            var pulledMeals = 0
            var pulledFoodItems = 0
            var pulledPhotoAssets = 0
            var latestServerTime = Date()

            while true {
                let changes = try await apiClient.fetchSyncChanges(
                    afterSeq: cursor,
                    limit: pullPageLimit
                )
                try await store.applyRemoteChanges(changes)

                pulledMeals += changes.meals.count
                pulledFoodItems += changes.foodItems.count
                pulledPhotoAssets += changes.photoAssets.count
                latestServerTime = changes.serverTime

                let nextCursor = max(cursor, changes.nextSeq)
                if !changes.hasMore || nextCursor <= cursor {
                    cursor = nextCursor
                    break
                }
                cursor = nextCursor
            }

            lastSyncSeq = try await store.lastSyncSeq()
            lastSyncedAt = try await store.lastSyncedAt() ?? latestServerTime
            queuedCount = try await store.pendingOutboxCount()
            status = .synced
            broadcast(currentSnapshot())

            return SyncReport(
                pushedCount: totalPushed,
                pulledMealCount: pulledMeals,
                pulledFoodItemCount: pulledFoodItems,
                pulledPhotoAssetCount: pulledPhotoAssets,
                latestSyncSeq: lastSyncSeq,
                syncedAt: lastSyncedAt ?? latestServerTime
            )
        } catch {
            queuedCount = (try? await store.pendingOutboxCount()) ?? queuedCount
            if Self.isOfflineError(error) {
                status = .offline
            } else {
                status = .error(error.localizedDescription)
            }
            broadcast(currentSnapshot())
            throw error
        }
    }

    private static func isOfflineError(_ error: Error) -> Bool {
        if let apiError = error as? NomNomAPIError {
            return apiError.isConnectivityFailure
        }
        if let urlError = error as? URLError {
            let offlineCodes: Set<URLError.Code> = [
                .notConnectedToInternet,
                .networkConnectionLost,
                .cannotConnectToHost,
                .cannotFindHost,
                .dnsLookupFailed,
                .timedOut,
                .dataNotAllowed,
                .internationalRoamingOff,
            ]
            return offlineCodes.contains(urlError.code)
        }
        return false
    }
}

// MARK: - Network Reachability Monitor

#if canImport(Network)

/// Thread-safe `NWPathMonitor` wrapper streaming online/offline reachability changes.
public final class NetworkReachabilityMonitor: Sendable {
    private struct State {
        var isOnline: Bool
        var isStarted: Bool = false
        var continuations: [UUID: AsyncStream<Bool>.Continuation] = [:]
    }

    private let state: OSAllocatedUnfairLock<State>
    private let queue: DispatchQueue
    private nonisolated(unsafe) var monitor: NWPathMonitor?

    public init(initialOnline: Bool = true) {
        self.state = OSAllocatedUnfairLock(initialState: State(isOnline: initialOnline))
        self.queue = DispatchQueue(label: "dev.brianphan.nomnom.reachability", qos: .utility)
    }

    deinit {
        stop()
    }

    public var isOnline: Bool {
        state.withLock(\.isOnline)
    }

    public func start() {
        let shouldStart = state.withLock { s -> Bool in
            guard !s.isStarted else { return false }
            s.isStarted = true
            return true
        }
        guard shouldStart else { return }

        let pathMonitor = NWPathMonitor()
        pathMonitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(isSatisfied: path.status == .satisfied)
        }
        monitor = pathMonitor
        pathMonitor.start(queue: queue)
    }

    public func stop() {
        let activeMonitor = state.withLock { s -> Bool in
            guard s.isStarted else { return false }
            s.isStarted = false
            return true
        }
        if activeMonitor {
            monitor?.cancel()
            monitor = nil
        }
    }

    public func updates() -> AsyncStream<Bool> {
        let id = UUID()
        return AsyncStream { continuation in
            let current = self.state.withLock { s -> Bool in
                s.continuations[id] = continuation
                return s.isOnline
            }
            continuation.yield(current)

            continuation.onTermination = { [weak self] _ in
                self?.state.withLock { s in
                    _ = s.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    private func handlePathUpdate(isSatisfied: Bool) {
        let targets = state.withLock { s -> [AsyncStream<Bool>.Continuation] in
            guard s.isOnline != isSatisfied else { return [] }
            s.isOnline = isSatisfied
            return Array(s.continuations.values)
        }
        for continuation in targets {
            continuation.yield(isSatisfied)
        }
    }
}

#else

public final class NetworkReachabilityMonitor: Sendable {
    public let isOnline: Bool

    public init(initialOnline: Bool = true) {
        self.isOnline = initialOnline
    }

    public func start() {}
    public func stop() {}

    public func updates() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            continuation.yield(self.isOnline)
            continuation.finish()
        }
    }
}

#endif
