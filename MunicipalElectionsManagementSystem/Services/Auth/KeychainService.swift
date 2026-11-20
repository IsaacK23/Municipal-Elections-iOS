//
//  KeychainService.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation
import Security

// Stores the JWT and the signed-in user's email in the Keychain.
// The email is the user's identifier in Firestore.
nonisolated struct KeychainService: Sendable {
    private let service = "MunicipalElectionsCompanion"
    private let tokenAccount = "jwt"
    private let emailAccount = "email"

    // MARK: - Token

    func saveToken(_ token: String) {
        save(token, account: tokenAccount)
    }

    func readToken() -> String? {
        read(account: tokenAccount)
    }

    func deleteToken() {
        delete(account: tokenAccount)
    }

    // MARK: - Email

    func saveEmail(_ email: String) {
        save(email, account: emailAccount)
    }

    func readEmail() -> String? {
        read(account: emailAccount)
    }

    func deleteEmail() {
        delete(account: emailAccount)
    }

    // MARK: - Helpers

    private func save(_ value: String, account: String) {
        delete(account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(value.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
