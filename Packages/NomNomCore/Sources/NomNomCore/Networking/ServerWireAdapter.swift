import Foundation
import NomNomShared

/// Byte-for-byte JSON wire models and bidirectional adapters bridging `NomNomShared`
/// domain/API types to the deployed Hetzner VPS (`NomNomServerCore`) HTTP contract.
public enum ServerWireAdapter: Sendable {
    // MARK: - Error Envelope

    public struct ServerErrorBody: Codable, Sendable, Equatable {
        public struct Detail: Codable, Sendable, Equatable {
            public let code: String
            public let message: String
            public let phase: String?

            public init(code: String, message: String, phase: String? = nil) {
                self.code = code
                self.message = message
                self.phase = phase
            }
        }

        public let error: Detail

        public init(code: String, message: String, phase: String? = nil) {
            self.error = Detail(code: code, message: message, phase: phase)
        }
    }

    /// Decodes both nested VPS `{ "error": { "code", "message", "phase" } }`
    /// and flat `{ "code", "message" }` envelopes into `APIErrorEnvelope`.
    public static func decodeErrorEnvelope(
        from data: Data,
        decoder: JSONDecoder = NomNomJSON.makeDecoder()
    ) -> APIErrorEnvelope? {
        guard !data.isEmpty else { return nil }
        if let nested = try? decoder.decode(ServerErrorBody.self, from: data) {
            let details = nested.error.phase.map { ["phase": $0] }
            return APIErrorEnvelope(
                code: nested.error.code,
                message: nested.error.message,
                requestId: nil,
                details: details
            )
        }
        return try? decoder.decode(APIErrorEnvelope.self, from: data)
    }

    // MARK: - Auth Wire Models

    public struct ServerAppleAuthRequest: Codable, Sendable, Equatable {
        public let identityToken: String
        public let authorizationCode: String
        public let rawNonce: String?
        public let displayName: String?
        public let deviceID: String?

        enum CodingKeys: String, CodingKey {
            case identityToken = "identity_token"
            case authorizationCode = "authorization_code"
            case rawNonce = "raw_nonce"
            case displayName = "display_name"
            case deviceID = "device_id"
        }

        public init(
            identityToken: String,
            authorizationCode: String,
            rawNonce: String? = nil,
            displayName: String? = nil,
            deviceID: String? = nil
        ) {
            self.identityToken = identityToken
            self.authorizationCode = authorizationCode
            self.rawNonce = rawNonce
            self.displayName = displayName
            self.deviceID = deviceID
        }
    }

    public struct ServerRefreshTokenRequest: Codable, Sendable, Equatable {
        public let refreshToken: String
        public let deviceID: String?

        enum CodingKeys: String, CodingKey {
            case refreshToken = "refresh_token"
            case deviceID = "device_id"
        }

        public init(refreshToken: String, deviceID: String? = nil) {
            self.refreshToken = refreshToken
            self.deviceID = deviceID
        }
    }

    public struct ServerLogoutRequest: Codable, Sendable, Equatable {
        public let refreshToken: String?

        enum CodingKeys: String, CodingKey {
            case refreshToken = "refresh_token"
        }

        public init(refreshToken: String? = nil) {
            self.refreshToken = refreshToken
        }
    }

    public struct ServerLogoutResponse: Codable, Sendable, Equatable {
        public let loggedOut: Bool

        enum CodingKeys: String, CodingKey {
            case loggedOut = "logged_out"
        }

        public init(loggedOut: Bool = true) {
            self.loggedOut = loggedOut
        }
    }

    public struct ServerAuthUserDTO: Codable, Sendable, Equatable {
        public let id: UUID
        public let displayName: String?
        public let email: String?
        public let isPrivateEmail: Bool
        public let createdAt: Date

        enum CodingKeys: String, CodingKey {
            case id
            case displayName = "display_name"
            case email
            case isPrivateEmail = "is_private_email"
            case createdAt = "created_at"
        }

        public init(
            id: UUID,
            displayName: String?,
            email: String?,
            isPrivateEmail: Bool,
            createdAt: Date
        ) {
            self.id = id
            self.displayName = displayName
            self.email = email
            self.isPrivateEmail = isPrivateEmail
            self.createdAt = createdAt
        }
    }

    public struct ServerAuthSessionResponse: Codable, Sendable, Equatable {
        public let accessToken: String
        public let tokenType: String
        public let expiresIn: Int
        public let refreshToken: String
        public let refreshExpiresIn: Int?
        public let user: ServerAuthUserDTO

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
            case expiresIn = "expires_in"
            case refreshToken = "refresh_token"
            case refreshExpiresIn = "refresh_expires_in"
            case user
        }

