import Foundation
import NomNomShared
import os
import Security

/// Keys persisted in the device Keychain for authenticated user sessions.
public enum CredentialKey: String, CaseIterable, Sendable {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case userId = "user_id"
    case deviceId = "device_id"
    case displayName = "display_name"
    case email = "email"
    case isPrivateEmail = "is_private_email"
    case appleUserId = "apple_user_id"

    /// Keys removed when signing out or deleting an account.
    /// `deviceId` is intentionally preserved so the device retains a stable identity.
    public static let sessionKeys: [CredentialKey] = [
        .accessToken,
        .refreshToken,
        .userId,
        .displayName,
        .email,
        .isPrivateEmail,
        .appleUserId,
    ]
}

public enum KeychainStoreError: Error, Sendable, Equatable, LocalizedError {
    case osStatus(Int32)
    case invalidUTF8Data

    public var errorDescription: String? {
        switch self {
        case let .osStatus(status):
            "Keychain operation failed with OSStatus \(status)."
        case .invalidUTF8Data:
            "Keychain item contained non-UTF8 bytes."
        }
    }
}

/// Point-in-time snapshot of credentials stored on device.
public struct StoredSessionCredentials: Codable, Sendable, Equatable {
    public var accessToken: String?
    public var refreshToken: String?
    public var userId: String?
    public var deviceId: String?
    public var displayName: String?
    public var email: String?
    public var isPrivateEmail: Bool
    public var appleUserId: String?

    public var isSignedIn: Bool {
        guard let accessToken, !accessToken.isEmpty,
              let refreshToken, !refreshToken.isEmpty,
              let userId, !userId.isEmpty
        else {
            return false
        }
        return true
    }

    public init(
        accessToken: String? = nil,
        refreshToken: String? = nil,
        userId: String? = nil,
        deviceId: String? = nil,
        displayName: String? = nil,
        email: String? = nil,
        isPrivateEmail: Bool = false,
        appleUserId: String? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userId = userId
        self.deviceId = deviceId
        self.displayName = displayName
        self.email = email
        self.isPrivateEmail = isPrivateEmail
        self.appleUserId = appleUserId
    }
}

/// Persistence contract for session tokens and user identity metadata.
public protocol SessionCredentialStore: Sendable {
    func string(for key: CredentialKey) throws -> String?
    func set(_ value: String?, for key: CredentialKey) throws
    func clearSession() throws
}

public extension SessionCredentialStore {
    var accessToken: String? {
        try? string(for: .accessToken)
    }

    var refreshToken: String? {
        try? string(for: .refreshToken)
    }

    var userId: String? {
        try? string(for: .userId)
    }

    var deviceId: String? {
        try? string(for: .deviceId)
    }

    var displayName: String? {
        try? string(for: .displayName)
    }

    var email: String? {
        try? string(for: .email)
    }

    var isPrivateEmail: Bool {
        (try? string(for: .isPrivateEmail)) == "true"
    }

    var appleUserId: String? {
        try? string(for: .appleUserId)
    }

    func setAccessToken(_ token: String?) throws {
        try set(token, for: .accessToken)
    }

    func setRefreshToken(_ token: String?) throws {
        try set(token, for: .refreshToken)
    }

    func setUserId(_ userId: String?) throws {
        try set(userId, for: .userId)
    }

    func setDeviceId(_ deviceId: String?) throws {
        try set(deviceId, for: .deviceId)
    }

    func setDisplayName(_ displayName: String?) throws {
        try set(displayName, for: .displayName)
    }

    func setEmail(_ email: String?) throws {
        try set(email, for: .email)
    }

    func setIsPrivateEmail(_ isPrivate: Bool) throws {
        try set(isPrivate ? "true" : "false", for: .isPrivateEmail)
    }

    func setAppleUserId(_ appleUserId: String?) throws {
        try set(appleUserId, for: .appleUserId)
    }

    /// Returns an existing persistent device identifier or creates and stores a new UUID.
    func getOrCreateDeviceId() throws -> String {
        if let existing = try string(for: .deviceId), !existing.isEmpty {
            return existing
        }
        let generated = UUID().uuidString.lowercased()
        try set(generated, for: .deviceId)
        return generated
    }

    /// Atomically writes all tokens and user profile attributes from an authentication response.
    func saveAuthSession(_ response: AuthTokenResponse, appleUserId: String? = nil) throws {
        try set(response.accessToken, for: .accessToken)
        try set(response.refreshToken, for: .refreshToken)
        try set(response.user.id.uuidString, for: .userId)
        if let displayName = response.user.displayName {
            try set(displayName, for: .displayName)
        }
        if let email = response.user.email {
            try set(email, for: .email)
        }
        try set(response.user.isPrivateEmail ? "true" : "false", for: .isPrivateEmail)
        if let appleUserId {
            try set(appleUserId, for: .appleUserId)
        }
    }

    func loadCredentials() throws -> StoredSessionCredentials {
        StoredSessionCredentials(
            accessToken: try string(for: .accessToken),
            refreshToken: try string(for: .refreshToken),
            userId: try string(for: .userId),
            deviceId: try string(for: .deviceId),
            displayName: try string(for: .displayName),
            email: try string(for: .email),
            isPrivateEmail: (try string(for: .isPrivateEmail)) == "true",
            appleUserId: try string(for: .appleUserId)
        )
    }

    func clearSession() throws {
        for key in CredentialKey.sessionKeys {
            try set(nil, for: key)
        }
    }
}

/// Production Keychain credential store backed by Apple Security framework using
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
public struct KeychainStore: SessionCredentialStore {
    public let service: String
    public let accessGroup: String?

    public init(
        service: String = "dev.brianphan.nomnom.session",
        accessGroup: String? = nil
    ) {
        self.service = service
        self.accessGroup = accessGroup
    }

    public func string(for key: CredentialKey) throws -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let decoded = String(data: data, encoding: .utf8)
            else {
                throw KeychainStoreError.invalidUTF8Data
            }
            return decoded
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainStoreError.osStatus(status)
        }
    }

    public func set(_ value: String?, for key: CredentialKey) throws {
        let query = baseQuery(for: key)

        guard let value else {
            let status = SecItemDelete(query as CFDictionary)
            if status != errSecSuccess && status != errSecItemNotFound {
                throw KeychainStoreError.osStatus(status)
            }
            return
        }

        let data = Data(value.utf8)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus == errSecSuccess {
            return
        }

        if addStatus == errSecDuplicateItem {
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainStoreError.osStatus(updateStatus)
            }
            return
        }

        throw KeychainStoreError.osStatus(addStatus)
    }

    private func baseQuery(for key: CredentialKey) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}

/// Thread-safe in-memory credential store designed for fast deterministic unit tests.
public final class InMemoryCredentialStore: SessionCredentialStore {
    private let storage: OSAllocatedUnfairLock<[CredentialKey: String]>

    public init(initialValues: [CredentialKey: String] = [:]) {
        self.storage = OSAllocatedUnfairLock(initialState: initialValues)
    }

    public func string(for key: CredentialKey) throws -> String? {
        storage.withLock { $0[key] }
    }

    public func set(_ value: String?, for key: CredentialKey) throws {
        storage.withLock { state in
            if let value {
                state[key] = value
            } else {
                state.removeValue(forKey: key)
            }
        }
    }

    public func clearAll() {
        storage.withLock { $0.removeAll() }
    }
}
