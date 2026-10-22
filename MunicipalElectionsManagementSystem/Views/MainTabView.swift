//
//  MainTabView.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import SwiftUI

struct MainTabView: View {
    var api: any APIClientProtocol = APIClient()

    var body: some View {
        TabView {
            // TODO (steps 4-7): replace these placeholders with
            // MunicipalitiesView(api: api), CandidatesView(api: api) and VotingGuideView(api: api).
            // Each of those views should own its own NavigationStack, like ProfileView does.
            placeholder("Municipalities", systemImage: "building.columns")
                .tabItem {
                    Label("Municipalities", systemImage: "building.columns")
                }

            placeholder("Candidates", systemImage: "person.3")
                .tabItem {
                    Label("Candidates", systemImage: "person.3")
                }

            placeholder("Voting Guide", systemImage: "checklist")
                .tabItem {
                    Label("Voting Guide", systemImage: "checklist")
                }

            ProfileView(api: api)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }

    private func placeholder(_ title: String, systemImage: String) -> some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: systemImage, description: Text("Coming soon."))
                .navigationTitle(title)
        }
    }
}

#Preview {
    MainTabView(api: MockAPIClient())
        .environment(SessionViewModel())
}
