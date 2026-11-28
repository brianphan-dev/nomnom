import Foundation
import Testing
@testable import NomNomShared

@Suite("Domain Models & API DTOs")
struct DomainAndDTOTests {
    private let encoder = NomNomJSON.makeEncoder(sortedKeys: true)
    private let decoder = NomNomJSON.makeDecoder()

    private func fixedDate(_ iso: String) -> Date {
        guard let date = NomNomJSON.parseISO8601(iso) else {
            fatalError("Invalid test date fixture: \(iso)")
        }
        return date
    }

    @Test("NomNomJSON parses fractional seconds, whole seconds, and timezone offsets")
    func iso8601DateParsing() throws {
        let msDate = NomNomJSON.parseISO8601("2026-11-27T23:37:24.123Z")
        let wholeDate = NomNomJSON.parseISO8601("2026-11-27T23:37:24Z")
        let offsetDate = NomNomJSON.parseISO8601("2026-11-27T15:37:24.123-08:00")
        let microDate = NomNomJSON.parseISO8601("2026-11-27T23:37:24.123456Z")

        #expect(msDate != nil)
        #expect(wholeDate != nil)
        #expect(offsetDate != nil)
        #expect(microDate != nil)
        if let msDate, let offsetDate {
            #expect(abs(msDate.timeIntervalSince(offsetDate)) < 0.001)
        }
        if let msDate, let wholeDate {
            #expect(abs(msDate.timeIntervalSince(wholeDate) - 0.123) < 0.001)
        }
        #expect(NomNomJSON.parseISO8601("not-a-date") == nil)
    }

    @Test("NutritionSnapshot scaling and summation preserve micronutrients and extraNutrients")
    func nutritionSnapshotMath() {
        let base = NutritionSnapshot(
            caloriesKcal: 200,
            proteinG: 20,
            carbsG: 10,
            fatG: 8,
            fiberG: 3,
            sugarG: 2,
            sodiumMg: 300,
            vitaminDMcg: 2.5,
            extraNutrients: ["zinc_mg": 1.2, "magnesium_mg": 40]
        )

        let scaled = base.scaled(by: 1.5)
        #expect(scaled.caloriesKcal == 300)
        #expect(scaled.proteinG == 30)
        #expect(scaled.carbsG == 15)
        #expect(scaled.fatG == 12)
        #expect(scaled.fiberG == 4.5)
        #expect(scaled.sugarG == 3)
        #expect(scaled.saturatedFatG == nil)
        #expect(scaled.sodiumMg == 450)
        #expect(scaled.vitaminDMcg == 3.75)
        #expect(abs((scaled.extraNutrients?["zinc_mg"] ?? 0) - 1.8) < 1e-9)
        #expect(scaled.extraNutrients?["magnesium_mg"] == 60)

        let negativeScaled = base.scaled(by: -2)
        #expect(negativeScaled.caloriesKcal == 0)
        #expect(negativeScaled.fiberG == 0)

        let extra = NutritionSnapshot(
            caloriesKcal: 100,
            proteinG: 0,
            carbsG: 5,
            fatG: 9,
            saturatedFatG: 1.5,
            extraNutrients: ["zinc_mg": 0.8, "omega3_g": 0.5]
        )

        let summed = base + extra
        #expect(summed.caloriesKcal == 300)
        #expect(summed.proteinG == 20)
        #expect(summed.carbsG == 15)
        #expect(summed.fatG == 17)
        #expect(summed.fiberG == 3)
        #expect(summed.saturatedFatG == 1.5)
        #expect(summed.calciumMg == nil)
        #expect(summed.extraNutrients?["zinc_mg"] == 2.0)
        #expect(summed.extraNutrients?["omega3_g"] == 0.5)
    }

