import Foundation
import Security

public struct GitHubTokenStore {
    private let service = "com.cheesecake.vela.github-token"
    private let account = "default"

    public init() {}

    public func load() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainError(status: status)
        }
        guard let data = result as? Data else {
            throw KeychainError(status: errSecDecode)
        }
        return String(data: data, encoding: .utf8)
    }

    public func save(_ token: String) throws {
        let data = Data(token.utf8)
        let status = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if status == errSecItemNotFound {
            var query = baseQuery
            query[kSecValueData as String] = data
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError(status: addStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError(status: status)
        }
    }

    public func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

private struct KeychainError: LocalizedError {
    let status: OSStatus

    var errorDescription: String? {
        "Could not access the macOS Keychain (error \(status))."
    }
}
