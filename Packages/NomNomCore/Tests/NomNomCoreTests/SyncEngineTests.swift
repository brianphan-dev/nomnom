import Foundation
import NomNomCore
import NomNomShared
import os
import Testing

@Suite("SyncEngine End-to-End Push & Pull")
struct SyncEngineTests {
    private let baseURL = URL(string: "https://api.nomnom.test")!

    @Test("Offline save queues outbox, reconnect pushes idempotently and pulls remote meals + tombstones")
    func offlineToOnlinePushThenPaginatedPull() async throws {
        let routeID = UUID().uuidString
        defer { ScopedMockURLProtocol.removeHandler(routeID: routeID) }

        let store = try LocalDiaryStore.inMemory()
        let credentials = InMemoryCredentialStore(initialValues: [
            .accessToken: "sync-access-token",
            .refreshToken: "sync-refresh-token",
            .deviceId: "iphone-16-pro",
            .userId: UUID().uuidString,
        ])

        // Pre-seed a local meal that Device 2 will remotely tombstone later.
        let mealToBeTombstoned = TestFixtures.makeMeal(
            localDate: "2026-11-27",
            mealType: .snack,
            title: "Stale Snack",
            calories: 200,
            syncSeq: 5
        )
        try await store.upsertRemoteMeal(mealToBeTombstoned)
        try await store.setLastSyncSeq(5)

        // Device 1 logs a meal while offline.
        let offlineMeal = TestFixtures.makeMeal(
            localDate: "2026-11-27",
            mealType: .breakfast,
            title: "Sourdough & Avocado Eggs",
            calories: 520,
            protein: 26,
            carbs: 44,
            fat: 26
        )
        try await store.saveMeal(offlineMeal, enqueueSync: true)
        #expect(try await store.pendingOutboxCount() == 1)

        // Device 2 logged a meal on iPhone Duo and deleted Stale Snack.
        let secondDeviceMeal = TestFixtures.makeMeal(
            localDate: "2026-11-27",
            mealType: .dinner,
            title: "iPhone Duo Pho Tai",
            calories: 680,
            protein: 42,
            carbs: 78,
            fat: 18,
            syncSeq: 12
        )
        let tombstonedFromDevice2: Meal = {
            var copy = mealToBeTombstoned
            copy.deletedAt = TestFixtures.fixedDate("2026-11-27T19:00:00Z")
            copy.updatedAt = TestFixtures.fixedDate("2026-11-27T19:00:00Z")
            copy.syncSeq = 13
            return copy
        }()

        struct BackendState: Sendable {
            var isOffline = true
            var pushedMutationIds: [UUID] = []
            var pushedDeviceIds: [String] = []
            var changeCursorsRequested: [Int64] = []
        }
        let backend = OSAllocatedUnfairLock(initialState: BackendState())
        let serverTime = TestFixtures.fixedDate("2026-11-27T20:00:00Z")

        let session = ScopedMockURLProtocol.makeSession(routeID: routeID) { request, body in
            let isOffline = backend.withLock(\.isOffline)
            if isOffline {
                throw URLError(.notConnectedToInternet)
            }

            let url = request.url!
            if url.path == "/v1/sync/push" {
                let rawBody = try #require(body)
                let pushReq = try NomNomJSON.makeDecoder().decode(SyncPushRequest.self, from: rawBody)
                backend.withLock {
                    $0.pushedDeviceIds.append(pushReq.deviceId)
                    $0.pushedMutationIds.append(contentsOf: pushReq.mutations.map(\.mutationId))
                }

                let acks = pushReq.mutations.map { mutation in
                    SyncMutationAck(
                        mutationId: mutation.mutationId,
                        entityType: mutation.entityType,
                        entityId: mutation.entityId,
                        status: .applied,
                        syncSeq: 10
                    )
                }
                let pushRes = SyncPushResponse(
                    acceptedCount: acks.count,
                    latestSyncSeq: 10,
                    results: acks,
                    serverTime: serverTime
                )
                return (
                    TestFixtures.makeHTTPResponse(url: url, statusCode: 200),
                    try TestFixtures.encodeJSON(pushRes)
                )
            }

            if url.path == "/v1/sync/changes" {
                let afterSeq = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "after_seq" })?.value
                    .flatMap(Int64.init) ?? 0
                backend.withLock { $0.changeCursorsRequested.append(afterSeq) }

                let response: SyncChangesResponse
                if afterSeq < 12 {
                    response = SyncChangesResponse(
                        sinceSeq: afterSeq,
                        nextSeq: 12,
                        hasMore: true,
                        meals: [secondDeviceMeal],
                        serverTime: serverTime
                    )
                } else {
                    response = SyncChangesResponse(
                        sinceSeq: afterSeq,
                        nextSeq: 13,
                        hasMore: false,
                        meals: [tombstonedFromDevice2],
                        serverTime: serverTime
                    )
                }
                return (
                    TestFixtures.makeHTTPResponse(url: url, statusCode: 200),
                    try TestFixtures.encodeJSON(response)
                )
            }

