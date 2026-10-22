//
//  LoginViewModel.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var email = "" {
        didSet { emailEdited = true }
    }
    var password = "" {
        didSet { passwordEdited = true }
    }

    private(set) var emailEdited = false
    private(set) var passwordEdited = false
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let api: any APIClientProtocol

    init(api: any APIClientProtocol) {
        self.api = api
    }

    // Inline errors only appear after the field has been edited.
    var emailError: String? {
        emailEdited ? Validators.emailError(email) : nil
    }

    var passwordError: String? {
        passwordEdited
            ? Validators.requiredError(password, fieldName: "Password") : nil
    }

    var isFormValid: Bool {
        Validators.emailError(email) == nil
            && Validators.requiredError(password, fieldName: "Password") == nil
    }

    func login(session: SessionViewModel) async {
        guard isFormValid, !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let trimmedEmail = email.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            let response = try await api.login(
                email: trimmedEmail,
                password: password
            )
            session.login(token: response.token)
        } catch APIError.unauthorized {
            errorMessage = "Invalid email or password."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
