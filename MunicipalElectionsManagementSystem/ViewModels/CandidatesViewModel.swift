//
//  CandidatesViewModel.swift
//  MunicipalElectionsManagementSystem
//

import Foundation
import Observation

// Candidate directory for one municipality. Every request goes through
// /api/{slug}/..., so the API only returns that municipality's data.
@MainActor
@Observable
final class CandidatesViewModel {
    let municipality: Municipality

    var searchText = ""
    var selectedPositionId: Int?

    private(set) var positions: [Position] = []
    private(set) var candidates: [Candidate] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let api: any APIClientProtocol

    init(api: any APIClientProtocol, municipality: Municipality) {
        self.api = api
        self.municipality = municipality
    }

    // Changes whenever the search or filter changes; drives .task(id:) so a new
    // request cancels the previous one.
    var queryKey: String {
        "\(searchText)|\(selectedPositionId.map(String.init) ?? "all")"
    }

    var hasActiveFilter: Bool {
        !Validators.isBlank(searchText) || selectedPositionId != nil
    }

    func loadPositions(session: SessionViewModel) async {
        do {
            positions = try await api.positions(slug: municipality.slug)
        } catch APIError.unauthorized {
            session.expireSession()
        } catch let error as APIError where error.isCancelled {
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadCandidates(session: SessionViewModel) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            candidates = try await api.candidates(
                slug: municipality.slug,
                search: searchText,
                positionId: selectedPositionId
            )
        } catch APIError.unauthorized {
            session.expireSession()
        } catch let error as APIError where error.isCancelled {
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearFilters() {
        searchText = ""
        selectedPositionId = nil
    }
}