    @Test("MealEntryItem.effectiveNutrition sums scaled base plus included optional ingredients only")
    func mealEntryItemEffectiveNutrition() {
        let baseBreakdown = IngredientEstimate(
            name: "Salmon fillet",
            category: .base,
            estimatedGrams: 150,
            nutrition: NutritionSnapshot(caloriesKcal: 300, proteinG: 34, carbsG: 0, fatG: 18),
            isOptionalEstimate: false,
            isIncluded: true
        )
        let includedOil = IngredientEstimate(
            name: "Olive oil",
            category: .oil,
            estimatedGrams: 10,
            nutrition: NutritionSnapshot(caloriesKcal: 88, proteinG: 0, carbsG: 0, fatG: 10, saturatedFatG: 1.4),
            isOptionalEstimate: true,
            isIncluded: true
        )
        let excludedGlaze = IngredientEstimate(
            name: "Teriyaki glaze",
            category: .sauce,
            estimatedGrams: 15,
            nutrition: NutritionSnapshot(caloriesKcal: 45, proteinG: 1, carbsG: 10, fatG: 0, sodiumMg: 420),
            isOptionalEstimate: true,
            isIncluded: false
        )

        let item = MealEntryItem(
            displayName: "Grilled Salmon",
            servingLabel: "1 fillet (~150g)",
            quantity: 1,
            gramWeight: 150,
            portionMultiplier: 1.5,
            confidence: 0.91,
            nutrition: NutritionSnapshot(caloriesKcal: 300, proteinG: 34, carbsG: 0, fatG: 18),
            ingredients: [baseBreakdown, includedOil, excludedGlaze]
        )

        let effective = item.effectiveNutrition
        // 300 * 1.5 + 88 = 538 kcal (baseBreakdown not double-counted; excludedGlaze omitted)
        #expect(effective.caloriesKcal == 538)
        #expect(effective.proteinG == 51)
        #expect(effective.carbsG == 0)
        #expect(effective.fatG == 37)
        #expect(effective.saturatedFatG == 1.4)
        #expect(effective.sodiumMg == nil)
    }

    @Test("Meal, FoodItem, and PhotoAsset round-trip via NomNomJSON with snake_case keys")
    func domainModelsRoundTrip() throws {
        let t1 = fixedDate("2026-11-27T18:30:00.250Z")
        let mealId = UUID()
        let photoId = UUID()
        let foodId = UUID()

        let meal = Meal(
            id: mealId,
            localDate: "2026-11-27",
            eatenAt: t1,
            timezoneId: "America/Los_Angeles",
            mealType: .dinner,
            title: "Salmon Rice Bowl",
            notes: "Extra avocado",
            captureMethod: .photoAI,
            aiStatus: .analyzed,
            healthKitCorrelationId: "hk-corr-123",
            dedupeFingerprint: PureSHA256.hex("sample"),
            syncSeq: 42,
            items: [
                MealEntryItem(
                    mealId: mealId,
                    foodItemId: foodId,
                    displayName: "Atlantic Salmon",
                    brand: "Wild Catch",
                    servingLabel: "1 fillet",
                    quantity: 1,
                    gramWeight: 160,
                    portionMultiplier: 1.25,
                    confidence: 0.88,
                    nutrition: NutritionSnapshot(
                        caloriesKcal: 320,
                        proteinG: 36,
                        carbsG: 0,
                        fatG: 19,
                        sodiumMg: 95,
                        potassiumMg: 620,
                        calciumMg: 18,
                        ironMg: 0.7,
                        vitaminCMg: 0,
                        vitaminDMcg: 14.2,
                        extraNutrients: ["omega3_g": 2.4]
                    ),
                    ingredients: [
                        IngredientEstimate(
                            name: "Sesame oil",
                            category: .oil,
                            estimatedGrams: 5,
                            nutrition: NutritionSnapshot(caloriesKcal: 44, proteinG: 0, carbsG: 0, fatG: 5),
                            isOptionalEstimate: true,
                            isIncluded: true
                        ),
                    ]
                ),
            ],
            photoIds: [photoId],
            createdAt: t1,
            updatedAt: t1,
            deletedAt: nil
        )

        #expect(meal.totalNutrition.caloriesKcal == 444)

        let mealData = try encoder.encode(meal)
        let mealJSON = String(decoding: mealData, as: UTF8.self)
        #expect(mealJSON.contains("\"local_date\":\"2026-11-27\""))
        #expect(mealJSON.contains("\"capture_method\":\"photo_ai\""))
        #expect(mealJSON.contains("\"portion_multiplier\":1.25"))
        #expect(mealJSON.contains("\"is_optional_estimate\":true"))
        #expect(mealJSON.contains("\"healthkit_correlation_id\":\"hk-corr-123\""))

        let decodedMeal = try decoder.decode(Meal.self, from: mealData)
        #expect(decodedMeal == meal)

        let food = FoodItem(
            id: foodId,
            name: "Rolled Oats",
            brand: "Bob's Red Mill",
            barcode: "039978001535",
            source: .usda,
            externalId: "173904",
            nutritionPer100g: NutritionSnapshot(
                caloriesKcal: 379,
                proteinG: 13.2,
                carbsG: 67.7,
                fatG: 6.5,
                fiberG: 10.1
            ),
            servingOptions: [
                ServingOption(label: "1/2 cup dry", gramWeight: 40, isDefault: true),
                ServingOption(label: "1 cup dry", gramWeight: 80, isDefault: false),
            ],
            isFavorite: true,
            lastUsedAt: t1,
            syncSeq: 7,
            createdAt: t1,
            updatedAt: t1
        )
        #expect(abs(food.nutrition(for: food.servingOptions[0], quantity: 1).caloriesKcal - 151.6) < 0.01)

        let decodedFood = try decoder.decode(FoodItem.self, from: encoder.encode(food))
        #expect(decodedFood == food)

        let photo = PhotoAsset(
            id: photoId,
            mealId: mealId,
            localFilename: "meal_\(photoId.uuidString).heic",
            sha256Hash: PureSHA256.hex("photo-bytes"),
            r2ObjectKey: "users/u1/photos/\(photoId.uuidString).heic",
            mimeType: "image/heic",
            byteSize: 152_400,
            widthPx: 1440,
            heightPx: 1920,
            uploadState: .synced,
            syncSeq: 43,
            createdAt: t1,
            updatedAt: t1
        )
        let photoData = try encoder.encode(photo)
        #expect(String(decoding: photoData, as: UTF8.self).contains("\"upload_state\":\"synced\""))
        #expect(try decoder.decode(PhotoAsset.self, from: photoData) == photo)
    }

