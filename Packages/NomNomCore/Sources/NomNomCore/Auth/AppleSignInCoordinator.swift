import CryptoKit
import Foundation
import NomNomShared
import Security

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Errors & Value Types

public enum AppleSignInError: Error, Sendable, Equatable, LocalizedError {
    case nonceGenerationFailed(Int32)
    case authorizationInProgress
    case missingCredential
    case missingIdentityToken
    case missingAuthorizationCode
    case cancelled
    case authorizationFailed(String)
    case unsupportedPlatform

    public var errorDescription: String? {
        switch self {
        case let .nonceGenerationFailed(status):
            "Failed to generate cryptographic nonce (OSStatus \(status))."
        case .authorizationInProgress:
            "A Sign in with Apple request is already in progress."
        case .missingCredential:
            "Apple authorization did not return an Apple ID credential."
        case .missingIdentityToken:
            "Apple ID credential did not contain a valid UTF-8 identity token."
        case .missingAuthorizationCode:
            "Apple ID credential did not contain a valid UTF-8 authorization code."
        case .cancelled:
            "Sign in with Apple was cancelled."
        case let .authorizationFailed(message):
            "Sign in with Apple failed: \(message)"
        case .unsupportedPlatform:
            "Sign in with Apple is unavailable on this platform."
        }
    }
}

/// Cryptographic nonce pair sent to Apple (`sha256Hex`) and verified by the backend (`rawNonce`).
public struct AppleNoncePair: Sendable, Equatable {
    public let rawNonce: String
    public let sha256Hex: String

    public init(rawNonce: String, sha256Hex: String) {
        self.rawNonce = rawNonce
        self.sha256Hex = sha256Hex
    }
}

/// Generates 32-byte cryptographically random nonces and lowercase hex SHA-256 digests using CryptoKit.
public enum AppleNonceGenerator: Sendable {
    public static let defaultByteCount = 32

    public static func generate(byteCount: Int = defaultByteCount) throws -> AppleNoncePair {
        let count = max(16, byteCount)
        var randomBytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &randomBytes)
        guard status == errSecSuccess else {
            throw AppleSignInError.nonceGenerationFailed(status)
        }

        // URL-safe base64 without padding preserves full entropy in clean ASCII characters.
        let rawNonce = Data(randomBytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        return AppleNoncePair(
            rawNonce: rawNonce,
            sha256Hex: sha256Hex(rawNonce)
        )
    }

    public static func sha256Hex(_ rawNonce: String) -> String {
        let digest = SHA256.hash(data: Data(rawNonce.utf8))
        return digest.map { byte in
            let high = byte >> 4
            let low = byte & 0x0F
            return String(Self.hexDigits[Int(high)]) + String(Self.hexDigits[Int(low)])
        }.joined()
    }

    private static let hexDigits: [Character] = Array("0123456789abcdef")
}

/// Full result returned by Sign in with Apple, containing both the backend wire request
/// and the opaque Apple user ID for credential state monitoring.
public struct AppleSignInResult: Sendable, Equatable {
    public let request: AppleAuthRequest
    public let appleUserId: String
    public let email: String?
    public let hashedNonce: String

    public init(
        request: AppleAuthRequest,
        appleUserId: String,
        email: String?,
        hashedNonce: String
    ) {
        self.request = request
        self.appleUserId = appleUserId
        self.email = email
        self.hashedNonce = hashedNonce
    }
}

/// Platform-neutral mirror of `ASAuthorizationAppleIDProvider.CredentialState`.
public enum AppleCredentialState: String, Sendable, Equatable {
    case authorized
    case revoked
    case notFound
    case transferred
}

// MARK: - Sign in with Apple Coordinator

#if canImport(AuthenticationServices)

@MainActor
public final class AppleSignInCoordinator: NSObject {
    private struct ActiveFlow {
        let continuation: CheckedContinuation<AppleSignInResult, Error>
        let nonce: AppleNoncePair
        let deviceId: String
        let deviceName: String?
        let anchor: ASPresentationAnchor?
    }

    private var activeFlow: ActiveFlow?
    private var activeController: ASAuthorizationController?

    public override init() {
        super.init()
    }

    /// Creates a configured `ASAuthorizationAppleIDRequest` with `[.fullName, .email]` scopes
    /// and a fresh 32-byte random nonce hashed via SHA-256.
    public func prepareRequest() throws -> (request: ASAuthorizationAppleIDRequest, nonce: AppleNoncePair) {
        let nonce = try AppleNonceGenerator.generate()
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = nonce.sha256Hex
        return (request, nonce)
    }

    /// Runs the native Sign in with Apple flow and returns an `AppleAuthRequest` ready for `POST /v1/auth/apple`.
    public func signIn(
        deviceId: String,
        deviceName: String? = nil,
        presentationAnchor: ASPresentationAnchor? = nil
    ) async throws -> AppleAuthRequest {
        let result = try await signInWithResult(
            deviceId: deviceId,
            deviceName: deviceName,
            presentationAnchor: presentationAnchor
        )
        return result.request
    }

    /// Runs the native Sign in with Apple flow and returns both the `AppleAuthRequest` and Apple user metadata.
    public func signInWithResult(
        deviceId: String,
        deviceName: String? = nil,
        presentationAnchor: ASPresentationAnchor? = nil
    ) async throws -> AppleSignInResult {
        guard activeFlow == nil else {
            throw AppleSignInError.authorizationInProgress
        }

        let (request, nonce) = try prepareRequest()
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        return try await withCheckedThrowingContinuation { continuation in
            self.activeFlow = ActiveFlow(
                continuation: continuation,
                nonce: nonce,
                deviceId: deviceId,
                deviceName: deviceName ?? Self.defaultDeviceName(),
                anchor: presentationAnchor
            )
            self.activeController = controller
            controller.performRequests()
        }
    }

