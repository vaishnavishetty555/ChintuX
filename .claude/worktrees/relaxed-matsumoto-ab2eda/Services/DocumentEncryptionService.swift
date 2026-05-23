import Foundation
import CryptoKit
import Security

/// PRD — Pet Vault encryption. AES-GCM with a device-bound key stored in the
/// Secure Enclave-backed keychain. The key never leaves the device.
enum DocumentEncryptionService {
    private static let keyIdentifier = "com.pawly.vault.encryptionKey"

    // MARK: - Key management

    private static func fetchOrCreateKey() -> SymmetricKey? {
        if let data = keychainRead(key: keyIdentifier) {
            return SymmetricKey(data: data)
        }
        let key = SymmetricKey(size: .bits256)
        if keychainWrite(key: keyIdentifier, data: key.withUnsafeBytes { Data($0) }) {
            return key
        }
        return nil
    }

    // MARK: - Encrypt / Decrypt

    /// Encrypts plaintext data and returns AES-GCM sealed box bytes.
    static func encrypt(data: Data) -> Data? {
        guard let key = fetchOrCreateKey() else { return nil }
        do {
            let sealed = try AES.GCM.seal(data, using: key)
            return sealed.combined
        } catch {
            return nil
        }
    }

    /// Decrypts AES-GCM combined bytes back to plaintext.
    static func decrypt(data: Data) -> Data? {
        guard let key = fetchOrCreateKey() else { return nil }
        do {
            let sealed = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealed, using: key)
        } catch {
            return nil
        }
    }

    // MARK: - Keychain helpers

    private static func keychainRead(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    @discardableResult
    private static func keychainWrite(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }
}
