import Foundation
import NomNomShared

#if canImport(HealthKit)
import HealthKit
#endif

// MARK: - Errors & Protocol

public enum HealthKitServiceError: Error, Sendable, Equatable, LocalizedError {
    case healthDataUnavailable
    case emptyNutritionPayload
    case syncFailed(String)

    public var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            "Apple Health is not available on this device."
        case .emptyNutritionPayload:
            "Cannot sync a meal with zero recorded nutrients to Apple Health."
        case let .syncFailed(message):
            "Apple Health sync failed: \(message)"
        }
    }
}

/// Platform-neutral representation of a dietary sample used for deterministic grouping & unit testing.
public struct HealthKitDietarySample: Sendable, Equatable {
    public enum NutrientKind: String, Sendable, Equatable, CaseIterable {
        case caloriesKcal
        case proteinG
        case carbsG
        case fatG
        case fiberG
        case sugarG
        case sodiumMg
    }

    public var kind: NutrientKind
    public var value: Double
    public var startDate: Date
    public var endDate: Date
    public var foodName: String?
    public var sourceIdentifier: String?

    public init(
        kind: NutrientKind,
        value: Double,
        startDate: Date,
        endDate: Date,
        foodName: String? = nil,
        sourceIdentifier: String? = nil
    ) {
        self.kind = kind
        self.value = value
        self.startDate = startDate
        self.endDate = endDate
        self.foodName = foodName
        self.sourceIdentifier = sourceIdentifier
    }
}

/// Contract for reading historical dietary logs from Apple Health and writing idempotent meal correlations.
public protocol HealthKitSyncing: Sendable {
    var isHealthDataAvailable: Bool { get }
    func requestAuthorization() async throws
    func importMeals(from startDate: Date, to endDate: Date) async throws -> [Meal]
    @discardableResult
    func syncMeal(_ meal: Meal) async throws -> String?
    func deleteSyncedMeal(mealId: UUID) async throws
}

// MARK: - Deterministic Sample-to-Meal Mapper

/// Groups individual dietary nutrient samples from Apple Health into domain `Meal` entries
/// with deterministic SHA-256 deduplication fingerprints.
public enum HealthKitMealMapper: Sendable {
    /// Groups samples occurring within `bucketSeconds` (default 5 minutes) into distinct meals.
    public static func groupSamplesIntoMeals(
        _ samples: [HealthKitDietarySample],
        bucketSeconds: TimeInterval = 300,
        timeZone: TimeZone = .current,
        now: Date = Date()
    ) -> [Meal] {
        guard !samples.isEmpty else { return [] }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let safeBucket = max(60, bucketSeconds)
        var buckets: [String: [HealthKitDietarySample]] = [:]

        for sample in samples where sample.value.isFinite && sample.value > 0 {
            let localDate = formatLocalDate(sample.startDate, calendar: calendar)
            let bucketIndex = Int64(floor(sample.startDate.timeIntervalSince1970 / safeBucket))
            let nameKey = sample.foodName?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
            let key = "\(localDate)|\(bucketIndex)|\(nameKey)"
            buckets[key, default: []].append(sample)
        }

        var meals: [Meal] = []
        meals.reserveCapacity(buckets.count)

        for (_, group) in buckets {
            guard let earliest = group.map(\.startDate).min() else { continue }
            let localDate = formatLocalDate(earliest, calendar: calendar)
            let mealType = inferMealType(for: earliest, calendar: calendar)

            var calories = 0.0
            var protein = 0.0
            var carbs = 0.0
            var fat = 0.0
            var fiber: Double?
            var sugar: Double?
            var sodium: Double?

            for sample in group {
                switch sample.kind {
                case .caloriesKcal:
                    calories += sample.value
                case .proteinG:
                    protein += sample.value
                case .carbsG:
                    carbs += sample.value
                case .fatG:
                    fat += sample.value
                case .fiberG:
                    fiber = (fiber ?? 0) + sample.value
                case .sugarG:
                    sugar = (sugar ?? 0) + sample.value
                case .sodiumMg:
                    sodium = (sodium ?? 0) + sample.value
                }
            }

            // Skip empty groups that only had zero values.
            guard calories > 0 || protein > 0 || carbs > 0 || fat > 0 else { continue }

            let nutrition = NutritionSnapshot(
                caloriesKcal: calories,
                proteinG: protein,
                carbsG: carbs,
                fatG: fat,
                fiberG: fiber,
                sugarG: sugar,
                sodiumMg: sodium
            )

            let title = group.compactMap(\.foodName)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first(where: { !$0.isEmpty })
                ?? "\(mealType.displayName) (Apple Health)"

            let fingerprint = fingerprint(
                localDate: localDate,
                mealType: mealType,
                eatenAt: earliest,
                nutrition: nutrition
            )

            let mealId = UUID()
            let item = MealEntryItem(
                mealId: mealId,
                displayName: title,
                servingLabel: "Apple Health entry",
                quantity: 1.0,
                portionMultiplier: 1.0,
                nutrition: nutrition
            )

            meals.append(
                Meal(
                    id: mealId,
                    localDate: localDate,
                    eatenAt: earliest,
                    timezoneId: timeZone.identifier,
                    mealType: mealType,
                    title: title,
                    notes: "Imported from Apple Health",
                    captureMethod: .importedHealthKit,
                    aiStatus: .none,
                    dedupeFingerprint: fingerprint,
                    items: [item],
                    createdAt: now,
                    updatedAt: now
                )
            )
        }

        return meals.sorted { lhs, rhs in
            if lhs.eatenAt != rhs.eatenAt {
                return lhs.eatenAt < rhs.eatenAt
            }
            return lhs.title < rhs.title
        }
    }

