import Foundation
import NomNomShared
import Observation

// MARK: - Supporting State Models

/// User-configurable daily calorie and macro targets.
public struct DailyNutritionTargets: Codable, Sendable, Equatable {
    public var caloriesKcal: Int
    public var proteinG: Int
    public var carbsG: Int
    public var fatG: Int

    public static let `default` = DailyNutritionTargets(
        caloriesKcal: 2100,
        proteinG: 150,
        carbsG: 215,
        fatG: 70
    )

    public init(
        caloriesKcal: Int = 2100,
        proteinG: Int = 150,
        carbsG: Int = 215,
        fatG: Int = 70
    ) {
        self.caloriesKcal = caloriesKcal
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
    }
}

/// Daily aggregated totals powering the iPhone Duo & iPad 7-day trend panel.
public struct DayCaloriePoint: Sendable, Equatable, Identifiable {
    public var id: String { localDate }
    public var localDate: String
    public var date: Date
    public var caloriesKcal: Double
    public var proteinG: Double
    public var carbsG: Double
    public var fatG: Double
    public var mealCount: Int

    public init(
        localDate: String,
        date: Date,
        caloriesKcal: Double,
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        mealCount: Int
    ) {
        self.localDate = localDate
        self.date = date
        self.caloriesKcal = caloriesKcal
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.mealCount = mealCount
    }
}

/// Summary receipt returned after completing a MyFitnessPal or Apple Health import.
public struct ImportSummary: Sendable, Equatable {
    public var source: String
    public var importedCount: Int
    public var skippedCount: Int
    public var replacedCount: Int
    public var warnings: [String]

    public init(
        source: String,
        importedCount: Int,
        skippedCount: Int,
        replacedCount: Int = 0,
        warnings: [String] = []
    ) {
        self.source = source
        self.importedCount = importedCount
        self.skippedCount = skippedCount
        self.replacedCount = replacedCount
        self.warnings = warnings
    }
}

// MARK: - Main Observable App Store

/// Unified `@Observable @MainActor` application store powering iPhone, iPhone Duo, and iPad views.
@Observable
@MainActor
public final class NomNomAppStore {
    // MARK: Dependencies

    public let store: LocalDiaryStore
    public let apiClient: any NomNomAPIClientProtocol
    public let syncEngine: SyncEngine
    public let credentialStore: any SessionCredentialStore
    public let healthKitService: any HealthKitSyncing
    public let reachabilityMonitor: NetworkReachabilityMonitor

    private let userDefaults: UserDefaults?
    private let timeZone: TimeZone
    private var reachabilityTask: Task<Void, Never>?

    // MARK: Auth State

    public private(set) var isSignedIn: Bool = false
    public private(set) var currentUser: UserProfileDTO?
    public var apiBaseURL: URL {
        didSet {
            userDefaults?.set(apiBaseURL.absoluteString, forKey: DefaultsKey.apiBaseURL)
            let updatedURL = apiBaseURL
            Task { await apiClient.setBaseURL(updatedURL) }
        }
    }
    public private(set) var isBackendHealthy: Bool?

    // MARK: Diary State

    public var selectedDate: Date
    public private(set) var todayMeals: [Meal] = []
    public private(set) var weekCalories: [DayCaloriePoint] = []
    public var targets: DailyNutritionTargets {
        didSet { persistTargets() }
    }

    // MARK: Sync & Connectivity State

    public private(set) var syncStatus: SyncStatus = .synced
    public private(set) var queuedCount: Int = 0
    public private(set) var lastSyncedAt: Date?
    public private(set) var quotaRemaining: Int?
    public private(set) var isOffline: Bool = false

    // MARK: Preferences & Transient UI State

    public var openToCamera: Bool {
        didSet { userDefaults?.set(openToCamera, forKey: DefaultsKey.openToCamera) }
    }
    public var healthKitEnabled: Bool {
        didSet { userDefaults?.set(healthKitEnabled, forKey: DefaultsKey.healthKitEnabled) }
    }
    public var obsidianSyncEnabled: Bool {
        didSet { userDefaults?.set(obsidianSyncEnabled, forKey: DefaultsKey.obsidianSyncEnabled) }
    }
    public private(set) var isLoading: Bool = false
    public private(set) var lastErrorMessage: String?

