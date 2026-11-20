//
//  MunicipalitiesViewModel.swift
//  MunicipalElectionsManagementSystem
//

import Foundation
import Observation

@MainActor
@Observable
final class MunicipalitiesViewModel {
    private(set) var municipalities: [Municipality] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let api: any APIClientProtocol

    init(api: any APIClientProtocol) {
        self.api = api
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            municipalities = try await api.municipalities()
        } catch let error as APIError where error.isCancelled {
            // The view went away or the request was replaced; nothing to show.
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
