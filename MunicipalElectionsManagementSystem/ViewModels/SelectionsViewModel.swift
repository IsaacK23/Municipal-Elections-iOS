//
//  SelectionsViewModel.swift
//  MunicipalElectionsManagementSystem
//

import Foundation
import Observation

// The signed-in user's candidate selections for their current municipality, stored in Firestore.
// Created in the App struct and shared with .environment, so the candidate detail screen,
// My Candidate Selections and Profile all show the same, already-loaded data (it also
// survives rotation and switching between the iPhone and iPad layouts).
@MainActor
@Observable
final class SelectionsViewModel {
    private(set) var selections: [CandidateSelection] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?
    // Last successful read or write against Firestore, shown on the Profile screen.
    private(set) var lastSync: Date?

    private let service: any FirestoreSelectionsServicing
    private var email: String?
    private var municipality: Municipality?

    init(service: any FirestoreSelectionsServicing = PreviewFirestoreService()) {
        self.service = service
    }

    var count: Int { selections.count }

    func selection(forCandidateId candidateId: Int) -> CandidateSelection? {
        selections.first { $0.candidateId == candidateId }
    }

    // MARK: - Read

    // Loads the selections for this user and municipality. When the municipality changes,
    // the previous city's selections are cleared straight away so they are never shown.
    func load(email: String, municipality: Municipality) async {
        if self.email != email || self.municipality?.municipalityId != municipality.municipalityId {
            selections = []
            hasLoaded = false
        }
        self.email = email
        self.municipality = municipality
        await refresh()
    }

    func refresh() async {
        guard let email, let municipality else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loaded = try await service.selections(userEmail: email, municipalityId: municipality.municipalityId)
            // Ignore a late response for a municipality the user has already switched away from.
            guard municipality.municipalityId == self.municipality?.municipalityId else { return }
            selections = loaded
            hasLoaded = true
            lastSync = Date()
        } catch is CancellationError {
        } catch {
            errorMessage = FirebaseErrorMessage.message(for: error)
        }
    }

    // MARK: - Validation

    // Nil when the candidate can be added; otherwise the reason it can't.
    func addError(for candidate: Candidate, notes: String) -> String? {
        guard let municipality else {
            return "Choose your municipality before saving candidates."
        }
        if candidate.municipalityId != municipality.municipalityId {
            return "\(candidate.name) isn't running in \(municipality.name)."
        }
        if selection(forCandidateId: candidate.candidateId) != nil {
            return "\(candidate.name) is already in your selections."
        }
        if let notesError = Validators.notesError(notes) {
            return notesError
        }
        return seatLimitError(for: candidate, in: municipality)
    }

    // A voter may choose at most `seatsAvailable` candidates for each position
    // (e.g. Burnaby: 1 mayor, 8 councillors, 7 school trustees).
    private func seatLimitError(for candidate: Candidate, in municipality: Municipality) -> String? {
        guard let position = municipality.positions.first(where: { $0.positionId == candidate.positionId }) else {
            return nil
        }
        let chosen = selections.filter { $0.positionId == candidate.positionId }.count
        guard chosen >= position.seatsAvailable else { return nil }

        let limit = position.seatsAvailable == 1
            ? "only 1 \(position.name)"
            : "up to \(position.seatsAvailable) \(position.name) candidates"
        return "You can select \(limit) in \(municipality.name). Remove one before adding another."
    }

    // How many more candidates can be chosen for a position; nil if the position is unknown.
    func remainingSeats(forPositionId positionId: Int) -> Int? {
        guard let position = municipality?.positions.first(where: { $0.positionId == positionId }) else {
            return nil
        }
        return max(0, position.seatsAvailable - selections.filter { $0.positionId == positionId }.count)
    }

    // MARK: - Create, update, delete

    func add(_ candidate: Candidate, notes: String) async throws {
        if let error = addError(for: candidate, notes: notes) {
            throw SelectionError.invalid(error)
        }
        guard let email else { throw SelectionError.notSignedIn }

        do {
            // Also check Firestore, in case the candidate was saved on another device.
            if try await service.isSaved(userEmail: email, candidateId: candidate.candidateId) {
                await refresh()
                throw SelectionError.invalid("\(candidate.name) is already in your selections.")
            }
            let saved = try await service.add(CandidateSelection.make(from: candidate, userEmail: email, notes: notes))
            selections.insert(saved, at: 0)
            lastSync = Date()
        } catch let error as SelectionError {
            throw error
        } catch {
            throw SelectionError.invalid(FirebaseErrorMessage.message(for: error))
        }
    }

    func update(_ selection: CandidateSelection, notes: String) async throws {
        if let error = Validators.notesError(notes) {
            throw SelectionError.invalid(error)
        }

        var updated = selection
        updated.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.dateModified = Date()

        do {
            try await service.update(updated)
            if let index = selections.firstIndex(where: { $0.id == selection.id }) {
                selections[index] = updated
            }
            lastSync = Date()
        } catch {
            throw SelectionError.invalid(FirebaseErrorMessage.message(for: error))
        }
    }

    func delete(_ selection: CandidateSelection) async throws {
        do {
            try await service.delete(id: selection.id)
            // Remove locally right away so the list refreshes immediately.
            selections.removeAll { $0.id == selection.id }
            lastSync = Date()
        } catch {
            throw SelectionError.invalid(FirebaseErrorMessage.message(for: error))
        }
    }

    // Called on logout so the next user starts clean.
    func reset() {
        selections = []
        hasLoaded = false
        errorMessage = nil
        lastSync = nil
        email = nil
        municipality = nil
    }
}

nonisolated enum SelectionError: LocalizedError {
    case invalid(String)
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .invalid(let message):
            return message
        case .notSignedIn:
            return "Your session has expired. Please log in again."
        }
    }
}

extension SelectionsViewModel {
    // A loaded view model with sample selections, for previews.
    static func preview(_ municipality: Municipality = .burnaby, selections: [CandidateSelection]? = nil) -> SelectionsViewModel {
        let seed = selections ?? CandidateSelection.samples
        let viewModel = SelectionsViewModel(service: PreviewFirestoreService(seed: seed))
        viewModel.email = UserProfile.sample.email
        viewModel.municipality = municipality
        viewModel.selections = seed.filter { $0.municipalityId == municipality.municipalityId }
        viewModel.hasLoaded = true
        viewModel.lastSync = Date()
        return viewModel
    }
}

nonisolated extension CandidateSelection {
    static let samples: [CandidateSelection] = [
        CandidateSelection.make(
            from: .eleanorVasquez,
            userEmail: UserProfile.sample.email,
            notes: "Strong record on transit. Ask about the housing plan at the town hall."
        ),
        CandidateSelection.make(from: .carolinePrice, userEmail: UserProfile.sample.email, notes: "")
    ].enumerated().map { index, selection in
        var copy = selection
        copy.id = "sample-\(index)"
        return copy
    }
}
