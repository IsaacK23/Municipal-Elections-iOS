//
//  APIError.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation

nonisolated enum APIError: LocalizedError {
    case network(URLError)
    case unauthorized
    case validation([String])
    case server(status: Int, message: String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .network(let error):
            switch error.code {
            case .notConnectedToInternet, .dataNotAllowed, .networkConnectionLost:
                return "No internet connection."
            case .timedOut:
                return "The request timed out."
            default:
                return "The server could not be reached."
            }
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .validation(let messages):
            return messages.joined(separator: "\n")
        case .server(_, let message):
            return message
        case .decoding:
            return "Something went wrong. Please try again."
        }
    }

    // True when a request was cancelled, e.g. by .task(id:) or leaving a screen.
    // View models should ignore these instead of showing an error.
    var isCancelled: Bool {
        if case .network(let error) = self {
            return error.code == .cancelled
        }
        return false
    }
}
