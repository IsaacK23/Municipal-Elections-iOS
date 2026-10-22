//
//  RegisterView.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import SwiftUI

struct RegisterView: View {
    @Environment(SessionViewModel.self) private var session
    @State private var viewModel: RegisterViewModel

    init(api: any APIClientProtocol = APIClient()) {
        _viewModel = State(initialValue: RegisterViewModel(api: api))
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $viewModel.name)
                    .textContentType(.name)
                if let error = viewModel.nameError {
                    errorText(error)
                }

                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if let error = viewModel.emailError {
                    errorText(error)
                }
            }

            Section {
                SecureField("Password", text: $viewModel.password)
                    .textContentType(.newPassword)
                if !viewModel.passwordErrors.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.passwordErrors, id: \.self) { error in
                            errorText("• \(error)")
                        }
                    }
                }

                SecureField(
                    "Confirm Password",
                    text: $viewModel.confirmPassword
                )
                .textContentType(.newPassword)
                if let error = viewModel.confirmPasswordError {
                    errorText(error)
                }
            }

            Section {
                Button {
                    Task { await viewModel.register(session: session) }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Create Account")
                                .bold()
                        }
                        Spacer()
                    }
                }
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
            }

            // Server validation messages, e.g. "An account with this email already exists."
            if !viewModel.serverErrors.isEmpty {
                Section {
                    ForEach(viewModel.serverErrors, id: \.self) { message in
                        Label(message, systemImage: "exclamationmark.circle")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("Register")
    }

    private func errorText(_ message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.red)
    }
}

#Preview {
    NavigationStack {
        RegisterView(api: MockAPIClient())
    }
    .environment(SessionViewModel())
}
