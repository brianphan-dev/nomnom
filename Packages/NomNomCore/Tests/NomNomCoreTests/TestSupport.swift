import CoreGraphics
import Foundation
import ImageIO
import NomNomCore
import NomNomShared
import os
import UniformTypeIdentifiers

/// Concurrency-safe `URLProtocol` routing requests by per-session header (`X-Test-Route-ID`)
/// so parallel Swift Testing suites never interfere with one another.
final class ScopedMockURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest, Data?) throws -> (HTTPURLResponse, Data)

    private static let routeHeader = "X-Test-Route-ID"
    private static let handlers = OSAllocatedUnfairLock<[String: Handler]>(initialState: [:])

    static func makeSession(
        routeID: String = UUID().uuidString,
        handler: @escaping Handler
    ) -> URLSession {
        handlers.withLock { $0[routeID] = handler }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ScopedMockURLProtocol.self]
        config.httpAdditionalHeaders = [routeHeader: routeID]
        return URLSession(configuration: config)
    }

    static func updateHandler(routeID: String, handler: @escaping Handler) {
        handlers.withLock { $0[routeID] = handler }
    }

    static func removeHandler(routeID: String) {
        handlers.withLock { _ = $0.removeValue(forKey: routeID) }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.value(forHTTPHeaderField: routeHeader) != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let routeID = request.value(forHTTPHeaderField: Self.routeHeader),
              let handler = Self.handlers.withLock({ $0[routeID] })
        else {
            client?.urlProtocol(
                self,
                didFailWithError: URLError(.badURL)
            )
            return
        }

        let bodyData = Self.extractBody(from: request)

        do {
            let (response, data) = try handler(request, bodyData)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    private static func extractBody(from request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return nil
        }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            if read > 0 {
                data.append(buffer, count: read)
            } else {
                break
            }
        }
        return data
    }
}

/// Helper generating real JPEG images (optionally tagged with EXIF GPS metadata) for offline media tests.
enum SyntheticImageFactory {
    static func makeJPEG(
        width: Int,
        height: Int,
        includeGPSMetadata: Bool = false
    ) -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            fatalError("Failed to create CGContext")
        }

        context.setFillColor(red: 0.25, green: 0.55, blue: 0.35, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        guard let cgImage = context.makeImage() else {
            fatalError("Failed to create CGImage")
        }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            fatalError("Failed to create CGImageDestination")
        }

        var properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.9,
        ]

        if includeGPSMetadata {
            properties[kCGImagePropertyGPSDictionary] = [
                kCGImagePropertyGPSLatitude: 37.7749,
                kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: 122.4194,
                kCGImagePropertyGPSLongitudeRef: "W",
            ]
        }

        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            fatalError("Failed to finalize synthetic JPEG")
        }
        return mutableData as Data
    }
}

/// Deterministic HealthKit test double tracking authorization, imports, writes, and deletes.
final class MockHealthKitService: HealthKitSyncing {
    struct State: Sendable {
        var isAvailable: Bool
        var authorizationRequestCount: Int = 0
        var importableMeals: [Meal]
        var syncedMeals: [Meal] = []
        var deletedMealIds: [UUID] = []
    }

    private let state: OSAllocatedUnfairLock<State>

    init(isAvailable: Bool = true, importableMeals: [Meal] = []) {
        self.state = OSAllocatedUnfairLock(
            initialState: State(isAvailable: isAvailable, importableMeals: importableMeals)
        )
    }

    var isHealthDataAvailable: Bool {
        state.withLock(\.isAvailable)
    }

    var authorizationRequestCount: Int {
        state.withLock(\.authorizationRequestCount)
    }

    var syncedMeals: [Meal] {
        state.withLock(\.syncedMeals)
    }

    var deletedMealIds: [UUID] {
        state.withLock(\.deletedMealIds)
    }

    func requestAuthorization() async throws {
        state.withLock { $0.authorizationRequestCount += 1 }
    }

    func importMeals(from startDate: Date, to endDate: Date) async throws -> [Meal] {
        state.withLock(\.importableMeals)
    }

    @discardableResult
    func syncMeal(_ meal: Meal) async throws -> String? {
        state.withLock { $0.syncedMeals.append(meal) }
        return meal.id.uuidString
    }

    func deleteSyncedMeal(mealId: UUID) async throws {
        state.withLock { $0.deletedMealIds.append(mealId) }
    }
}

enum TestFixtures {
    static func fixedDate(_ iso: String) -> Date {
        guard let parsed = NomNomJSON.parseISO8601(iso) else {
            fatalError("Invalid fixture date: \(iso)")
        }
        return parsed
    }

    static func makeMeal(
        id: UUID = UUID(),
        localDate: String = "2026-11-27",
        eatenAt: Date? = nil,
        mealType: MealType = .lunch,
        title: String = "Grilled Salmon Bowl",
        calories: Double = 620,
        protein: Double = 42,
        carbs: Double = 55,
        fat: Double = 24,
        captureMethod: CaptureMethod = .photoAI,
        syncSeq: Int64? = nil,
        dedupeFingerprint: String? = nil,
        deletedAt: Date? = nil,
        ingredients: [IngredientEstimate] = []
    ) -> Meal {
        let timestamp = eatenAt ?? fixedDate("\(localDate)T12:30:00Z")
        let item = MealEntryItem(
            mealId: id,
            displayName: title,
            servingLabel: "1 bowl",
            quantity: 1.0,
            gramWeight: 380,
            portionMultiplier: 1.0,
            confidence: 0.91,
            nutrition: NutritionSnapshot(
                caloriesKcal: calories,
                proteinG: protein,
                carbsG: carbs,
                fatG: fat,
                fiberG: 6.5,
                sodiumMg: 480
            ),
            ingredients: ingredients
        )
        return Meal(
            id: id,
            localDate: localDate,
            eatenAt: timestamp,
            timezoneId: "UTC",
            mealType: mealType,
            title: title,
            captureMethod: captureMethod,
            aiStatus: captureMethod == .photoAI ? .analyzed : .none,
            dedupeFingerprint: dedupeFingerprint,
            syncSeq: syncSeq,
            items: [item],
            createdAt: timestamp,
            updatedAt: timestamp,
            deletedAt: deletedAt
        )
    }

    static func makeUser(
        id: UUID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
        displayName: String = "Brian Phan",
        email: String = "brian@privaterelay.appleid.com",
        isPrivateEmail: Bool = true
    ) -> UserProfileDTO {
        UserProfileDTO(
            id: id,
            displayName: displayName,
            email: email,
            isPrivateEmail: isPrivateEmail,
            linkedProviders: [.apple],
            dailyCalorieTarget: 2200,
            dailyProteinTargetG: 165,
            dailyCarbsTargetG: 220,
            dailyFatTargetG: 70,
            createdAt: fixedDate("2026-11-01T00:00:00Z"),
            updatedAt: fixedDate("2026-11-27T00:00:00Z")
        )
    }

    static func makeHTTPResponse(
        url: URL,
        statusCode: Int,
        headers: [String: String] = [:]
    ) -> HTTPURLResponse {
        var allHeaders = ["Content-Type": "application/json"]
        for (k, v) in headers {
            allHeaders[k] = v
        }
        return HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: allHeaders
        )!
    }

    static func encodeJSON<T: Encodable>(_ value: T) throws -> Data {
        try NomNomJSON.makeEncoder().encode(value)
    }
}