    @Test("Auth and error DTOs round-trip cleanly")
    func authDTOsRoundTrip() throws {
        let now = fixedDate("2026-11-27T10:00:00.000Z")

        let appleReq = AppleAuthRequest(
            identityToken: "eyJ.apple.token",
            authorizationCode: "c12345",
            rawNonce: "nonce-xyz",
            givenName: "Brian",
            familyName: "Phan",
            deviceId: "iphone-duo-1",
            deviceName: "iPhone Duo"
        )
        #expect(try decoder.decode(AppleAuthRequest.self, from: encoder.encode(appleReq)) == appleReq)

        let googleReq = GoogleAuthRequest(
            idToken: "eyJ.google.token",
            authorizationCode: "g-code",
            rawNonce: "g-nonce",
            deviceId: "ipad-pro-1"
        )
        #expect(try decoder.decode(GoogleAuthRequest.self, from: encoder.encode(googleReq)) == googleReq)

        let refreshReq = RefreshTokenRequest(refreshToken: "rt_abc", deviceId: "iphone-duo-1")
        #expect(try decoder.decode(RefreshTokenRequest.self, from: encoder.encode(refreshReq)) == refreshReq)

        let profile = UserProfileDTO(
            id: UUID(),
            displayName: "Brian Phan",
            email: "relay@privaterelay.appleid.com",
            isPrivateEmail: true,
            linkedProviders: [.apple, .google],
            dailyCalorieTarget: 2200,
            dailyProteinTargetG: 165,
            dailyCarbsTargetG: 220,
            dailyFatTargetG: 70,
            createdAt: now,
            updatedAt: now
        )
        let tokenResp = AuthTokenResponse(
            accessToken: "jwt.access",
            refreshToken: "rt.refresh",
            expiresInSeconds: 3600,
            user: profile
        )
        #expect(try decoder.decode(AuthTokenResponse.self, from: encoder.encode(tokenResp)) == tokenResp)

        let errorEnvelope = APIErrorEnvelope(
            code: "ai_quota_exceeded",
            message: "Daily AI scan limit reached.",
            requestId: "req_01J",
            details: ["daily_limit": "20"]
        )
        #expect(try decoder.decode(APIErrorEnvelope.self, from: encoder.encode(errorEnvelope)) == errorEnvelope)
    }