    // MARK: Computed Properties

    public var selectedLocalDate: String {
        Self.localDateString(for: selectedDate, timeZone: timeZone)
    }

    public var todayTotals: NutritionSnapshot {
        NutritionSnapshot.sum(todayMeals.map(\.totalNutrition))
    }

    public var weekTotalCalories: Double {
        weekCalories.reduce(0) { $0 + $1.caloriesKcal }
    }

    public var weekAverageCalories: Double {
        let loggedDays = weekCalories.filter { $0.mealCount > 0 }
        guard !loggedDays.isEmpty else { return 0 }
        let sum = loggedDays.reduce(0.0) { $0 + $1.caloriesKcal }
        return sum / Double(loggedDays.count)
    }

    // MARK: Initialization

    public init(
        store: LocalDiaryStore,
        apiClient: any NomNomAPIClientProtocol,
        credentialStore: any SessionCredentialStore = InMemoryCredentialStore(),
        healthKitService: any HealthKitSyncing = NoOpHealthKitService(),
        reachabilityMonitor: NetworkReachabilityMonitor = NetworkReachabilityMonitor(),
        apiBaseURL: URL = NomNomAPIClient.defaultBaseURL,
        selectedDate: Date = Date(),
        timeZone: TimeZone = .current,
        userDefaults: UserDefaults? = nil
    ) {
        self.store = store
        self.apiClient = apiClient
        self.credentialStore = credentialStore
        self.healthKitService = healthKitService
        self.reachabilityMonitor = reachabilityMonitor
        self.syncEngine = SyncEngine(
            store: store,
            apiClient: apiClient,
            credentialStore: credentialStore
        )
        self.timeZone = timeZone
        self.userDefaults = userDefaults
        self.selectedDate = selectedDate

        if let storedURLString = userDefaults?.string(forKey: DefaultsKey.apiBaseURL),
           let storedURL = URL(string: storedURLString)
        {
            self.apiBaseURL = storedURL
        } else {
            self.apiBaseURL = apiBaseURL
        }

        self.openToCamera = userDefaults?.bool(forKey: DefaultsKey.openToCamera) ?? false
        self.healthKitEnabled = userDefaults?.bool(forKey: DefaultsKey.healthKitEnabled) ?? false
        self.obsidianSyncEnabled = userDefaults?.bool(forKey: DefaultsKey.obsidianSyncEnabled) ?? false

        if let data = userDefaults?.data(forKey: DefaultsKey.targets),
           let decoded = try? JSONDecoder().decode(DailyNutritionTargets.self, from: data)
        {
            self.targets = decoded
        } else {
            self.targets = .default
        }
    }

    /// Production factory storing SQLite in Application Support, tokens in Keychain, and HealthKit when available.
    public static func makeLive(
        baseURL: URL = NomNomAPIClient.defaultBaseURL,
        userDefaults: UserDefaults = .standard
    ) throws -> NomNomAppStore {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dbURL = appSupport
            .appendingPathComponent("NomNom", isDirectory: true)
            .appendingPathComponent("diary.sqlite")

        let localStore = try LocalDiaryStore(url: dbURL)
        let keychain = KeychainStore()
        let effectiveURL: URL = {
            if let saved = userDefaults.string(forKey: DefaultsKey.apiBaseURL),
               let parsed = URL(string: saved)
            {
                return parsed
            }
            return baseURL
        }()
        let client = NomNomAPIClient(baseURL: effectiveURL, credentialStore: keychain)

        #if canImport(HealthKit)
        let healthService: any HealthKitSyncing = LiveHealthKitService()
        #else
        let healthService: any HealthKitSyncing = NoOpHealthKitService()
        #endif

        return NomNomAppStore(
            store: localStore,
            apiClient: client,
            credentialStore: keychain,
            healthKitService: healthService,
            apiBaseURL: effectiveURL,
            userDefaults: userDefaults
        )
    }

    // MARK: - Lifecycle & Reachability

