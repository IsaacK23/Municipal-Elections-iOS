//
//  MainTabView.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import SwiftUI

// The app's sections, shared by the iPhone tab bar and the iPad sidebar.
enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case home, candidates, selections, profile

    var id: Self { self }

    var title: String {
        switch self {
        case .home: "Home"
        case .candidates: "Candidates"
        case .selections: "My Selections"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .candidates: "person.3"
        case .selections: "checklist"
        case .profile: "person.crop.circle"
        }
    }
}

// Shown once the user has a municipality. Every section is built for that municipality.
//
// Navigation adapts to the device: a TabView with a NavigationStack per tab on iPhone
// (compact width), and a NavigationSplitView with a sidebar on iPad (regular width).
// The selected section and the candidate navigation path are stored here, above the
// layout switch, so rotating the device or resizing an iPad window keeps the user's place.
struct MainTabView: View {
    @Environment(SessionViewModel.self) private var session
    @Environment(MunicipalitySettingsViewModel.self) private var settings
    @Environment(SelectionsViewModel.self) private var selections
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var api: any APIClientProtocol = APIClient()

    @SceneStorage("selectedSection") private var section: AppSection = .home
    @State private var candidatesPath: [CandidateRoute] = []

    var body: some View {
        // RootView only shows this view when settings.state is .ready.
        if let municipality = settings.municipality {
            Group {
                if horizontalSizeClass == .regular {
                    splitView(for: municipality)
                } else {
                    tabView(for: municipality)
                }
            }
            // Loads (and on a municipality change, replaces) the Firestore selections.
            .task(id: "\(session.userEmail ?? "")|\(municipality.municipalityId)") {
                if let email = session.userEmail {
                    await selections.load(email: email, municipality: municipality)
                }
            }
            .onChange(of: municipality.municipalityId) {
                // The previous city's candidate detail screens no longer apply.
                candidatesPath = []
            }
        }
    }

    // MARK: - iPhone

    private func tabView(for municipality: Municipality) -> some View {
        TabView(selection: $section) {
            ForEach(AppSection.allCases) { section in
                stack(for: section, municipality: municipality)
                    .tabItem {
                        Label(section.title, systemImage: section.systemImage)
                    }
                    .tag(section)
            }
        }
    }

    // MARK: - iPad

    private func splitView(for municipality: Municipality) -> some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: Binding<AppSection?>(
                get: { section },
                set: { if let newValue = $0 { section = newValue } }
            )) { section in
                Label(section.title, systemImage: section.systemImage)
                    .badge(section == .selections && selections.hasLoaded ? selections.count : 0)
            }
            .navigationTitle("Elections")
            .navigationSubtitle("City: \(municipality.name)")
        } detail: {
            stack(for: section, municipality: municipality)
        }
    }

    // MARK: - Sections

    // Each section gets its own NavigationStack. .id(...) rebuilds it (new view model,
    // fresh .task) when the municipality changes, so its data is reloaded and nothing
    // from the previous city remains.
    @ViewBuilder
    private func stack(for section: AppSection, municipality: Municipality) -> some View {
        switch section {
        case .home:
            NavigationStack {
                HomeView(api: api, municipality: municipality)
            }
            .id(municipality.municipalityId)
        case .candidates:
            NavigationStack(path: $candidatesPath) {
                CandidatesView(api: api, municipality: municipality)
                    .navigationDestination(for: CandidateRoute.self) { route in
                        CandidateDetailView(candidate: route.candidate, municipality: route.municipality)
                    }
            }
            .id(municipality.municipalityId)
        case .selections:
            NavigationStack {
                MySelectionsView()
            }
        case .profile:
            NavigationStack {
                ProfileView(api: api)
            }
        }
    }
}

#Preview("iPhone") {
    MainTabView(api: MockAPIClient())
        .environment(SessionViewModel())
        .environment(MunicipalitySettingsViewModel.preview())
        .environment(SelectionsViewModel.preview())
}
