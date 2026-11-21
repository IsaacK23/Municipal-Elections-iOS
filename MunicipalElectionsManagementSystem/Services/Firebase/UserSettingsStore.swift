//
//  UserSettingsStore.swift
//  MunicipalElectionsManagementSystem
//

import Foundation

// Loads and saves the signed-in user's settings (their municipality).
// The Firestore implementation (UserProfiles/{email}) replaces LocalUserSettingsStore
// once the Firebase SDK is added in Phase 3; nothing else needs to change.
nonisolated protocol UserSettingsStoring: Sendable {
    // Nil when the user has never chosen a municipality (first login).
    func loadSettings(email: String) async throws -> UserSettings?
    func saveSettings(_ settings: UserSettings, email: String) async throws
}

// Temporary on-device store (UserDefaults) so the app works before Firebase is set up.
// Also used by previews.
nonisolated struct LocalUserSettingsStore: UserSettingsStoring {
    func loadSettings(email: String) async throws -> UserSettings? {
        guard let data = UserDefaults.standard.data(forKey: key(for: email)) else { return nil }
        return try JSONDecoder().decode(UserSettings.self, from: data)
    }

    func saveSettings(_ settings: UserSettings, email: String) async throws {
        let data = try JSONEncoder().encode(settings)
        UserDefaults.standard.set(data, forKey: key(for: email))
    }

    // Emails are case-insensitive, so "Jane@x.com" and "jane@x.com" share settings.
    private func key(for email: String) -> String {
        "userSettings.\(email.lowercased())"
    }
}
