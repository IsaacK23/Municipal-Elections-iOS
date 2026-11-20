//
//  JWT.swift
//  MunicipalElectionsManagementSystem
//

import Foundation

// Reads the claims the app needs from a JWT. A JWT is header.payload.signature;
// the payload is base64url-encoded JSON. The signature is checked by the API, not here.
nonisolated enum JWT {
    // The "exp" claim (seconds since 1970). Nil when the token can't be read.
    static func expirationDate(of token: String) -> Date? {
        guard let payload = payload(of: token) else { return nil }
        return Date(timeIntervalSince1970: payload.exp)
    }

    // Unreadable tokens count as expired.
    static func isExpired(_ token: String, now: Date = Date()) -> Bool {
        guard let expiry = expirationDate(of: token) else { return true }
        return expiry <= now
    }

    private struct Payload: Decodable {
        let exp: TimeInterval
    }

    private static func payload(of token: String) -> Payload? {
        let segments = token.split(separator: ".")
        guard segments.count == 3 else { return nil }

        var base64 = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 += "="
        }

        guard let data = Data(base64Encoded: base64) else { return nil }
        return try? JSONDecoder().decode(Payload.self, from: data)
    }
}
