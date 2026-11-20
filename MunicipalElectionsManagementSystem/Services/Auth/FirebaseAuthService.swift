//
//  FirebaseAuthService.swift
//  MunicipalElectionsManagementSystem
//

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
}

// Used until the Firebase SDK is added (Phase 3), and by previews.
nonisolated struct PreviewFirebaseAuthService: FirebaseAuthServicing {
    func signIn(email: String, password: String, isNewAccount: Bool) async throws {}
    func signOut() {}
}
