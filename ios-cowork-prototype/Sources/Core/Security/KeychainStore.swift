import Foundation
import Security

public enum KeychainError: Error, LocalizedError {
    case notFound(String)
    case writeFailed(OSStatus)
    case readFailed(OSStatus)
    case deleteFailed(OSStatus)
    case encodingError

    public var errorDescription: String? {
        switch self {
        case .notFound(let key): return "No keychain entry for '\(key)'"
        case .writeFailed(let s): return "Keychain write failed: \(s)"
        case .readFailed(let s): return "Keychain read failed: \(s)"
        case .deleteFailed(let s): return "Keychain delete failed: \(s)"
        case .encodingError: return "Could not encode key as UTF-8"
        }
    }
}

public struct KeychainStore: Sendable {
    private static let bundleID = Bundle.main.bundleIdentifier ?? "com.carpcowork.prototype"

    public init() {}

    public func write(service: String, value: String) throws {
        guard let data = value.data(using: .utf8) else { throw KeychainError.encodingError }
        try delete(service: service)   // remove existing entry before writing
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Self.bundleID,
            kSecAttrAccount: service,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.writeFailed(status) }
    }

    public func read(service: String) throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Self.bundleID,
            kSecAttrAccount: service,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound { throw KeychainError.notFound(service) }
            throw KeychainError.readFailed(status)
        }
        guard let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.encodingError
        }
        return value
    }

    @discardableResult
    public func delete(service: String) throws -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Self.bundleID,
            kSecAttrAccount: service,
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecItemNotFound { return false }
        guard status == errSecSuccess else { throw KeychainError.deleteFailed(status) }
        return true
    }

    public func hasKey(service: String) -> Bool {
        (try? read(service: service)) != nil
    }
}
