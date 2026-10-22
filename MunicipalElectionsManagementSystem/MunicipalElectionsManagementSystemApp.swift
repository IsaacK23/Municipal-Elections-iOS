//
//  MunicipalElectionsManagementSystemApp.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-21.
//

import SwiftUI

@main
struct MunicipalElectionsManagementSystemApp: App {
    @State private var session = SessionViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
    }
}
