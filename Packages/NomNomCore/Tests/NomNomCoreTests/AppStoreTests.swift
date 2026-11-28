import Foundation
import NomNomCore
import NomNomShared
import os
import Testing

@Suite("NomNomAppStore End-to-End Application State")
struct AppStoreTests {
    private let baseURL = URL(string: "https://api.nomnom.test")!
    private let utcTimeZone = TimeZone(secondsFromGMT: 0)!

    @Test("Sign-in -> log meal -> MyFitnessPal CSV dedupe -> weekly totals -> Obsidian & JSON export")
    @MainActor
    func fullDiaryWorkflowAndExports() async throws {
        let routeID = UUID().uuidString
        defer { ScopedMockURLProtocol.removeHandler(routeID: routeID) }

        let user = TestFixtures.makeUser()
        let authResponse = AuthTokenResponse(
            accessToken: "app-access-token",
            refreshToken: "app-refresh-token",
            tokenType: "Bearer",
            expiresInSeconds: 3600,
            user: user
        )

        let session = ScopedMockURLProtocol.makeSession(routeID: routeID) { request, _ in
            let url = request.url!
            switch (request.httpMethod, url.path) {
            case ("POST", "/v1/auth/apple"):
                return (
                    TestFixtures.makeHTTPResponse(url: url, statusCode: 200),
                    try TestFixtures.encodeJSON(authResponse)
                )
            case ("GET", "/healthz"):
                return (
                    TestFixtures.makeHTTPResponse(url: url, statusCode: 200),
                    Data(#"{"status":"ok"}"#.utf8)
                )
            case ("POST", "/v1/ai/analyze-meal-photo"):
                let ai = AnalyzeMealResponse(
                    suggestedTitle: "Avocado Chicken Salad",
                    suggestedMealType: .lunch,
                    items: [
                        DetectedMealItemDTO(
                            displayName: "Grilled Chicken Salad",
                            servingLabel: "1 bowl (320g)",
                            gramWeight: 320,
                            confidence: 0.92,
                            nutrition: NutritionSnapshot(caloriesKcal: 480, proteinG: 44, carbsG: 18, fatG: 26)
                        ),
                    ],
                    modelUsed: "gemini-3.5-flash-lite"
                )
                return (
                    TestFixtures.makeHTTPResponse(
                        url: url,
                        statusCode: 200,
                        headers: ["X-AI-Quota-Remaining": "18"]
                    ),
                    try TestFixtures.encodeJSON(ai)
                )
            case ("DELETE", "/v1/account"):
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 204), Data())
            default:
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 404), Data())
            }
        }

        let localStore = try LocalDiaryStore.inMemory()
        let credentials = InMemoryCredentialStore()
        let apiClient = NomNomAPIClient(baseURL: baseURL, session: session, credentialStore: credentials)
        let anchorDate = TestFixtures.fixedDate("2026-11-27T12:00:00Z")

        let appStore = NomNomAppStore(
            store: localStore,
            apiClient: apiClient,
            credentialStore: credentials,
            apiBaseURL: baseURL,
            selectedDate: anchorDate,
            timeZone: utcTimeZone
        )

        // 1. Bootstrap seeds USDA staples for instant offline search.
        try await appStore.bootstrap()
        #expect(appStore.isSignedIn == false)
        let offlineSearch = try await appStore.searchFoods("salmon")
        #expect(offlineSearch.contains { $0.name.localizedCaseInsensitiveContains("Atlantic Salmon") })

        // 2. Backend health & Sign in with Apple.
        #expect(await appStore.checkBackendHealth() == true)
        #expect(appStore.isBackendHealthy == true)

        let nonce = try AppleNonceGenerator.generate()
        let deviceId = try credentials.getOrCreateDeviceId()
        _ = try await appStore.signInWithApple(
            AppleAuthRequest(
                identityToken: "apple-jwt",
                authorizationCode: "apple-code",
                rawNonce: nonce.rawNonce,
                givenName: "Brian",
                familyName: "Phan",
                deviceId: deviceId
            )
        )
        #expect(appStore.isSignedIn == true)
        #expect(appStore.currentUser?.id == user.id)
        #expect(appStore.targets.caloriesKcal == 2200)
        #expect(appStore.targets.proteinG == 165)

        // 3. Log a meal with a toggleable optional cooking oil ingredient.
        let oliveOil = IngredientEstimate(
            name: "Extra Virgin Olive Oil",
            category: .oil,
            estimatedGrams: 10,
            nutrition: NutritionSnapshot(caloriesKcal: 88, proteinG: 0, carbsG: 0, fatG: 10),
            isOptionalEstimate: true,
            isIncluded: true
        )
        let loggedMeal = TestFixtures.makeMeal(
            localDate: "2026-11-27",
            mealType: .lunch,
            title: "Salmon Rice Bowl",
            calories: 600,
            protein: 45,
            carbs: 60,
            fat: 20,
            ingredients: [oliveOil]
        )
        try await appStore.logMeal(loggedMeal)

        #expect(appStore.todayMeals.count == 1)
        #expect(appStore.todayTotals.caloriesKcal == 688) // 600 base + 88 optional olive oil
        #expect(appStore.queuedCount == 1)

        // 4. Import MyFitnessPal CSV across multiple dates in the same 7-day window.
        let mfpCSV = """
        Date,Meal,Calories,Fat (g),Carbohydrates (g),Protein (g),Fiber (g),Sodium (mg),Note
        2026-11-25,Breakfast,410,12,50,25,6,320,"Oats & whey"
        2026-11-26,Dinner,750,24,78,52,8,690,"Steak & sweet potato"
        2026-11-27,Breakfast,380,10,45,28,5,210,"Greek yogurt bowl"
        """

        let firstImport = try await appStore.importMyFitnessPalCSV(mfpCSV, policy: .skip)
        #expect(firstImport.importedCount == 3)
        #expect(firstImport.skippedCount == 0)

        // Re-importing the exact same CSV must skip all 3 duplicates deterministically!
        let secondImport = try await appStore.importMyFitnessPalCSV(mfpCSV, policy: .skip)
        #expect(secondImport.importedCount == 0)
        #expect(secondImport.skippedCount == 3)

        // 5. Verify weekly trend aggregation across the 7-day window (Nov 21 -> Nov 27).
        #expect(appStore.weekCalories.count == 7)
        #expect(appStore.weekCalories.first?.localDate == "2026-11-21")
        #expect(appStore.weekCalories.last?.localDate == "2026-11-27")

        let nov25 = try #require(appStore.weekCalories.first { $0.localDate == "2026-11-25" })
        let nov26 = try #require(appStore.weekCalories.first { $0.localDate == "2026-11-26" })
        let nov27 = try #require(appStore.weekCalories.first { $0.localDate == "2026-11-27" })
        #expect(nov25.caloriesKcal == 410)
        #expect(nov26.caloriesKcal == 750)
        #expect(nov27.caloriesKcal == 1068) // 688 logged lunch + 380 imported breakfast
        #expect(nov27.mealCount == 2)
        #expect(appStore.weekTotalCalories == 2228)

        // 6. Verify Obsidian Markdown export contains YAML frontmatter, daily totals, and sauces/oils callout.
        let markdown = try await appStore.exportObsidianMarkdown(for: "2026-11-27")
        #expect(markdown.contains("date: 2026-11-27"))
        #expect(markdown.contains("calories_kcal: 1068"))
        #expect(markdown.contains("## Lunch — Salmon Rice Bowl"))
        #expect(markdown.contains("> [!note]- Sauces, Oils & Seasonings"))
        #expect(markdown.contains("Extra Virgin Olive Oil"))

        // 7. Verify portable JSON archive round-trips cleanly.
        let jsonData = try await appStore.exportDiaryJSON(appVersion: "1.0.0")
        let decodedArchive = try PortableExporter.decodeJSON(jsonData)
        #expect(decodedArchive.manifest.mealCount == 4)
        #expect(decodedArchive.meals.count == 4)
        #expect(decodedArchive.foodItems.count >= 15)

        // 8. Verify photo analysis resizes/strips EXIF and updates quotaRemaining.
        let samplePhoto = SyntheticImageFactory.makeJPEG(width: 1024, height: 768, includeGPSMetadata: true)
        let aiResult = try await appStore.analyzePhoto(jpegData: samplePhoto, hint: "light dressing")
        #expect(aiResult.suggestedTitle == "Avocado Chicken Salad")
        #expect(appStore.quotaRemaining == 18)

        // 9. Verify account deletion wipes diary meals and resets auth state cleanly.
        try await appStore.deleteAccount()
        #expect(appStore.isSignedIn == false)
        #expect(appStore.currentUser == nil)
        #expect(appStore.todayMeals.isEmpty)
        #expect(appStore.weekTotalCalories == 0)
        #expect(appStore.queuedCount == 0)
        // Default USDA staples are still available offline after reset.
        #expect(!(try await appStore.searchFoods("chicken")).isEmpty)
    }

    @Test("HealthKit import deduplicates repeated imports and syncs logged meals when enabled")
    @MainActor
    func healthKitImportAndLiveSyncHooks() async throws {
        let importedFingerprint = PureSHA256.hex("hk|2026-11-27|breakfast|500.0")
        let hkMeal = TestFixtures.makeMeal(
            localDate: "2026-11-27",
            mealType: .breakfast,
            title: "HealthKit Breakfast",
            calories: 500,
            captureMethod: .importedHealthKit,
            dedupeFingerprint: importedFingerprint
        )

        let mockHealthKit = MockHealthKitService(isAvailable: true, importableMeals: [hkMeal])
        let store = try LocalDiaryStore.inMemory()
        let credentials = InMemoryCredentialStore()
        let apiClient = NomNomAPIClient(baseURL: baseURL, credentialStore: credentials)

        let appStore = NomNomAppStore(
            store: store,
            apiClient: apiClient,
            credentialStore: credentials,
            healthKitService: mockHealthKit,
            selectedDate: TestFixtures.fixedDate("2026-11-27T12:00:00Z"),
            timeZone: utcTimeZone
        )

        let first = try await appStore.importFromHealthKit(days: 14)
        #expect(first.importedCount == 1)
        #expect(first.skippedCount == 0)
        #expect(mockHealthKit.authorizationRequestCount == 1)

        // Repeating HealthKit import must skip the already-imported meal.
        let second = try await appStore.importFromHealthKit(days: 14)
        #expect(second.importedCount == 0)
        #expect(second.skippedCount == 1)

        // Enabling HealthKit write sync triggers syncMeal on logMeal and deleteSyncedMeal on deleteMeal.
        appStore.healthKitEnabled = true
        let newMeal = TestFixtures.makeMeal(localDate: "2026-11-27", mealType: .dinner, title: "Steak", calories: 700)
        try await appStore.logMeal(newMeal)
        #expect(mockHealthKit.syncedMeals.map(\.id) == [newMeal.id])

        try await appStore.deleteMeal(id: newMeal.id)
        #expect(mockHealthKit.deletedMealIds == [newMeal.id])
    }

    @Test("Barcode caching, text estimation, meal editing, replaceDate import, and syncNow work end-to-end")
    @MainActor
    func barcodeCacheTextEstimateReplaceDateAndSync() async throws {
        let routeID = UUID().uuidString
        defer { ScopedMockURLProtocol.removeHandler(routeID: routeID) }

        let barcodeCalls = OSAllocatedUnfairLock(initialState: 0)
        let serverTime = TestFixtures.fixedDate("2026-11-27T17:00:00Z")
        let scannedFood = FoodItem(
            name: "Fairlife Core Power Elite",
            brand: "Fairlife",
            barcode: "0811620021951",
            source: .usda,
            nutritionPer100g: NutritionSnapshot(caloriesKcal: 56, proteinG: 10.2, carbsG: 1.7, fatG: 0.8),
            servingOptions: [ServingOption(label: "1 bottle (414ml)", gramWeight: 414, isDefault: true)]
        )

        let session = ScopedMockURLProtocol.makeSession(routeID: routeID) { request, body in
            let url = request.url!
            switch (request.httpMethod, url.path) {
            case ("GET", "/v1/foods/barcode/0811620021951"):
                barcodeCalls.withLock { $0 += 1 }
                let res = BarcodeLookupResponse(
                    barcode: "0811620021951",
                    found: true,
                    foodItem: scannedFood,
                    source: .usda,
                    cached: false
                )
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 200), try TestFixtures.encodeJSON(res))

            case ("POST", "/v1/ai/estimate-meal-text"):
                let res = AnalyzeMealResponse(
                    suggestedTitle: "Pho Tai",
                    suggestedMealType: .dinner,
                    items: [
                        DetectedMealItemDTO(
                            displayName: "Pho Tai",
                            servingLabel: "1 medium bowl",
                            confidence: 0.85,
                            nutrition: NutritionSnapshot(caloriesKcal: 620, proteinG: 38, carbsG: 76, fatG: 16)
                        ),
                    ]
                )
                return (
                    TestFixtures.makeHTTPResponse(url: url, statusCode: 200, headers: ["X-AI-Quota-Remaining": "12"]),
                    try TestFixtures.encodeJSON(res)
                )

            case ("POST", "/v1/sync/push"):
                let req = try NomNomJSON.makeDecoder().decode(SyncPushRequest.self, from: try #require(body))
                let acks = req.mutations.map {
                    SyncMutationAck(
                        mutationId: $0.mutationId,
                        entityType: $0.entityType,
                        entityId: $0.entityId,
                        status: .applied,
                        syncSeq: 20
                    )
                }
                return (
                    TestFixtures.makeHTTPResponse(url: url, statusCode: 200),
                    try TestFixtures.encodeJSON(
                        SyncPushResponse(acceptedCount: acks.count, latestSyncSeq: 20, results: acks, serverTime: serverTime)
                    )
                )

            case ("GET", "/v1/sync/changes"):
                return (
                    TestFixtures.makeHTTPResponse(url: url, statusCode: 200),
                    try TestFixtures.encodeJSON(
                        SyncChangesResponse(sinceSeq: 0, nextSeq: 20, hasMore: false, serverTime: serverTime)
                    )
                )

            default:
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 404), Data())
            }
        }

        let store = try LocalDiaryStore.inMemory()
        let credentials = InMemoryCredentialStore(initialValues: [
            .accessToken: "valid-token",
            .refreshToken: "valid-refresh",
            .deviceId: "iphone-duo-test",
            .userId: UUID().uuidString,
        ])
        let apiClient = NomNomAPIClient(baseURL: baseURL, session: session, credentialStore: credentials)
        let appStore = NomNomAppStore(
            store: store,
            apiClient: apiClient,
            credentialStore: credentials,
            selectedDate: TestFixtures.fixedDate("2026-11-27T12:00:00Z"),
            timeZone: utcTimeZone
        )
        try await appStore.bootstrap()
        #expect(appStore.isSignedIn == true)

        // Barcode lookup hits backend once, then serves instantaneously from SQLite cache.
        let firstBarcode = try await appStore.lookupBarcode("0811620021951")
        #expect(firstBarcode.found == true)
        #expect(firstBarcode.cached == false)
        let secondBarcode = try await appStore.lookupBarcode("0811620021951")
        #expect(secondBarcode.found == true)
        #expect(secondBarcode.cached == true)
        #expect(barcodeCalls.withLock { $0 } == 1)

        // Natural-language meal text estimate updates quotaRemaining.
        let estimate = try await appStore.estimateTextMeal("1 medium bowl pho tai", mealTypeHint: .dinner)
        #expect(estimate.suggestedTitle == "Pho Tai")
        #expect(appStore.quotaRemaining == 12)

        // Log and edit a meal, then replace the date via MFP import.
        var meal = TestFixtures.makeMeal(localDate: "2026-11-27", title: "Draft Lunch", calories: 500)
        try await appStore.logMeal(meal)
        meal.title = "Updated Lunch"
        try await appStore.updateMeal(meal)
        #expect(appStore.todayMeals.first?.title == "Updated Lunch")

        let replacementCSV = """
        Date,Meal,Calories,Fat (g),Carbohydrates (g),Protein (g)
        2026-11-27,Lunch,640,20,70,45
        """
        let replaced = try await appStore.importMyFitnessPalCSV(replacementCSV, policy: .replaceDate)
        #expect(replaced.importedCount == 1)
        #expect(replaced.replacedCount == 1)
        #expect(appStore.todayMeals.count == 1)
        #expect(appStore.todayTotals.caloriesKcal == 640)

        // Run syncNow() to drain all queued mutations cleanly.
        let report = try await appStore.syncNow()
        #expect(report.pushedCount >= 3)
        #expect(appStore.syncStatus == .synced)
        #expect(appStore.queuedCount == 0)
        #expect(appStore.lastSyncedAt == serverTime)
    }
}
