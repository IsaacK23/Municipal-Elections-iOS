//
//  ProfileViewModel.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    private(set) var profile: UserProfile?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let api: any APIClientProtocol

    init(api: any APIClientProtocol) {
        self.api = api
    }

    func load(session: SessionViewModel) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            profile = try await api.me()
        } catch APIError.unauthorized {
            session.logout()
        } catch let error as APIError where error.isCancelled {
            // The view went away or the request was replaced; nothing to show.
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
