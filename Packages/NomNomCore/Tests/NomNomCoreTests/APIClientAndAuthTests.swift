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

@Suite("API Client, Auth, Media & HealthKit")
struct APIClientAndAuthTests {
    private let baseURL = URL(string: "https://api.nomnom.test")!

    @Test("POST /v1/auth/apple exchanges Apple credentials and persists session tokens")
    func signInWithAppleStoresSession() async throws {
        let routeID = UUID().uuidString
        defer { ScopedMockURLProtocol.removeHandler(routeID: routeID) }

        let capturedBody = OSAllocatedUnfairLock<Data?>(initialState: nil)
        let user = TestFixtures.makeUser()
        let authResponse = AuthTokenResponse(
            accessToken: "access-token-initial",
            refreshToken: "refresh-token-initial",
            tokenType: "Bearer",
            expiresInSeconds: 3600,
            user: user
        )

        let session = ScopedMockURLProtocol.makeSession(routeID: routeID) { request, body in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path == "/v1/auth/apple")
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
            capturedBody.withLock { $0 = body }
            let data = try TestFixtures.encodeJSON(authResponse)
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
        #expect(result == authResponse)
        #expect(credentials.accessToken == "access-token-initial")
        #expect(credentials.refreshToken == "refresh-token-initial")
        #expect(credentials.userId == user.id.uuidString)
        #expect(credentials.displayName == "Brian Phan")
        #expect(credentials.email == "brian@privaterelay.appleid.com")
        #expect(credentials.isPrivateEmail == true)

        // Confirm snake_case wire format matches NomNomShared contract.
        let rawBody = try #require(capturedBody.withLock { $0 })
        let decodedSent = try NomNomJSON.makeDecoder().decode(AppleAuthRequest.self, from: rawBody)
        #expect(decodedSent == request)
    }

    @Test("Concurrent 401 responses trigger exactly one single-flight refresh rotation")
    func singleFlightRefreshOnConcurrent401() async throws {
        let routeID = UUID().uuidString
        defer { ScopedMockURLProtocol.removeHandler(routeID: routeID) }

        struct ServerState: Sendable {
            var refreshCalls = 0
            var searchCalls = 0
        }
        let serverState = OSAllocatedUnfairLock(initialState: ServerState())
        let user = TestFixtures.makeUser()

        let session = ScopedMockURLProtocol.makeSession(routeID: routeID) { request, _ in
            let url = request.url!
            if url.path == "/v1/auth/refresh" {
                // Brief pause so concurrent 401 callers overlap in flight.
                Thread.sleep(forTimeInterval: 0.05)
                let callNumber = serverState.withLock { s -> Int in
                    s.refreshCalls += 1
                    return s.refreshCalls
                }
                let rotated = AuthTokenResponse(
                    accessToken: "fresh-access-\(callNumber)",
                    refreshToken: "fresh-refresh-\(callNumber)",
                    tokenType: "Bearer",
                    expiresInSeconds: 3600,
                    user: user
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
                    let envelope = APIErrorEnvelope(code: "token_expired", message: "Access token expired")
                    return (
                        TestFixtures.makeHTTPResponse(url: url, statusCode: 401),
                        try TestFixtures.encodeJSON(envelope)
                    )
                }

                #expect(auth == "Bearer fresh-access-1")
                let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "q" })?.value ?? ""
                let payload = FoodSearchResponse(query: query, items: [], totalCount: 0)
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
        #expect(finalState.searchCalls == 8) // 4 initial 401s + 4 successful retries
        #expect(credentials.accessToken == "fresh-access-1")
        #expect(credentials.refreshToken == "fresh-refresh-1")
    }

