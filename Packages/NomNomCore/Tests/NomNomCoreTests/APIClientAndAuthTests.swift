import Foundation
import ImageIO
import NomNomCore
import NomNomShared
import os
import Testing

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

#if canImport(HealthKit)
import HealthKit
#endif

@Suite("API Client, VPS Wire Contract, Auth, Media & HealthKit")
struct APIClientAndAuthTests {
    private let baseURL = URL(string: "https://api.nomnom.test")!

    private func makeServerAuthResponse(
        accessToken: String,
        refreshToken: String,
        user: UserProfileDTO = TestFixtures.makeUser()
    ) -> ServerWireAdapter.ServerAuthSessionResponse {
        ServerWireAdapter.ServerAuthSessionResponse(
            accessToken: accessToken,
            tokenType: "Bearer",
            expiresIn: 900,
            refreshToken: refreshToken,
            refreshExpiresIn: 2_592_000,
            user: ServerWireAdapter.ServerAuthUserDTO(
                id: user.id,
                displayName: user.displayName,
                email: user.email,
                isPrivateEmail: user.isPrivateEmail,
                createdAt: user.createdAt
            )
        )
    }

    @Test("Error envelope decoder parses both nested VPS { error: {...} } and flat { code, message }")
    func errorEnvelopeDecoding() {
        let nestedJSON = Data(
            #"{"error":{"code":"not_implemented","message":"Google Sign-In is scheduled for Phase 2.","phase":"phase_2"}}"#.utf8
        )
        let nested = ServerWireAdapter.decodeErrorEnvelope(from: nestedJSON)
        #expect(nested?.code == "not_implemented")
        #expect(nested?.message == "Google Sign-In is scheduled for Phase 2.")
        #expect(nested?.details?["phase"] == "phase_2")

        let flatJSON = Data(
            #"{"code":"invalid_request","message":"Bad input","request_id":"req-42"}"#.utf8
        )
        let flat = ServerWireAdapter.decodeErrorEnvelope(from: flatJSON)
        #expect(flat?.code == "invalid_request")
        #expect(flat?.message == "Bad input")
        #expect(flat?.requestId == "req-42")
    }

    @Test("POST /v1/auth/apple sends VPS wire shape with combined display_name and maps AuthSessionResponse")
    func signInWithAppleStoresSession() async throws {
        let routeID = UUID().uuidString
        defer { ScopedMockURLProtocol.removeHandler(routeID: routeID) }

        let capturedBody = OSAllocatedUnfairLock<Data?>(initialState: nil)
        let user = TestFixtures.makeUser()
        let serverResponse = makeServerAuthResponse(
            accessToken: "access-token-initial",
            refreshToken: "refresh-token-initial",
            user: user
        )

        let session = ScopedMockURLProtocol.makeSession(routeID: routeID) { request, body in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path == "/v1/auth/apple")
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
            capturedBody.withLock { $0 = body }
            let data = try TestFixtures.encodeJSON(serverResponse)
            return (TestFixtures.makeHTTPResponse(url: request.url!, statusCode: 200), data)
        }

        let credentials = InMemoryCredentialStore()
        let deviceId = try credentials.getOrCreateDeviceId()
        let client = NomNomAPIClient(baseURL: baseURL, session: session, credentialStore: credentials)

        let nonce = try AppleNonceGenerator.generate()
        let request = AppleAuthRequest(
            identityToken: "eyJhbGciOiJSUzI1NiJ9.payload.sig",
            authorizationCode: "c-apple-auth-code",
            rawNonce: nonce.rawNonce,
            givenName: "Brian",
            familyName: "Phan",
            deviceId: deviceId,
            deviceName: "iPhone Duo"
        )

        let result = try await client.signInWithApple(request)
        #expect(result.accessToken == "access-token-initial")
        #expect(result.refreshToken == "refresh-token-initial")
        #expect(result.expiresInSeconds == 900)
        #expect(result.user.id == user.id)
        #expect(result.user.displayName == "Brian Phan")
        #expect(result.user.email == "brian@privaterelay.appleid.com")
        #expect(result.user.isPrivateEmail == true)

        #expect(credentials.accessToken == "access-token-initial")
        #expect(credentials.refreshToken == "refresh-token-initial")
        #expect(credentials.userId == user.id.uuidString)
        #expect(credentials.displayName == "Brian Phan")
        #expect(credentials.email == "brian@privaterelay.appleid.com")
        #expect(credentials.isPrivateEmail == true)

