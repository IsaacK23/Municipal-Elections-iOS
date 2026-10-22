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

nonisolated struct LoginRequest: Codable, Sendable {
    let email: String
    let password: String
}

nonisolated struct AuthResponse: Codable, Sendable {
    let token: String
}

nonisolated struct UserProfile: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let email: String
}
