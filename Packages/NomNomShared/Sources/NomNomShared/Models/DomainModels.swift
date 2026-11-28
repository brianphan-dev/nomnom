import Foundation

// MARK: - Canonical JSON Coding

/// Shared JSON encoder/decoder factory enforcing UTC ISO-8601 timestamps
/// with fractional-second support across iOS, macOS, and Linux.
public enum NomNomJSON: Sendable {
    public static func makeEncoder(
        prettyPrinted: Bool = false,
        sortedKeys: Bool = false
    ) -> JSONEncoder {
        let encoder = JSONEncoder()
        var formatting: JSONEncoder.OutputFormatting = [.withoutEscapingSlashes]
        if prettyPrinted {
            formatting.insert(.prettyPrinted)
        }
        if sortedKeys {
            formatting.insert(.sortedKeys)
        }
        encoder.outputFormatting = formatting
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(formatISO8601(date))
        }
        return encoder
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            guard let parsed = parseISO8601(raw) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid ISO-8601 timestamp: '\(raw)'"
                )
            }
            return parsed
        }
        return decoder
    }

    public static func formatISO8601(_ date: Date) -> String {
        Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(date)
    }

    public static func parseISO8601(_ string: String) -> Date? {
        if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(string) {
            return date
        }
        if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: false).parse(string) {
            return date
        }
        return nil
    }
}

// MARK: - Domain Enums

public enum AuthProvider: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case apple
    case google
}

public enum MealType: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack

    public var displayName: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snack: "Snack"
        }
    }

    /// Chronological sort rank within a calendar day.
    public var sortOrder: Int {
        switch self {
        case .breakfast: 0
        case .lunch: 1
        case .dinner: 2
        case .snack: 3
        }
    }
}

public enum CaptureMethod: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case photoAI = "photo_ai"
    case barcode = "barcode"
    case labelOCR = "label_ocr"
    case manualDB = "manual_db"
    case manualAI = "manual_ai"
    case importedMFP = "imported_mfp"
    case importedHealthKit = "imported_healthkit"
}

public enum AIStatus: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case none
    case pending
    case analyzed
    case failed
}

public enum IngredientCategory: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case base
    case sauce
    case oil
    case seasoning
    case garnish
    case topping
}

public enum FoodSource: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case usda = "usda"
    case openFoodFacts = "open_food_facts"
    case labelOCR = "label_ocr"
    case custom = "custom"
    case aiEstimate = "ai_estimate"
}

public enum PhotoUploadState: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case localOnly = "local_only"
    case uploading = "uploading"
    case synced = "synced"
}

// MARK: - NutritionSnapshot

/// Immutable point-in-time macro and micronutrient snapshot.
public struct NutritionSnapshot: Codable, Sendable, Equatable, Hashable {
    public var caloriesKcal: Double
    public var proteinG: Double
    public var carbsG: Double
    public var fatG: Double
    public var fiberG: Double?
    public var sugarG: Double?
    public var saturatedFatG: Double?
    public var sodiumMg: Double?
    public var potassiumMg: Double?
    public var calciumMg: Double?
    public var ironMg: Double?
    public var vitaminCMg: Double?
    public var vitaminDMcg: Double?
    public var extraNutrients: [String: Double]?

    public static let zero = NutritionSnapshot(
        caloriesKcal: 0,
        proteinG: 0,
        carbsG: 0,
        fatG: 0
    )

    public init(
        caloriesKcal: Double,
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        fiberG: Double? = nil,
        sugarG: Double? = nil,
        saturatedFatG: Double? = nil,
        sodiumMg: Double? = nil,
        potassiumMg: Double? = nil,
        calciumMg: Double? = nil,
        ironMg: Double? = nil,
        vitaminCMg: Double? = nil,
        vitaminDMcg: Double? = nil,
        extraNutrients: [String: Double]? = nil
    ) {
        self.caloriesKcal = caloriesKcal
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.fiberG = fiberG
        self.sugarG = sugarG
        self.saturatedFatG = saturatedFatG
        self.sodiumMg = sodiumMg
        self.potassiumMg = potassiumMg
        self.calciumMg = calciumMg
        self.ironMg = ironMg
        self.vitaminCMg = vitaminCMg
        self.vitaminDMcg = vitaminDMcg
        self.extraNutrients = extraNutrients
    }