    @Test("Sync DTOs round-trip upsert and delete mutations across all entity types")
    func syncDTOsRoundTrip() throws {
        let now = fixedDate("2026-11-27T12:15:30.500Z")
        let meal = Meal(
            localDate: "2026-11-27",
            eatenAt: now,
            mealType: .lunch,
            title: "Pho Tai",
            captureMethod: .manualAI,
            aiStatus: .analyzed,
            syncSeq: 10,
            createdAt: now,
            updatedAt: now
        )
        let food = FoodItem(
            name: "Greek Yogurt",
            source: .openFoodFacts,
            nutritionPer100g: NutritionSnapshot(caloriesKcal: 97, proteinG: 9, carbsG: 3.6, fatG: 5),
            createdAt: now,
            updatedAt: now
        )
        let photo = PhotoAsset(
            mealId: meal.id,
            localFilename: "pho.heic",
            sha256Hash: PureSHA256.hex("pho"),
            uploadState: .localOnly,
            createdAt: now,
            updatedAt: now
        )
        let deletedMealId = UUID()

        let pushReq = SyncPushRequest(
            deviceId: "iphone-duo-1",
            mutations: [
                .upsert(meal, clientUpdatedAt: now),
                .upsert(food, clientUpdatedAt: now),
                .upsert(photo, clientUpdatedAt: now),
                .delete(entityType: .meal, entityId: deletedMealId, clientUpdatedAt: now),
            ]
        )

        let pushData = try encoder.encode(pushReq)
        let decodedPush = try decoder.decode(SyncPushRequest.self, from: pushData)
        #expect(decodedPush == pushReq)
        #expect(decodedPush.mutations[3].payload == nil)

        let pushResp = SyncPushResponse(
            acceptedCount: 4,
            latestSyncSeq: 104,
            results: [
                SyncMutationAck(
                    mutationId: pushReq.mutations[0].mutationId,
                    entityType: .meal,
                    entityId: meal.id,
                    status: .applied,
                    syncSeq: 101
                ),
            ],
            serverTime: now
        )
        #expect(try decoder.decode(SyncPushResponse.self, from: encoder.encode(pushResp)) == pushResp)

        let changes = SyncChangesResponse(
            sinceSeq: 100,
            nextSeq: 104,
            hasMore: false,
            meals: [meal],
            foodItems: [food],
            photoAssets: [photo],
            serverTime: now
        )
        #expect(try decoder.decode(SyncChangesResponse.self, from: encoder.encode(changes)) == changes)
    }

    @Test("AI, Food/Barcode, and Photo presign DTOs round-trip cleanly")
    func aiFoodAndPhotoDTOsRoundTrip() throws {
        let now = fixedDate("2026-11-27T19:00:00.000Z")
        let resetsAt = fixedDate("2026-11-28T00:00:00.000Z")

        let analyzePhotoReq = AnalyzeMealPhotoRequest(
            photoId: UUID(),
            r2ObjectKey: "users/1/p.heic",
            mimeType: "image/heic",
            contextHint: "chicken thighs, light oil, half rice",
            mealTypeHint: .dinner,
            locale: "en_US"
        )
        #expect(try decoder.decode(AnalyzeMealPhotoRequest.self, from: encoder.encode(analyzePhotoReq)) == analyzePhotoReq)

        let textReq = EstimateMealTextRequest(
            text: "2 scrambled eggs in butter + sourdough toast",
            mealTypeHint: .breakfast,
            existingMealId: UUID(),
            locale: "en_US"
        )
        #expect(try decoder.decode(EstimateMealTextRequest.self, from: encoder.encode(textReq)) == textReq)

        let detected = DetectedMealItemDTO(
            displayName: "Scrambled Eggs",
            servingLabel: "2 large eggs",
            quantity: 1,
            gramWeight: 100,
            confidence: 0.92,
            nutrition: NutritionSnapshot(caloriesKcal: 148, proteinG: 10, carbsG: 1.6, fatG: 11),
            ingredients: [
                IngredientEstimate(
                    name: "Butter",
                    category: .oil,
                    estimatedGrams: 5,
                    nutrition: NutritionSnapshot(caloriesKcal: 36, proteinG: 0, carbsG: 0, fatG: 4),
                    isOptionalEstimate: true,
                    isIncluded: true
                ),
            ],
            validationWarnings: []
        )
        let entryItem = detected.toMealEntryItem()
        #expect(entryItem.effectiveNutrition.caloriesKcal == 184)

        let quota = AIQuotaStatusDTO(dailyLimit: 20, usedToday: 20, remainingToday: 0, resetsAt: resetsAt)
        #expect(quota.isExceeded)

        let analyzeResp = AnalyzeMealResponse(
            suggestedTitle: "Eggs & Sourdough Toast",
            suggestedMealType: .breakfast,
            items: [detected],
            modelUsed: "gemini-3.5-flash-lite",
            latencyMs: 1420,
            warnings: [],
            quota: quota
        )
        #expect(try decoder.decode(AnalyzeMealResponse.self, from: encoder.encode(analyzeResp)) == analyzeResp)

        let barcodeResp = BarcodeLookupResponse(
            barcode: "012345678905",
            found: true,
            foodItem: FoodItem(
                name: "Protein Bar",
                brand: "Barebells",
                barcode: "012345678905",
                source: .openFoodFacts,
                nutritionPer100g: NutritionSnapshot(caloriesKcal: 364, proteinG: 36, carbsG: 36, fatG: 13),
                createdAt: now,
                updatedAt: now
            ),
            source: .openFoodFacts,
            cached: true
        )
        #expect(try decoder.decode(BarcodeLookupResponse.self, from: encoder.encode(barcodeResp)) == barcodeResp)

        let searchResp = FoodSearchResponse(
            query: "protein bar",
            items: barcodeResp.foodItem.map { [$0] } ?? [],
            totalCount: 1,
            nextCursor: nil
        )
        #expect(try decoder.decode(FoodSearchResponse.self, from: encoder.encode(searchResp)) == searchResp)

        let presignReq = PresignUploadRequest(
            photoId: UUID(),
            mealId: UUID(),
            mimeType: "image/heic",
            byteSize: 148_200,
            sha256Hash: PureSHA256.hex("img")
        )
        #expect(try decoder.decode(PresignUploadRequest.self, from: encoder.encode(presignReq)) == presignReq)

        let presignResp = PresignUploadResponse(
            photoId: presignReq.photoId,
            r2ObjectKey: "users/u1/photos/p1.heic",
            uploadUrl: "https://r2.example.com/upload?sig=abc",
            httpMethod: "PUT",
            requiredHeaders: ["Content-Type": "image/heic"],
            expiresAt: resetsAt
        )
        #expect(try decoder.decode(PresignUploadResponse.self, from: encoder.encode(presignResp)) == presignResp)

        let downloadResp = PhotoDownloadURLResponse(
            photoId: presignReq.photoId,
            r2ObjectKey: presignResp.r2ObjectKey,
            downloadUrl: "https://r2.example.com/get?sig=xyz",
            expiresAt: resetsAt
        )
        #expect(try decoder.decode(PhotoDownloadURLResponse.self, from: encoder.encode(downloadResp)) == downloadResp)
    }

