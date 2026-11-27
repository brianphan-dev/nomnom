import Foundation

// MARK: - Auth DTOs

public struct AppleAuthRequest: Codable, Sendable, Equatable {
    public var identityToken: String
    public var authorizationCode: String
    public var rawNonce: String
    public var givenName: String?
    public var familyName: String?
    public var deviceId: String
    public var deviceName: String?

    public init(
        identityToken: String,
        authorizationCode: String,
        rawNonce: String,
        givenName: String? = nil,
        familyName: String? = nil,
        deviceId: String,
        deviceName: String? = nil
    ) {
        self.identityToken = identityToken
        self.authorizationCode = authorizationCode
        self.rawNonce = rawNonce
        self.givenName = givenName
        self.familyName = familyName
        self.deviceId = deviceId
        self.deviceName = deviceName
    }

    private enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
        case authorizationCode = "authorization_code"
        case rawNonce = "raw_nonce"
        case givenName = "given_name"
        case familyName = "family_name"
        case deviceId = "device_id"
        case deviceName = "device_name"
    }
}

public struct GoogleAuthRequest: Codable, Sendable, Equatable {
    public var idToken: String
    public var authorizationCode: String?
    public var rawNonce: String?
    public var deviceId: String
    public var deviceName: String?

    public init(
        idToken: String,
        authorizationCode: String? = nil,
        rawNonce: String? = nil,
        deviceId: String,
        deviceName: String? = nil
    ) {
        self.idToken = idToken
        self.authorizationCode = authorizationCode
        self.rawNonce = rawNonce
        self.deviceId = deviceId
        self.deviceName = deviceName
    }

    private enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
        case authorizationCode = "authorization_code"
        case rawNonce = "raw_nonce"
        case deviceId = "device_id"
        case deviceName = "device_name"
    }
}

public struct RefreshTokenRequest: Codable, Sendable, Equatable {
    public var refreshToken: String
    public var deviceId: String

    public init(refreshToken: String, deviceId: String) {
        self.refreshToken = refreshToken
        self.deviceId = deviceId
    }

    private enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
        case deviceId = "device_id"
    }
}

public struct UserProfileDTO: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var displayName: String?
    public var email: String?
    public var isPrivateEmail: Bool
    public var linkedProviders: [AuthProvider]
    public var dailyCalorieTarget: Int?
    public var dailyProteinTargetG: Int?
    public var dailyCarbsTargetG: Int?
    public var dailyFatTargetG: Int?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID,
        displayName: String? = nil,
        email: String? = nil,
        isPrivateEmail: Bool = false,
        linkedProviders: [AuthProvider] = [.apple],
        dailyCalorieTarget: Int? = nil,
        dailyProteinTargetG: Int? = nil,
        dailyCarbsTargetG: Int? = nil,
        dailyFatTargetG: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.isPrivateEmail = isPrivateEmail
        self.linkedProviders = linkedProviders
        self.dailyCalorieTarget = dailyCalorieTarget
        self.dailyProteinTargetG = dailyProteinTargetG
        self.dailyCarbsTargetG = dailyCarbsTargetG
        self.dailyFatTargetG = dailyFatTargetG
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case email
        case isPrivateEmail = "is_private_email"
        case linkedProviders = "linked_providers"
        case dailyCalorieTarget = "daily_calorie_target"
        case dailyProteinTargetG = "daily_protein_target_g"
        case dailyCarbsTargetG = "daily_carbs_target_g"
        case dailyFatTargetG = "daily_fat_target_g"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct AuthTokenResponse: Codable, Sendable, Equatable {
    public var accessToken: String
    public var refreshToken: String
    public var tokenType: String
    public var expiresInSeconds: Int
    public var user: UserProfileDTO

    public init(
        accessToken: String,
        refreshToken: String,
        tokenType: String = "Bearer",
        expiresInSeconds: Int,
        user: UserProfileDTO
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresInSeconds = expiresInSeconds
        self.user = user
    }

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresInSeconds = "expires_in_seconds"
        case user
    }
}

public struct APIErrorEnvelope: Codable, Sendable, Equatable, Error {
    public var code: String
    public var message: String
    public var requestId: String?
    public var details: [String: String]?

    public init(
        code: String,
        message: String,
        requestId: String? = nil,
        details: [String: String]? = nil
    ) {
        self.code = code
        self.message = message
        self.requestId = requestId
        self.details = details
    }

    private enum CodingKeys: String, CodingKey {
        case code
        case message
        case requestId = "request_id"
        case details
    }
}

