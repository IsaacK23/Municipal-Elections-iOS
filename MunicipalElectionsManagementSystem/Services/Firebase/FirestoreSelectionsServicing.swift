//
//  FirestoreSelectionsServicing.swift
//  MunicipalElectionsManagementSystem
//

import Foundation

// CRUD for the user's saved candidate selections. Every call is scoped to one
// user (their email) and one municipality, so the app only ever reads or writes
// that user's selections for the city they are currently in.
nonisolated protocol FirestoreSelectionsServicing: Sendable {
    func selections(userEmail: String, municipalityName: String) async throws -> [CandidateSelection]
    func add(_ selection: CandidateSelection) async throws -> CandidateSelection
    func update(_ selection: CandidateSelection) async throws
    func delete(id: String) async throws
    // True when the user has already saved this candidate; used to block duplicates.
    func isSaved(userEmail: String, candidateId: Int) async throws -> Bool
}

// Used in previews and until the Firebase SDK is wired up. Keeps selections in
// memory so the selection screens can be built and previewed without a network.
actor PreviewFirestoreService: FirestoreSelectionsServicing {
    private var store: [CandidateSelection]

    init(seed: [CandidateSelection] = []) {
        self.store = seed
    }

    func selections(userEmail: String, municipalityName: String) async throws -> [CandidateSelection] {
        store
            .filter { $0.userEmail == userEmail && $0.municipalityName == municipalityName }
            .sorted { $0.dateCreated > $1.dateCreated }
    }

    func add(_ selection: CandidateSelection) async throws -> CandidateSelection {
        var copy = selection
        copy.id = UUID().uuidString
        store.append(copy)
        return copy
    }

    func update(_ selection: CandidateSelection) async throws {
        if let index = store.firstIndex(where: { $0.id == selection.id }) {
            store[index] = selection
        }
    }

    func delete(id: String) async throws {
        store.removeAll { $0.id == id }
    }

    func isSaved(userEmail: String, candidateId: Int) async throws -> Bool {
        store.contains { $0.userEmail == userEmail && $0.candidateId == candidateId }
    }
}
