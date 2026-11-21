//
//  ProfileView.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import SwiftUI

struct ProfileView: View {
    @Environment(SessionViewModel.self) private var session
    @Environment(MunicipalitySettingsViewModel.self) private var settings
    @State private var viewModel: ProfileViewModel
    @State private var showLogoutConfirmation = false
    @State private var showMunicipalityPicker = false
    private let api: any APIClientProtocol

    init(api: any APIClientProtocol = APIClient()) {
        self.api = api
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

                Section {
                    LabeledContent("City", value: settings.municipality?.name ?? "Not set")
                    LabeledContent("Last Synchronized") {
                        if let lastSync = settings.lastSync {
                            Text(lastSync, format: .dateTime.month().day().hour().minute())
                        } else {
                            Text("Never")
                        }
                    }
                    Button("Change Municipality") {
                        showMunicipalityPicker = true
                    }
                } header: {
                    Text("Municipality")
                } footer: {
                    Text("Candidates, positions and your selections are shown for this municipality only.")
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
            .navigationSubtitle("City: \(settings.municipality?.name ?? "Not set")")
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
            .sheet(isPresented: $showMunicipalityPicker) {
                NavigationStack {
                    MunicipalityPickerView(api: api, mode: .change)
                }
            }
        }
    }
}

#Preview("Profile") {
    ProfileView(api: MockAPIClient())
        .environment(SessionViewModel())
        .environment(MunicipalitySettingsViewModel.preview())
}

#Preview("Error") {
    ProfileView(api: MockAPIClient(shouldFail: true))
        .environment(SessionViewModel())
        .environment(MunicipalitySettingsViewModel.preview())
}