    /// Seeds local offline USDA staples on first launch, restores stored session credentials,
    /// and hydrates today's meals, 7-day trend, and sync queue counts.
    public func bootstrap(startReachability: Bool = false) async throws {
        isLoading = true
        defer { isLoading = false }

        _ = try await store.seedFoodItemsIfEmpty(DefaultUSDAStaples.catalog())
        restorePersistedSession()
        try await reloadDiaryState()

        if startReachability {
            startReachabilityMonitoring()
        }
    }

    public func startReachabilityMonitoring() {
        reachabilityMonitor.start()
        reachabilityTask?.cancel()
        let monitor = reachabilityMonitor
        reachabilityTask = Task { [weak self] in
            for await online in monitor.updates() {
                guard let self else { break }
                self.isOffline = !online
                await self.syncEngine.setOffline(!online)
                let snap = await self.syncEngine.currentSnapshot()
                self.syncStatus = snap.status
                if online, self.isSignedIn, self.queuedCount > 0 {
                    _ = try? await self.syncNow()
                }
            }
        }
    }

    public func stopReachabilityMonitoring() {
        reachabilityTask?.cancel()
        reachabilityTask = nil
        reachabilityMonitor.stop()
    }

    public func selectDate(_ date: Date) async throws {
        selectedDate = date
        try await reloadDiaryState()
    }

    // MARK: - Auth Actions

