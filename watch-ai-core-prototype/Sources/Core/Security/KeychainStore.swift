import Foundation
#if canImport(Security)
import Security
#endif

public enum KeychainError: Error, LocalizedError {
    case notFound(String)
    case writeFailed(Int32)
    case readFailed(Int32)
    case deleteFailed(Int32)
    case encodingError
    case unsupportedPlatform

    public var errorDescription: String? {
        switch self {
        case .notFound(let key): "No keychain entry for '\(key)'"
        case .writeFailed(let s): "Keychain write failed: \(s)"
        case .readFailed(let s): "Keychain read failed: \(s)"
        case .deleteFailed(let s): "Keychain delete failed: \(s)"
        case .encodingError: "Could not encode value as UTF-8"
        case .unsupportedPlatform: "Keychain unavailable on this platform"
        }
    }
}

/// Thin Keychain wrapper. Uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
/// so secrets do not migrate to a restored device.
///
/// On non-Apple platforms (Linux test runs) this becomes a no-op that always
/// throws `.unsupportedPlatform` — keeps the package buildable for CI.
public struct KeychainStore: Sendable {
    private let service: String

    public init(service: String? = nil) {
        self.service = service ?? Bundle.main.bundleIdentifier ?? "com.carpcode.watchaicore"
    }

    public func write(account: String, value: String) throws {
#if canImport(Security)
        guard let data = value.data(using: .utf8) else { throw KeychainError.encodingError }
        try? delete(account: account)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.writeFailed(status) }
#else
        throw KeychainError.unsupportedPlatform
#endif
    }

    public func read(account: String) throws -> String {
#if canImport(Security)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound { throw KeychainError.notFound(account) }
            throw KeychainError.readFailed(status)
        }
        guard let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.encodingError
        }
        return value
#else
        throw KeychainError.unsupportedPlatform
#endif
    }

    @discardableResult
    public func delete(account: String) throws -> Bool {
#if canImport(Security)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecItemNotFound { return false }
        guard status == errSecSuccess else { throw KeychainError.deleteFailed(status) }
        return true
#else
        return false
#endif
    }

    public func hasKey(account: String) -> Bool {
        (try? read(account: account)) != nil
    }
}
