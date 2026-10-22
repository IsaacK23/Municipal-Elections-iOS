//
//  SessionViewModel.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation
import Observation

// The single source of truth for whether the user is logged in.
// Created in the App struct and passed down with .environment.
@MainActor
@Observable
final class SessionViewModel {
    private(set) var isLoggedIn = false

    private let keychain: KeychainService

    init(keychain: KeychainService = KeychainService()) {
        self.keychain = keychain

        if let token = keychain.readToken() {
            if Self.isExpired(token) {
                keychain.deleteToken()
            } else {
                isLoggedIn = true
            }
        }
    }

    func login(token: String) {
        keychain.saveToken(token)
        isLoggedIn = true
    }

    // Each tab's view model is owned by its view, so switching RootView
    // back to LoginView throws away all cached screen state.
    func logout() {
        keychain.deleteToken()
        isLoggedIn = false
    }

    // A JWT is header.payload.signature. The payload is base64url-encoded JSON
    // with an "exp" claim in seconds since 1970. Unreadable tokens count as expired.
    static func isExpired(_ token: String, now: Date = Date()) -> Bool {
        let segments = token.split(separator: ".")
        guard segments.count == 3 else { return true }

        var base64 = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 += "="
        }

        guard let data = Data(base64Encoded: base64),
              let payload = try? JSONDecoder().decode(JWTPayload.self, from: data) else {
            return true
        }
        return Date(timeIntervalSince1970: payload.exp) <= now
    }

    private struct JWTPayload: Decodable {
        let exp: TimeInterval
    }
}