    @Test("All domain and sync enums encode exact snake_case wire contract values")
    func enumWireContractValues() {
        #expect(AuthProvider.allCases.map(\.rawValue) == ["apple", "google"])
        #expect(MealType.allCases.map(\.rawValue) == ["breakfast", "lunch", "dinner", "snack"])
        #expect(
            CaptureMethod.allCases.map(\.rawValue)
                == ["photo_ai", "barcode", "label_ocr", "manual_db", "manual_ai", "imported_mfp", "imported_healthkit"]
        )
        #expect(AIStatus.allCases.map(\.rawValue) == ["none", "pending", "analyzed", "failed"])
        #expect(
            IngredientCategory.allCases.map(\.rawValue)
                == ["base", "sauce", "oil", "seasoning", "garnish", "topping"]
        )
        #expect(PhotoUploadState.allCases.map(\.rawValue) == ["local_only", "uploading", "synced"])
        #expect(SyncMutationOp.allCases.map(\.rawValue) == ["upsert", "delete"])
        #expect(SyncEntityType.allCases.map(\.rawValue) == ["meal", "food_item", "photo_asset"])
    }

    @Test("Meal and MealEntryItem decode cleanly when optional collection defaults are omitted")
    func minimalJSONDecodingDefaults() throws {
        let mealId = UUID()
        let itemId = UUID()
        let json = """
        {
          "id": "\(mealId.uuidString)",
          "local_date": "2026-11-27",
          "eaten_at": "2026-11-27T12:00:00Z",
          "timezone_id": "UTC",
          "meal_type": "lunch",
          "title": "Simple Bowl",
          "capture_method": "manual_db",
          "items": [
            {
              "id": "\(itemId.uuidString)",
              "display_name": "Brown Rice",
              "serving_label": "1 cup",
              "nutrition": {
                "calories_kcal": 216,
                "protein_g": 5,
                "carbs_g": 45,
                "fat_g": 1.8
              }
            }
          ],
          "created_at": "2026-11-27T12:00:00Z",
          "updated_at": "2026-11-27T12:00:00Z"
        }
        """

        let decoded = try decoder.decode(Meal.self, from: Data(json.utf8))
        #expect(decoded.aiStatus == .none)
        #expect(decoded.photoIds.isEmpty)
        #expect(decoded.items.count == 1)
        #expect(decoded.items[0].quantity == 1.0)
        #expect(decoded.items[0].portionMultiplier == 1.0)
        #expect(decoded.items[0].ingredients.isEmpty)
        #expect(decoded.totalNutrition.caloriesKcal == 216)
    }
}
