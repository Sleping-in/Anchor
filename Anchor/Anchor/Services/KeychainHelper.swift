//
//  KeychainHelper.swift
//  Anchor
//
//  Simple Keychain wrapper for persisting the API key.
//

import Foundation
import Security

enum KeychainHelper {

    private static let service = "com.anchor.app"

    /// Save a string value to the Keychain.
    @discardableResult
    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        // Remove any existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Load a string value from the Keychain.
    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Delete a value from the Keychain.
    @discardableResult
    static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    // MARK: - Convenience

    private static let apiKeyAccount = "GEMINI_API_KEY"

    /// The persisted Gemini API key, falling back to env/plist for dev builds.
    static var geminiAPIKey: String? {
        if let saved = load(key: apiKeyAccount), !saved.isEmpty {
            return saved
        }
        // Fallback: env var or Info.plist (Xcode scheme / CI)
        let env = ProcessInfo.processInfo.environment
        let info = Bundle.main.infoDictionary ?? [:]
        return env["GEMINI_API_KEY"] ?? info["GEMINI_API_KEY"] as? String
    }

    /// Persist a new API key.
    static func setGeminiAPIKey(_ key: String) {
        if key.isEmpty {
            delete(key: apiKeyAccount)
        } else {
            save(key: apiKeyAccount, value: key)
        }
    }
}