// MARK: - Sync DTOs

public enum SyncMutationOp: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case upsert
    case delete
}

public enum SyncEntityType: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case meal = "meal"
    case foodItem = "food_item"
    case photoAsset = "photo_asset"
}

public enum SyncAckStatus: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case applied
    case duplicate
    case conflict
    case rejected
}

public enum SyncPayload: Codable, Sendable, Equatable, Hashable {
    case meal(Meal)
    case foodItem(FoodItem)
    case photoAsset(PhotoAsset)

    public var entityType: SyncEntityType {
        switch self {
        case .meal: .meal
        case .foodItem: .foodItem
        case .photoAsset: .photoAsset
        }
    }

    public var entityId: UUID {
        switch self {
        case let .meal(meal): meal.id
        case let .foodItem(item): item.id
        case let .photoAsset(asset): asset.id
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(SyncEntityType.self, forKey: .type)
        switch type {
        case .meal:
            self = .meal(try container.decode(Meal.self, forKey: .data))
        case .foodItem:
            self = .foodItem(try container.decode(FoodItem.self, forKey: .data))
        case .photoAsset:
            self = .photoAsset(try container.decode(PhotoAsset.self, forKey: .data))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entityType, forKey: .type)
        switch self {
        case let .meal(meal):
            try container.encode(meal, forKey: .data)
        case let .foodItem(item):
            try container.encode(item, forKey: .data)
        case let .photoAsset(asset):
            try container.encode(asset, forKey: .data)
        }
    }
}

public struct SyncMutation: Codable, Sendable, Equatable, Hashable {
    public var mutationId: UUID
    public var entityType: SyncEntityType
    public var entityId: UUID
    public var op: SyncMutationOp
    public var clientUpdatedAt: Date
    public var payload: SyncPayload?

    public init(
        mutationId: UUID = UUID(),
        entityType: SyncEntityType,
        entityId: UUID,
        op: SyncMutationOp,
        clientUpdatedAt: Date = Date(),
        payload: SyncPayload? = nil
    ) {
        self.mutationId = mutationId
        self.entityType = entityType
        self.entityId = entityId
        self.op = op
        self.clientUpdatedAt = clientUpdatedAt
        self.payload = payload
    }

    public static func upsert(
        _ meal: Meal,
        mutationId: UUID = UUID(),
        clientUpdatedAt: Date? = nil
    ) -> SyncMutation {
        SyncMutation(
            mutationId: mutationId,
            entityType: .meal,
            entityId: meal.id,
            op: .upsert,
            clientUpdatedAt: clientUpdatedAt ?? meal.updatedAt,
            payload: .meal(meal)
        )
    }

    public static func upsert(
        _ foodItem: FoodItem,
        mutationId: UUID = UUID(),
        clientUpdatedAt: Date? = nil
    ) -> SyncMutation {
        SyncMutation(
            mutationId: mutationId,
            entityType: .foodItem,
            entityId: foodItem.id,
            op: .upsert,
            clientUpdatedAt: clientUpdatedAt ?? foodItem.updatedAt,
            payload: .foodItem(foodItem)
        )
    }

    public static func upsert(
        _ photoAsset: PhotoAsset,
        mutationId: UUID = UUID(),
        clientUpdatedAt: Date? = nil
    ) -> SyncMutation {
        SyncMutation(
            mutationId: mutationId,
            entityType: .photoAsset,
            entityId: photoAsset.id,
            op: .upsert,
            clientUpdatedAt: clientUpdatedAt ?? photoAsset.updatedAt,
            payload: .photoAsset(photoAsset)
        )
    }

    public static func delete(
        entityType: SyncEntityType,
        entityId: UUID,
        mutationId: UUID = UUID(),
        clientUpdatedAt: Date = Date()
    ) -> SyncMutation {
        SyncMutation(
            mutationId: mutationId,
            entityType: entityType,
            entityId: entityId,
            op: .delete,
            clientUpdatedAt: clientUpdatedAt,
            payload: nil
        )
    }

    private enum CodingKeys: String, CodingKey {
        case mutationId = "mutation_id"
        case entityType = "entity_type"
        case entityId = "entity_id"
        case op
        case clientUpdatedAt = "client_updated_at"
        case payload
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.mutationId = try container.decode(UUID.self, forKey: .mutationId)
        self.entityType = try container.decode(SyncEntityType.self, forKey: .entityType)
        self.entityId = try container.decode(UUID.self, forKey: .entityId)
        self.op = try container.decode(SyncMutationOp.self, forKey: .op)
        self.clientUpdatedAt = try container.decode(Date.self, forKey: .clientUpdatedAt)

