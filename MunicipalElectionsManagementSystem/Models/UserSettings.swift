//
//  UserSettings.swift
//  MunicipalElectionsManagementSystem
//

import Foundation

// Per-user settings, keyed by the user's email. In Firestore this is the
// UserProfiles/{email} document.
nonisolated struct UserSettings: Codable, Equatable, Sendable {
    // The municipality the user lives in. Every API request for election data uses it.
    let municipalityId: Int
    let municipalityName: String
    // When the user's data was last written to or read from the cloud.
    var lastSync: Date?
}