        public init(
            accessToken: String,
            tokenType: String = "Bearer",
            expiresIn: Int,
            refreshToken: String,
            refreshExpiresIn: Int? = nil,
            user: ServerAuthUserDTO
        ) {
            self.accessToken = accessToken
            self.tokenType = tokenType
            self.expiresIn = expiresIn
            self.refreshToken = refreshToken
            self.refreshExpiresIn = refreshExpiresIn
            self.user = user
        }
    }

    public struct ServerAccountDeletionResponse: Codable, Sendable, Equatable {
        public let deleted: Bool
        public let appleTokenRevoked: Bool
        public let requiresManualAppleRevocation: Bool
        public let userID: UUID

        enum CodingKeys: String, CodingKey {
            case deleted
            case appleTokenRevoked = "apple_token_revoked"
            case requiresManualAppleRevocation = "requires_manual_apple_revocation"
            case userID = "user_id"
        }

        public init(
            deleted: Bool,
            appleTokenRevoked: Bool,
            requiresManualAppleRevocation: Bool,
            userID: UUID
        ) {
            self.deleted = deleted
            self.appleTokenRevoked = appleTokenRevoked
            self.requiresManualAppleRevocation = requiresManualAppleRevocation
            self.userID = userID
        }
    }

    // MARK: - Sync Wire Models

    public enum ServerCaptureMethod: String, Codable, Sendable, Equatable {
        case photo
        case barcode
        case text
        case manual
        case quickAdd = "quick_add"
    }

    public enum ServerAIStatus: String, Codable, Sendable, Equatable {
        case none
        case pending
        case completed
        case failed
        case edited
    }

    public struct ServerIngredientBreakdownDTO: Codable, Sendable, Equatable {
        public let name: String
        public let grams: Double?
        public let calories: Double?
        public let proteinG: Double?
        public let carbsG: Double?
        public let fatG: Double?

        enum CodingKeys: String, CodingKey {
            case name
            case grams
            case calories
            case proteinG = "protein_g"
            case carbsG = "carbs_g"
            case fatG = "fat_g"
        }

        public init(
            name: String,
            grams: Double? = nil,
            calories: Double? = nil,
            proteinG: Double? = nil,
            carbsG: Double? = nil,
            fatG: Double? = nil
        ) {
            self.name = name
            self.grams = grams
            self.calories = calories
            self.proteinG = proteinG
            self.carbsG = carbsG
            self.fatG = fatG
        }
    }

    public struct ServerMealEntryItemDTO: Codable, Sendable, Equatable {
        public let id: UUID
        public let foodItemID: UUID?
        public let name: String
        public let brand: String?
        public let servingLabel: String
        public let servingGrams: Double?
        public let quantity: Double
        public let calories: Double
        public let proteinG: Double
        public let carbsG: Double
        public let fatG: Double
        public let fiberG: Double?
        public let sugarG: Double?
        public let sodiumMg: Double?
        public let saturatedFatG: Double?
        public let potassiumMg: Double?
        public let cholesterolMg: Double?
        public let confidence: Double?
        public let ingredients: [ServerIngredientBreakdownDTO]
        public let sortOrder: Int

        enum CodingKeys: String, CodingKey {
            case id
            case foodItemID = "food_item_id"
            case name
            case brand
            case servingLabel = "serving_label"
            case servingGrams = "serving_grams"
            case quantity
            case calories
            case proteinG = "protein_g"
            case carbsG = "carbs_g"
            case fatG = "fat_g"
            case fiberG = "fiber_g"
            case sugarG = "sugar_g"
            case sodiumMg = "sodium_mg"
            case saturatedFatG = "saturated_fat_g"
            case potassiumMg = "potassium_mg"
            case cholesterolMg = "cholesterol_mg"
            case confidence
            case ingredients
            case sortOrder = "sort_order"
        }

        public init(
            id: UUID = UUID(),
            foodItemID: UUID? = nil,
            name: String,
            brand: String? = nil,
            servingLabel: String,
            servingGrams: Double? = nil,
            quantity: Double = 1.0,
            calories: Double,
            proteinG: Double,
            carbsG: Double,
            fatG: Double,
            fiberG: Double? = nil,
            sugarG: Double? = nil,
            sodiumMg: Double? = nil,
            saturatedFatG: Double? = nil,
            potassiumMg: Double? = nil,
            cholesterolMg: Double? = nil,
            confidence: Double? = nil,
            ingredients: [ServerIngredientBreakdownDTO] = [],
            sortOrder: Int = 0
        ) {
            self.id = id
            self.foodItemID = foodItemID
            self.name = name
            self.brand = brand
            self.servingLabel = servingLabel
            self.servingGrams = servingGrams
            self.quantity = quantity
            self.calories = calories
            self.proteinG = proteinG
            self.carbsG = carbsG
            self.fatG = fatG
            self.fiberG = fiberG
            self.sugarG = sugarG
            self.sodiumMg = sodiumMg
            self.saturatedFatG = saturatedFatG
            self.potassiumMg = potassiumMg
            self.cholesterolMg = cholesterolMg
            self.confidence = confidence
            self.ingredients = ingredients
            self.sortOrder = sortOrder
        }
    }

    public struct ServerMealRecordDTO: Codable, Sendable, Equatable {
        public let id: UUID
        public let localDate: String
        public let eatenAt: Date
        public let timezoneID: String
        public let mealType: MealType
        public let captureMethod: ServerCaptureMethod
        public let aiStatus: ServerAIStatus
        public let title: String?
        public let notes: String?
        public let photoAssetID: UUID?
        public let totalCalories: Double
        public let totalProteinG: Double
        public let totalCarbsG: Double
        public let totalFatG: Double
        public let totalFiberG: Double?
        public let totalSugarG: Double?
        public let totalSodiumMg: Double?
        public let items: [ServerMealEntryItemDTO]
        public let syncSeq: Int64
        public let clientUpdatedAt: Date
        public let createdAt: Date
        public let updatedAt: Date
        public let deletedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id
            case localDate = "local_date"
            case eatenAt = "eaten_at"
            case timezoneID = "timezone_id"
            case mealType = "meal_type"
            case captureMethod = "capture_method"
            case aiStatus = "ai_status"
            case title
            case notes
            case photoAssetID = "photo_asset_id"
            case totalCalories = "total_calories"
            case totalProteinG = "total_protein_g"
            case totalCarbsG = "total_carbs_g"
            case totalFatG = "total_fat_g"
            case totalFiberG = "total_fiber_g"
            case totalSugarG = "total_sugar_g"
            case totalSodiumMg = "total_sodium_mg"
            case items
            case syncSeq = "sync_seq"
            case clientUpdatedAt = "client_updated_at"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case deletedAt = "deleted_at"
        }

        public init(
            id: UUID = UUID(),
            localDate: String,
            eatenAt: Date,
            timezoneID: String,
            mealType: MealType,
            captureMethod: ServerCaptureMethod,
            aiStatus: ServerAIStatus = .none,
            title: String? = nil,
            notes: String? = nil,
            photoAssetID: UUID? = nil,
            totalCalories: Double,
            totalProteinG: Double,
            totalCarbsG: Double,
            totalFatG: Double,
            totalFiberG: Double? = nil,
            totalSugarG: Double? = nil,
            totalSodiumMg: Double? = nil,
            items: [ServerMealEntryItemDTO] = [],
            syncSeq: Int64 = 0,
            clientUpdatedAt: Date = Date(),
            createdAt: Date = Date(),
            updatedAt: Date = Date(),
            deletedAt: Date? = nil
        ) {
            self.id = id
            self.localDate = localDate
            self.eatenAt = eatenAt
            self.timezoneID = timezoneID
            self.mealType = mealType
            self.captureMethod = captureMethod
            self.aiStatus = aiStatus
            self.title = title
            self.notes = notes
            self.photoAssetID = photoAssetID
            self.totalCalories = totalCalories
            self.totalProteinG = totalProteinG
            self.totalCarbsG = totalCarbsG
            self.totalFatG = totalFatG
            self.totalFiberG = totalFiberG
            self.totalSugarG = totalSugarG
            self.totalSodiumMg = totalSodiumMg
            self.items = items
            self.syncSeq = syncSeq
            self.clientUpdatedAt = clientUpdatedAt
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.deletedAt = deletedAt
        }
    }

    public struct ServerSyncMutationDTO: Codable, Sendable, Equatable {
        public let op: SyncMutationOp
        public let mealID: UUID
        public let meal: ServerMealRecordDTO?
        public let deletedAt: Date?

        enum CodingKeys: String, CodingKey {
            case op
            case mealID = "meal_id"
            case meal
            case deletedAt = "deleted_at"
        }

        public init(
            op: SyncMutationOp,
            mealID: UUID,
            meal: ServerMealRecordDTO? = nil,
            deletedAt: Date? = nil
        ) {
            self.op = op
            self.mealID = mealID
            self.meal = meal
            self.deletedAt = deletedAt
        }
    }

    public struct ServerSyncPushRequest: Codable, Sendable, Equatable {
        public let idempotencyKey: String
        public let mutations: [ServerSyncMutationDTO]

        enum CodingKeys: String, CodingKey {
            case idempotencyKey = "idempotency_key"
            case mutations
        }

        public init(idempotencyKey: String, mutations: [ServerSyncMutationDTO]) {
            self.idempotencyKey = idempotencyKey
            self.mutations = mutations
        }
    }

    public struct ServerSyncPushResponse: Codable, Sendable, Equatable {
        public let idempotencyKey: String
        public let appliedCount: Int
        public let latestSyncSeq: Int64
        public let meals: [ServerMealRecordDTO]

        enum CodingKeys: String, CodingKey {
            case idempotencyKey = "idempotency_key"
            case appliedCount = "applied_count"
            case latestSyncSeq = "latest_sync_seq"
            case meals
        }

        public init(
            idempotencyKey: String,
            appliedCount: Int,
            latestSyncSeq: Int64,
            meals: [ServerMealRecordDTO]
        ) {
            self.idempotencyKey = idempotencyKey
            self.appliedCount = appliedCount
            self.latestSyncSeq = latestSyncSeq
            self.meals = meals
        }
    }

    public struct ServerSyncChangesResponse: Codable, Sendable, Equatable {
        public let changes: [ServerMealRecordDTO]
        public let nextSeq: Int64
        public let hasMore: Bool

        enum CodingKeys: String, CodingKey {
            case changes
            case nextSeq = "next_seq"
            case hasMore = "has_more"
        }

        public init(changes: [ServerMealRecordDTO], nextSeq: Int64, hasMore: Bool) {
            self.changes = changes
            self.nextSeq = nextSeq
            self.hasMore = hasMore
        }
    }

    // MARK: - Photos Wire Models

    public struct ServerPhotoPresignUploadRequest: Codable, Sendable, Equatable {
        public let sha256Hash: String
        public let contentType: String?
        public let byteSize: Int64?

        enum CodingKeys: String, CodingKey {
            case sha256Hash = "sha256_hash"
            case contentType = "content_type"
            case byteSize = "byte_size"
        }

        public init(sha256Hash: String, contentType: String? = "image/heic", byteSize: Int64? = nil) {
            self.sha256Hash = sha256Hash
            self.contentType = contentType
            self.byteSize = byteSize
        }
    }

    public struct ServerPhotoPresignUploadResponse: Codable, Sendable, Equatable {
        public let photoID: UUID
        public let objectKey: String
        public let uploadURL: String
        public let method: String
        public let headers: [String: String]
        public let expiresIn: Int

        enum CodingKeys: String, CodingKey {
            case photoID = "photo_id"
            case objectKey = "object_key"
            case uploadURL = "upload_url"
            case method
            case headers
            case expiresIn = "expires_in"
        }

        public init(
            photoID: UUID,
            objectKey: String,
            uploadURL: String,
            method: String = "PUT",
            headers: [String: String] = [:],
            expiresIn: Int
        ) {
            self.photoID = photoID
            self.objectKey = objectKey
            self.uploadURL = uploadURL
            self.method = method
            self.headers = headers
            self.expiresIn = expiresIn
        }
    }

    public struct ServerPhotoDownloadURLResponse: Codable, Sendable, Equatable {
        public let photoID: UUID
        public let objectKey: String
        public let downloadURL: String
        public let expiresIn: Int

        enum CodingKeys: String, CodingKey {
            case photoID = "photo_id"
            case objectKey = "object_key"
            case downloadURL = "download_url"
            case expiresIn = "expires_in"
        }

        public init(photoID: UUID, objectKey: String, downloadURL: String, expiresIn: Int) {
            self.photoID = photoID
            self.objectKey = objectKey
            self.downloadURL = downloadURL
            self.expiresIn = expiresIn
        }
    }

    // MARK: - AI Wire Models

    public struct ServerAnalyzeMealPhotoRequest: Codable, Sendable, Equatable {
        public let photoID: UUID?
        public let imageBase64: String?
        public let contentType: String?
        public let userHint: String?
        public let localDate: String?

        enum CodingKeys: String, CodingKey {
            case photoID = "photo_id"
            case imageBase64 = "image_base64"
            case contentType = "content_type"
            case userHint = "user_hint"
            case localDate = "local_date"
        }

        public init(
            photoID: UUID? = nil,
            imageBase64: String? = nil,
            contentType: String? = "image/jpeg",
            userHint: String? = nil,
            localDate: String? = nil
        ) {
            self.photoID = photoID
            self.imageBase64 = imageBase64
            self.contentType = contentType
            self.userHint = userHint
            self.localDate = localDate
        }
    }

    public struct ServerEstimateMealTextRequest: Codable, Sendable, Equatable {
        public let description: String
        public let mealType: MealType?
        public let localDate: String?

        enum CodingKeys: String, CodingKey {
            case description
            case mealType = "meal_type"
            case localDate = "local_date"
        }

        public init(description: String, mealType: MealType? = nil, localDate: String? = nil) {
            self.description = description
            self.mealType = mealType
            self.localDate = localDate
        }
    }

    public struct ServerAtwaterWarningDTO: Codable, Sendable, Equatable {
        public let itemName: String?
        public let code: String
        public let message: String
        public let reportedCalories: Double?
        public let expectedCalories: Double?
        public let deviationPercent: Double?

        enum CodingKeys: String, CodingKey {
            case itemName = "item_name"
            case code
            case message
            case reportedCalories = "reported_calories"
            case expectedCalories = "expected_calories"
            case deviationPercent = "deviation_percent"
        }

        public init(
            itemName: String? = nil,
            code: String,
            message: String,
            reportedCalories: Double? = nil,
            expectedCalories: Double? = nil,
            deviationPercent: Double? = nil
        ) {
            self.itemName = itemName
            self.code = code
            self.message = message
            self.reportedCalories = reportedCalories
            self.expectedCalories = expectedCalories
            self.deviationPercent = deviationPercent
        }
    }

    public struct ServerAIEstimatedItemDTO: Codable, Sendable, Equatable {
        public let name: String
        public let servingLabel: String
        public let servingGrams: Double?
        public let calories: Double
        public let proteinG: Double
        public let carbsG: Double
        public let fatG: Double
        public let fiberG: Double?
        public let sugarG: Double?
        public let sodiumMg: Double?
        public let confidence: Double
        public let ingredients: [ServerIngredientBreakdownDTO]
        public let atwaterWarnings: [ServerAtwaterWarningDTO]

        enum CodingKeys: String, CodingKey {
            case name
            case servingLabel = "serving_label"
            case servingGrams = "serving_grams"
            case calories
            case proteinG = "protein_g"
            case carbsG = "carbs_g"
            case fatG = "fat_g"
            case fiberG = "fiber_g"
            case sugarG = "sugar_g"
            case sodiumMg = "sodium_mg"
            case confidence
            case ingredients
            case atwaterWarnings = "atwater_warnings"
        }

        public init(
            name: String,
            servingLabel: String,
            servingGrams: Double? = nil,
            calories: Double,
            proteinG: Double,
            carbsG: Double,
            fatG: Double,
            fiberG: Double? = nil,
            sugarG: Double? = nil,
            sodiumMg: Double? = nil,
            confidence: Double = 0.85,
            ingredients: [ServerIngredientBreakdownDTO] = [],
            atwaterWarnings: [ServerAtwaterWarningDTO] = []
        ) {
            self.name = name
            self.servingLabel = servingLabel
            self.servingGrams = servingGrams
            self.calories = calories
            self.proteinG = proteinG
            self.carbsG = carbsG
            self.fatG = fatG
            self.fiberG = fiberG
            self.sugarG = sugarG
            self.sodiumMg = sodiumMg
            self.confidence = confidence
            self.ingredients = ingredients
            self.atwaterWarnings = atwaterWarnings
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try c.decode(String.self, forKey: .name)
            self.servingLabel = try c.decode(String.self, forKey: .servingLabel)
            self.servingGrams = try c.decodeIfPresent(Double.self, forKey: .servingGrams)
            self.calories = try c.decode(Double.self, forKey: .calories)
            self.proteinG = try c.decode(Double.self, forKey: .proteinG)
            self.carbsG = try c.decode(Double.self, forKey: .carbsG)
            self.fatG = try c.decode(Double.self, forKey: .fatG)
            self.fiberG = try c.decodeIfPresent(Double.self, forKey: .fiberG)
            self.sugarG = try c.decodeIfPresent(Double.self, forKey: .sugarG)
            self.sodiumMg = try c.decodeIfPresent(Double.self, forKey: .sodiumMg)
            self.confidence = try c.decodeIfPresent(Double.self, forKey: .confidence) ?? 0.85
            self.ingredients = try c.decodeIfPresent([ServerIngredientBreakdownDTO].self, forKey: .ingredients) ?? []
            self.atwaterWarnings = try c.decodeIfPresent([ServerAtwaterWarningDTO].self, forKey: .atwaterWarnings) ?? []
        }
    }

    public struct ServerAIMealAnalysisResponse: Codable, Sendable, Equatable {
        public let provider: String
        public let model: String
        public let mealTitle: String
        public let items: [ServerAIEstimatedItemDTO]
        public let totalCalories: Double
        public let totalProteinG: Double
        public let totalCarbsG: Double
        public let totalFatG: Double
        public let warnings: [ServerAtwaterWarningDTO]
        public let quotaRemaining: Int
        public let quotaLimit: Int

        enum CodingKeys: String, CodingKey {
            case provider
            case model
            case mealTitle = "meal_title"
            case items
            case totalCalories = "total_calories"
            case totalProteinG = "total_protein_g"
            case totalCarbsG = "total_carbs_g"
            case totalFatG = "total_fat_g"
            case warnings
            case quotaRemaining = "quota_remaining"
            case quotaLimit = "quota_limit"
        }

        public init(
            provider: String,
            model: String,
            mealTitle: String,
            items: [ServerAIEstimatedItemDTO],
            totalCalories: Double,
            totalProteinG: Double,
            totalCarbsG: Double,
            totalFatG: Double,
            warnings: [ServerAtwaterWarningDTO] = [],
            quotaRemaining: Int,
            quotaLimit: Int
        ) {
            self.provider = provider
            self.model = model
            self.mealTitle = mealTitle
            self.items = items
            self.totalCalories = totalCalories
            self.totalProteinG = totalProteinG
            self.totalCarbsG = totalCarbsG
            self.totalFatG = totalFatG
            self.warnings = warnings
            self.quotaRemaining = quotaRemaining
            self.quotaLimit = quotaLimit
        }
    }

    // MARK: - Food Catalog Wire Models

    public struct ServerServingOptionDTO: Codable, Sendable, Equatable {
        public let id: UUID
        public let label: String
        public let grams: Double
        public let isDefault: Bool

        enum CodingKeys: String, CodingKey {
            case id
            case label
            case grams
            case isDefault = "is_default"
        }

        public init(id: UUID = UUID(), label: String, grams: Double, isDefault: Bool = false) {
            self.id = id
            self.label = label
            self.grams = grams
            self.isDefault = isDefault
        }
    }

    public struct ServerFoodItemDTO: Codable, Sendable, Equatable {
        public let id: UUID
        public let barcodeGTIN: String?
        public let name: String
        public let brand: String?
        public let source: String
        public let externalID: String?
        public let servingSizeG: Double?
        public let servingDescription: String?
        public let caloriesPer100g: Double
        public let proteinGPer100g: Double
        public let carbsGPer100g: Double
        public let fatGPer100g: Double
        public let fiberGPer100g: Double?
        public let sugarGPer100g: Double?
        public let sodiumMgPer100g: Double?
        public let saturatedFatGPer100g: Double?
        public let potassiumMgPer100g: Double?
        public let cholesterolMgPer100g: Double?
        public let ingredientsText: String?
        public let servingOptions: [ServerServingOptionDTO]
        public let cacheHit: Bool

        enum CodingKeys: String, CodingKey {
            case id
            case barcodeGTIN = "barcode_gtin"
            case name
            case brand
            case source
            case externalID = "external_id"
            case servingSizeG = "serving_size_g"
            case servingDescription = "serving_description"
            case caloriesPer100g = "calories_per_100g"
            case proteinGPer100g = "protein_g_per_100g"
            case carbsGPer100g = "carbs_g_per_100g"
            case fatGPer100g = "fat_g_per_100g"
            case fiberGPer100g = "fiber_g_per_100g"
            case sugarGPer100g = "sugar_g_per_100g"
            case sodiumMgPer100g = "sodium_mg_per_100g"
            case saturatedFatGPer100g = "saturated_fat_g_per_100g"
            case potassiumMgPer100g = "potassium_mg_per_100g"
            case cholesterolMgPer100g = "cholesterol_mg_per_100g"
            case ingredientsText = "ingredients_text"
            case servingOptions = "serving_options"
            case cacheHit = "cache_hit"
        }

        public init(
            id: UUID = UUID(),
            barcodeGTIN: String? = nil,
            name: String,
            brand: String? = nil,
            source: String,
            externalID: String? = nil,
            servingSizeG: Double? = nil,
            servingDescription: String? = nil,
            caloriesPer100g: Double,
            proteinGPer100g: Double,
            carbsGPer100g: Double,
            fatGPer100g: Double,
            fiberGPer100g: Double? = nil,
            sugarGPer100g: Double? = nil,
            sodiumMgPer100g: Double? = nil,
            saturatedFatGPer100g: Double? = nil,
            potassiumMgPer100g: Double? = nil,
            cholesterolMgPer100g: Double? = nil,
            ingredientsText: String? = nil,
            servingOptions: [ServerServingOptionDTO] = [],
            cacheHit: Bool = false
        ) {
            self.id = id
            self.barcodeGTIN = barcodeGTIN
            self.name = name
            self.brand = brand
            self.source = source
            self.externalID = externalID
            self.servingSizeG = servingSizeG
            self.servingDescription = servingDescription
            self.caloriesPer100g = caloriesPer100g
            self.proteinGPer100g = proteinGPer100g
            self.carbsGPer100g = carbsGPer100g
            self.fatGPer100g = fatGPer100g
            self.fiberGPer100g = fiberGPer100g
            self.sugarGPer100g = sugarGPer100g
            self.sodiumMgPer100g = sodiumMgPer100g
            self.saturatedFatGPer100g = saturatedFatGPer100g
            self.potassiumMgPer100g = potassiumMgPer100g
            self.cholesterolMgPer100g = cholesterolMgPer100g
            self.ingredientsText = ingredientsText
            self.servingOptions = servingOptions
            self.cacheHit = cacheHit
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try c.decode(UUID.self, forKey: .id)
            self.barcodeGTIN = try c.decodeIfPresent(String.self, forKey: .barcodeGTIN)
            self.name = try c.decode(String.self, forKey: .name)
            self.brand = try c.decodeIfPresent(String.self, forKey: .brand)
            self.source = try c.decode(String.self, forKey: .source)
            self.externalID = try c.decodeIfPresent(String.self, forKey: .externalID)
            self.servingSizeG = try c.decodeIfPresent(Double.self, forKey: .servingSizeG)
            self.servingDescription = try c.decodeIfPresent(String.self, forKey: .servingDescription)
            self.caloriesPer100g = try c.decode(Double.self, forKey: .caloriesPer100g)
            self.proteinGPer100g = try c.decode(Double.self, forKey: .proteinGPer100g)
            self.carbsGPer100g = try c.decode(Double.self, forKey: .carbsGPer100g)
            self.fatGPer100g = try c.decode(Double.self, forKey: .fatGPer100g)
            self.fiberGPer100g = try c.decodeIfPresent(Double.self, forKey: .fiberGPer100g)
            self.sugarGPer100g = try c.decodeIfPresent(Double.self, forKey: .sugarGPer100g)
            self.sodiumMgPer100g = try c.decodeIfPresent(Double.self, forKey: .sodiumMgPer100g)
            self.saturatedFatGPer100g = try c.decodeIfPresent(Double.self, forKey: .saturatedFatGPer100g)
            self.potassiumMgPer100g = try c.decodeIfPresent(Double.self, forKey: .potassiumMgPer100g)
            self.cholesterolMgPer100g = try c.decodeIfPresent(Double.self, forKey: .cholesterolMgPer100g)
            self.ingredientsText = try c.decodeIfPresent(String.self, forKey: .ingredientsText)
            self.servingOptions = try c.decodeIfPresent([ServerServingOptionDTO].self, forKey: .servingOptions) ?? []
            self.cacheHit = try c.decodeIfPresent(Bool.self, forKey: .cacheHit) ?? false
        }
    }

    public struct ServerFoodSearchResponse: Codable, Sendable, Equatable {
        public let query: String
        public let results: [ServerFoodItemDTO]

        public init(query: String, results: [ServerFoodItemDTO]) {
            self.query = query
            self.results = results
        }
    }

    // MARK: - Auth Mapping

    public static func toServerAppleAuthRequest(_ request: AppleAuthRequest) -> ServerAppleAuthRequest {
        let nameParts = [request.givenName, request.familyName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let displayName = nameParts.isEmpty ? nil : nameParts.joined(separator: " ")

        return ServerAppleAuthRequest(
            identityToken: request.identityToken,
            authorizationCode: request.authorizationCode,
            rawNonce: request.rawNonce,
            displayName: displayName,
            deviceID: request.deviceId
        )
    }

    public static func toDomainAuthTokenResponse(_ wire: ServerAuthSessionResponse) -> AuthTokenResponse {
        let user = UserProfileDTO(
            id: wire.user.id,
            displayName: wire.user.displayName,
            email: wire.user.email,
            isPrivateEmail: wire.user.isPrivateEmail,
            linkedProviders: [.apple],
            createdAt: wire.user.createdAt,
            updatedAt: wire.user.createdAt
        )
        return AuthTokenResponse(
            accessToken: wire.accessToken,
            refreshToken: wire.refreshToken,
            tokenType: wire.tokenType,
            expiresInSeconds: wire.expiresIn,
            user: user
        )
    }

    // MARK: - Sync Mapping

    public static func toServerCaptureMethod(_ method: CaptureMethod) -> ServerCaptureMethod {
        switch method {
        case .photoAI:
            return .photo
        case .barcode:
            return .barcode
        case .manualAI:
            return .text
        case .manualDB, .labelOCR, .importedMFP, .importedHealthKit:
            return .manual
        }
    }

    public static func toDomainCaptureMethod(_ method: ServerCaptureMethod) -> CaptureMethod {
        switch method {
        case .photo:
            return .photoAI
        case .barcode:
            return .barcode
        case .text:
            return .manualAI
        case .manual, .quickAdd:
            return .manualDB
        }
    }

    public static func toServerAIStatus(_ status: AIStatus) -> ServerAIStatus {
        switch status {
        case .none:
            return .none
        case .pending:
            return .pending
        case .analyzed:
            return .completed
        case .failed:
            return .failed
        }
    }

    public static func toDomainAIStatus(_ status: ServerAIStatus) -> AIStatus {
        switch status {
        case .none:
            return .none
        case .pending:
            return .pending
        case .completed, .edited:
            return .analyzed
        case .failed:
            return .failed
        }
    }

    public static func toServerIngredient(_ ingredient: IngredientEstimate) -> ServerIngredientBreakdownDTO {
        ServerIngredientBreakdownDTO(
            name: ingredient.name,
            grams: ingredient.estimatedGrams,
            calories: ingredient.nutrition.caloriesKcal,
            proteinG: ingredient.nutrition.proteinG,
            carbsG: ingredient.nutrition.carbsG,
            fatG: ingredient.nutrition.fatG
        )
    }

    public static func toDomainIngredient(_ wire: ServerIngredientBreakdownDTO) -> IngredientEstimate {
        let category = inferIngredientCategory(name: wire.name)
        return IngredientEstimate(
            name: wire.name,
            category: category,
            estimatedGrams: wire.grams,
            nutrition: NutritionSnapshot(
                caloriesKcal: wire.calories ?? 0,
                proteinG: wire.proteinG ?? 0,
                carbsG: wire.carbsG ?? 0,
                fatG: wire.fatG ?? 0
            ),
            // Server item totals already include ingredient breakdown macros, so mark informational
            // (`isOptionalEstimate = false`) to avoid double-counting in `effectiveNutrition`.
            isOptionalEstimate: false,
            isIncluded: true
        )
    }

    public static func toServerMealItem(_ item: MealEntryItem, sortOrder: Int) -> ServerMealEntryItemDTO {
        let effective = item.effectiveNutrition
        return ServerMealEntryItemDTO(
            id: item.id,
            foodItemID: item.foodItemId,
            name: item.displayName,
            brand: item.brand,
            servingLabel: item.servingLabel,
            servingGrams: item.gramWeight,
            quantity: item.quantity * item.portionMultiplier,
            calories: effective.caloriesKcal,
            proteinG: effective.proteinG,
            carbsG: effective.carbsG,
            fatG: effective.fatG,
            fiberG: effective.fiberG,
            sugarG: effective.sugarG,
            sodiumMg: effective.sodiumMg,
            saturatedFatG: effective.saturatedFatG,
            potassiumMg: effective.potassiumMg,
            cholesterolMg: effective.extraNutrients?["cholesterol_mg"],
            confidence: item.confidence,
            ingredients: item.ingredients.filter(\.isIncluded).map(toServerIngredient),
            sortOrder: sortOrder
        )
    }

    public static func toDomainMealItem(_ wire: ServerMealEntryItemDTO, mealId: UUID) -> MealEntryItem {
        let extras: [String: Double]? = wire.cholesterolMg.map { ["cholesterol_mg": $0] }
        let nutrition = NutritionSnapshot(
            caloriesKcal: wire.calories,
            proteinG: wire.proteinG,
            carbsG: wire.carbsG,
            fatG: wire.fatG,
            fiberG: wire.fiberG,
            sugarG: wire.sugarG,
            saturatedFatG: wire.saturatedFatG,
            sodiumMg: wire.sodiumMg,
            potassiumMg: wire.potassiumMg,
            extraNutrients: extras
        )

        return MealEntryItem(
            id: wire.id,
            mealId: mealId,
            foodItemId: wire.foodItemID,
            displayName: wire.name,
            brand: wire.brand,
            servingLabel: wire.servingLabel,
            quantity: wire.quantity,
            gramWeight: wire.servingGrams,
            portionMultiplier: 1.0,
            confidence: wire.confidence,
            nutrition: nutrition,
            ingredients: wire.ingredients.map(toDomainIngredient)
        )
    }

    public static func toServerMealRecord(_ meal: Meal) -> ServerMealRecordDTO {
        let totals = meal.totalNutrition
        let serverItems = meal.items.enumerated().map { index, item in
            toServerMealItem(item, sortOrder: index)
        }
        return ServerMealRecordDTO(
            id: meal.id,
            localDate: meal.localDate,
            eatenAt: meal.eatenAt,
            timezoneID: meal.timezoneId,
            mealType: meal.mealType,
            captureMethod: toServerCaptureMethod(meal.captureMethod),
            aiStatus: toServerAIStatus(meal.aiStatus),
            title: meal.title,
            notes: meal.notes,
            photoAssetID: meal.photoIds.first,
            totalCalories: totals.caloriesKcal,
            totalProteinG: totals.proteinG,
            totalCarbsG: totals.carbsG,
            totalFatG: totals.fatG,
            totalFiberG: totals.fiberG,
            totalSugarG: totals.sugarG,
            totalSodiumMg: totals.sodiumMg,
            items: serverItems,
            syncSeq: meal.syncSeq ?? 0,
            clientUpdatedAt: meal.updatedAt,
            createdAt: meal.createdAt,
            updatedAt: meal.updatedAt,
            deletedAt: meal.deletedAt
        )
    }

    public static func toDomainMeal(_ wire: ServerMealRecordDTO) -> Meal {
        let resolvedTitle = wire.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? wire.title!
            : wire.mealType.displayName

        var domainItems = wire.items
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { toDomainMealItem($0, mealId: wire.id) }

        // Preserve totals for quick-add/rolled-up server records that have no child items.
        if domainItems.isEmpty,
           wire.totalCalories > 0 || wire.totalProteinG > 0 || wire.totalCarbsG > 0 || wire.totalFatG > 0
        {
            domainItems = [
                MealEntryItem(
                    mealId: wire.id,
                    displayName: resolvedTitle,
                    servingLabel: "1 meal",
                    quantity: 1.0,
                    portionMultiplier: 1.0,
                    nutrition: NutritionSnapshot(
                        caloriesKcal: wire.totalCalories,
                        proteinG: wire.totalProteinG,
                        carbsG: wire.totalCarbsG,
                        fatG: wire.totalFatG,
                        fiberG: wire.totalFiberG,
                        sugarG: wire.totalSugarG,
                        sodiumMg: wire.totalSodiumMg
                    )
                ),
            ]
        }

        return Meal(
            id: wire.id,
            localDate: wire.localDate,
            eatenAt: wire.eatenAt,
            timezoneId: wire.timezoneID,
            mealType: wire.mealType,
            title: resolvedTitle,
            notes: wire.notes,
            captureMethod: toDomainCaptureMethod(wire.captureMethod),
            aiStatus: toDomainAIStatus(wire.aiStatus),
            syncSeq: wire.syncSeq,
            items: domainItems,
            photoIds: wire.photoAssetID.map { [$0] } ?? [],
            createdAt: wire.createdAt,
            updatedAt: wire.updatedAt,
            deletedAt: wire.deletedAt
        )
    }

    /// Builds a deterministic server `POST /v1/sync/push` request for meal mutations in a batch.
    /// Returns `nil` when the batch contains no meal mutations (e.g., local-only non-meal records).
    public static func toServerSyncPushRequest(_ request: SyncPushRequest) -> ServerSyncPushRequest? {
        let mealMutations = request.mutations.filter { $0.entityType == .meal }
        guard !mealMutations.isEmpty else { return nil }

        let keyMaterial = "push|\(request.deviceId)|" + mealMutations.map { $0.mutationId.uuidString.lowercased() }.joined(separator: ",")
        let idempotencyKey = PureSHA256.hex(keyMaterial)

        let wireMutations: [ServerSyncMutationDTO] = mealMutations.map { mutation in
            switch mutation.op {
            case .upsert:
                if case let .meal(meal) = mutation.payload {
                    return ServerSyncMutationDTO(
                        op: .upsert,
                        mealID: meal.id,
                        meal: toServerMealRecord(meal),
                        deletedAt: meal.deletedAt
                    )
                }
                return ServerSyncMutationDTO(
                    op: .upsert,
                    mealID: mutation.entityId,
                    meal: nil,
                    deletedAt: nil
                )
            case .delete:
                return ServerSyncMutationDTO(
                    op: .delete,
                    mealID: mutation.entityId,
                    meal: nil,
                    deletedAt: mutation.clientUpdatedAt
                )
            }
        }

        return ServerSyncPushRequest(
            idempotencyKey: idempotencyKey,
            mutations: wireMutations
        )
    }

    public static func toDomainSyncPushResponse(
        _ wire: ServerSyncPushResponse,
        originalMutations: [SyncMutation],
        now: Date = Date()
    ) -> SyncPushResponse {
        let mealSeqById = Dictionary(
            wire.meals.map { ($0.id, $0.syncSeq) },
            uniquingKeysWith: max
        )
        let acks = originalMutations.map { mutation in
            SyncMutationAck(
                mutationId: mutation.mutationId,
                entityType: mutation.entityType,
                entityId: mutation.entityId,
                status: .applied,
                syncSeq: mealSeqById[mutation.entityId] ?? wire.latestSyncSeq
            )
        }
        return SyncPushResponse(
            acceptedCount: max(wire.appliedCount, originalMutations.count),
            latestSyncSeq: wire.latestSyncSeq,
            results: acks,
            serverTime: now
        )
    }

    public static func toDomainSyncChangesResponse(
        _ wire: ServerSyncChangesResponse,
        sinceSeq: Int64,
        now: Date = Date()
    ) -> SyncChangesResponse {
        SyncChangesResponse(
            sinceSeq: sinceSeq,
            nextSeq: wire.nextSeq,
            hasMore: wire.hasMore,
            meals: wire.changes.map(toDomainMeal),
            foodItems: [],
            photoAssets: [],
            serverTime: now
        )
    }

    // MARK: - Photos Mapping

    public static func toServerPresignUploadRequest(_ request: PresignUploadRequest) -> ServerPhotoPresignUploadRequest {
        ServerPhotoPresignUploadRequest(
            sha256Hash: request.sha256Hash,
            contentType: request.mimeType,
            byteSize: request.byteSize
        )
    }

    public static func toDomainPresignUploadResponse(
        _ wire: ServerPhotoPresignUploadResponse,
        now: Date = Date()
    ) -> PresignUploadResponse {
        PresignUploadResponse(
            photoId: wire.photoID,
            r2ObjectKey: wire.objectKey,
            uploadUrl: wire.uploadURL,
            httpMethod: wire.method,
            requiredHeaders: wire.headers,
            expiresAt: now.addingTimeInterval(Double(wire.expiresIn))
        )
    }

    public static func toDomainPhotoDownloadURLResponse(
        _ wire: ServerPhotoDownloadURLResponse,
        now: Date = Date()
    ) -> PhotoDownloadURLResponse {
        PhotoDownloadURLResponse(
            photoId: wire.photoID,
            r2ObjectKey: wire.objectKey,
            downloadUrl: wire.downloadURL,
            expiresAt: now.addingTimeInterval(Double(wire.expiresIn))
        )
    }

    // MARK: - AI Mapping

    public static func toServerAnalyzeMealPhotoRequest(
        _ request: AnalyzeMealPhotoRequest,
        localDate: String? = nil
    ) -> ServerAnalyzeMealPhotoRequest {
        ServerAnalyzeMealPhotoRequest(
            photoID: request.photoId,
            imageBase64: request.imageBase64,
            contentType: request.mimeType,
            userHint: request.contextHint,
            localDate: localDate ?? utcLocalDateString()
        )
    }

    public static func toServerEstimateMealTextRequest(
        _ request: EstimateMealTextRequest,
        localDate: String? = nil
    ) -> ServerEstimateMealTextRequest {
        ServerEstimateMealTextRequest(
            description: request.text,
            mealType: request.mealTypeHint,
            localDate: localDate ?? utcLocalDateString()
        )
    }

    public static func toDomainAnalyzeMealResponse(
        _ wire: ServerAIMealAnalysisResponse,
        now: Date = Date()
    ) -> AnalyzeMealResponse {
        let mappedItems = wire.items.map { item in
            DetectedMealItemDTO(
                displayName: item.name,
                servingLabel: item.servingLabel,
                quantity: 1.0,
                gramWeight: item.servingGrams,
                confidence: item.confidence,
                nutrition: NutritionSnapshot(
                    caloriesKcal: item.calories,
                    proteinG: item.proteinG,
                    carbsG: item.carbsG,
                    fatG: item.fatG,
                    fiberG: item.fiberG,
                    sugarG: item.sugarG,
                    sodiumMg: item.sodiumMg
                ),
                ingredients: item.ingredients.map(toDomainIngredient),
                validationWarnings: item.atwaterWarnings.map(\.message)
            )
        }

        let modelName = wire.provider.isEmpty ? wire.model : "\(wire.provider)/\(wire.model)"
        let quota = AIQuotaStatusDTO(
            dailyLimit: wire.quotaLimit,
            usedToday: max(0, wire.quotaLimit - wire.quotaRemaining),
            remainingToday: wire.quotaRemaining,
            resetsAt: nextUTCMidnight(after: now)
        )

        return AnalyzeMealResponse(
            suggestedTitle: wire.mealTitle,
            suggestedMealType: nil,
            items: mappedItems,
            modelUsed: modelName,
            latencyMs: nil,
            warnings: wire.warnings.map(\.message),
            quota: quota
        )
    }

    // MARK: - Food Catalog Mapping

    public static func toDomainFoodItem(_ wire: ServerFoodItemDTO) -> FoodItem {
        let extras: [String: Double]? = wire.cholesterolMgPer100g.map { ["cholesterol_mg": $0] }
        let per100g = NutritionSnapshot(
            caloriesKcal: wire.caloriesPer100g,
            proteinG: wire.proteinGPer100g,
            carbsG: wire.carbsGPer100g,
            fatG: wire.fatGPer100g,
            fiberG: wire.fiberGPer100g,
            sugarG: wire.sugarGPer100g,
            saturatedFatG: wire.saturatedFatGPer100g,
            sodiumMg: wire.sodiumMgPer100g,
            potassiumMg: wire.potassiumMgPer100g,
            extraNutrients: extras
        )

        var servingOptions = wire.servingOptions.map { option in
            ServingOption(
                id: option.id,
                label: option.label,
                gramWeight: option.grams,
                isDefault: option.isDefault
            )
        }

        if servingOptions.isEmpty, let servingSizeG = wire.servingSizeG, servingSizeG > 0 {
            let label = wire.servingDescription?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? wire.servingDescription!
                : "1 serving (\(Int(servingSizeG.rounded()))g)"
            servingOptions = [
                ServingOption(label: label, gramWeight: servingSizeG, isDefault: true),
            ]
        }

        return FoodItem(
            id: wire.id,
            name: wire.name,
            brand: wire.brand,
            barcode: wire.barcodeGTIN,
            source: mapFoodSource(wire.source),
            externalId: wire.externalID,
            nutritionPer100g: per100g,
            servingOptions: servingOptions
        )
    }

    public static func toDomainBarcodeLookupResponse(
        _ wire: ServerFoodItemDTO,
        requestedGTIN: String
    ) -> BarcodeLookupResponse {
        let domainFood = toDomainFoodItem(wire)
        return BarcodeLookupResponse(
            barcode: wire.barcodeGTIN ?? requestedGTIN,
            found: true,
            foodItem: domainFood,
            source: domainFood.source,
            cached: wire.cacheHit
        )
    }

    public static func toDomainFoodSearchResponse(_ wire: ServerFoodSearchResponse) -> FoodSearchResponse {
        let mapped = wire.results.map(toDomainFoodItem)
        return FoodSearchResponse(
            query: wire.query,
            items: mapped,
            totalCount: mapped.count
        )
    }

    // MARK: - Private Helpers

    private static func mapFoodSource(_ raw: String) -> FoodSource {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let direct = FoodSource(rawValue: normalized) {
            return direct
        }
        switch normalized {
        case "off", "openfoodfacts":
            return .openFoodFacts
        case "merged", "fdc":
            return .usda
        default:
            return .custom
        }
    }

    private static func inferIngredientCategory(name: String) -> IngredientCategory {
        let lower = name.lowercased()
        if lower.contains("oil") || lower.contains("butter") || lower.contains("ghee") || lower.contains("lard") {
            return .oil
        }
        if lower.contains("sauce") || lower.contains("dressing") || lower.contains("mayo")
            || lower.contains("glaze") || lower.contains("ketchup") || lower.contains("mustard")
            || lower.contains("hoisin") || lower.contains("sriracha") || lower.contains("teriyaki")
            || lower.contains("aioli") || lower.contains("vinegar")
        {
            return .sauce
        }
        if lower.contains("salt") || lower.contains("pepper") || lower.contains("spice")
            || lower.contains("seasoning") || lower.contains("garlic powder") || lower.contains("paprika")
        {
            return .seasoning
        }
        if lower.contains("cilantro") || lower.contains("parsley") || lower.contains("scallion")
            || lower.contains("green onion") || lower.contains("sesame") || lower.contains("garnish")
        {
            return .garnish
        }
        return .base
    }

    private static func utcLocalDateString(from date: Date = Date()) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 1970, c.month ?? 1, c.day ?? 1)
    }

    private static func nextUTCMidnight(after date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let startOfToday = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? date.addingTimeInterval(86_400)
    }
}