    /// Pure request builder usable from SwiftUI `SignInWithAppleButton` completion handlers and unit tests.
    public nonisolated static func buildAuthRequest(
        identityTokenData: Data?,
        authorizationCodeData: Data?,
        rawNonce: String,
        fullName: PersonNameComponents?,
        deviceId: String,
        deviceName: String? = nil
    ) throws -> AppleAuthRequest {
        guard let identityTokenData,
              let identityToken = String(data: identityTokenData, encoding: .utf8),
              !identityToken.isEmpty
        else {
            throw AppleSignInError.missingIdentityToken
        }

        guard let authorizationCodeData,
              let authorizationCode = String(data: authorizationCodeData, encoding: .utf8),
              !authorizationCode.isEmpty
        else {
            throw AppleSignInError.missingAuthorizationCode
        }

        let givenName = fullName?.givenName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let familyName = fullName?.familyName?.trimmingCharacters(in: .whitespacesAndNewlines)

        return AppleAuthRequest(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            rawNonce: rawNonce,
            givenName: (givenName?.isEmpty == false) ? givenName : nil,
            familyName: (familyName?.isEmpty == false) ? familyName : nil,
            deviceId: deviceId,
            deviceName: deviceName
        )
    }

    /// Extracts an `AppleSignInResult` from a completed `ASAuthorization` object.
    public nonisolated static func extractSignInResult(
        from authorization: ASAuthorization,
        nonce: AppleNoncePair,
        deviceId: String,
        deviceName: String? = nil
    ) throws -> AppleSignInResult {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AppleSignInError.missingCredential
        }

        let request = try buildAuthRequest(
            identityTokenData: credential.identityToken,
            authorizationCodeData: credential.authorizationCode,
            rawNonce: nonce.rawNonce,
            fullName: credential.fullName,
            deviceId: deviceId,
            deviceName: deviceName
        )

        return AppleSignInResult(
            request: request,
            appleUserId: credential.user,
            email: credential.email,
            hashedNonce: nonce.sha256Hex
        )
    }

    private static func defaultDeviceName() -> String {
        #if canImport(UIKit)
        return UIDevice.current.name
        #elseif os(macOS)
        return Host.current().localizedName ?? "Mac"
        #else
        return "Apple Device"
        #endif
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let flow = activeFlow else { return }
        activeFlow = nil
        activeController = nil

        do {
            let result = try Self.extractSignInResult(
                from: authorization,
                nonce: flow.nonce,
                deviceId: flow.deviceId,
                deviceName: flow.deviceName
            )
            flow.continuation.resume(returning: result)
        } catch {
            flow.continuation.resume(throwing: error)
        }
    }

    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: any Error
    ) {
        guard let flow = activeFlow else { return }
        activeFlow = nil
        activeController = nil

        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            flow.continuation.resume(throwing: AppleSignInError.cancelled)
        } else {
            flow.continuation.resume(throwing: AppleSignInError.authorizationFailed(error.localizedDescription))
        }
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let explicitAnchor = activeFlow?.anchor {
            return explicitAnchor
        }

        #if canImport(UIKit)
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let keyWindow = scenes
            .filter({ $0.activationState == .foregroundActive })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        {
            return keyWindow
        }
        if let anyWindow = scenes.flatMap(\.windows).first {
            return anyWindow
        }
        return UIWindow()
        #elseif canImport(AppKit)
        if let keyWindow = NSApplication.shared.keyWindow {
            return keyWindow
        }
        if let firstWindow = NSApplication.shared.windows.first {
            return firstWindow
        }
        return NSWindow()
        #endif
    }
}

// MARK: - Credential State Monitor

/// Monitors Sign in with Apple credential validity and revocation notifications.
public final class AppleCredentialStateMonitor: Sendable {
    private let notificationCenter: NotificationCenter

    public init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    /// Queries Apple for the current credential state of an opaque Apple user ID.
    public func checkCredentialState(forUserID userID: String) async throws -> AppleCredentialState {
        try await withCheckedThrowingContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let mapped: AppleCredentialState = switch state {
                case .authorized: .authorized
                case .revoked: .revoked
                case .notFound: .notFound
                case .transferred: .transferred
                @unknown default: .notFound
                }
                continuation.resume(returning: mapped)
            }
        }
    }

    /// Returns an `AsyncStream` that yields whenever `ASAuthorizationAppleIDProvider.credentialRevokedNotification` fires.
    public func revocationStream() -> AsyncStream<Void> {
        let center = notificationCenter
        return AsyncStream { continuation in
            let box = RevocationObserverBox(center: center) {
                continuation.yield(())
            }
            continuation.onTermination = { _ in
                box.invalidate()
            }
        }
    }
}

private final class RevocationObserverBox: @unchecked Sendable {
    private let lock = NSLock()
    private var token: (any NSObjectProtocol)?
    private let center: NotificationCenter

    init(center: NotificationCenter, onFire: @escaping @Sendable () -> Void) {
        self.center = center
        self.token = center.addObserver(
            forName: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
            object: nil,
            queue: nil
        ) { _ in
            onFire()
        }
    }

    func invalidate() {
        lock.lock()
        let observer = token
        token = nil
        lock.unlock()
        if let observer {
            center.removeObserver(observer)
        }
    }

    deinit {
        invalidate()
    }
}

#else

/// Fallback monitor when AuthenticationServices is unavailable.
public final class AppleCredentialStateMonitor: Sendable {
    public init() {}

    public func checkCredentialState(forUserID userID: String) async throws -> AppleCredentialState {
        throw AppleSignInError.unsupportedPlatform
    }

    public func revocationStream() -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
}

#endif
