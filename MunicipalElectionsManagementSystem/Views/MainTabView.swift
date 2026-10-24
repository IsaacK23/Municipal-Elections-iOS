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
            MunicipalitiesView(api: api)
                .tabItem {
                    Label("Municipalities", systemImage: "building.columns")
                }

            CandidatesView(api: api)
                .tabItem {
                    Label("Candidates", systemImage: "person.3")
                }

            VotingGuideView(api: api)
                .tabItem {
                    Label("Voting Guide", systemImage: "checklist")
                }

            ProfileView(api: api)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }

    private func placeholder(_ title: String, systemImage: String) -> some View
    {
        NavigationStack {
            ContentUnavailableView(
                title,
                systemImage: systemImage,
                description: Text("Coming soon.")
            )
            .navigationTitle(title)
        }
    }
}

#Preview {
    MainTabView(api: MockAPIClient())
        .environment(SessionViewModel())
}
