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
//
// A session spans two services: the ASP.NET API (JWT in the Keychain) and
// Firebase (needed for Firestore). Both are signed in and out together.
@MainActor
@Observable
final class SessionViewModel {
    private(set) var isLoggedIn = false
    // The logged-in user's email, lowercased; their identifier in Firestore.
    private(set) var userEmail: String?
    // Shown on the login screen after an automatic logout, e.g. when the token expires.
    private(set) var sessionMessage: String?

    private let keychain: KeychainService
    private let firebaseAuth: any FirebaseAuthServicing
    private var expiryTask: Task<Void, Never>?

    init(
        keychain: KeychainService = KeychainService(),
        firebaseAuth: any FirebaseAuthServicing = PreviewFirebaseAuthService()
    ) {
        self.keychain = keychain
        self.firebaseAuth = firebaseAuth

        // Restore the previous session only if the API token is still valid and Firebase is
        // still signed in (it keeps its own sign-in across launches). Otherwise log in again.
        if let token = keychain.readToken(), let email = keychain.readEmail(),
           !JWT.isExpired(token), firebaseAuth.isSignedIn {
            isLoggedIn = true
            userEmail = email.lowercased()
            scheduleExpiry(for: token)
        } else {
            clearStoredCredentials()
        }
    }

    // Called after the API accepted a login or registration.
    // Signs in to Firebase too; if that fails nothing is stored and the error is rethrown.
    func signIn(token: String, email: String, password: String, isNewAccount: Bool) async throws {
        guard !JWT.isExpired(token) else {
            throw APIError.unauthorized
        }

        do {
            try await firebaseAuth.signIn(email: email, password: password, isNewAccount: isNewAccount)
        } catch {
            throw SessionError.firebaseSignInFailed
        }

        // Emails are case-insensitive; Firestore document ids and security rules use lowercase.
        let normalizedEmail = email.lowercased()
        keychain.saveToken(token)
        keychain.saveEmail(normalizedEmail)
        userEmail = normalizedEmail
        sessionMessage = nil
        isLoggedIn = true
        scheduleExpiry(for: token)
    }

    // Each tab's view model is owned by its view, so switching RootView
    // back to LoginView throws away all cached screen state.
    func logout() {
        expiryTask?.cancel()
        expiryTask = nil
        firebaseAuth.signOut()
        clearStoredCredentials()
        userEmail = nil
        isLoggedIn = false
    }

    // Logs out and tells the user why. Called when the API returns 401 or the token runs out.
    func expireSession() {
        guard isLoggedIn else { return }
        logout()
        sessionMessage = APIError.unauthorized.localizedDescription
    }

    // Called when the app returns to the foreground: the timer doesn't run while suspended.
    func checkExpiry() {
        guard isLoggedIn else { return }
        if keychain.readToken().map({ JWT.isExpired($0) }) ?? true {
            expireSession()
        }
    }

    func clearSessionMessage() {
        sessionMessage = nil
    }

    // Logs the user out the moment the JWT expires, instead of waiting for a request to fail.
    private func scheduleExpiry(for token: String) {
        expiryTask?.cancel()
        guard let expiry = JWT.expirationDate(of: token) else { return }

        expiryTask = Task { [weak self] in
            let seconds = expiry.timeIntervalSinceNow
            if seconds > 0 {
                try? await Task.sleep(for: .seconds(seconds))
            }
            guard !Task.isCancelled else { return }
            self?.expireSession()
        }
    }

    private func clearStoredCredentials() {
        keychain.deleteToken()
        keychain.deleteEmail()
    }
}

nonisolated enum SessionError: LocalizedError {
    case firebaseSignInFailed

    var errorDescription: String? {
        switch self {
        case .firebaseSignInFailed:
            return "Signed in, but your saved selections couldn't be reached. Check your connection and try again."
        }
    }
}
