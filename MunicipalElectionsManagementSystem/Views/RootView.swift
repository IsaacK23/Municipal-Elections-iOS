//
//  RootView.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import SwiftUI

struct RootView: View {
    @Environment(SessionViewModel.self) private var session
    @Environment(MunicipalitySettingsViewModel.self) private var settings
    var api: any APIClientProtocol = APIClient()

    var body: some View {
        Group {
            if session.isLoggedIn {
                loggedInContent
                    // Runs on login, and again if a different user logs in.
                    .task(id: session.userEmail) {
                        if let email = session.userEmail {
                            await settings.load(email: email)
                        }
                    }
            } else {
                NavigationStack {
                    LoginView(api: api)
                }
            }
        }
        .onChange(of: session.isLoggedIn) { _, isLoggedIn in
            if !isLoggedIn {
                settings.reset()
            }
        }
    }

    @ViewBuilder
    private var loggedInContent: some View {
        switch settings.state {
        case .idle, .loading:
            ProgressView("Loading your municipality…")
        case .needsSelection:
            // First login: the user must choose where they live before seeing any election data.
            NavigationStack {
                MunicipalityPickerView(api: api, mode: .firstLogin)
            }
        case .failed(let message):
            ErrorStateView(message: message) {
                if let email = session.userEmail {
                    Task { await settings.load(email: email) }
                }
            }
        case .ready:
            MainTabView(api: api)
        }
    }
}

#Preview {
    RootView(api: MockAPIClient())
        .environment(SessionViewModel())
        .environment(MunicipalitySettingsViewModel.preview())
}