    public static func fingerprint(
        localDate: String,
        mealType: MealType,
        eatenAt: Date,
        nutrition: NutritionSnapshot
    ) -> String {
        let minuteBucket = Int64(eatenAt.timeIntervalSince1970 / 60.0)
        let kcal = String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), nutrition.caloriesKcal)
        let p = String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), nutrition.proteinG)
        let c = String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), nutrition.carbsG)
        let f = String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), nutrition.fatG)
        return PureSHA256.hex("hk|\(localDate)|\(mealType.rawValue)|\(minuteBucket)|\(kcal)|\(p)|\(c)|\(f)")
    }

    public static func inferMealType(for date: Date, calendar: Calendar) -> MealType {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 4..<11:
            return .breakfast
        case 11..<15:
            return .lunch
        case 17..<22:
            return .dinner
        default:
            return .snack
        }
    }

    private static func formatLocalDate(_ date: Date, calendar: Calendar) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let year = comps.year ?? 1970
        let month = comps.month ?? 1
        let day = comps.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}

// MARK: - Live HealthKit Service

#if canImport(HealthKit)

/// Production HealthKit integration reading dietary history and writing idempotent `HKCorrelation` food entries.
public final class LiveHealthKitService: HealthKitSyncing, @unchecked Sendable {
    private let healthStore: HKHealthStore
    private let nomnomSourceMarker = "dev.brianphan.nomnom"