    private enum CodingKeys: String, CodingKey {
        case caloriesKcal = "calories_kcal"
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
        case sugarG = "sugar_g"
        case saturatedFatG = "saturated_fat_g"
        case sodiumMg = "sodium_mg"
        case potassiumMg = "potassium_mg"
        case calciumMg = "calcium_mg"
        case ironMg = "iron_mg"
        case vitaminCMg = "vitamin_c_mg"
        case vitaminDMcg = "vitamin_d_mcg"
        case extraNutrients = "extra_nutrients"
    }

    /// Returns a copy with all present nutrients multiplied by `factor` (clamped at 0 for non-finite or negative inputs).
    public func scaled(by factor: Double) -> NutritionSnapshot {
        let safeFactor = factor.isFinite ? max(0, factor) : 0
        return NutritionSnapshot(
            caloriesKcal: caloriesKcal * safeFactor,
            proteinG: proteinG * safeFactor,
            carbsG: carbsG * safeFactor,
            fatG: fatG * safeFactor,
            fiberG: fiberG.map { $0 * safeFactor },
            sugarG: sugarG.map { $0 * safeFactor },
            saturatedFatG: saturatedFatG.map { $0 * safeFactor },
            sodiumMg: sodiumMg.map { $0 * safeFactor },
            potassiumMg: potassiumMg.map { $0 * safeFactor },
            calciumMg: calciumMg.map { $0 * safeFactor },
            ironMg: ironMg.map { $0 * safeFactor },
            vitaminCMg: vitaminCMg.map { $0 * safeFactor },
            vitaminDMcg: vitaminDMcg.map { $0 * safeFactor },
            extraNutrients: extraNutrients?.mapValues { $0 * safeFactor }
        )
    }

    /// Returns the element-wise sum of two nutrition snapshots.
    /// Optional micronutrients remain `nil` only when absent in both snapshots.
    public func adding(_ other: NutritionSnapshot) -> NutritionSnapshot {
        let mergedExtras: [String: Double]?
        switch (extraNutrients, other.extraNutrients) {
        case (nil, nil):
            mergedExtras = nil
        case let (lhs?, nil):
            mergedExtras = lhs
        case let (nil, rhs?):
            mergedExtras = rhs
        case let (lhs?, rhs?):
            mergedExtras = lhs.merging(rhs, uniquingKeysWith: +)
        }

        return NutritionSnapshot(
            caloriesKcal: caloriesKcal + other.caloriesKcal,
            proteinG: proteinG + other.proteinG,
            carbsG: carbsG + other.carbsG,
            fatG: fatG + other.fatG,
            fiberG: Self.sumOptional(fiberG, other.fiberG),
            sugarG: Self.sumOptional(sugarG, other.sugarG),
            saturatedFatG: Self.sumOptional(saturatedFatG, other.saturatedFatG),
            sodiumMg: Self.sumOptional(sodiumMg, other.sodiumMg),
            potassiumMg: Self.sumOptional(potassiumMg, other.potassiumMg),
            calciumMg: Self.sumOptional(calciumMg, other.calciumMg),
            ironMg: Self.sumOptional(ironMg, other.ironMg),
            vitaminCMg: Self.sumOptional(vitaminCMg, other.vitaminCMg),
            vitaminDMcg: Self.sumOptional(vitaminDMcg, other.vitaminDMcg),
            extraNutrients: mergedExtras
        )
    }

    public static func + (lhs: NutritionSnapshot, rhs: NutritionSnapshot) -> NutritionSnapshot {
        lhs.adding(rhs)
    }

    public static func sum(_ snapshots: [NutritionSnapshot]) -> NutritionSnapshot {
        snapshots.reduce(.zero) { $0.adding($1) }
    }

    private static func sumOptional(_ lhs: Double?, _ rhs: Double?) -> Double? {
        switch (lhs, rhs) {
        case (nil, nil): nil
        case let (a?, nil): a
        case let (nil, b?): b
        case let (a?, b?): a + b
        }
    }
}

// MARK: - IngredientEstimate

