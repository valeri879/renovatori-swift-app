import Foundation
import Security

/// Keeps the access and refresh tokens in the Keychain (never UserDefaults).
/// Items are readable only on this device, after its first unlock.
final class TokenStore: @unchecked Sendable {
    static let shared = TokenStore()

    private let service = "ge.renovatori.app.auth"
    private let accessAccount = "accessToken"
    private let refreshAccount = "refreshToken"

    var accessToken: String? { read(accessAccount) }
    var refreshToken: String? { read(refreshAccount) }

    func save(accessToken: String, refreshToken: String) {
        write(accessToken, account: accessAccount)
        write(refreshToken, account: refreshAccount)
    }

    func clear() {
        delete(accessAccount)
        delete(refreshAccount)
    }

    // MARK: Keychain

    private func baseQuery(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    private func read(_ account: String) -> String? {
        var query = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func write(_ value: String, account: String) {
        let data = Data(value.utf8)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let status = SecItemUpdate(baseQuery(account) as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            let query = baseQuery(account).merging(attributes) { _, new in new }
            SecItemAdd(query as CFDictionary, nil)
        }
    }

    private func delete(_ account: String) {
        SecItemDelete(baseQuery(account) as CFDictionary)
    }
}