            return (TestFixtures.makeHTTPResponse(url: url, statusCode: 404), Data())
        }

        let apiClient = NomNomAPIClient(baseURL: baseURL, session: session, credentialStore: credentials)
        let engine = SyncEngine(store: store, apiClient: apiClient, credentialStore: credentials)

        // Step 1: Sync while offline fails gracefully and retains queued mutation.
        await #expect(throws: NomNomAPIError.self) {
            try await engine.syncNow()
        }
        let offlineSnapshot = await engine.currentSnapshot()
        #expect(offlineSnapshot.status == .offline)
        #expect(offlineSnapshot.queuedCount == 1)
        #expect(try await store.pendingOutboxCount() == 1)

        // Step 2: Reconnect and run syncNow().
        backend.withLock { $0.isOffline = false }
        let report = try await engine.syncNow()

        #expect(report.pushedCount == 1)
        #expect(report.pulledMealCount == 2)
        #expect(report.latestSyncSeq == 13)

        let syncedSnapshot = await engine.currentSnapshot()
        #expect(syncedSnapshot.status == .synced)
        #expect(syncedSnapshot.queuedCount == 0)
        #expect(syncedSnapshot.lastSyncSeq == 13)
        #expect(syncedSnapshot.lastSyncedAt == serverTime)

        let serverSnapshot = backend.withLock { $0 }
        #expect(serverSnapshot.pushedDeviceIds == ["iphone-16-pro"])
        #expect(serverSnapshot.pushedMutationIds.count == 1)
        #expect(serverSnapshot.changeCursorsRequested == [5, 12])

        // Step 3: Verify BOTH Device 1 and Device 2 meals exist in SQLite and tombstone is hidden.
        let mealsToday = try await store.meals(forLocalDate: "2026-11-27")
        #expect(Set(mealsToday.map(\.id)) == Set([offlineMeal.id, secondDeviceMeal.id]))
        #expect(!mealsToday.contains { $0.id == mealToBeTombstoned.id })
        #expect(try await store.meal(id: mealToBeTombstoned.id)?.isDeleted == true)
    }

    @Test("Duplicate ack status is treated as idempotent success and concurrent syncNow calls coalesce")
    func duplicateAckAndSingleFlightSyncCoalescing() async throws {
        let routeID = UUID().uuidString
        defer { ScopedMockURLProtocol.removeHandler(routeID: routeID) }

        let store = try LocalDiaryStore.inMemory()
        let credentials = InMemoryCredentialStore(initialValues: [
            .accessToken: "token",
            .deviceId: "ipad-pro",
        ])

        let meal = TestFixtures.makeMeal(localDate: "2026-11-27", title: "Protein Shake", calories: 210)
        try await store.saveMeal(meal, enqueueSync: true)

        let pushCallCount = OSAllocatedUnfairLock(initialState: 0)
        let session = ScopedMockURLProtocol.makeSession(routeID: routeID) { request, body in
            let url = request.url!
            if url.path == "/v1/sync/push" {
                Thread.sleep(forTimeInterval: 0.04)
                pushCallCount.withLock { $0 += 1 }
                let req = try NomNomJSON.makeDecoder().decode(SyncPushRequest.self, from: try #require(body))
                let acks = req.mutations.map {
                    SyncMutationAck(
                        mutationId: $0.mutationId,
                        entityType: $0.entityType,
                        entityId: $0.entityId,
                        status: .duplicate,
                        syncSeq: 7
                    )
                }
                return (
                    TestFixtures.makeHTTPResponse(url: url, statusCode: 200),
                    try TestFixtures.encodeJSON(SyncPushResponse(acceptedCount: 0, latestSyncSeq: 7, results: acks))
                )
            }
            if url.path == "/v1/sync/changes" {
                return (
                    TestFixtures.makeHTTPResponse(url: url, statusCode: 200),
                    try TestFixtures.encodeJSON(SyncChangesResponse(sinceSeq: 0, nextSeq: 7, hasMore: false))
                )
            }
            return (TestFixtures.makeHTTPResponse(url: url, statusCode: 404), Data())
        }

        let client = NomNomAPIClient(baseURL: baseURL, session: session, credentialStore: credentials)
        let engine = SyncEngine(store: store, apiClient: client, credentialStore: credentials)

        async let firstReport = engine.syncNow()
        async let secondReport = engine.syncNow()
        let (r1, r2) = try await (firstReport, secondReport)

        #expect(r1 == r2)
        #expect(pushCallCount.withLock { $0 } == 1)
        #expect(try await store.pendingOutboxCount() == 0)
        #expect(try await store.lastSyncSeq() == 7)
    }
}