/// Sub-ingredient detected within a dish, including toggleable sauces, oils, and seasonings.
public struct IngredientEstimate: Codable, Sendable, Equatable, Hashable, Identifiable {
    public var id: UUID
    public var name: String
    public var category: IngredientCategory
    public var estimatedGrams: Double?
    public var nutrition: NutritionSnapshot
    public var isOptionalEstimate: Bool
    public var isIncluded: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        category: IngredientCategory,
        estimatedGrams: Double? = nil,
        nutrition: NutritionSnapshot,
        isOptionalEstimate: Bool = false,
        isIncluded: Bool = true
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.estimatedGrams = estimatedGrams
        self.nutrition = nutrition
        self.isOptionalEstimate = isOptionalEstimate
        self.isIncluded = isIncluded
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case estimatedGrams = "estimated_grams"
        case nutrition
        case isOptionalEstimate = "is_optional_estimate"
        case isIncluded = "is_included"
    }
}

// MARK: - MealEntryItem

/// Logged food entry inside a `Meal`, preserving an immutable base nutrition snapshot
/// alongside user portion multiplier and toggleable optional ingredients.
public struct MealEntryItem: Codable, Sendable, Equatable, Hashable, Identifiable {
    public var id: UUID
    public var mealId: UUID?
    public var foodItemId: UUID?
    public var displayName: String
    public var brand: String?
    public var servingLabel: String
    public var quantity: Double
    public var gramWeight: Double?
    public var portionMultiplier: Double
    public var confidence: Double?
    public var nutrition: NutritionSnapshot
    public var ingredients: [IngredientEstimate]

    public init(
        id: UUID = UUID(),
        mealId: UUID? = nil,
        foodItemId: UUID? = nil,
        displayName: String,
        brand: String? = nil,
        servingLabel: String,
        quantity: Double = 1.0,
        gramWeight: Double? = nil,
        portionMultiplier: Double = 1.0,
        confidence: Double? = nil,
        nutrition: NutritionSnapshot,
        ingredients: [IngredientEstimate] = []
    ) {
        self.id = id
        self.mealId = mealId
        self.foodItemId = foodItemId
        self.displayName = displayName
        self.brand = brand
        self.servingLabel = servingLabel
        self.quantity = quantity
        self.gramWeight = gramWeight
        self.portionMultiplier = portionMultiplier
        self.confidence = confidence
        self.nutrition = nutrition
        self.ingredients = ingredients
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case mealId = "meal_id"
        case foodItemId = "food_item_id"
        case displayName = "display_name"
        case brand
        case servingLabel = "serving_label"
        case quantity
        case gramWeight = "gram_weight"
        case portionMultiplier = "portion_multiplier"
        case confidence
        case nutrition
        case ingredients
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.mealId = try container.decodeIfPresent(UUID.self, forKey: .mealId)
        self.foodItemId = try container.decodeIfPresent(UUID.self, forKey: .foodItemId)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.brand = try container.decodeIfPresent(String.self, forKey: .brand)
        self.servingLabel = try container.decode(String.self, forKey: .servingLabel)
        self.quantity = try container.decodeIfPresent(Double.self, forKey: .quantity) ?? 1.0
        self.gramWeight = try container.decodeIfPresent(Double.self, forKey: .gramWeight)
        self.portionMultiplier = try container.decodeIfPresent(Double.self, forKey: .portionMultiplier) ?? 1.0
        self.confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        self.nutrition = try container.decode(NutritionSnapshot.self, forKey: .nutrition)
        self.ingredients = try container.decodeIfPresent([IngredientEstimate].self, forKey: .ingredients) ?? []
    }

    /// Effective nutrition computed as `nutrition.scaled(by: portionMultiplier)` plus
    /// the nutrition of all optional ingredients (`isOptionalEstimate == true`) currently
    /// toggled on (`isIncluded == true`).
    ///
    /// Non-optional ingredients (`isOptionalEstimate == false`) are informational breakdowns
    /// already reflected in the base `nutrition` snapshot and are not double-counted.
    public var effectiveNutrition: NutritionSnapshot {
        let scaledBase = nutrition.scaled(by: portionMultiplier)
        return ingredients
            .filter { $0.isOptionalEstimate && $0.isIncluded }
            .reduce(scaledBase) { partial, ingredient in
                partial.adding(ingredient.nutrition)
            }
    }
}

// MARK: - Meal