    public init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    public var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Constituent dietary quantity types requested for both read and write authorization.
    /// Note: HealthKit forbids passing `HKCorrelationType.food` directly to `toShare`.
    public static var dietaryQuantityTypes: Set<HKQuantityType> {
        Set([
            HKQuantityType(.dietaryEnergyConsumed),
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryCarbohydrates),
            HKQuantityType(.dietaryFatTotal),
            HKQuantityType(.dietaryFiber),
            HKQuantityType(.dietarySugar),
            HKQuantityType(.dietarySodium),
        ])
    }

    public func requestAuthorization() async throws {
        guard isHealthDataAvailable else {
            throw HealthKitServiceError.healthDataUnavailable
        }
        let shareTypes: Set<HKSampleType> = Set(Self.dietaryQuantityTypes)
        let readTypes: Set<HKObjectType> = Set(Self.dietaryQuantityTypes)
        try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
    }

    public func importMeals(from startDate: Date, to endDate: Date) async throws -> [Meal] {
        guard isHealthDataAvailable else {
            throw HealthKitServiceError.healthDataUnavailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: [.strictStartDate]
        )

        let descriptors: [(HKQuantityType, HKUnit, HealthKitDietarySample.NutrientKind)] = [
            (HKQuantityType(.dietaryEnergyConsumed), .kilocalorie(), .caloriesKcal),
            (HKQuantityType(.dietaryProtein), .gram(), .proteinG),
            (HKQuantityType(.dietaryCarbohydrates), .gram(), .carbsG),
            (HKQuantityType(.dietaryFatTotal), .gram(), .fatG),
            (HKQuantityType(.dietaryFiber), .gram(), .fiberG),
            (HKQuantityType(.dietarySugar), .gram(), .sugarG),
            (HKQuantityType(.dietarySodium), .gramUnit(with: .milli), .sodiumMg),
        ]

        var collected: [HealthKitDietarySample] = []

        for (quantityType, unit, kind) in descriptors {
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.quantitySample(type: quantityType, predicate: predicate)],
                sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
            )
            let samples = try await descriptor.result(for: healthStore)
            for sample in samples {
                // Skip samples previously written by nomnom itself to avoid echo imports.
                if let bundleId = sample.sourceRevision.source.bundleIdentifier as String?,
                   bundleId.hasPrefix(nomnomSourceMarker)
                {
                    continue
                }
                let foodName = sample.metadata?[HKMetadataKeyFoodType] as? String
                collected.append(
                    HealthKitDietarySample(
                        kind: kind,
                        value: sample.quantity.doubleValue(for: unit),
                        startDate: sample.startDate,
                        endDate: sample.endDate,
                        foodName: foodName,
                        sourceIdentifier: sample.sourceRevision.source.bundleIdentifier
                    )
                )
            }
        }

        return HealthKitMealMapper.groupSamplesIntoMeals(collected)
    }

    /// Writes a `Meal` to Apple Health as an idempotent `HKCorrelation` keyed by `meal.id.uuidString`.
    /// Editing and re-syncing the same meal replaces prior samples cleanly via `HKMetadataKeySyncVersion`.
    @discardableResult
    public func syncMeal(_ meal: Meal) async throws -> String? {
        guard isHealthDataAvailable else {
            throw HealthKitServiceError.healthDataUnavailable
        }

        if meal.isDeleted {
            try await deleteSyncedMeal(mealId: meal.id)
            return nil
        }

        let correlation = try Self.makeCorrelation(for: meal)
        try await healthStore.save(correlation)
        return meal.id.uuidString
    }

    public func deleteSyncedMeal(mealId: UUID) async throws {
        guard isHealthDataAvailable else {
            throw HealthKitServiceError.healthDataUnavailable
        }

        let baseId = mealId.uuidString
        let suffixes = ["kcal", "protein", "carbs", "fat", "fiber", "sugar", "sodium"]
        let syncIdentifiers = [baseId] + suffixes.map { "\(baseId):\($0)" }

        let predicate = HKQuery.predicateForObjects(
            withMetadataKey: HKMetadataKeySyncIdentifier,
            allowedValues: syncIdentifiers
        )

        for quantityType in Self.dietaryQuantityTypes {
            _ = try await healthStore.deleteObjects(of: quantityType, predicate: predicate)
        }
    }

    /// Pure builder creating an idempotent `HKCorrelation` for a `Meal` (testable without live HealthKit permissions).
    public static func makeCorrelation(for meal: Meal) throws -> HKCorrelation {
        let totals = meal.totalNutrition
        let syncVersion = max(1, Int(meal.updatedAt.timeIntervalSince1970))
        let baseMetadata: [String: Any] = [
            HKMetadataKeySyncIdentifier: meal.id.uuidString,
            HKMetadataKeySyncVersion: NSNumber(value: syncVersion),
            HKMetadataKeyFoodType: meal.title,
            HKMetadataKeyTimeZone: meal.timezoneId,
        ]

        var objects = Set<HKSample>()
        let timestamp = meal.eatenAt

        func addSample(
            identifier: HKQuantityTypeIdentifier,
            unit: HKUnit,
            value: Double?,
            suffix: String
        ) {
            guard let value, value.isFinite, value > 0 else { return }
            var sampleMeta = baseMetadata
            sampleMeta[HKMetadataKeySyncIdentifier] = "\(meal.id.uuidString):\(suffix)"
            let sample = HKQuantitySample(
                type: HKQuantityType(identifier),
                quantity: HKQuantity(unit: unit, doubleValue: value),
                start: timestamp,
                end: timestamp,
                metadata: sampleMeta
            )
            objects.insert(sample)
        }

        addSample(identifier: .dietaryEnergyConsumed, unit: .kilocalorie(), value: totals.caloriesKcal, suffix: "kcal")
        addSample(identifier: .dietaryProtein, unit: .gram(), value: totals.proteinG, suffix: "protein")
        addSample(identifier: .dietaryCarbohydrates, unit: .gram(), value: totals.carbsG, suffix: "carbs")
        addSample(identifier: .dietaryFatTotal, unit: .gram(), value: totals.fatG, suffix: "fat")
        addSample(identifier: .dietaryFiber, unit: .gram(), value: totals.fiberG, suffix: "fiber")
        addSample(identifier: .dietarySugar, unit: .gram(), value: totals.sugarG, suffix: "sugar")
        addSample(identifier: .dietarySodium, unit: .gramUnit(with: .milli), value: totals.sodiumMg, suffix: "sodium")

        guard !objects.isEmpty else {
            throw HealthKitServiceError.emptyNutritionPayload
        }

        return HKCorrelation(
            type: HKCorrelationType(.food),
            start: timestamp,
            end: timestamp,
            objects: objects,
            metadata: baseMetadata
        )
    }
}

#endif

// MARK: - No-Op Fallback Service

/// Safe fallback implementation for platforms or preview environments without HealthKit.
public struct NoOpHealthKitService: HealthKitSyncing {
    public let isHealthDataAvailable = false

    public init() {}

    public func requestAuthorization() async throws {
        throw HealthKitServiceError.healthDataUnavailable
    }

    public func importMeals(from startDate: Date, to endDate: Date) async throws -> [Meal] {
        []
    }

    @discardableResult
    public func syncMeal(_ meal: Meal) async throws -> String? {
        nil
    }

    public func deleteSyncedMeal(mealId: UUID) async throws {}
}
