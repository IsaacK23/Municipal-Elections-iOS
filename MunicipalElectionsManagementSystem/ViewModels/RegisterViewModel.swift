//
//  RegisterViewModel.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation
import Observation

@MainActor
@Observable
final class RegisterViewModel {
    var name = "" {
        didSet { nameEdited = true }
    }
    var email = "" {
        didSet { emailEdited = true }
    }
    var password = "" {
        didSet { passwordEdited = true }
    }
    var confirmPassword = "" {
        didSet { confirmPasswordEdited = true }
    }

    private(set) var nameEdited = false
    private(set) var emailEdited = false
    private(set) var passwordEdited = false
    private(set) var confirmPasswordEdited = false
    private(set) var isLoading = false
    private(set) var serverErrors: [String] = []

    private let api: any APIClientProtocol

    init(api: any APIClientProtocol) {
        self.api = api
    }

    // Inline errors only appear after the field has been edited.
    var nameError: String? {
        nameEdited ? Validators.nameError(name) : nil
    }

    var emailError: String? {
        emailEdited ? Validators.emailError(email) : nil
    }

    var passwordErrors: [String] {
        passwordEdited ? Validators.passwordErrors(password) : []
    }

    var confirmPasswordError: String? {
        confirmPasswordEdited
            ? Validators.confirmPasswordError(password: password, confirmPassword: confirmPassword)
            : nil
    }

    var isFormValid: Bool {
        Validators.nameError(name) == nil
            && Validators.emailError(email) == nil
            && Validators.passwordErrors(password).isEmpty
            && Validators.confirmPasswordError(password: password, confirmPassword: confirmPassword) == nil
    }

    func register(session: SessionViewModel) async {
        guard isFormValid, !isLoading else { return }

        isLoading = true
        serverErrors = []
        defer { isLoading = false }

        do {
            let response = try await api.register(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            // The response includes a token, so the user is logged straight in.
            session.login(token: response.token)
        } catch APIError.validation(let messages) {
            serverErrors = messages
        } catch {
            serverErrors = [error.localizedDescription]
        }
    }
}
