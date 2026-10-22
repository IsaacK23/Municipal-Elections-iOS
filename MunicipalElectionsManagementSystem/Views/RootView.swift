//
//  RootView.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import SwiftUI

struct RootView: View {
    @Environment(SessionViewModel.self) private var session
    var api: any APIClientProtocol = APIClient()

    var body: some View {
        if session.isLoggedIn {
            MainTabView(api: api)
        } else {
            NavigationStack {
                LoginView(api: api)
            }
        }
    }
}

#Preview {
    RootView(api: MockAPIClient())
        .environment(SessionViewModel())
}
