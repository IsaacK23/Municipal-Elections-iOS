//
//  ProfileView.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import SwiftUI

struct ProfileView: View {
    @Environment(SessionViewModel.self) private var session
    @State private var viewModel: ProfileViewModel
    @State private var showLogoutConfirmation = false

    init(api: any APIClientProtocol = APIClient()) {
        _viewModel = State(initialValue: ProfileViewModel(api: api))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let profile = viewModel.profile {
                        HStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.largeTitle)
                                .imageScale(.large)
                                .foregroundStyle(.tint)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.name)
                                    .font(.headline)
                                Text(profile.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    } else if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if let message = viewModel.errorMessage {
                        ErrorStateView(message: message) {
                            Task { await viewModel.load(session: session) }
                        }
                    }
                }

                // Log Out stays available even if the profile failed to load.
                Section {
                    Button("Log Out", role: .destructive) {
                        showLogoutConfirmation = true
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .task {
                await viewModel.load(session: session)
            }
            .refreshable {
                await viewModel.load(session: session)
            }
            .confirmationDialog(
                "Are you sure you want to log out?",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Log Out", role: .destructive) {
                    session.logout()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

#Preview("Profile") {
    ProfileView(api: MockAPIClient())
        .environment(SessionViewModel())
}

#Preview("Error") {
    ProfileView(api: MockAPIClient(shouldFail: true))
        .environment(SessionViewModel())
}
