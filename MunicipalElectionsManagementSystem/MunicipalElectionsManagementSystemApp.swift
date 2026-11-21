//
//  MunicipalElectionsManagementSystemApp.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-21.
//

import FirebaseCore
import SwiftUI

@main
struct MunicipalElectionsManagementSystemApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: SessionViewModel
    @State private var municipalitySettings: MunicipalitySettingsViewModel
    @State private var selections: SelectionsViewModel

    init() {
        // Reads GoogleService-Info.plist. Must run before any Firebase Auth or Firestore call.
        FirebaseApp.configure()

        // The live app uses Firebase; previews use the in-memory defaults of each view model.
        _session = State(initialValue: SessionViewModel(firebaseAuth: FirebaseAuthService()))
        _municipalitySettings = State(initialValue: MunicipalitySettingsViewModel(store: FirestoreUserSettingsStore()))
        _selections = State(initialValue: SelectionsViewModel(service: FirestoreService()))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(municipalitySettings)
                .environment(selections)
        }
        .onChange(of: scenePhase) { _, phase in
            // The expiry timer doesn't fire while the app is suspended.
            if phase == .active {
                session.checkExpiry()
            }
        }
    }
}
