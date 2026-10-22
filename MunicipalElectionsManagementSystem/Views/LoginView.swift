//
//  LoginView.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import SwiftUI

struct LoginView: View {
    @Environment(SessionViewModel.self) private var session
    @State private var viewModel: LoginViewModel
    private let api: any APIClientProtocol

    init(api: any APIClientProtocol = APIClient()) {
        self.api = api
        _viewModel = State(initialValue: LoginViewModel(api: api))
    }

    var body: some View {
        Form {
            Section {
                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if let error = viewModel.emailError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
                if let error = viewModel.passwordError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            if let message = viewModel.errorMessage {
                Section {
                    Label(message, systemImage: "exclamationmark.circle")
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task { await viewModel.login(session: session) }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Log In")
                                .bold()
                        }
                        Spacer()
                    }
                }
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
            }

            Section {
                NavigationLink {
                    RegisterView(api: api)
                } label: {
                    Text("Don't have an account? Register")
                }
            }
        }
        .navigationTitle("Log In")
    }
}

#Preview {
    NavigationStack {
        LoginView(api: MockAPIClient())
    }
    .environment(SessionViewModel())
}