        if container.contains(.payload), (try? container.decodeNil(forKey: .payload)) == false {
            switch entityType {
            case .meal:
                self.payload = .meal(try container.decode(Meal.self, forKey: .payload))
            case .foodItem:
                self.payload = .foodItem(try container.decode(FoodItem.self, forKey: .payload))
            case .photoAsset:
                self.payload = .photoAsset(try container.decode(PhotoAsset.self, forKey: .payload))
            }
        } else {
            self.payload = nil
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mutationId, forKey: .mutationId)
        try container.encode(entityType, forKey: .entityType)
        try container.encode(entityId, forKey: .entityId)
        try container.encode(op, forKey: .op)
        try container.encode(clientUpdatedAt, forKey: .clientUpdatedAt)

        if let payload {
            switch payload {
            case let .meal(meal):
                try container.encode(meal, forKey: .payload)
            case let .foodItem(item):
                try container.encode(item, forKey: .payload)
            case let .photoAsset(asset):
                try container.encode(asset, forKey: .payload)
            }
        }
    }
}

public struct SyncPushRequest: Codable, Sendable, Equatable {
    public var deviceId: String
    public var mutations: [SyncMutation]

    public init(deviceId: String, mutations: [SyncMutation]) {
        self.deviceId = deviceId
        self.mutations = mutations
    }

    private enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case mutations
    }
}

public struct SyncMutationAck: Codable, Sendable, Equatable {
    public var mutationId: UUID
    public var entityType: SyncEntityType
    public var entityId: UUID
    public var status: SyncAckStatus
    public var syncSeq: Int64?
    public var errorMessage: String?

    public init(
        mutationId: UUID,
        entityType: SyncEntityType,
        entityId: UUID,
        status: SyncAckStatus,
        syncSeq: Int64? = nil,
        errorMessage: String? = nil
    ) {
        self.mutationId = mutationId
        self.entityType = entityType
        self.entityId = entityId
        self.status = status
        self.syncSeq = syncSeq
        self.errorMessage = errorMessage
    }

    private enum CodingKeys: String, CodingKey {
        case mutationId = "mutation_id"
        case entityType = "entity_type"
        case entityId = "entity_id"
        case status
        case syncSeq = "sync_seq"
        case errorMessage = "error_message"
    }
}

public struct SyncPushResponse: Codable, Sendable, Equatable {
    public var acceptedCount: Int
    public var latestSyncSeq: Int64
    public var results: [SyncMutationAck]
    public var serverTime: Date

    public init(
        acceptedCount: Int,
        latestSyncSeq: Int64,
        results: [SyncMutationAck],
        serverTime: Date = Date()
    ) {
        self.acceptedCount = acceptedCount
        self.latestSyncSeq = latestSyncSeq
        self.results = results
        self.serverTime = serverTime
    }

    private enum CodingKeys: String, CodingKey {
        case acceptedCount = "accepted_count"
        case latestSyncSeq = "latest_sync_seq"
        case results
        case serverTime = "server_time"
    }
}

public struct SyncChangesResponse: Codable, Sendable, Equatable {
    public var sinceSeq: Int64
    public var nextSeq: Int64
    public var hasMore: Bool
    public var meals: [Meal]
    public var foodItems: [FoodItem]
    public var photoAssets: [PhotoAsset]
    public var serverTime: Date

    public init(
        sinceSeq: Int64,
        nextSeq: Int64,
        hasMore: Bool,
        meals: [Meal] = [],
        foodItems: [FoodItem] = [],
        photoAssets: [PhotoAsset] = [],
        serverTime: Date = Date()
    ) {
        self.sinceSeq = sinceSeq
        self.nextSeq = nextSeq
        self.hasMore = hasMore
        self.meals = meals
        self.foodItems = foodItems
        self.photoAssets = photoAssets
        self.serverTime = serverTime
    }

    private enum CodingKeys: String, CodingKey {
        case sinceSeq = "since_seq"
        case nextSeq = "next_seq"
        case hasMore = "has_more"
        case meals
        case foodItems = "food_items"
        case photoAssets = "photo_assets"
        case serverTime = "server_time"
    }
}

// MARK: - AI Analysis DTOs

public struct AnalyzeMealPhotoRequest: Codable, Sendable, Equatable {
    public var photoId: UUID?
    public var r2ObjectKey: String?
    public var imageBase64: String?
    public var mimeType: String
    public var contextHint: String?
    public var mealTypeHint: MealType?
    public var locale: String?

