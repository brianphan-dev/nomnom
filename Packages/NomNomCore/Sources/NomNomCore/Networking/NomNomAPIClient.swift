import Foundation
import NomNomShared

// MARK: - API Errors

public enum NomNomAPIError: Error, Sendable, Equatable, LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case missingAccessToken
    case missingRefreshToken
    case unauthorized(APIErrorEnvelope?)
    case forbidden(APIErrorEnvelope?)
    case notFound(APIErrorEnvelope?)
    case quotaExceeded(quotaRemaining: Int, retryAfterSeconds: Int?, message: String)
    case clientError(statusCode: Int, envelope: APIErrorEnvelope?)
    case serverError(statusCode: Int, envelope: APIErrorEnvelope?)
    case decodingFailed(String)
    case transportError(code: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case let .invalidURL(raw):
            "Invalid API URL: \(raw)"
        case .invalidResponse:
            "Received a non-HTTP response from the server."
        case .missingAccessToken:
            "Authentication required: no access token is stored."
        case .missingRefreshToken:
            "Session expired: no refresh token is available."
        case let .unauthorized(envelope):
            envelope?.message ?? "Your session has expired. Please sign in again."
        case let .forbidden(envelope):
            envelope?.message ?? "You do not have permission to perform this action."
        case let .notFound(envelope):
            envelope?.message ?? "The requested resource was not found."
        case let .quotaExceeded(_, _, message):
            message
        case let .clientError(statusCode, envelope):
            envelope?.message ?? "Request failed with HTTP \(statusCode)."
        case let .serverError(statusCode, envelope):
            envelope?.message ?? "Server error (HTTP \(statusCode))."
        case let .decodingFailed(reason):
            "Failed to decode server response: \(reason)"
        case let .transportError(_, message):
            message
        }
    }

    public var isConnectivityFailure: Bool {
        guard case let .transportError(code, _) = self else { return false }
        let offlineCodes: Set<Int> = [
            URLError.notConnectedToInternet.rawValue,
            URLError.networkConnectionLost.rawValue,
            URLError.cannotConnectToHost.rawValue,
            URLError.cannotFindHost.rawValue,
            URLError.dnsLookupFailed.rawValue,
            URLError.timedOut.rawValue,
            URLError.dataNotAllowed.rawValue,
            URLError.internationalRoamingOff.rawValue,
        ]
        return offlineCodes.contains(code)
    }
}

// MARK: - API Client Protocol

public protocol NomNomAPIClientProtocol: Sendable {
    func getBaseURL() async -> URL
    func setBaseURL(_ url: URL) async
    func healthCheck() async throws -> Bool
    func signInWithApple(_ request: AppleAuthRequest) async throws -> AuthTokenResponse
    func refreshSession() async throws -> AuthTokenResponse
    func signOut() async throws
    func deleteAccount() async throws
    func pushSync(_ request: SyncPushRequest) async throws -> SyncPushResponse
    func fetchSyncChanges(afterSeq: Int64, limit: Int) async throws -> SyncChangesResponse
    func presignPhotoUpload(_ request: PresignUploadRequest) async throws -> PresignUploadResponse
    func uploadPhotoToPresignedURL(_ url: URL, data: Data, contentType: String) async throws
    func photoDownloadURL(photoId: UUID) async throws -> PhotoDownloadURLResponse
    func analyzeMealPhoto(_ request: AnalyzeMealPhotoRequest) async throws -> (AnalyzeMealResponse, quotaRemaining: Int?)
    func estimateMealText(_ request: EstimateMealTextRequest) async throws -> (AnalyzeMealResponse, quotaRemaining: Int?)
    func lookupBarcode(_ gtin: String) async throws -> BarcodeLookupResponse
    func searchFoods(query: String) async throws -> FoodSearchResponse
}

// MARK: - Actor API Client