    @Test("DELETE /v1/account clears session tokens while preserving stable deviceId")
    func deleteAccountClearsCredentials() async throws {
        let routeID = UUID().uuidString
        defer { ScopedMockURLProtocol.removeHandler(routeID: routeID) }

        let deleteObserved = OSAllocatedUnfairLock(initialState: false)
        let session = ScopedMockURLProtocol.makeSession(routeID: routeID) { request, _ in
            #expect(request.httpMethod == "DELETE")
            #expect(request.url?.path == "/v1/account")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer live-token")
            deleteObserved.withLock { $0 = true }
            return (TestFixtures.makeHTTPResponse(url: request.url!, statusCode: 204), Data())
        }

        let credentials = InMemoryCredentialStore(initialValues: [
            .accessToken: "live-token",
            .refreshToken: "live-refresh",
            .userId: UUID().uuidString,
            .deviceId: "stable-device-id",
            .displayName: "Brian",
            .email: "brian@example.com",
            .isPrivateEmail: "true",
        ])
        let client = NomNomAPIClient(baseURL: baseURL, session: session, credentialStore: credentials)

        try await client.deleteAccount()

        #expect(deleteObserved.withLock { $0 } == true)
        #expect(credentials.accessToken == nil)
        #expect(credentials.refreshToken == nil)
        #expect(credentials.userId == nil)
        #expect(credentials.displayName == nil)
        #expect(credentials.email == nil)
        #expect(credentials.deviceId == "stable-device-id")
    }