    public init(
        photoId: UUID? = nil,
        r2ObjectKey: String? = nil,
        imageBase64: String? = nil,
        mimeType: String = "image/jpeg",
        contextHint: String? = nil,
        mealTypeHint: MealType? = nil,
        locale: String? = nil
    ) {
        self.photoId = photoId
        self.r2ObjectKey = r2ObjectKey
        self.imageBase64 = imageBase64
        self.mimeType = mimeType
        self.contextHint = contextHint
        self.mealTypeHint = mealTypeHint
        self.locale = locale
    }

    private enum CodingKeys: String, CodingKey {
        case photoId = "photo_id"
        case r2ObjectKey = "r2_object_key"
        case imageBase64 = "image_base64"
        case mimeType = "mime_type"
        case contextHint = "context_hint"
        case mealTypeHint = "meal_type_hint"
        case locale
    }
}

public struct EstimateMealTextRequest: Codable, Sendable, Equatable {
    public var text: String
    public var mealTypeHint: MealType?
    public var existingMealId: UUID?
    public var locale: String?

    public init(
        text: String,
        mealTypeHint: MealType? = nil,
        existingMealId: UUID? = nil,
        locale: String? = nil
    ) {
        self.text = text
        self.mealTypeHint = mealTypeHint
        self.existingMealId = existingMealId
        self.locale = locale
    }

    private enum CodingKeys: String, CodingKey {
        case text
        case mealTypeHint = "meal_type_hint"
        case existingMealId = "existing_meal_id"
        case locale
    }
}

public struct DetectedMealItemDTO: Codable, Sendable, Equatable {
    public var displayName: String
    public var servingLabel: String
    public var quantity: Double
    public var gramWeight: Double?
    public var confidence: Double
    public var nutrition: NutritionSnapshot
    public var ingredients: [IngredientEstimate]
    public var validationWarnings: [String]

    public init(
        displayName: String,
        servingLabel: String,
        quantity: Double = 1.0,
        gramWeight: Double? = nil,
        confidence: Double,
        nutrition: NutritionSnapshot,
        ingredients: [IngredientEstimate] = [],
        validationWarnings: [String] = []
    ) {
        self.displayName = displayName
        self.servingLabel = servingLabel
        self.quantity = quantity
        self.gramWeight = gramWeight
        self.confidence = confidence
        self.nutrition = nutrition
        self.ingredients = ingredients
        self.validationWarnings = validationWarnings
    }

    private enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case servingLabel = "serving_label"
        case quantity
        case gramWeight = "gram_weight"
        case confidence
        case nutrition
        case ingredients
        case validationWarnings = "validation_warnings"
    }

    /// Converts an AI detection result into a persistable `MealEntryItem`.
    public func toMealEntryItem(id: UUID = UUID(), mealId: UUID? = nil) -> MealEntryItem {
        MealEntryItem(
            id: id,
            mealId: mealId,
            displayName: displayName,
            servingLabel: servingLabel,
            quantity: quantity,
            gramWeight: gramWeight,
            portionMultiplier: 1.0,
            confidence: confidence,
            nutrition: nutrition,
            ingredients: ingredients
        )
    }
}

public struct AIQuotaStatusDTO: Codable, Sendable, Equatable {
    public var dailyLimit: Int
    public var usedToday: Int
    public var remainingToday: Int
    public var resetsAt: Date

    public init(
        dailyLimit: Int,
        usedToday: Int,
        remainingToday: Int,
        resetsAt: Date
    ) {
        self.dailyLimit = dailyLimit
        self.usedToday = usedToday
        self.remainingToday = remainingToday
        self.resetsAt = resetsAt
    }

    public var isExceeded: Bool {
        remainingToday <= 0
    }

    private enum CodingKeys: String, CodingKey {
        case dailyLimit = "daily_limit"
        case usedToday = "used_today"
        case remainingToday = "remaining_today"
        case resetsAt = "resets_at"
    }
}

public struct AnalyzeMealResponse: Codable, Sendable, Equatable {
    public var suggestedTitle: String
    public var suggestedMealType: MealType?
    public var items: [DetectedMealItemDTO]
    public var modelUsed: String?
    public var latencyMs: Int?
    public var warnings: [String]
    public var quota: AIQuotaStatusDTO?