        // Verify exact deployed VPS request JSON keys.
        let rawBody = try #require(capturedBody.withLock { $0 })
        let jsonObject = try #require(JSONSerialization.jsonObject(with: rawBody) as? [String: Any])
        #expect(jsonObject["identity_token"] as? String == request.identityToken)
        #expect(jsonObject["authorization_code"] as? String == request.authorizationCode)
        #expect(jsonObject["raw_nonce"] as? String == nonce.rawNonce)
        #expect(jsonObject["display_name"] as? String == "Brian Phan")
        #expect(jsonObject["device_id"] as? String == deviceId)
        #expect(jsonObject["given_name"] == nil)
        #expect(jsonObject["family_name"] == nil)
    }

    @Test("Concurrent 401 responses trigger exactly one single-flight VPS refresh rotation")
    func singleFlightRefreshOnConcurrent401() async throws {
        let routeID = UUID().uuidString
        defer { ScopedMockURLProtocol.removeHandler(routeID: routeID) }

        struct ServerState: Sendable {
            var refreshCalls = 0
            var searchCalls = 0
        }
        let serverState = OSAllocatedUnfairLock(initialState: ServerState())
        let user = TestFixtures.makeUser()

        let session = ScopedMockURLProtocol.makeSession(routeID: routeID) { request, body in
            let url = request.url!
            if url.path == "/v1/auth/refresh" {
                let rawBody = try #require(body)
                let req = try NomNomJSON.makeDecoder().decode(
                    ServerWireAdapter.ServerRefreshTokenRequest.self,
                    from: rawBody
                )
                #expect(req.refreshToken == "valid-refresh")
                #expect(req.deviceID == "device-duo-1")

                Thread.sleep(forTimeInterval: 0.05)
                let callNumber = serverState.withLock { s -> Int in
                    s.refreshCalls += 1
                    return s.refreshCalls
                }
                let rotated = ServerWireAdapter.ServerAuthSessionResponse(
                    accessToken: "fresh-access-\(callNumber)",
                    tokenType: "Bearer",
                    expiresIn: 900,
                    refreshToken: "fresh-refresh-\(callNumber)",
                    refreshExpiresIn: 2_592_000,
                    user: ServerWireAdapter.ServerAuthUserDTO(
                        id: user.id,
                        displayName: user.displayName,
                        email: user.email,
                        isPrivateEmail: user.isPrivateEmail,
                        createdAt: user.createdAt
                    )
                )
                return (
                    TestFixtures.makeHTTPResponse(url: url, statusCode: 200),
                    try TestFixtures.encodeJSON(rotated)
                )
            }

            if url.path == "/v1/foods/search" {
                serverState.withLock { $0.searchCalls += 1 }
                let auth = request.value(forHTTPHeaderField: "Authorization")
                if auth == "Bearer expired-access" {
                    let errorBody = ServerWireAdapter.ServerErrorBody(
                        code: "token_expired",
                        message: "Access token expired"
                    )
                    return (
                        TestFixtures.makeHTTPResponse(url: url, statusCode: 401),
                        try TestFixtures.encodeJSON(errorBody)
                    )
                }

                #expect(auth == "Bearer fresh-access-1")
                let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "q" })?.value ?? ""
                let payload = ServerWireAdapter.ServerFoodSearchResponse(query: query, results: [])
                return (
                    TestFixtures.makeHTTPResponse(url: url, statusCode: 200),
                    try TestFixtures.encodeJSON(payload)
                )
            }

            return (TestFixtures.makeHTTPResponse(url: url, statusCode: 404), Data())
        }

        let credentials = InMemoryCredentialStore(initialValues: [
            .accessToken: "expired-access",
            .refreshToken: "valid-refresh",
            .deviceId: "device-duo-1",
            .userId: user.id.uuidString,
        ])
        let client = NomNomAPIClient(baseURL: baseURL, session: session, credentialStore: credentials)

        let queries = ["salmon", "oats", "avocado", "rice"]
        let responses = try await withThrowingTaskGroup(of: FoodSearchResponse.self) { group in
            for q in queries {
                group.addTask {
                    try await client.searchFoods(query: q)
                }
            }
            var collected: [FoodSearchResponse] = []
            for try await res in group {
                collected.append(res)
            }
            return collected
        }

        #expect(responses.count == 4)
        #expect(Set(responses.map(\.query)) == Set(queries))
        let finalState = serverState.withLock { $0 }
        #expect(finalState.refreshCalls == 1)
        #expect(finalState.searchCalls == 8)
        #expect(credentials.accessToken == "fresh-access-1")
        #expect(credentials.refreshToken == "fresh-refresh-1")
    }

    @Test("DELETE /v1/account decodes VPS AccountDeletionResponse and clears credentials preserving deviceId")
    func deleteAccountClearsCredentials() async throws {
        let routeID = UUID().uuidString
        defer { ScopedMockURLProtocol.removeHandler(routeID: routeID) }

        let userId = UUID()
        let deleteObserved = OSAllocatedUnfairLock(initialState: false)
        let session = ScopedMockURLProtocol.makeSession(routeID: routeID) { request, _ in
            #expect(request.httpMethod == "DELETE")
            #expect(request.url?.path == "/v1/account")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer live-token")
            deleteObserved.withLock { $0 = true }
            let response = ServerWireAdapter.ServerAccountDeletionResponse(
                deleted: true,
                appleTokenRevoked: true,
                requiresManualAppleRevocation: false,
                userID: userId
            )
            return (
                TestFixtures.makeHTTPResponse(url: request.url!, statusCode: 200),
                try TestFixtures.encodeJSON(response)
            )
        }

        let credentials = InMemoryCredentialStore(initialValues: [
            .accessToken: "live-token",
            .refreshToken: "live-refresh",
            .userId: userId.uuidString,
            .deviceId: "stable-device-id",
            .displayName: "Brian",
            .email: "brian@example.com",
            .isPrivateEmail: "true",
        ])
        let client = NomNomAPIClient(baseURL: baseURL, session: session, credentialStore: credentials)

        let receipt = try await client.deleteAccountWithReceipt()

        #expect(deleteObserved.withLock { $0 } == true)
        #expect(receipt?.deleted == true)
        #expect(receipt?.appleTokenRevoked == true)
        #expect(receipt?.requiresManualAppleRevocation == false)
        #expect(receipt?.userID == userId)
        #expect(credentials.accessToken == nil)
        #expect(credentials.refreshToken == nil)
        #expect(credentials.userId == nil)
        #expect(credentials.displayName == nil)
        #expect(credentials.email == nil)
        #expect(credentials.deviceId == "stable-device-id")
    }

    @Test("AI endpoints speak exact VPS JSON request/response contract, map ingredients, and map HTTP 429")
    func aiWireContractQuotaParsingAnd429ErrorMapping() async throws {
        let routeID = UUID().uuidString
        defer { ScopedMockURLProtocol.removeHandler(routeID: routeID) }

        let capturedPhotoJSON = OSAllocatedUnfairLock<Data?>(initialState: nil)
        let capturedTextJSON = OSAllocatedUnfairLock<Data?>(initialState: nil)

        let serverAIResponse = ServerWireAdapter.ServerAIMealAnalysisResponse(
            provider: "gemini",
            model: "gemini-2.5-flash-lite",
            mealTitle: "Salmon Poke Bowl",
            items: [
                ServerWireAdapter.ServerAIEstimatedItemDTO(
                    name: "Salmon Poke",
                    servingLabel: "1 bowl (~350g)",
                    servingGrams: 350,
                    calories: 540,
                    proteinG: 36,
                    carbsG: 52,
                    fatG: 19,
                    fiberG: 4.5,
                    sugarG: 6.0,
                    sodiumMg: 620,
                    confidence: 0.88,
                    ingredients: [
                        ServerWireAdapter.ServerIngredientBreakdownDTO(
                            name: "Sesame Oil",
                            grams: 5,
                            calories: 44,
                            proteinG: 0,
                            carbsG: 0,
                            fatG: 5
                        ),
                        ServerWireAdapter.ServerIngredientBreakdownDTO(
                            name: "Spicy Mayo Sauce",
                            grams: 15,
                            calories: 95,
                            proteinG: 0.2,
                            carbsG: 1.0,
                            fatG: 10.0
                        ),
                    ],
                    atwaterWarnings: [
                        ServerWireAdapter.ServerAtwaterWarningDTO(
                            itemName: "Salmon Poke",
                            code: "minor_variance",
                            message: "Minor label rounding delta",
                            reportedCalories: 540,
                            expectedCalories: 523
                        ),
                    ]
                ),
            ],
            totalCalories: 540,
            totalProteinG: 36,
            totalCarbsG: 52,
            totalFatG: 19,
            warnings: [
                ServerWireAdapter.ServerAtwaterWarningDTO(
                    code: "portion_estimate",
                    message: "Verify rice portion size"
                ),
            ],
            quotaRemaining: 14,
            quotaLimit: 20
        )

        let session = ScopedMockURLProtocol.makeSession(routeID: routeID) { request, body in
            let url = request.url!
            if url.path == "/v1/ai/analyze-meal-photo" {
                capturedPhotoJSON.withLock { $0 = body }
                return (
                    TestFixtures.makeHTTPResponse(
                        url: url,
                        statusCode: 200,
                        headers: ["X-AI-Quota-Remaining": "14"]
                    ),
                    try TestFixtures.encodeJSON(serverAIResponse)
                )
            }
            if url.path == "/v1/ai/estimate-meal-text" {
                capturedTextJSON.withLock { $0 = body }
                let errorBody = ServerWireAdapter.ServerErrorBody(
                    code: "ai_quota_exceeded",
                    message: "Daily AI scan limit reached (20/20)."
                )
                return (
                    TestFixtures.makeHTTPResponse(
                        url: url,
                        statusCode: 429,
                        headers: [
                            "X-AI-Quota-Remaining": "0",
                            "Retry-After": "3600",
                        ]
                    ),
                    try TestFixtures.encodeJSON(errorBody)
                )
            }
            return (TestFixtures.makeHTTPResponse(url: url, statusCode: 404), Data())
        }

        let credentials = InMemoryCredentialStore(initialValues: [.accessToken: "token-ok"])
        let client = NomNomAPIClient(baseURL: baseURL, session: session, credentialStore: credentials)

        let photoId = UUID()
        let (analysis, remaining) = try await client.analyzeMealPhoto(
            AnalyzeMealPhotoRequest(
                photoId: photoId,
                imageBase64: "AAAA",
                mimeType: "image/jpeg",
                contextHint: "light sauce"
            )
        )
        #expect(analysis.suggestedTitle == "Salmon Poke Bowl")
        #expect(analysis.modelUsed == "gemini/gemini-2.5-flash-lite")
        #expect(analysis.items.count == 1)
        #expect(analysis.items[0].displayName == "Salmon Poke")
        #expect(analysis.items[0].ingredients.count == 2)
        #expect(analysis.items[0].ingredients[0].category == .oil)
        #expect(analysis.items[0].ingredients[1].category == .sauce)
        #expect(analysis.items[0].validationWarnings == ["Minor label rounding delta"])
        #expect(analysis.warnings == ["Verify rice portion size"])
        #expect(analysis.quota?.dailyLimit == 20)
        #expect(analysis.quota?.remainingToday == 14)
        #expect(remaining == 14)

        // Confirm exact VPS request keys for photo analysis.
        let photoBody = try #require(capturedPhotoJSON.withLock { $0 })
        let photoJSON = try #require(JSONSerialization.jsonObject(with: photoBody) as? [String: Any])
        #expect(photoJSON["photo_id"] as? String == photoId.uuidString)
        #expect(photoJSON["image_base64"] as? String == "AAAA")
        #expect(photoJSON["content_type"] as? String == "image/jpeg")
        #expect(photoJSON["user_hint"] as? String == "light sauce")
        #expect(photoJSON["local_date"] as? String != nil)

        do {
            _ = try await client.estimateMealText(
                EstimateMealTextRequest(text: "2 eggs and sourdough", mealTypeHint: .breakfast)
            )
            Issue.record("Expected NomNomAPIError.quotaExceeded to be thrown")
        } catch let error as NomNomAPIError {
            #expect(
                error == .quotaExceeded(
                    quotaRemaining: 0,
                    retryAfterSeconds: 3600,
                    message: "Daily AI scan limit reached (20/20)."
                )
            )
        }

        // Confirm exact VPS request keys for text estimation.
        let textBody = try #require(capturedTextJSON.withLock { $0 })
        let textJSON = try #require(JSONSerialization.jsonObject(with: textBody) as? [String: Any])
        #expect(textJSON["description"] as? String == "2 eggs and sourdough")
        #expect(textJSON["meal_type"] as? String == "breakfast")
        #expect(textJSON["local_date"] as? String != nil)
    }

    @Test("Photos presign/url, barcode 200+404, food search, and logout match exact VPS wire contracts")
    func photosBarcodeSearchAndLogoutWireContracts() async throws {
        let routeID = UUID().uuidString
        defer { ScopedMockURLProtocol.removeHandler(routeID: routeID) }

        let photoId = UUID()
        let mealId = UUID()
        let foodId = UUID()
        let sha = PureSHA256.hex("photo-data")
        let capturedLogoutBody = OSAllocatedUnfairLock<Data?>(initialState: nil)
        let capturedPresignBody = OSAllocatedUnfairLock<Data?>(initialState: nil)

        let serverFood = ServerWireAdapter.ServerFoodItemDTO(
            id: foodId,
            barcodeGTIN: "0894700010045",
            name: "Chobani Zero Sugar Vanilla",
            brand: "Chobani",
            source: "open_food_facts",
            externalID: "off:0894700010045",
            servingSizeG: 150,
            servingDescription: "1 cup (150g)",
            caloriesPer100g: 40,
            proteinGPer100g: 7.3,
            carbsGPer100g: 2.7,
            fatGPer100g: 0.0,
            sodiumMgPer100g: 43,
            cholesterolMgPer100g: 3.3,
            servingOptions: [
                ServerWireAdapter.ServerServingOptionDTO(
                    label: "1 cup (150g)",
                    grams: 150,
                    isDefault: true
                ),
            ],
            cacheHit: true
        )

        let session = ScopedMockURLProtocol.makeSession(routeID: routeID) { request, body in
            let url = request.url!
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer live-access")
            switch (request.httpMethod, url.path) {
            case ("POST", "/v1/photos/presign-upload"):
                capturedPresignBody.withLock { $0 = body }
                let res = ServerWireAdapter.ServerPhotoPresignUploadResponse(
                    photoID: photoId,
                    objectKey: "photos/\(photoId.uuidString.lowercased()).heic",
                    uploadURL: "https://r2.example.invalid/upload/\(photoId.uuidString.lowercased())",
                    method: "PUT",
                    headers: ["Content-Type": "image/heic"],
                    expiresIn: 900
                )
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 200), try TestFixtures.encodeJSON(res))

            case ("GET", "/v1/photos/\(photoId.uuidString.lowercased())/url"):
                let res = ServerWireAdapter.ServerPhotoDownloadURLResponse(
                    photoID: photoId,
                    objectKey: "photos/\(photoId.uuidString.lowercased()).heic",
                    downloadURL: "https://r2.example.invalid/download/\(photoId.uuidString.lowercased())",
                    expiresIn: 900
                )
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 200), try TestFixtures.encodeJSON(res))

            case ("GET", "/v1/foods/barcode/0894700010045"):
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 200), try TestFixtures.encodeJSON(serverFood))

            case ("GET", "/v1/foods/barcode/9999999999999"):
                let notFound = ServerWireAdapter.ServerErrorBody(
                    code: "food_not_found",
                    message: "No nutrition record found for barcode 9999999999999."
                )
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 404), try TestFixtures.encodeJSON(notFound))

            case ("GET", "/v1/foods/search"):
                let res = ServerWireAdapter.ServerFoodSearchResponse(query: "chobani", results: [serverFood])
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 200), try TestFixtures.encodeJSON(res))

            case ("POST", "/v1/auth/logout"):
                capturedLogoutBody.withLock { $0 = body }
                let res = ServerWireAdapter.ServerLogoutResponse(loggedOut: true)
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 200), try TestFixtures.encodeJSON(res))

            default:
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 404), Data())
            }
        }

        let credentials = InMemoryCredentialStore(initialValues: [
            .accessToken: "live-access",
            .refreshToken: "live-refresh",
            .deviceId: "device-mac",
            .userId: UUID().uuidString,
        ])
        let client = NomNomAPIClient(baseURL: baseURL, session: session, credentialStore: credentials)

        let presign = try await client.presignPhotoUpload(
            PresignUploadRequest(
                photoId: photoId,
                mealId: mealId,
                mimeType: "image/heic",
                byteSize: 85_000,
                sha256Hash: sha
            )
        )
        #expect(presign.photoId == photoId)
        #expect(presign.r2ObjectKey == "photos/\(photoId.uuidString.lowercased()).heic")
        #expect(presign.requiredHeaders["Content-Type"] == "image/heic")

        let presignBody = try #require(capturedPresignBody.withLock { $0 })
        let presignJSON = try #require(JSONSerialization.jsonObject(with: presignBody) as? [String: Any])
        #expect(presignJSON["sha256_hash"] as? String == sha)
        #expect(presignJSON["content_type"] as? String == "image/heic")
        #expect(presignJSON["byte_size"] as? Int == 85_000)

        let download = try await client.photoDownloadURL(photoId: photoId)
        #expect(download.r2ObjectKey == presign.r2ObjectKey)
        #expect(download.downloadUrl.contains("/download/"))

        let barcodeHit = try await client.lookupBarcode("0894700010045")
        #expect(barcodeHit.found == true)
        #expect(barcodeHit.cached == true)
        #expect(barcodeHit.source == .openFoodFacts)
        #expect(barcodeHit.foodItem?.id == foodId)
        #expect(barcodeHit.foodItem?.name == "Chobani Zero Sugar Vanilla")
        #expect(barcodeHit.foodItem?.nutritionPer100g.extraNutrients?["cholesterol_mg"] == 3.3)
        #expect(barcodeHit.foodItem?.servingOptions.first?.gramWeight == 150)

        // Barcode 404 must map cleanly to found == false without throwing.
        let barcodeMiss = try await client.lookupBarcode("9999999999999")
        #expect(barcodeMiss.found == false)
        #expect(barcodeMiss.barcode == "9999999999999")
        #expect(barcodeMiss.foodItem == nil)

        let search = try await client.searchFoods(query: "chobani")
        #expect(search.query == "chobani")
        #expect(search.totalCount == 1)
        #expect(search.items.first?.id == foodId)

        try await client.signOut()
        #expect(credentials.accessToken == nil)
        #expect(credentials.refreshToken == nil)
        #expect(credentials.deviceId == "device-mac")

        let logoutBody = try #require(capturedLogoutBody.withLock { $0 })
        let logoutJSON = try #require(JSONSerialization.jsonObject(with: logoutBody) as? [String: Any])
        #expect(logoutJSON["refresh_token"] as? String == "live-refresh")
    }

    @Test("Sync wire adapter maps capture methods, AI statuses, and meal records bidirectionally")
    func syncWireAdapterMappings() {
        #expect(ServerWireAdapter.toServerCaptureMethod(.photoAI) == .photo)
        #expect(ServerWireAdapter.toServerCaptureMethod(.barcode) == .barcode)
        #expect(ServerWireAdapter.toServerCaptureMethod(.manualAI) == .text)
        #expect(ServerWireAdapter.toServerCaptureMethod(.manualDB) == .manual)
        #expect(ServerWireAdapter.toServerCaptureMethod(.labelOCR) == .manual)
        #expect(ServerWireAdapter.toServerCaptureMethod(.importedMFP) == .manual)
        #expect(ServerWireAdapter.toServerCaptureMethod(.importedHealthKit) == .manual)

        #expect(ServerWireAdapter.toDomainCaptureMethod(.photo) == .photoAI)
        #expect(ServerWireAdapter.toDomainCaptureMethod(.barcode) == .barcode)
        #expect(ServerWireAdapter.toDomainCaptureMethod(.text) == .manualAI)
        #expect(ServerWireAdapter.toDomainCaptureMethod(.manual) == .manualDB)
        #expect(ServerWireAdapter.toDomainCaptureMethod(.quickAdd) == .manualDB)

        #expect(ServerWireAdapter.toServerAIStatus(.analyzed) == .completed)
        #expect(ServerWireAdapter.toDomainAIStatus(.completed) == .analyzed)
        #expect(ServerWireAdapter.toDomainAIStatus(.edited) == .analyzed)

        let photoId = UUID()
        var meal = TestFixtures.makeMeal(
            localDate: "2026-11-27",
            mealType: .dinner,
            title: "Teriyaki Salmon",
            calories: 640,
            protein: 45,
            carbs: 58,
            fat: 22,
            captureMethod: .photoAI
        )
        meal.photoIds = [photoId]

        let wire = ServerWireAdapter.toServerMealRecord(meal)
        #expect(wire.captureMethod == .photo)
        #expect(wire.aiStatus == .completed)
        #expect(wire.photoAssetID == photoId)
        #expect(wire.totalCalories == 640)
        #expect(wire.items.count == 1)
        #expect(wire.items[0].name == "Teriyaki Salmon")

        let roundTripped = ServerWireAdapter.toDomainMeal(wire)
        #expect(roundTripped.id == meal.id)
        #expect(roundTripped.captureMethod == .photoAI)
        #expect(roundTripped.aiStatus == .analyzed)
        #expect(roundTripped.photoIds == [photoId])
        #expect(roundTripped.totalNutrition.caloriesKcal == 640)
    }

    @Test("Presigned R2 PUT uploads binary image without Authorization header and healthCheck parses /healthz")
    func presignedUploadAndHealthCheck() async throws {
        let routeID = UUID().uuidString
        defer { ScopedMockURLProtocol.removeHandler(routeID: routeID) }

        let uploadedBytes = OSAllocatedUnfairLock<Data?>(initialState: nil)
        let session = ScopedMockURLProtocol.makeSession(routeID: routeID) { request, body in
            let url = request.url!
            if url.path == "/healthz" {
                return (
                    TestFixtures.makeHTTPResponse(url: url, statusCode: 200),
                    Data(#"{"status":"ok","service":"nomnom-api","version":"0.1.0"}"#.utf8)
                )
            }
            if url.host == "r2.example.invalid" {
                #expect(request.httpMethod == "PUT")
                #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
                #expect(request.value(forHTTPHeaderField: "Content-Type") == "image/jpeg")
                uploadedBytes.withLock { $0 = body }
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 200), Data())
            }
            return (TestFixtures.makeHTTPResponse(url: url, statusCode: 404), Data())
        }

        let client = NomNomAPIClient(
            baseURL: baseURL,
            session: session,
            credentialStore: InMemoryCredentialStore(initialValues: [.accessToken: "secret-bearer"])
        )

        #expect(try await client.healthCheck() == true)

        let payload = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02])
        let presigned = URL(string: "https://r2.example.invalid/photos/meal.jpg?sig=abc")!
        try await client.uploadPhotoToPresignedURL(presigned, data: payload, contentType: "image/jpeg")
        #expect(uploadedBytes.withLock { $0 } == payload)
    }

    @Test("AppleNonceGenerator, AppleSignInCoordinator builder, and revocation stream work deterministically")
    func appleAuthHelpersAndRevocationMonitor() async throws {
        let pair1 = try AppleNonceGenerator.generate()
        let pair2 = try AppleNonceGenerator.generate()
        #expect(pair1.rawNonce != pair2.rawNonce)
        #expect(pair1.rawNonce.count >= 40)
        #expect(pair1.sha256Hex.count == 64)
        #expect(pair1.sha256Hex == PureSHA256.hex(pair1.rawNonce))
        #expect(pair1.sha256Hex == pair1.sha256Hex.lowercased())

        #if canImport(AuthenticationServices)
        var name = PersonNameComponents()
        name.givenName = "  Brian "
        name.familyName = "Phan "

        let authReq = try AppleSignInCoordinator.buildAuthRequest(
            identityTokenData: Data("jwt.identity.token".utf8),
            authorizationCodeData: Data("apple-auth-code".utf8),
            rawNonce: pair1.rawNonce,
            fullName: name,
            deviceId: "device-1",
            deviceName: "iPhone 16 Pro"
        )
        #expect(authReq.identityToken == "jwt.identity.token")
        #expect(authReq.authorizationCode == "apple-auth-code")
        #expect(authReq.givenName == "Brian")
        #expect(authReq.familyName == "Phan")
        #expect(authReq.rawNonce == pair1.rawNonce)

        #expect(throws: AppleSignInError.missingIdentityToken) {
            try AppleSignInCoordinator.buildAuthRequest(
                identityTokenData: nil,
                authorizationCodeData: Data("code".utf8),
                rawNonce: pair1.rawNonce,
                fullName: nil,
                deviceId: "device-1"
            )
        }

        let center = NotificationCenter()
        let monitor = AppleCredentialStateMonitor(notificationCenter: center)
        let stream = monitor.revocationStream()
        let received = Task<Bool, Never> {
            for await _ in stream {
                return true
            }
            return false
        }
        try await Task.sleep(for: .milliseconds(20))
        center.post(name: ASAuthorizationAppleIDProvider.credentialRevokedNotification, object: nil)
        #expect(await received.value == true)
        #endif
    }

    @Test("PhotoProcessor resizes to 1200px archival & 768px Vision JPEG and strips EXIF GPS")
    func photoProcessorResizingAndGPSStripping() throws {
        let rawWithGPS = SyntheticImageFactory.makeJPEG(
            width: 1800,
            height: 1200,
            includeGPSMetadata: true
        )

        let source = try #require(CGImageSourceCreateWithData(rawWithGPS as CFData, nil))
        let sourceProps = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        #expect(sourceProps[kCGImagePropertyGPSDictionary] != nil)

        let bundle = try PhotoProcessor.processMealPhoto(rawWithGPS, preferHEICForArchival: false)

        #expect(max(bundle.archival.widthPx, bundle.archival.heightPx) == 1200)
        #expect(bundle.archival.sha256Hex == PureSHA256.hex(bundle.archival.data))
        #expect(bundle.archival.byteSize == Int64(bundle.archival.data.count))

        #expect(max(bundle.visionAI.widthPx, bundle.visionAI.heightPx) == 768)
        #expect(bundle.visionAI.mimeType == "image/jpeg")
        #expect(bundle.visionAI.sha256Hex == PureSHA256.hex(bundle.visionAI.data))

        for outputData in [bundle.archival.data, bundle.visionAI.data] {
            let outSource = try #require(CGImageSourceCreateWithData(outputData as CFData, nil))
            let outProps = CGImageSourceCopyPropertiesAtIndex(outSource, 0, nil) as? [CFString: Any]
            #expect(outProps?[kCGImagePropertyGPSDictionary] == nil)
        }
    }

    @Test("PhotoProcessor avoids upscaling small images and rejects invalid data")
    func photoProcessorSmallImageAndErrorHandling() throws {
        let smallJPEG = SyntheticImageFactory.makeJPEG(width: 400, height: 300, includeGPSMetadata: false)
        let bundle = try PhotoProcessor.processMealPhoto(smallJPEG, preferHEICForArchival: false)
        #expect(bundle.archival.widthPx == 400)
        #expect(bundle.archival.heightPx == 300)
        #expect(bundle.visionAI.widthPx == 400)
        #expect(bundle.visionAI.heightPx == 300)

        #expect(throws: PhotoProcessingError.invalidImageData) {
            try PhotoProcessor.prepareVisionAICopy(from: Data("not-an-image".utf8))
        }
    }

    @Test("HealthKitMealMapper groups samples and LiveHealthKitService builds idempotent HKCorrelation")
    func healthKitMappingAndCorrelationBuilder() throws {
        let timeZone = TimeZone(secondsFromGMT: 0)!
        let breakfastTime = TestFixtures.fixedDate("2026-11-27T08:15:00Z")
        let samples: [HealthKitDietarySample] = [
            HealthKitDietarySample(kind: .caloriesKcal, value: 420, startDate: breakfastTime, endDate: breakfastTime, foodName: "Oatmeal"),
            HealthKitDietarySample(kind: .proteinG, value: 24, startDate: breakfastTime.addingTimeInterval(30), endDate: breakfastTime.addingTimeInterval(30), foodName: "Oatmeal"),
            HealthKitDietarySample(kind: .carbsG, value: 58, startDate: breakfastTime, endDate: breakfastTime, foodName: "Oatmeal"),
            HealthKitDietarySample(kind: .fatG, value: 10, startDate: breakfastTime, endDate: breakfastTime, foodName: "Oatmeal"),
            HealthKitDietarySample(kind: .fiberG, value: 8, startDate: breakfastTime, endDate: breakfastTime, foodName: "Oatmeal"),
        ]

        let meals = HealthKitMealMapper.groupSamplesIntoMeals(samples, timeZone: timeZone)
        #expect(meals.count == 1)
        let meal = try #require(meals.first)
        #expect(meal.mealType == .breakfast)
        #expect(meal.captureMethod == .importedHealthKit)
        #expect(meal.title == "Oatmeal")
        #expect(meal.totalNutrition.caloriesKcal == 420)
        #expect(meal.totalNutrition.proteinG == 24)
        #expect(meal.totalNutrition.fiberG == 8)
        #expect(meal.dedupeFingerprint?.count == 64)

        #if canImport(HealthKit)
        let correlation = try LiveHealthKitService.makeCorrelation(for: meal)
        #expect(correlation.metadata?[HKMetadataKeySyncIdentifier] as? String == meal.id.uuidString)
        #expect((correlation.metadata?[HKMetadataKeySyncVersion] as? NSNumber)?.intValue ?? 0 > 0)
        #expect(correlation.objects.count == 5)
        #endif
    }
}
