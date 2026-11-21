//
//  UserSettingsStore.swift
//  MunicipalElectionsManagementSystem
//

import FirebaseFirestore
import Foundation

// Loads and saves the signed-in user's settings (their municipality).
nonisolated protocol UserSettingsStoring: Sendable {
    // Nil when the user has never chosen a municipality (first login).
    func loadSettings(email: String) async throws -> UserSettings?
    func saveSettings(_ settings: UserSettings, email: String) async throws
}

// Firestore store: one UserProfiles/{email} document per user. Uses the same
// dictionary approach as FirestoreService. The user must be signed in to Firebase,
// because the security rules only allow access to the document named after their own email.
//
// Firestore's client is internally thread-safe, so this is marked @unchecked Sendable.
nonisolated final class FirestoreUserSettingsStore: UserSettingsStoring, @unchecked Sendable {
    // Looked up on use, not at init, so creating the store never runs before FirebaseApp.configure().
    private var collection: CollectionReference {
        Firestore.firestore().collection("UserProfiles")
    }

    func loadSettings(email: String) async throws -> UserSettings? {
        let snapshot = try await collection.document(email.lowercased()).getDocument()
        guard let data = snapshot.data() else { return nil }

        guard
            let municipalityId = (data["municipalityId"] as? Int) ?? (data["municipalityId"] as? NSNumber)?.intValue,
            let municipalityName = data["municipalityName"] as? String
        else {
            throw FirestoreServiceError.invalidData
        }

        return UserSettings(
            municipalityId: municipalityId,
            municipalityName: municipalityName,
            lastSync: (data["lastSync"] as? Timestamp)?.dateValue()
        )
    }

    func saveSettings(_ settings: UserSettings, email: String) async throws {
        var data: [String: Any] = [
            "municipalityId": settings.municipalityId,
            "municipalityName": settings.municipalityName
        ]
        if let lastSync = settings.lastSync {
            data["lastSync"] = Timestamp(date: lastSync)
        }
        try await collection.document(email.lowercased()).setData(data, merge: true)
    }
}

// On-device store (UserDefaults). Used by previews.
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
