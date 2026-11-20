//
//  MunicipalElectionsManagementSystemApp.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-21.
//

import SwiftUI

@main
struct MunicipalElectionsManagementSystemApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var session = SessionViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
        .onChange(of: scenePhase) { _, phase in
            // The expiry timer doesn't fire while the app is suspended.
            if phase == .active {
                session.checkExpiry()
            }
        }
    }
}
