//
//  FirebaseAuthService.swift
//  MunicipalElectionsManagementSystem
//

import FirebaseAuth
import Foundation

// Signs the user in to Firebase after the ASP.NET API has accepted their credentials.
// Firestore security rules check request.auth, so selections can only be read or
// written once this has succeeded.
//
// The ASP.NET API stays the source of truth for accounts: Firebase sign-in only
// happens after a successful API login or registration.
nonisolated protocol FirebaseAuthServicing: Sendable {
    // `isNewAccount` is true right after registration, so an implementation can
    // create the Firebase user instead of signing in.
    func signIn(email: String, password: String, isNewAccount: Bool) async throws
    func signOut()
    // Firebase keeps its sign-in across launches; false if it was lost (e.g. app reinstalled).
    var isSignedIn: Bool { get }
}

// Firebase Email/Password sign-in using the same credentials as the API account.
nonisolated struct FirebaseAuthService: FirebaseAuthServicing {
    func signIn(email: String, password: String, isNewAccount: Bool) async throws {
        let auth = Auth.auth()

        if isNewAccount {
            do {
                try await auth.createUser(withEmail: email, password: password)
            } catch where Self.code(of: error) == .emailAlreadyInUse {
                // Registered in Firebase before (e.g. the API account was recreated); sign in instead.
                try await auth.signIn(withEmail: email, password: password)
            }
            return
        }

        do {
            try await auth.signIn(withEmail: email, password: password)
        } catch let signInError where Self.isMissingAccount(signInError) {
            // Accounts registered with the API before Firebase was added have no Firebase user yet.
            // The API has just verified the password, so create it now. If the email does exist,
            // the Firebase password differs from the API one and the sign-in error is the real problem.
            do {
                try await auth.createUser(withEmail: email, password: password)
            } catch where Self.code(of: error) == .emailAlreadyInUse {
                throw signInError
            }
        }
    }

    var isSignedIn: Bool {
        Auth.auth().currentUser != nil
    }

    func signOut() {
        // Only fails if the keychain can't be cleared; the API session is already gone either way.
        try? Auth.auth().signOut()
    }

    private static func code(of error: Error) -> AuthErrorCode? {
        AuthErrorCode(rawValue: (error as NSError).code)
    }

    // With email-enumeration protection (on by default), an unknown email reports
    // invalidCredential rather than userNotFound.
    private static func isMissingAccount(_ error: Error) -> Bool {
        let code = code(of: error)
        return code == .userNotFound || code == .invalidCredential
    }
}

// Used by previews.
nonisolated struct PreviewFirebaseAuthService: FirebaseAuthServicing {
    var isSignedIn: Bool { true }
    func signIn(email: String, password: String, isNewAccount: Bool) async throws {}
    func signOut() {}
}
