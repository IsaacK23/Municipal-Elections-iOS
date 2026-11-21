//
//  MunicipalitySettingsViewModel.swift
//  MunicipalElectionsManagementSystem
//

import Foundation
import Observation

// The user's configured municipality. Created in the App struct and passed down with
// .environment, so every screen reads the same city.
//
// RootView shows the municipality picker while `state` is .needsSelection (first login),
// and the main tabs once it is .ready.
@MainActor
@Observable
final class MunicipalitySettingsViewModel {
    enum State: Equatable {
        case idle
        case loading
        case needsSelection
        case ready
        case failed(String)
    }

    private(set) var state: State = .idle
    // Full municipality details from the API (election date, positions...). Set when .ready.
    private(set) var municipality: Municipality?
    private(set) var lastSync: Date?
    private(set) var isSaving = false
    private(set) var saveError: String?

    private let api: any APIClientProtocol
    private let store: any UserSettingsStoring
    private var email: String?

    init(
        api: any APIClientProtocol = APIClient(),
        store: any UserSettingsStoring = LocalUserSettingsStore()
    ) {
        self.api = api
        self.store = store
    }

    // Loads the saved municipality for this user, then its current details from the API.
    func load(email: String) async {
        self.email = email
        state = .loading

        do {
            guard let settings = try await store.loadSettings(email: email) else {
                state = .needsSelection
                return
            }
            municipality = try await api.municipality(id: settings.municipalityId)
            lastSync = settings.lastSync
            state = .ready
        } catch let error as APIError where error.isCancelled {
            // RootView's task was replaced (e.g. a different user logged in).
        } catch APIError.server(status: 404, _) {
            // The saved municipality was deleted on the server; ask the user to choose again.
            municipality = nil
            state = .needsSelection
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // Saves the new municipality, then publishes it. Screens that depend on it are rebuilt
    // for the new id, so they reload their data. Returns false if saving failed.
    @discardableResult
    func select(_ newMunicipality: Municipality) async -> Bool {
        guard let email, !isSaving else { return false }

        isSaving = true
        saveError = nil
        defer { isSaving = false }

        let settings = UserSettings(
            municipalityId: newMunicipality.municipalityId,
            municipalityName: newMunicipality.name,
            lastSync: Date()
        )
        do {
            try await store.saveSettings(settings, email: email)
            municipality = newMunicipality
            lastSync = settings.lastSync
            state = .ready
            return true
        } catch {
            saveError = "Your municipality couldn't be saved. \(error.localizedDescription)"
            return false
        }
    }

    // Records a successful cloud sync (e.g. selections loaded), shown on the Profile screen.
    func recordSync(at date: Date = Date()) {
        lastSync = date
    }

    func clearSaveError() {
        saveError = nil
    }

    // Called on logout so the next user starts clean.
    func reset() {
        state = .idle
        municipality = nil
        lastSync = nil
        saveError = nil
        email = nil
    }
}

extension MunicipalitySettingsViewModel {
    // A view model that is already .ready, for previews.
    static func preview(_ municipality: Municipality = .burnaby) -> MunicipalitySettingsViewModel {
        let viewModel = MunicipalitySettingsViewModel(api: MockAPIClient())
        viewModel.email = UserProfile.sample.email
        viewModel.municipality = municipality
        viewModel.lastSync = Date()
        viewModel.state = .ready
        return viewModel
    }
}
