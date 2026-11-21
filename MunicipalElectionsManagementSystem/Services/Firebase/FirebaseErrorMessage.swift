//
//  FirebaseErrorMessage.swift
//  MunicipalElectionsManagementSystem
//

import FirebaseFirestore
import Foundation

// Turns Firestore and network errors into messages a user can act on, instead of
// raw SDK text such as "Missing or insufficient permissions."
nonisolated enum FirebaseErrorMessage {
    static func message(for error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == FirestoreErrorDomain, let code = FirestoreErrorCode.Code(rawValue: nsError.code) {
            switch code {
            case .unavailable, .deadlineExceeded:
                return "Your saved selections couldn't be reached. Check your internet connection and try again."
            case .permissionDenied, .unauthenticated:
                return "You don't have access to these selections. Please log out and log in again."
            case .notFound:
                return "This selection no longer exists. Pull down to refresh."
            case .resourceExhausted:
                return "Too many requests right now. Please wait a moment and try again."
            case .invalidArgument, .failedPrecondition, .dataLoss:
                return "Your selections couldn't be saved because the data was invalid."
            default:
                return "Something went wrong with your saved selections. Please try again."
            }
        }

        // Our own errors (APIError, FirestoreServiceError, SelectionError) already have good text.
        if let description = (error as? LocalizedError)?.errorDescription {
            return description
        }
        if nsError.domain == NSURLErrorDomain {
            return "No internet connection. Check your connection and try again."
        }
        return "Something went wrong. Please try again."
    }
}