/// Primary food diary entry representing a logged meal.
public struct Meal: Codable, Sendable, Equatable, Hashable, Identifiable {
    public var id: UUID
    /// Calendar date in `YYYY-MM-DD` format relative to `timezoneId`.
    public var localDate: String
    public var eatenAt: Date
    public var timezoneId: String
    public var mealType: MealType
    public var title: String
    public var notes: String?
    public var captureMethod: CaptureMethod
    public var aiStatus: AIStatus
    public var healthKitCorrelationId: String?
    public var dedupeFingerprint: String?
    public var syncSeq: Int64?
    public var items: [MealEntryItem]
    public var photoIds: [UUID]
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        localDate: String,
        eatenAt: Date,
        timezoneId: String = "UTC",
        mealType: MealType,
        title: String,
        notes: String? = nil,
        captureMethod: CaptureMethod,
        aiStatus: AIStatus = .none,
        healthKitCorrelationId: String? = nil,
        dedupeFingerprint: String? = nil,
        syncSeq: Int64? = nil,
        items: [MealEntryItem] = [],
        photoIds: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.localDate = localDate
        self.eatenAt = eatenAt
        self.timezoneId = timezoneId
        self.mealType = mealType
        self.title = title
        self.notes = notes
        self.captureMethod = captureMethod
        self.aiStatus = aiStatus
        self.healthKitCorrelationId = healthKitCorrelationId
        self.dedupeFingerprint = dedupeFingerprint
        self.syncSeq = syncSeq
        self.items = items
        self.photoIds = photoIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case localDate = "local_date"
        case eatenAt = "eaten_at"
        case timezoneId = "timezone_id"
        case mealType = "meal_type"
        case title
        case notes
        case captureMethod = "capture_method"
        case aiStatus = "ai_status"
        case healthKitCorrelationId = "healthkit_correlation_id"
        case dedupeFingerprint = "dedupe_fingerprint"
        case syncSeq = "sync_seq"
        case items
        case photoIds = "photo_ids"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.localDate = try container.decode(String.self, forKey: .localDate)
        self.eatenAt = try container.decode(Date.self, forKey: .eatenAt)
        self.timezoneId = try container.decode(String.self, forKey: .timezoneId)
        self.mealType = try container.decode(MealType.self, forKey: .mealType)
        self.title = try container.decode(String.self, forKey: .title)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
        self.captureMethod = try container.decode(CaptureMethod.self, forKey: .captureMethod)
        self.aiStatus = try container.decodeIfPresent(AIStatus.self, forKey: .aiStatus) ?? .none
        self.healthKitCorrelationId = try container.decodeIfPresent(String.self, forKey: .healthKitCorrelationId)
        self.dedupeFingerprint = try container.decodeIfPresent(String.self, forKey: .dedupeFingerprint)
        self.syncSeq = try container.decodeIfPresent(Int64.self, forKey: .syncSeq)
        self.items = try container.decodeIfPresent([MealEntryItem].self, forKey: .items) ?? []
        self.photoIds = try container.decodeIfPresent([UUID].self, forKey: .photoIds) ?? []
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
    }

    /// Combined effective nutrition across all items in this meal.
    public var totalNutrition: NutritionSnapshot {
        NutritionSnapshot.sum(items.map(\.effectiveNutrition))
    }

    /// Convenience tombstone flag.
    public var isDeleted: Bool {
        deletedAt != nil
    }
}

// MARK: - Food Catalog Models

public struct ServingOption: Codable, Sendable, Equatable, Hashable, Identifiable {
    public var id: UUID
    public var label: String
    public var gramWeight: Double
    public var isDefault: Bool

    public init(
        id: UUID = UUID(),
        label: String,
        gramWeight: Double,
        isDefault: Bool = false
    ) {
        self.id = id
        self.label = label
        self.gramWeight = gramWeight
        self.isDefault = isDefault
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case label
        case gramWeight = "gram_weight"
        case isDefault = "is_default"
    }
}

/// Reusable cached USDA, Open Food Facts, Label OCR, or user-created food catalog entry.
public struct FoodItem: Codable, Sendable, Equatable, Hashable, Identifiable {
    public var id: UUID
    public var name: String
    public var brand: String?
    public var barcode: String?
    public var source: FoodSource
    public var externalId: String?
    public var nutritionPer100g: NutritionSnapshot
    public var servingOptions: [ServingOption]
    public var isFavorite: Bool
    public var lastUsedAt: Date?
    public var syncSeq: Int64?
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        barcode: String? = nil,
        source: FoodSource,
        externalId: String? = nil,
        nutritionPer100g: NutritionSnapshot,
        servingOptions: [ServingOption] = [],
        isFavorite: Bool = false,
        lastUsedAt: Date? = nil,
        syncSeq: Int64? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.source = source
        self.externalId = externalId
        self.nutritionPer100g = nutritionPer100g
        self.servingOptions = servingOptions
        self.isFavorite = isFavorite
        self.lastUsedAt = lastUsedAt
        self.syncSeq = syncSeq
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case barcode
        case source
        case externalId = "external_id"
        case nutritionPer100g = "nutrition_per_100g"
        case servingOptions = "serving_options"
        case isFavorite = "is_favorite"
        case lastUsedAt = "last_used_at"
        case syncSeq = "sync_seq"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    /// Computes scaled nutrition for the given gram weight.
    public func nutrition(forGrams grams: Double) -> NutritionSnapshot {
        nutritionPer100g.scaled(by: grams / 100.0)
    }

