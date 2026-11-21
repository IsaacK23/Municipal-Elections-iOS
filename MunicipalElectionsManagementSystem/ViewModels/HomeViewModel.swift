//
//  HomeViewModel.swift
//  MunicipalElectionsManagementSystem
//

import Foundation
import Observation

// Election offices (positions) for the configured municipality, loaded from the API so
// they're refreshed whenever the municipality changes.
@MainActor
@Observable
final class HomeViewModel {
    let municipality: Municipality

    private(set) var positions: [Position] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let api: any APIClientProtocol

    init(api: any APIClientProtocol, municipality: Municipality) {
        self.api = api
        self.municipality = municipality
    }

    func load(session: SessionViewModel) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            positions = try await api.positions(municipalityId: municipality.municipalityId)
        } catch APIError.unauthorized {
            session.expireSession()
        } catch let error as APIError where error.isCancelled {
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
