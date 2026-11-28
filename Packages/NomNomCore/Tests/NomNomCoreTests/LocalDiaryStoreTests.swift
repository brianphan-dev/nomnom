import Foundation
import NomNomCore
import NomNomShared
import Testing

@Suite("LocalDiaryStore (Native SQLite3 + FTS5 + Atomic Outbox)")
struct LocalDiaryStoreTests {
    @Test("File-backed SQLite persists meals across database reopen")
    func fileBackedPersistence() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("nomnom-store-test-\(UUID().uuidString)", isDirectory: true)
        let dbURL = tempDir.appendingPathComponent("diary.sqlite")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let meal = TestFixtures.makeMeal(
            localDate: "2026-11-27",
            mealType: .breakfast,
            title: "Greek Yogurt & Berries",
            calories: 340,
            protein: 28,
            carbs: 36,
            fat: 8
        )

        do {
            let store = try LocalDiaryStore(url: dbURL)
            try await store.saveMeal(meal)
        }

        // Reopen from disk to confirm durability.
        let reopened = try LocalDiaryStore(url: dbURL)
        let loaded = try await reopened.meals(forLocalDate: "2026-11-27")
        #expect(loaded.count == 1)
        #expect(loaded.first?.id == meal.id)
        #expect(loaded.first?.title == "Greek Yogurt & Berries")
        #expect(loaded.first?.totalNutrition.caloriesKcal == 340)
    }

    @Test("Saving, editing, and soft-deleting a meal atomically enqueues outbox mutations")
    func atomicOutboxEnqueueOnSaveAndDelete() async throws {
        let store = try LocalDiaryStore.inMemory()
        var meal = TestFixtures.makeMeal(
            localDate: "2026-11-27",
            mealType: .lunch,
            title: "Chicken Teriyaki Bowl",
            calories: 650,
            protein: 45,
            carbs: 72,
            fat: 18
        )

        try await store.saveMeal(meal)

        let afterSave = try await store.pendingOutboxMutations()
        #expect(afterSave.count == 1)
        #expect(afterSave[0].entityType == .meal)
        #expect(afterSave[0].entityId == meal.id)
        #expect(afterSave[0].op == .upsert)
        #expect(!afterSave[0].idempotencyKey.isEmpty)

        let decodedMutation = try afterSave[0].toSyncMutation()
        #expect(decodedMutation.mutationId == afterSave[0].id)
        #expect(decodedMutation.op == .upsert)
        if case let .meal(payloadMeal) = decodedMutation.payload {
            #expect(payloadMeal.id == meal.id)
            #expect(payloadMeal.title == "Chicken Teriyaki Bowl")
        } else {
            Issue.record("Expected .meal payload in SyncMutation")
        }

        // Edit meal -> second outbox upsert enqueued.
        meal.title = "Chicken Teriyaki Bowl (Half Rice)"
        meal.updatedAt = TestFixtures.fixedDate("2026-11-27T13:00:00Z")
        try await store.saveMeal(meal)
        #expect(try await store.pendingOutboxCount() == 2)

        // Soft-delete meal -> hides from active queries and enqueues delete mutation.
        let deleteTime = TestFixtures.fixedDate("2026-11-27T13:15:00Z")
        try await store.softDeleteMeal(id: meal.id, at: deleteTime)

        #expect(try await store.meals(forLocalDate: "2026-11-27").isEmpty)
        let persisted = try await store.meal(id: meal.id)
        #expect(persisted?.isDeleted == true)

        let allOutbox = try await store.pendingOutboxMutations()
        #expect(allOutbox.count == 3)
        #expect(allOutbox.last?.op == .delete)
        #expect(allOutbox.last?.entityId == meal.id)
        #expect(allOutbox.last?.payloadJSON == nil)

        // Marking mutations completed drains outbox.
        try await store.markOutboxCompleted(ids: allOutbox.map(\.id))
        #expect(try await store.pendingOutboxCount() == 0)
    }

    @Test("FTS5 food search supports prefix matching, brands, barcodes, and punctuation safely")
    func fts5FoodSearchAndRecents() async throws {
        let store = try LocalDiaryStore.inMemory()
        let now = TestFixtures.fixedDate("2026-11-27T12:00:00Z")

        let seeded = try await store.seedFoodItemsIfEmpty(DefaultUSDAStaples.catalog(now: now))
        #expect(seeded >= 15)
        // Second seed call must be a no-op.
        #expect(try await store.seedFoodItemsIfEmpty(DefaultUSDAStaples.catalog(now: now)) == 0)

        let customBar = FoodItem(
            name: "Protein Bar — Peanut Butter Crunch!",
            brand: "NomNom Kitchen",
            barcode: "0012345678905",
            source: .custom,
            nutritionPer100g: NutritionSnapshot(caloriesKcal: 390, proteinG: 32, carbsG: 36, fatG: 14),
            servingOptions: [ServingOption(label: "1 bar (60g)", gramWeight: 60, isDefault: true)],
            isFavorite: true,
            lastUsedAt: now.addingTimeInterval(600),
            createdAt: now,
            updatedAt: now
        )
        try await store.saveFoodItem(customBar)

        // Prefix search
        let chickenResults = try await store.searchLocalFoods(query: "chick", limit: 10)
        #expect(chickenResults.contains { $0.name.localizedCaseInsensitiveContains("Chicken Breast") })

        // Brand + multi-word prefix search with punctuation / FTS reserved operators
        let brandResults = try await store.searchLocalFoods(query: "NomNom (peanut)!", limit: 10)
        #expect(brandResults.first?.id == customBar.id)

        // Barcode lookup
        let barcodeMatch = try await store.foodItem(byBarcode: "0012345678905")
        #expect(barcodeMatch?.id == customBar.id)

        // Recents prioritize favorites and most recently used
        let recents = try await store.recentFoods(limit: 5)
        #expect(recents.first?.id == customBar.id)
    }

    @Test("mealsInDateRange aggregates weekly entries accurately and excludes tombstones")
    func mealsInDateRangeWeeklyAggregation() async throws {
        let store = try LocalDiaryStore.inMemory()

        let d1 = TestFixtures.makeMeal(localDate: "2026-11-21", title: "Day 1 Breakfast", calories: 450)
        let d2 = TestFixtures.makeMeal(localDate: "2026-11-23", title: "Day 3 Lunch", calories: 700)
        let d3 = TestFixtures.makeMeal(localDate: "2026-11-27", title: "Day 7 Dinner", calories: 820)
        let deleted = TestFixtures.makeMeal(localDate: "2026-11-25", title: "Deleted Snack", calories: 300)
        let outside = TestFixtures.makeMeal(localDate: "2026-11-19", title: "Old Meal", calories: 999)

        for meal in [d1, d2, d3, deleted, outside] {
            try await store.saveMeal(meal, enqueueSync: false)
        }
        try await store.softDeleteMeal(id: deleted.id, enqueueSync: false)

        let weekMeals = try await store.mealsInDateRange(from: "2026-11-21", to: "2026-11-27")
        #expect(weekMeals.map(\.id) == [d1.id, d2.id, d3.id])
        let totalKcal = NutritionSnapshot.sum(weekMeals.map(\.totalNutrition)).caloriesKcal
        #expect(totalKcal == 1970)
    }

    @Test("Remote upserts and tombstones advance sync cursor without re-enqueuing outbox")
    func remoteUpsertTombstoneAndCursor() async throws {
        let store = try LocalDiaryStore.inMemory()
        #expect(try await store.lastSyncSeq() == 0)
        #expect(try await store.lastSyncedAt() == nil)

        let remoteMeal = TestFixtures.makeMeal(
            localDate: "2026-11-27",
            title: "Remote Ramen",
            calories: 780,
            syncSeq: 41
        )
        try await store.upsertRemoteMeal(remoteMeal)
        #expect(try await store.pendingOutboxCount() == 0)
        #expect(try await store.meals(forLocalDate: "2026-11-27").count == 1)

        var tombstoned = remoteMeal
        tombstoned.deletedAt = TestFixtures.fixedDate("2026-11-27T18:00:00Z")
        tombstoned.updatedAt = TestFixtures.fixedDate("2026-11-27T18:00:00Z")
        tombstoned.syncSeq = 42

        let secondMeal = TestFixtures.makeMeal(
            localDate: "2026-11-27",
            title: "Remote Poke Bowl",
            calories: 590,
            syncSeq: 43
        )

        let serverTime = TestFixtures.fixedDate("2026-11-27T18:05:00Z")
        let changes = SyncChangesResponse(
            sinceSeq: 0,
            nextSeq: 43,
            hasMore: false,
            meals: [tombstoned, secondMeal],
            foodItems: [],
            photoAssets: [],
            serverTime: serverTime
        )

        try await store.applyRemoteChanges(changes)
        #expect(try await store.pendingOutboxCount() == 0)
        #expect(try await store.lastSyncSeq() == 43)
        #expect(try await store.lastSyncedAt() == serverTime)

        let activeMeals = try await store.meals(forLocalDate: "2026-11-27")
        #expect(activeMeals.count == 1)
        #expect(activeMeals.first?.id == secondMeal.id)
    }

    @Test("Import fingerprints persist and deduplicate deterministically")
    func importFingerprintDedupe() async throws {
        let store = try LocalDiaryStore.inMemory()
        let mealId = UUID()
        let fingerprint = MyFitnessPalParser.fingerprint(
            localDate: "2026-11-26",
            mealType: .lunch,
            caloriesKcal: 610,
            proteinG: 40,
            carbsG: 65,
            fatG: 18
        )

        #expect(try await store.hasImportFingerprint(fingerprint) == false)

        let importedMeal = TestFixtures.makeMeal(
            id: mealId,
            localDate: "2026-11-26",
            mealType: .lunch,
            title: "Lunch",
            calories: 610,
            protein: 40,
            carbs: 65,
            fat: 18,
            captureMethod: .importedMFP,
            dedupeFingerprint: fingerprint
        )

        try await store.applyImport(
            mealsToInsert: [importedMeal],
            source: CaptureMethod.importedMFP.rawValue,
            enqueueSync: true
        )

        #expect(try await store.hasImportFingerprint(fingerprint) == true)
        let mfpSet = try await store.existingImportFingerprints(source: CaptureMethod.importedMFP.rawValue)
        #expect(mfpSet.contains(fingerprint))
        #expect(try await store.pendingOutboxCount() == 1)
    }

    @Test("PhotoAssets persist by mealId and enqueue atomic outbox records")
    func photoAssetPersistenceAndOutbox() async throws {
        let store = try LocalDiaryStore.inMemory()
        let mealId = UUID()
        let now = TestFixtures.fixedDate("2026-11-27T12:00:00Z")
        let asset = PhotoAsset(
            mealId: mealId,
            localFilename: "meal-photo-1.heic",
            sha256Hash: PureSHA256.hex("synthetic-bytes"),
            r2ObjectKey: nil,
            mimeType: "image/heic",
            byteSize: 120_400,
            widthPx: 1200,
            heightPx: 900,
            uploadState: .localOnly,
            createdAt: now,
            updatedAt: now
        )

        try await store.savePhotoAsset(asset, enqueueSync: true)
        let fetched = try await store.photoAssets(forMealId: mealId)
        #expect(fetched.count == 1)
        #expect(fetched.first == asset)

        let outbox = try await store.pendingOutboxMutations()
        #expect(outbox.count == 1)
        #expect(outbox[0].entityType == .photoAsset)
        #expect(outbox[0].entityId == asset.id)

        var syncedAsset = asset
        syncedAsset.uploadState = .synced
        syncedAsset.r2ObjectKey = "users/u1/photos/\(asset.id.uuidString.lowercased()).heic"
        try await store.upsertRemotePhotoAsset(syncedAsset)

        let updated = try await store.photoAssets(forMealId: mealId)
        #expect(updated.first?.uploadState == .synced)
        #expect(updated.first?.r2ObjectKey == syncedAsset.r2ObjectKey)
        // Remote upsert must not add a second outbox row.
        #expect(try await store.pendingOutboxCount() == 1)
    }
}