    public init(
        suggestedTitle: String,
        suggestedMealType: MealType? = nil,
        items: [DetectedMealItemDTO],
        modelUsed: String? = nil,
        latencyMs: Int? = nil,
        warnings: [String] = [],
        quota: AIQuotaStatusDTO? = nil
    ) {
        self.suggestedTitle = suggestedTitle
        self.suggestedMealType = suggestedMealType
        self.items = items
        self.modelUsed = modelUsed
        self.latencyMs = latencyMs
        self.warnings = warnings
        self.quota = quota
    }

    private enum CodingKeys: String, CodingKey {
        case suggestedTitle = "suggested_title"
        case suggestedMealType = "suggested_meal_type"
        case items
        case modelUsed = "model_used"
        case latencyMs = "latency_ms"
        case warnings
        case quota
    }
}

// MARK: - Food & Barcode DTOs

public struct BarcodeLookupResponse: Codable, Sendable, Equatable {
    public var barcode: String
    public var found: Bool
    public var foodItem: FoodItem?
    public var source: FoodSource?
    public var cached: Bool

    public init(
        barcode: String,
        found: Bool,
        foodItem: FoodItem? = nil,
        source: FoodSource? = nil,
        cached: Bool = false
    ) {
        self.barcode = barcode
        self.found = found
        self.foodItem = foodItem
        self.source = source
        self.cached = cached
    }

    private enum CodingKeys: String, CodingKey {
        case barcode
        case found
        case foodItem = "food_item"
        case source
        case cached
    }
}

public struct FoodSearchResponse: Codable, Sendable, Equatable {
    public var query: String
    public var items: [FoodItem]
    public var totalCount: Int
    public var nextCursor: String?

    public init(
        query: String,
        items: [FoodItem],
        totalCount: Int,
        nextCursor: String? = nil
    ) {
        self.query = query
        self.items = items
        self.totalCount = totalCount
        self.nextCursor = nextCursor
    }

    private enum CodingKeys: String, CodingKey {
        case query
        case items
        case totalCount = "total_count"
        case nextCursor = "next_cursor"
    }
}

// MARK: - Photo Storage DTOs

public struct PresignUploadRequest: Codable, Sendable, Equatable {
    public var photoId: UUID
    public var mealId: UUID
    public var mimeType: String
    public var byteSize: Int64
    public var sha256Hash: String

    public init(
        photoId: UUID,
        mealId: UUID,
        mimeType: String = "image/heic",
        byteSize: Int64,
        sha256Hash: String
    ) {
        self.photoId = photoId
        self.mealId = mealId
        self.mimeType = mimeType
        self.byteSize = byteSize
        self.sha256Hash = sha256Hash
    }

    private enum CodingKeys: String, CodingKey {
        case photoId = "photo_id"
        case mealId = "meal_id"
        case mimeType = "mime_type"
        case byteSize = "byte_size"
        case sha256Hash = "sha256_hash"
    }
}

public struct PresignUploadResponse: Codable, Sendable, Equatable {
    public var photoId: UUID
    public var r2ObjectKey: String
    public var uploadUrl: String
    public var httpMethod: String
    public var requiredHeaders: [String: String]
    public var expiresAt: Date

    public init(
        photoId: UUID,
        r2ObjectKey: String,
        uploadUrl: String,
        httpMethod: String = "PUT",
        requiredHeaders: [String: String] = [:],
        expiresAt: Date
    ) {
        self.photoId = photoId
        self.r2ObjectKey = r2ObjectKey
        self.uploadUrl = uploadUrl
        self.httpMethod = httpMethod
        self.requiredHeaders = requiredHeaders
        self.expiresAt = expiresAt
    }

    private enum CodingKeys: String, CodingKey {
        case photoId = "photo_id"
        case r2ObjectKey = "r2_object_key"
        case uploadUrl = "upload_url"
        case httpMethod = "http_method"
        case requiredHeaders = "required_headers"
        case expiresAt = "expires_at"
    }
}

public struct PhotoDownloadURLResponse: Codable, Sendable, Equatable {
    public var photoId: UUID
    public var r2ObjectKey: String
    public var downloadUrl: String
    public var expiresAt: Date

    public init(
        photoId: UUID,
        r2ObjectKey: String,
        downloadUrl: String,
        expiresAt: Date
    ) {
        self.photoId = photoId
        self.r2ObjectKey = r2ObjectKey
        self.downloadUrl = downloadUrl
        self.expiresAt = expiresAt
    }

    private enum CodingKeys: String, CodingKey {
        case photoId = "photo_id"
        case r2ObjectKey = "r2_object_key"
        case downloadUrl = "download_url"
        case expiresAt = "expires_at"
    }
}
