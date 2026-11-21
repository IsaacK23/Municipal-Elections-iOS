//
//  MainTabView.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import SwiftUI

// Shown once the user has a municipality. Every tab is built for that municipality.
struct MainTabView: View {
    @Environment(MunicipalitySettingsViewModel.self) private var settings
    var api: any APIClientProtocol = APIClient()

    var body: some View {
        // RootView only shows this view when settings.state is .ready.
        if let municipality = settings.municipality {
            TabView {
                // .id(...) rebuilds each tab (new view model, fresh .task) when the municipality
                // changes, so its data is reloaded and nothing from the previous city remains.
                HomeView(api: api, municipality: municipality)
                    .id(municipality.municipalityId)
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

                NavigationStack {
                    CandidatesView(api: api, municipality: municipality)
                        .navigationDestination(for: CandidateRoute.self) { route in
                            CandidateDetailView(candidate: route.candidate, municipality: route.municipality)
                        }
                }
                .id(municipality.municipalityId)
                .tabItem {
                    Label("Candidates", systemImage: "person.3")
                }

                // Replaced by "My Candidate Selections" (Firestore) in Phase 5.
                placeholder("My Selections", systemImage: "checklist", city: municipality.name)
                    .id(municipality.municipalityId)
                    .tabItem {
                        Label("My Selections", systemImage: "checklist")
                    }

                ProfileView(api: api)
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
            }
        }
    }

    private func placeholder(_ title: String, systemImage: String, city: String) -> some View {
        NavigationStack {
            ContentUnavailableView(
                title,
                systemImage: systemImage,
                description: Text("Coming soon.")
            )
            .navigationTitle(title)
            .navigationSubtitle("City: \(city)")
        }
    }
}

#Preview {
    MainTabView(api: MockAPIClient())
        .environment(SessionViewModel())
        .environment(MunicipalitySettingsViewModel.preview())
}
