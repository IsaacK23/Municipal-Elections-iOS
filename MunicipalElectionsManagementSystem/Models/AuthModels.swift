//
//  AuthModels.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation

nonisolated struct RegisterRequest: Codable, Sendable {
    let name: String
    let email: String
    let password: String
}

// The API signs in by user name. Voter accounts use their email as the user name.
nonisolated struct LoginRequest: Codable, Sendable {
    let userName: String
    let password: String
}

// Returned by both /auth/login and /auth/register. Only the token is required;
// the other fields are informational and may be missing on older API versions.
nonisolated struct AuthResponse: Codable, Sendable {
    let token: String
    let userName: String?
    let role: String?
}

// GET /auth/me: identifies the logged-in user from the JWT.
nonisolated struct UserProfile: Codable, Hashable, Sendable {
    let name: String
    let email: String
}
