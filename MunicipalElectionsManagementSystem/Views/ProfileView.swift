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
    @Environment(SelectionsViewModel.self) private var selections
    @State private var viewModel: ProfileViewModel
    @State private var showLogoutConfirmation = false
    @State private var showMunicipalityPicker = false
    private let api: any APIClientProtocol

    init(api: any APIClientProtocol = APIClient()) {
        self.api = api
        _viewModel = State(initialValue: ProfileViewModel(api: api))
    }

    var body: some View {
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

            Section("My Candidate Selections") {
                LabeledContent("Email", value: session.userEmail ?? "")
                LabeledContent("Total Saved Selections") {
                    if selections.hasLoaded {
                        Text("\(selections.count)")
                    } else {
                        ProgressView()
                    }
                }
                LabeledContent("Last Synchronized") {
                    // The most recent Firestore read or write, of selections or the municipality.
                    if let lastSync = [selections.lastSync, settings.lastSync].compactMap({ $0 }).max() {
                        Text(lastSync, format: .dateTime.month().day().hour().minute().second())
                    } else {
                        Text("Never")
                    }
                }
            }

            Section {
                LabeledContent("City", value: settings.municipality?.name ?? "Not set")
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
            await selections.refresh()
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

#Preview("Profile") {
    NavigationStack {
        ProfileView(api: MockAPIClient())
    }
    .environment(SessionViewModel())
    .environment(MunicipalitySettingsViewModel.preview())
    .environment(SelectionsViewModel.preview())
}

#Preview("Error") {
    NavigationStack {
        ProfileView(api: MockAPIClient(shouldFail: true))
    }
    .environment(SessionViewModel())
    .environment(MunicipalitySettingsViewModel.preview())
    .environment(SelectionsViewModel.preview())
}