    @Test("AI endpoints parse X-AI-Quota-Remaining header and map HTTP 429 quotaExceeded")
    func aiQuotaParsingAnd429ErrorMapping() async throws {
        let routeID = UUID().uuidString
        defer { ScopedMockURLProtocol.removeHandler(routeID: routeID) }

        let sampleResponse = AnalyzeMealResponse(
            suggestedTitle: "Salmon Poke Bowl",
            suggestedMealType: .lunch,
            items: [
                DetectedMealItemDTO(
                    displayName: "Salmon Poke",
                    servingLabel: "1 bowl (~350g)",
                    gramWeight: 350,
                    confidence: 0.88,
                    nutrition: NutritionSnapshot(caloriesKcal: 540, proteinG: 36, carbsG: 52, fatG: 19)
                ),
            ],
            modelUsed: "gemini-3.5-flash-lite",
            latencyMs: 1240
        )

        let session = ScopedMockURLProtocol.makeSession(routeID: routeID) { request, _ in
            let url = request.url!
            if url.path == "/v1/ai/analyze-meal-photo" {
                return (
                    TestFixtures.makeHTTPResponse(
                        url: url,
                        statusCode: 200,
                        headers: ["X-AI-Quota-Remaining": "14"]
                    ),
                    try TestFixtures.encodeJSON(sampleResponse)
                )
            }
            if url.path == "/v1/ai/estimate-meal-text" {
                let envelope = APIErrorEnvelope(
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
                    try TestFixtures.encodeJSON(envelope)
                )
            }
            return (TestFixtures.makeHTTPResponse(url: url, statusCode: 404), Data())
        }

        let credentials = InMemoryCredentialStore(initialValues: [.accessToken: "token-ok"])
        let client = NomNomAPIClient(baseURL: baseURL, session: session, credentialStore: credentials)

        let (analysis, remaining) = try await client.analyzeMealPhoto(
            AnalyzeMealPhotoRequest(imageBase64: "AAAA", mimeType: "image/jpeg", contextHint: "light sauce")
        )
        #expect(analysis.suggestedTitle == "Salmon Poke Bowl")
        #expect(remaining == 14)

        do {
            _ = try await client.estimateMealText(EstimateMealTextRequest(text: "2 eggs and sourdough"))
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
    }

    @Test("Presigned R2 PUT uploads binary image without Authorization header and healthCheck parses /healthz")
    func presignedUploadAndHealthCheck() async throws {
        let routeID = UUID().uuidString
        defer { ScopedMockURLProtocol.removeHandler(routeID: routeID) }

        let uploadedBytes = OSAllocatedUnfairLock<Data?>(initialState: nil)
        let session = ScopedMockURLProtocol.makeSession(routeID: routeID) { request, body in
            let url = request.url!
            if url.path == "/healthz" {
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 200), Data(#"{"status":"ok"}"#.utf8))
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

        // Confirm GPS is present in input image before processing.
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

        // Confirm EXIF GPS dictionary is completely stripped from both derivatives.
        for outputData in [bundle.archival.data, bundle.visionAI.data] {
            let outSource = try #require(CGImageSourceCreateWithData(outputData as CFData, nil))
            let outProps = CGImageSourceCopyPropertiesAtIndex(outSource, 0, nil) as? [CFString: Any]
            #expect(outProps?[kCGImagePropertyGPSDictionary] == nil)
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

    @Test("signOut, presignPhotoUpload, photoDownloadURL, and lookupBarcode wire contracts match NomNomShared")
    func signOutPresignAndBarcodeEndpoints() async throws {
        let routeID = UUID().uuidString
        defer { ScopedMockURLProtocol.removeHandler(routeID: routeID) }

        let photoId = UUID()
        let mealId = UUID()
        let expiry = TestFixtures.fixedDate("2026-11-27T21:00:00Z")
        let barcodeItem = FoodItem(
            name: "Chobani Zero Sugar Vanilla",
            brand: "Chobani",
            barcode: "0894700010045",
            source: .openFoodFacts,
            nutritionPer100g: NutritionSnapshot(caloriesKcal: 40, proteinG: 7.3, carbsG: 2.7, fatG: 0.0),
            servingOptions: [ServingOption(label: "1 cup (150g)", gramWeight: 150, isDefault: true)]
        )

        let session = ScopedMockURLProtocol.makeSession(routeID: routeID) { request, body in
            let url = request.url!
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer live-access")
            switch (request.httpMethod, url.path) {
            case ("POST", "/v1/photos/presign-upload"):
                let req = try NomNomJSON.makeDecoder().decode(PresignUploadRequest.self, from: try #require(body))
                #expect(req.photoId == photoId)
                #expect(req.mealId == mealId)
                let res = PresignUploadResponse(
                    photoId: photoId,
                    r2ObjectKey: "photos/\(photoId.uuidString.lowercased()).heic",
                    uploadUrl: "https://r2.example.invalid/upload/\(photoId.uuidString.lowercased())",
                    expiresAt: expiry
                )
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 200), try TestFixtures.encodeJSON(res))

            case ("GET", "/v1/photos/\(photoId.uuidString.lowercased())/download-url"):
                let res = PhotoDownloadURLResponse(
                    photoId: photoId,
                    r2ObjectKey: "photos/\(photoId.uuidString.lowercased()).heic",
                    downloadUrl: "https://r2.example.invalid/download/\(photoId.uuidString.lowercased())",
                    expiresAt: expiry
                )
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 200), try TestFixtures.encodeJSON(res))

            case ("GET", "/v1/foods/barcode/0894700010045"):
                let res = BarcodeLookupResponse(
                    barcode: "0894700010045",
                    found: true,
                    foodItem: barcodeItem,
                    source: .openFoodFacts,
                    cached: true
                )
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 200), try TestFixtures.encodeJSON(res))

            case ("POST", "/v1/auth/logout"):
                let req = try NomNomJSON.makeDecoder().decode(RefreshTokenRequest.self, from: try #require(body))
                #expect(req.refreshToken == "live-refresh")
                #expect(req.deviceId == "device-mac")
                return (TestFixtures.makeHTTPResponse(url: url, statusCode: 204), Data())

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
                sha256Hash: PureSHA256.hex("photo-data")
            )
        )
        #expect(presign.photoId == photoId)

        let download = try await client.photoDownloadURL(photoId: photoId)
        #expect(download.r2ObjectKey == presign.r2ObjectKey)

        let barcode = try await client.lookupBarcode("0894700010045")
        #expect(barcode.found == true)
        #expect(barcode.foodItem?.name == "Chobani Zero Sugar Vanilla")

        try await client.signOut()
        #expect(credentials.accessToken == nil)
        #expect(credentials.refreshToken == nil)
        #expect(credentials.deviceId == "device-mac")
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
}