    @discardableResult
    public func signInWithApple(_ request: AppleAuthRequest) async throws -> AuthTokenResponse {
        isLoading = true
        lastErrorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await apiClient.signInWithApple(request)
            isSignedIn = true
            currentUser = response.user
            applyUserTargetsIfPresent(response.user)
            try await reloadDiaryState()
            return response
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    public func signOut() async throws {
        isLoading = true
        lastErrorMessage = nil
        defer { isLoading = false }

        do {
            try await apiClient.signOut()
            isSignedIn = false
            currentUser = nil
            quotaRemaining = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    public func deleteAccount() async throws {
        isLoading = true
        lastErrorMessage = nil
        defer { isLoading = false }

        do {
            try await apiClient.deleteAccount()
            try await store.clearAllData()
            _ = try await store.seedFoodItemsIfEmpty(DefaultUSDAStaples.catalog())
            isSignedIn = false
            currentUser = nil
            quotaRemaining = nil
            lastSyncedAt = nil
            syncStatus = .synced
            try await reloadDiaryState()
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    @discardableResult
    public func checkBackendHealth() async -> Bool {
        do {
            let healthy = try await apiClient.healthCheck()
            isBackendHealthy = healthy
            if healthy {
                isOffline = false
            }
            return healthy
        } catch let apiError as NomNomAPIError where apiError.isConnectivityFailure {
            isBackendHealthy = false
            isOffline = true
            syncStatus = .offline
            return false
        } catch {
            isBackendHealthy = false
            return false
        }
    }

    public func updateAPIBaseURL(_ url: URL) async {
        apiBaseURL = url
        await apiClient.setBaseURL(url)
    }

    // MARK: - Diary CRUD

    public func logMeal(_ meal: Meal) async throws {
        lastErrorMessage = nil
        var mealToSave = meal
        if mealToSave.localDate.isEmpty {
            mealToSave.localDate = Self.localDateString(for: mealToSave.eatenAt, timeZone: timeZone)
        }

        if healthKitEnabled, healthKitService.isHealthDataAvailable {
            if let correlationId = try? await healthKitService.syncMeal(mealToSave) {
                mealToSave.healthKitCorrelationId = correlationId
            }
        }

        try await store.saveMeal(mealToSave, enqueueSync: true)
        try await reloadDiaryState()
    }

    public func updateMeal(_ meal: Meal) async throws {
        lastErrorMessage = nil
        var updated = meal
        updated.updatedAt = Date()

        if healthKitEnabled, healthKitService.isHealthDataAvailable {
            if let correlationId = try? await healthKitService.syncMeal(updated) {
                updated.healthKitCorrelationId = correlationId
            }
        }

        try await store.saveMeal(updated, enqueueSync: true)
        try await reloadDiaryState()
    }

    public func deleteMeal(id: UUID) async throws {
        lastErrorMessage = nil
        try await store.softDeleteMeal(id: id, at: Date(), enqueueSync: true)

        if healthKitEnabled, healthKitService.isHealthDataAvailable {
            try? await healthKitService.deleteSyncedMeal(mealId: id)
        }

        try await reloadDiaryState()
    }

    // MARK: - AI Capture, Barcode & Food Search

    /// Resizes and EXIF-strips the captured photo to <= 768px JPEG before submitting to Vision AI.
    public func analyzePhoto(
        jpegData: Data,
        hint: String? = nil,
        mealTypeHint: MealType? = nil
    ) async throws -> AnalyzeMealResponse {
        lastErrorMessage = nil
        let processed = try PhotoProcessor.prepareVisionAICopy(from: jpegData)
        let request = AnalyzeMealPhotoRequest(
            imageBase64: processed.data.base64EncodedString(),
            mimeType: processed.mimeType,
            contextHint: hint,
            mealTypeHint: mealTypeHint,
            locale: Locale.current.identifier
        )

        do {
            let (response, remaining) = try await apiClient.analyzeMealPhoto(request)
            if let remaining {
                quotaRemaining = remaining
            }
            return response
        } catch let apiError as NomNomAPIError {
            if case let .quotaExceeded(remaining, _, _) = apiError {
                quotaRemaining = remaining
            } else if apiError.isConnectivityFailure {
                isOffline = true
                syncStatus = .offline
            }
            lastErrorMessage = apiError.localizedDescription
            throw apiError
        }
    }

    public func estimateTextMeal(
        _ text: String,
        mealTypeHint: MealType? = nil
    ) async throws -> AnalyzeMealResponse {
        lastErrorMessage = nil
        let request = EstimateMealTextRequest(
            text: text,
            mealTypeHint: mealTypeHint,
            locale: Locale.current.identifier
        )

        do {
            let (response, remaining) = try await apiClient.estimateMealText(request)
            if let remaining {
                quotaRemaining = remaining
            }
            return response
        } catch let apiError as NomNomAPIError {
            if case let .quotaExceeded(remaining, _, _) = apiError {
                quotaRemaining = remaining
            } else if apiError.isConnectivityFailure {
                isOffline = true
                syncStatus = .offline
            }
            lastErrorMessage = apiError.localizedDescription
            throw apiError
        }
    }

    public func lookupBarcode(_ gtin: String) async throws -> BarcodeLookupResponse {
        lastErrorMessage = nil
        let cleaned = gtin.trimmingCharacters(in: .whitespacesAndNewlines)

        if let cached = try await store.foodItem(byBarcode: cleaned) {
            return BarcodeLookupResponse(
                barcode: cleaned,
                found: true,
                foodItem: cached,
                source: cached.source,
                cached: true
            )
        }

        let response = try await apiClient.lookupBarcode(cleaned)
        if response.found, let item = response.foodItem {
            try await store.saveFoodItem(item, enqueueSync: false)
        }
        return response
    }

    /// Searches local FTS5 foods immediately (<10ms offline), and merges backend results when online & signed in.
    public func searchFoods(_ query: String) async throws -> [FoodItem] {
        lastErrorMessage = nil
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let localMatches = try await store.searchLocalFoods(query: trimmed, limit: 25)

        guard !trimmed.isEmpty, isSignedIn, !isOffline else {
            return localMatches
        }

        do {
            let remote = try await apiClient.searchFoods(query: trimmed)
            var merged = localMatches
            var seenIds = Set(localMatches.map(\.id))

            for item in remote.items {
                try await store.saveFoodItem(item, enqueueSync: false)
                if seenIds.insert(item.id).inserted {
                    merged.append(item)
                }
            }
            return merged
        } catch let apiError as NomNomAPIError where apiError.isConnectivityFailure {
            isOffline = true
            return localMatches
        } catch {
            // Preserve instant offline-first UX if remote search fails transiently.
            return localMatches
        }
    }

    public func recentFoods(limit: Int = 20) async throws -> [FoodItem] {
        try await store.recentFoods(limit: limit)
    }

    // MARK: - External Importers

    public func importMyFitnessPalCSV(
        _ csv: String,
        policy: DuplicatePolicy = .skip
    ) async throws -> ImportSummary {
        lastErrorMessage = nil
        let parsed = try MyFitnessPalParser.parse(csv: csv)
        let existingMeals = try await store.allMeals(includeDeleted: false)

        let reconciled = MyFitnessPalParser.reconcile(
            importedRows: parsed.rows,
            existingMeals: existingMeals,
            policy: policy,
            timezoneId: timeZone.identifier
        )

        var mealsToInsert = reconciled.mealsToInsert
        var skippedCount = reconciled.skippedCount

        // Also guard against already-recorded import fingerprints when skipping duplicates.
        if policy == .skip {
            let recordedFingerprints = try await store.existingImportFingerprints()
            var filtered: [Meal] = []
            filtered.reserveCapacity(mealsToInsert.count)
            for meal in mealsToInsert {
                if let fp = meal.dedupeFingerprint, recordedFingerprints.contains(fp) {
                    skippedCount += 1
                } else {
                    filtered.append(meal)
                }
            }
            mealsToInsert = filtered
        }

        try await store.applyImport(
            mealsToInsert: mealsToInsert,
            mealIdsToDelete: reconciled.mealIdsToDelete,
            source: CaptureMethod.importedMFP.rawValue,
            enqueueSync: true
        )
        try await reloadDiaryState()

        return ImportSummary(
            source: "MyFitnessPal",
            importedCount: mealsToInsert.count,
            skippedCount: skippedCount,
            replacedCount: reconciled.replacedCount,
            warnings: parsed.warnings
        )
    }

    public func importFromHealthKit(days: Int = 30) async throws -> ImportSummary {
        lastErrorMessage = nil
        let safeDays = max(1, days)
        let endDate = Date()
        let startDate = Calendar(identifier: .gregorian).date(
            byAdding: .day,
            value: -safeDays,
            to: endDate
        ) ?? endDate.addingTimeInterval(-Double(safeDays) * 86_400)

        try await healthKitService.requestAuthorization()
        let importedMeals = try await healthKitService.importMeals(from: startDate, to: endDate)

        let existingFingerprints = try await store.existingImportFingerprints()
        var existingActiveFingerprints = Set(
            try await store.allMeals(includeDeleted: false).compactMap(\.dedupeFingerprint)
        )
        existingActiveFingerprints.formUnion(existingFingerprints)

        var mealsToInsert: [Meal] = []
        var skippedCount = 0

        for meal in importedMeals {
            if let fp = meal.dedupeFingerprint, existingActiveFingerprints.contains(fp) {
                skippedCount += 1
            } else {
                if let fp = meal.dedupeFingerprint {
                    existingActiveFingerprints.insert(fp)
                }
                mealsToInsert.append(meal)
            }
        }

        try await store.applyImport(
            mealsToInsert: mealsToInsert,
            mealIdsToDelete: [],
            source: CaptureMethod.importedHealthKit.rawValue,
            enqueueSync: true
        )
        try await reloadDiaryState()

        return ImportSummary(
            source: "Apple Health",
            importedCount: mealsToInsert.count,
            skippedCount: skippedCount,
            replacedCount: 0,
            warnings: []
        )
    }

    // MARK: - Portable Exports

    public func exportDiaryJSON(appVersion: String = "1.0.0") async throws -> Data {
        let meals = try await store.allMeals(includeDeleted: false)
        let foodItems = try await store.allFoodItems(includeDeleted: false)
        let photoAssets = try await store.allPhotoAssets(includeDeleted: false)
        let export = PortableExporter.makeDiaryExport(
            meals: meals,
            foodItems: foodItems,
            photoAssets: photoAssets,
            appVersion: appVersion
        )
        return try PortableExporter.encodeJSON(export, prettyPrinted: true)
    }

    public func exportObsidianMarkdown(for localDate: String) async throws -> String {
        let dayMeals = try await store.meals(forLocalDate: localDate)
        return PortableExporter.obsidianDailyMarkdown(date: localDate, meals: dayMeals)
    }

    public func exportObsidianMarkdown(for date: Date? = nil) async throws -> String {
        let targetDate = Self.localDateString(for: date ?? selectedDate, timeZone: timeZone)
        return try await exportObsidianMarkdown(for: targetDate)
    }

    public func exportMealsCSV() async throws -> String {
        let meals = try await store.allMeals(includeDeleted: false)
        return PortableExporter.mealsCSV(meals: meals)
    }

    // MARK: - Cloud Sync

    @discardableResult
    public func syncNow() async throws -> SyncReport {
        lastErrorMessage = nil
        syncStatus = .syncing
        do {
            let report = try await syncEngine.syncNow()
            isOffline = false
            try await reloadDiaryState()
            let snapshot = await syncEngine.currentSnapshot()
            syncStatus = snapshot.status
            queuedCount = snapshot.queuedCount
            lastSyncedAt = snapshot.lastSyncedAt
            return report
        } catch {
            let snapshot = await syncEngine.currentSnapshot()
            syncStatus = snapshot.status
            queuedCount = snapshot.queuedCount
            if snapshot.status == .offline {
                isOffline = true
            }
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Internal Helpers

    private func restorePersistedSession() {
        guard let creds = try? credentialStore.loadCredentials(), creds.isSignedIn else {
            isSignedIn = false
            currentUser = nil
            return
        }

        isSignedIn = true
        if currentUser == nil, let idString = creds.userId, let uuid = UUID(uuidString: idString) {
            currentUser = UserProfileDTO(
                id: uuid,
                displayName: creds.displayName,
                email: creds.email,
                isPrivateEmail: creds.isPrivateEmail
            )
        }
    }

    private func applyUserTargetsIfPresent(_ user: UserProfileDTO) {
        if let kcal = user.dailyCalorieTarget { targets.caloriesKcal = kcal }
        if let protein = user.dailyProteinTargetG { targets.proteinG = protein }
        if let carbs = user.dailyCarbsTargetG { targets.carbsG = carbs }
        if let fat = user.dailyFatTargetG { targets.fatG = fat }
    }

    private func reloadDiaryState() async throws {
        let targetLocalDate = selectedLocalDate
        todayMeals = try await store.meals(forLocalDate: targetLocalDate)
        weekCalories = try await loadSevenDayTrend(endingAt: selectedDate)
        queuedCount = try await store.pendingOutboxCount()
        lastSyncedAt = try await store.lastSyncedAt()
    }

    private func loadSevenDayTrend(endingAt anchorDate: Date) async throws -> [DayCaloriePoint] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let anchorStart = calendar.startOfDay(for: anchorDate)
        let days: [(date: Date, localDate: String)] = (-6...0).compactMap { offset in
            guard let dayDate = calendar.date(byAdding: .day, value: offset, to: anchorStart) else {
                return nil
            }
            return (dayDate, Self.localDateString(for: dayDate, timeZone: timeZone))
        }

        guard let firstDay = days.first?.localDate, let lastDay = days.last?.localDate else {
            return []
        }

        let rangeMeals = try await store.mealsInDateRange(from: firstDay, to: lastDay)
        let grouped = Dictionary(grouping: rangeMeals, by: \.localDate)

        return days.map { entry in
            let mealsForDay = grouped[entry.localDate] ?? []
            let total = NutritionSnapshot.sum(mealsForDay.map(\.totalNutrition))
            return DayCaloriePoint(
                localDate: entry.localDate,
                date: entry.date,
                caloriesKcal: total.caloriesKcal,
                proteinG: total.proteinG,
                carbsG: total.carbsG,
                fatG: total.fatG,
                mealCount: mealsForDay.count
            )
        }
    }

    private func persistTargets() {
        guard let userDefaults else { return }
        if let encoded = try? JSONEncoder().encode(targets) {
            userDefaults.set(encoded, forKey: DefaultsKey.targets)
        }
    }

    public static func localDateString(for date: Date, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let year = comps.year ?? 1970
        let month = comps.month ?? 1
        let day = comps.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private enum DefaultsKey {
        static let apiBaseURL = "nomnom.apiBaseURL"
        static let openToCamera = "nomnom.openToCamera"
        static let healthKitEnabled = "nomnom.healthKitEnabled"
        static let obsidianSyncEnabled = "nomnom.obsidianSyncEnabled"
        static let targets = "nomnom.dailyNutritionTargets"
    }
}