    /// Computes scaled nutrition for `quantity` of a named serving option.
    public func nutrition(for serving: ServingOption, quantity: Double = 1.0) -> NutritionSnapshot {
        nutrition(forGrams: serving.gramWeight * quantity)
    }
}

// MARK: - PhotoAsset

/// Metadata record tracking a meal photo across local storage and Cloudflare R2 sync.
public struct PhotoAsset: Codable, Sendable, Equatable, Hashable, Identifiable {
    public var id: UUID
    public var mealId: UUID
    public var localFilename: String
    public var sha256Hash: String
    public var r2ObjectKey: String?
    public var mimeType: String
    public var byteSize: Int64?
    public var widthPx: Int?
    public var heightPx: Int?
    public var uploadState: PhotoUploadState
    public var syncSeq: Int64?
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        mealId: UUID,
        localFilename: String,
        sha256Hash: String,
        r2ObjectKey: String? = nil,
        mimeType: String = "image/heic",
        byteSize: Int64? = nil,
        widthPx: Int? = nil,
        heightPx: Int? = nil,
        uploadState: PhotoUploadState = .localOnly,
        syncSeq: Int64? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.mealId = mealId
        self.localFilename = localFilename
        self.sha256Hash = sha256Hash
        self.r2ObjectKey = r2ObjectKey
        self.mimeType = mimeType
        self.byteSize = byteSize
        self.widthPx = widthPx
        self.heightPx = heightPx
        self.uploadState = uploadState
        self.syncSeq = syncSeq
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case mealId = "meal_id"
        case localFilename = "local_filename"
        case sha256Hash = "sha256_hash"
        case r2ObjectKey = "r2_object_key"
        case mimeType = "mime_type"
        case byteSize = "byte_size"
        case widthPx = "width_px"
        case heightPx = "height_px"
        case uploadState = "upload_state"
        case syncSeq = "sync_seq"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

// MARK: - Internal Locale-Independent Numeric Formatting

internal enum CanonicalNumberFormatter: Sendable {
    static func fixed1(_ value: Double) -> String {
        formatFixed(value, scale: 10, decimals: 1)
    }

    static func fixed2(_ value: Double) -> String {
        formatFixed(value, scale: 100, decimals: 2)
    }

    static func compact(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        let roundedTenths = Int64((value * 10.0).rounded())
        let isNegative = roundedTenths < 0
        let magnitude = roundedTenths == Int64.min ? UInt64(Int64.max) + 1 : UInt64(abs(roundedTenths))
        let whole = magnitude / 10
        let frac = magnitude % 10
        let sign = (isNegative && magnitude > 0) ? "-" : ""
        if frac == 0 {
            return "\(sign)\(whole)"
        }
        return "\(sign)\(whole).\(frac)"
    }

    static func integerRounded(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        let rounded = Int64(value.rounded())
        return String(rounded)
    }

    private static func formatFixed(_ value: Double, scale: Double, decimals: Int) -> String {
        guard value.isFinite else {
            return decimals == 1 ? "0.0" : "0.00"
        }
        let scaled = Int64((value * scale).rounded())
        let isNegative = scaled < 0
        let magnitude = scaled == Int64.min ? UInt64(Int64.max) + 1 : UInt64(abs(scaled))
        let divisor = UInt64(scale)
        let whole = magnitude / divisor
        let frac = magnitude % divisor
        let sign = (isNegative && magnitude > 0) ? "-" : ""
        let fracStr = String(frac)
        let paddedFrac = fracStr.count < decimals
            ? String(repeating: "0", count: decimals - fracStr.count) + fracStr
            : fracStr
        return "\(sign)\(whole).\(paddedFrac)"
    }
}