/// Offline-aware, Swift 6 actor HTTP client communicating with the deployed nomnom VPS API.
/// Preserves clean `NomNomShared` Swift signatures while encoding/decoding the exact server wire
/// format via `ServerWireAdapter`, with automatic Bearer injection and single-flight HTTP 401 refresh.
public actor NomNomAPIClient: NomNomAPIClientProtocol {
    public static let defaultBaseURL = URL(string: "https://api.nomnom.brianphan.dev")!

    private var baseURL: URL
    private let session: URLSession
    private let credentialStore: any SessionCredentialStore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var inFlightRefreshTask: Task<AuthTokenResponse, Error>?

    public init(
        baseURL: URL = NomNomAPIClient.defaultBaseURL,
        session: URLSession = .shared,
        credentialStore: any SessionCredentialStore = KeychainStore()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.credentialStore = credentialStore
        self.encoder = NomNomJSON.makeEncoder()
        self.decoder = NomNomJSON.makeDecoder()
    }

    public func getBaseURL() -> URL {
        baseURL
    }

    public func setBaseURL(_ url: URL) {
        baseURL = url
    }

    // MARK: - Health

    public func healthCheck() async throws -> Bool {
        let url = try makeURL(path: "/healthz")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (_, response) = try await executeRaw(request)
        return (200..<300).contains(response.statusCode)
    }

    // MARK: - Auth

    public func signInWithApple(_ body: AppleAuthRequest) async throws -> AuthTokenResponse {
        let wireBody = ServerWireAdapter.toServerAppleAuthRequest(body)
        let (wireResponse, _): (ServerWireAdapter.ServerAuthSessionResponse, HTTPURLResponse) =
            try await sendUnauthenticated(
                method: "POST",
                path: "/v1/auth/apple",
                body: wireBody
            )
        let response = ServerWireAdapter.toDomainAuthTokenResponse(wireResponse)
        try credentialStore.saveAuthSession(response)
        return response
    }

    /// Rotates the current refresh token via `POST /v1/auth/refresh`.
    /// Concurrent callers share a single in-flight refresh network call.
    public func refreshSession() async throws -> AuthTokenResponse {
        try await coalesceRefresh(afterRejectedAccessToken: nil)
    }

    public func signOut() async throws {
        let payload = ServerWireAdapter.ServerLogoutRequest(refreshToken: credentialStore.refreshToken)
        if let accessToken = credentialStore.accessToken, !accessToken.isEmpty {
            _ = try await executeAuthenticatedWithRetry(
                method: "POST",
                path: "/v1/auth/logout",
                queryItems: [],
                body: payload
            )
        } else {
            let request = try buildRequest(
                method: "POST",
                path: "/v1/auth/logout",
                queryItems: [],
                body: payload,
                accessToken: nil
            )
            let (data, httpResponse) = try await executeRaw(request)
            try validateStatusCode(httpResponse: httpResponse, data: data)
        }

        try credentialStore.clearSession()
    }

    public func deleteAccount() async throws {
        _ = try await deleteAccountWithReceipt()
    }

    /// Permanently deletes the account via `DELETE /v1/account`, returning the server's
    /// Apple token revocation receipt when present (Guideline 5.1.1(v) / TN3194).
    public func deleteAccountWithReceipt() async throws -> ServerWireAdapter.ServerAccountDeletionResponse? {
        let (data, httpResponse) = try await executeAuthenticatedWithRetry(
            method: "DELETE",
            path: "/v1/account",
            queryItems: [],
            body: EmptyBody?.none
        )

        var receipt: ServerWireAdapter.ServerAccountDeletionResponse?
        if !data.isEmpty {
            let decoded = try decode(ServerWireAdapter.ServerAccountDeletionResponse.self, from: data)
            guard decoded.deleted else {
                throw NomNomAPIError.serverError(
                    statusCode: httpResponse.statusCode,
                    envelope: APIErrorEnvelope(
                        code: "account_deletion_incomplete",
                        message: "Server did not confirm account deletion."
                    )
                )
            }
            receipt = decoded
        }

        try credentialStore.clearSession()
        return receipt
    }

    // MARK: - Sync

    public func pushSync(_ request: SyncPushRequest) async throws -> SyncPushResponse {
        guard let wireRequest = ServerWireAdapter.toServerSyncPushRequest(request) else {
            // Only non-meal local mutations were present; acknowledge cleanly without a remote call.
            let acks = request.mutations.map { mutation in
                SyncMutationAck(
                    mutationId: mutation.mutationId,
                    entityType: mutation.entityType,
                    entityId: mutation.entityId,
                    status: .applied,
                    syncSeq: nil
                )
            }
            return SyncPushResponse(
                acceptedCount: acks.count,
                latestSyncSeq: 0,
                results: acks,
                serverTime: Date()
            )
        }

        let (wireResponse, _): (ServerWireAdapter.ServerSyncPushResponse, HTTPURLResponse) =
            try await sendAuthenticated(
                method: "POST",
                path: "/v1/sync/push",
                body: wireRequest
            )
        return ServerWireAdapter.toDomainSyncPushResponse(
            wireResponse,
            originalMutations: request.mutations
        )
    }

    public func fetchSyncChanges(afterSeq: Int64, limit: Int = 200) async throws -> SyncChangesResponse {
        let queryItems = [
            URLQueryItem(name: "after_seq", value: String(afterSeq)),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        let (wireResponse, _): (ServerWireAdapter.ServerSyncChangesResponse, HTTPURLResponse) =
            try await sendAuthenticated(
                method: "GET",
                path: "/v1/sync/changes",
                queryItems: queryItems,
                body: EmptyBody?.none
            )
        return ServerWireAdapter.toDomainSyncChangesResponse(wireResponse, sinceSeq: afterSeq)
    }

    // MARK: - Photos

    public func presignPhotoUpload(_ request: PresignUploadRequest) async throws -> PresignUploadResponse {
        let wireBody = ServerWireAdapter.toServerPresignUploadRequest(request)
        let (wireResponse, _): (ServerWireAdapter.ServerPhotoPresignUploadResponse, HTTPURLResponse) =
            try await sendAuthenticated(
                method: "POST",
                path: "/v1/photos/presign-upload",
                body: wireBody
            )
        return ServerWireAdapter.toDomainPresignUploadResponse(wireResponse)
    }

    public func uploadPhotoToPresignedURL(_ url: URL, data: Data, contentType: String) async throws {
        try await uploadPhotoToPresignedURL(url, data: data, contentType: contentType, extraHeaders: [:])
    }

    public func uploadPhotoToPresignedURL(
        _ url: URL,
        data: Data,
        contentType: String,
        extraHeaders: [String: String]
    ) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
        for (header, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: header)
        }
        request.httpBody = data

        let (responseData, httpResponse) = try await executeRaw(request)
        try validateStatusCode(httpResponse: httpResponse, data: responseData)
    }

    public func photoDownloadURL(photoId: UUID) async throws -> PhotoDownloadURLResponse {
        let (wireResponse, _): (ServerWireAdapter.ServerPhotoDownloadURLResponse, HTTPURLResponse) =
            try await sendAuthenticated(
                method: "GET",
                path: "/v1/photos/\(photoId.uuidString.lowercased())/url",
                body: EmptyBody?.none
            )
        return ServerWireAdapter.toDomainPhotoDownloadURLResponse(wireResponse)
    }

    // MARK: - AI Analysis

    public func analyzeMealPhoto(
        _ request: AnalyzeMealPhotoRequest
    ) async throws -> (AnalyzeMealResponse, quotaRemaining: Int?) {
        let wireBody = ServerWireAdapter.toServerAnalyzeMealPhotoRequest(request)
        let (wireResponse, httpResponse): (ServerWireAdapter.ServerAIMealAnalysisResponse, HTTPURLResponse) =
            try await sendAuthenticated(
                method: "POST",
                path: "/v1/ai/analyze-meal-photo",
                body: wireBody
            )
        let domainResponse = ServerWireAdapter.toDomainAnalyzeMealResponse(wireResponse)
        let quotaRemaining = parseQuotaRemaining(from: httpResponse) ?? wireResponse.quotaRemaining
        return (domainResponse, quotaRemaining)
    }

    public func estimateMealText(
        _ request: EstimateMealTextRequest
    ) async throws -> (AnalyzeMealResponse, quotaRemaining: Int?) {
        let wireBody = ServerWireAdapter.toServerEstimateMealTextRequest(request)
        let (wireResponse, httpResponse): (ServerWireAdapter.ServerAIMealAnalysisResponse, HTTPURLResponse) =
            try await sendAuthenticated(
                method: "POST",
                path: "/v1/ai/estimate-meal-text",
                body: wireBody
            )
        let domainResponse = ServerWireAdapter.toDomainAnalyzeMealResponse(wireResponse)
        let quotaRemaining = parseQuotaRemaining(from: httpResponse) ?? wireResponse.quotaRemaining
        return (domainResponse, quotaRemaining)
    }

    // MARK: - Food & Barcode Lookup

    public func lookupBarcode(_ gtin: String) async throws -> BarcodeLookupResponse {
        let cleaned = gtin.trimmingCharacters(in: .whitespacesAndNewlines)
        let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cleaned
        do {
            let (wireFood, _): (ServerWireAdapter.ServerFoodItemDTO, HTTPURLResponse) =
                try await sendAuthenticated(
                    method: "GET",
                    path: "/v1/foods/barcode/\(encoded)",
                    body: EmptyBody?.none
                )
            return ServerWireAdapter.toDomainBarcodeLookupResponse(wireFood, requestedGTIN: cleaned)
        } catch NomNomAPIError.notFound {
            return BarcodeLookupResponse(
                barcode: cleaned,
                found: false,
                foodItem: nil,
                source: nil,
                cached: false
            )
        }
    }

    public func searchFoods(query: String) async throws -> FoodSearchResponse {
        let queryItems = [
            URLQueryItem(name: "q", value: query),
        ]
        let (wireResponse, _): (ServerWireAdapter.ServerFoodSearchResponse, HTTPURLResponse) =
            try await sendAuthenticated(
                method: "GET",
                path: "/v1/foods/search",
                queryItems: queryItems,
                body: EmptyBody?.none
            )
        return ServerWireAdapter.toDomainFoodSearchResponse(wireResponse)
    }

    // MARK: - Internal Transport & Single-Flight Refresh

    private struct EmptyBody: Encodable {}

    private func coalesceRefresh(afterRejectedAccessToken rejectedToken: String?) async throws -> AuthTokenResponse {
        if let existingTask = inFlightRefreshTask {
            return try await existingTask.value
        }

        // If another request just finished rotating the access token while we were awaiting
        // our 401 response, avoid triggering a duplicate rotation with a stale refresh token.
        if let rejectedToken,
           let currentToken = credentialStore.accessToken,
           !currentToken.isEmpty,
           currentToken != rejectedToken
        {
            return AuthTokenResponse(
                accessToken: currentToken,
                refreshToken: credentialStore.refreshToken ?? "",
                tokenType: "Bearer",
                expiresInSeconds: 0,
                user: UserProfileDTO(
                    id: credentialStore.userId.flatMap(UUID.init(uuidString:)) ?? UUID(),
                    displayName: credentialStore.displayName,
                    email: credentialStore.email,
                    isPrivateEmail: credentialStore.isPrivateEmail
                )
            )
        }

        guard let refreshToken = credentialStore.refreshToken, !refreshToken.isEmpty else {
            throw NomNomAPIError.missingRefreshToken
        }
        let deviceId = try credentialStore.getOrCreateDeviceId()

        let task = Task<AuthTokenResponse, Error> {
            defer { self.inFlightRefreshTask = nil }
            let wirePayload = ServerWireAdapter.ServerRefreshTokenRequest(
                refreshToken: refreshToken,
                deviceID: deviceId
            )
            let (wireRefreshed, _): (ServerWireAdapter.ServerAuthSessionResponse, HTTPURLResponse) =
                try await self.sendUnauthenticated(
                    method: "POST",
                    path: "/v1/auth/refresh",
                    body: wirePayload
                )
            let refreshed = ServerWireAdapter.toDomainAuthTokenResponse(wireRefreshed)
            try self.credentialStore.saveAuthSession(refreshed)
            return refreshed
        }

        inFlightRefreshTask = task
        return try await task.value
    }

    private func sendUnauthenticated<Body: Encodable, Response: Decodable>(
        method: String,
        path: String,
        queryItems: [URLQueryItem] = [],
        body: Body?
    ) async throws -> (Response, HTTPURLResponse) {
        let request = try buildRequest(
            method: method,
            path: path,
            queryItems: queryItems,
            body: body,
            accessToken: nil
        )
        let (data, httpResponse) = try await executeRaw(request)
        try validateStatusCode(httpResponse: httpResponse, data: data)
        let decoded = try decode(Response.self, from: data)
        return (decoded, httpResponse)
    }

    private func sendAuthenticated<Body: Encodable, Response: Decodable>(
        method: String,
        path: String,
        queryItems: [URLQueryItem] = [],
        body: Body?
    ) async throws -> (Response, HTTPURLResponse) {
        let (data, httpResponse) = try await executeAuthenticatedWithRetry(
            method: method,
            path: path,
            queryItems: queryItems,
            body: body
        )
        let decoded = try decode(Response.self, from: data)
        return (decoded, httpResponse)
    }

    private func executeAuthenticatedWithRetry<Body: Encodable>(
        method: String,
        path: String,
        queryItems: [URLQueryItem],
        body: Body?
    ) async throws -> (Data, HTTPURLResponse) {
        let initialToken: String
        if let stored = credentialStore.accessToken, !stored.isEmpty {
            initialToken = stored
        } else if credentialStore.refreshToken != nil {
            let refreshed = try await coalesceRefresh(afterRejectedAccessToken: nil)
            initialToken = refreshed.accessToken
        } else {
            throw NomNomAPIError.missingAccessToken
        }

        let firstRequest = try buildRequest(
            method: method,
            path: path,
            queryItems: queryItems,
            body: body,
            accessToken: initialToken
        )

        let (firstData, firstResponse) = try await executeRaw(firstRequest)
        if firstResponse.statusCode != 401 {
            try validateStatusCode(httpResponse: firstResponse, data: firstData)
            return (firstData, firstResponse)
        }

        // Single-flight refresh and retry exactly once.
        let refreshed: AuthTokenResponse
        do {
            refreshed = try await coalesceRefresh(afterRejectedAccessToken: initialToken)
        } catch NomNomAPIError.missingRefreshToken {
            throw NomNomAPIError.unauthorized(decodeEnvelope(from: firstData))
        }

        let retryRequest = try buildRequest(
            method: method,
            path: path,
            queryItems: queryItems,
            body: body,
            accessToken: refreshed.accessToken
        )
        let (retryData, retryResponse) = try await executeRaw(retryRequest)
        try validateStatusCode(httpResponse: retryResponse, data: retryData)
        return (retryData, retryResponse)
    }

    private func buildRequest<Body: Encodable>(
        method: String,
        path: String,
        queryItems: [URLQueryItem],
        body: Body?,
        accessToken: String?
    ) throws -> URLRequest {
        let url = try makeURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }
        return request
    }

    private func makeURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw NomNomAPIError.invalidURL(baseURL.absoluteString)
        }
        let normalizedBase = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        components.path = normalizedBase + normalizedPath
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw NomNomAPIError.invalidURL(normalizedBase + normalizedPath)
        }
        return url
    }

    private func executeRaw(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw NomNomAPIError.transportError(
                code: urlError.errorCode,
                message: urlError.localizedDescription
            )
        } catch {
            throw NomNomAPIError.transportError(
                code: (error as NSError).code,
                message: error.localizedDescription
            )
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NomNomAPIError.invalidResponse
        }
        return (data, httpResponse)
    }

    private func validateStatusCode(httpResponse: HTTPURLResponse, data: Data) throws {
        let status = httpResponse.statusCode
        if (200..<300).contains(status) {
            return
        }

        let envelope = decodeEnvelope(from: data)
        switch status {
        case 401:
            throw NomNomAPIError.unauthorized(envelope)
        case 403:
            throw NomNomAPIError.forbidden(envelope)
        case 404:
            throw NomNomAPIError.notFound(envelope)
        case 429:
            let remaining = parseQuotaRemaining(from: httpResponse) ?? 0
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
            let message = envelope?.message ?? "Daily AI analysis quota reached. Barcode and manual entry remain unlimited."
            throw NomNomAPIError.quotaExceeded(
                quotaRemaining: remaining,
                retryAfterSeconds: retryAfter,
                message: message
            )
        case 400..<500:
            throw NomNomAPIError.clientError(statusCode: status, envelope: envelope)
        default:
            throw NomNomAPIError.serverError(statusCode: status, envelope: envelope)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw NomNomAPIError.decodingFailed(String(describing: error))
        }
    }

    private func decodeEnvelope(from data: Data) -> APIErrorEnvelope? {
        ServerWireAdapter.decodeErrorEnvelope(from: data, decoder: decoder)
    }

    private func parseQuotaRemaining(from response: HTTPURLResponse) -> Int? {
        guard let raw = response.value(forHTTPHeaderField: "X-AI-Quota-Remaining") else {
            return nil
        }
        return Int(raw.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
