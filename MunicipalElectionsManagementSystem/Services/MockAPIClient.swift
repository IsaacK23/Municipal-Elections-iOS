//
//  MockAPIClient.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation

// Returns sample data without touching the network. Used by #Previews.
// Set shouldFail to preview error states.
nonisolated struct MockAPIClient: APIClientProtocol {
    var shouldFail = false

    private func check() throws {
        if shouldFail {
            throw APIError.network(URLError(.cannotConnectToHost))
        }
    }

    // MARK: - Auth

    func register(name: String, email: String, password: String) async throws -> AuthResponse {
        try check()
        return AuthResponse(token: "preview-token")
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try check()
        return AuthResponse(token: "preview-token")
    }

    func me() async throws -> UserProfile {
        try check()
        return .sample
    }

    // MARK: - Municipalities and positions

    func municipalities() async throws -> [Municipality] {
        try check()
        return Municipality.samples
    }

    func municipality(id: Int) async throws -> Municipality {
        try check()
        guard let municipality = Municipality.samples.first(where: { $0.municipalityId == id }) else {
            throw APIError.server(status: 404, message: "Municipality not found.")
        }
        return municipality
    }

    func positions(municipalityId: Int?) async throws -> [Position] {
        try check()
        return Position.samples.filter { municipalityId == nil || $0.municipalityId == municipalityId }
    }

    func position(id: Int) async throws -> Position {
        try check()
        guard let position = Position.samples.first(where: { $0.positionId == id }) else {
            throw APIError.server(status: 404, message: "Position not found.")
        }
        return position
    }

    // MARK: - Candidates

    func candidates(municipalityId: Int?, positionId: Int?) async throws -> [Candidate] {
        try check()
        return Candidate.samples.filter {
            (municipalityId == nil || $0.municipalityId == municipalityId)
                && (positionId == nil || $0.positionId == positionId)
        }
    }

    func searchCandidates(name: String, municipalityId: Int?, positionId: Int?) async throws -> [Candidate] {
        try await candidates(municipalityId: municipalityId, positionId: positionId)
            .filter { $0.name.localizedCaseInsensitiveContains(name) }
    }

    func candidate(id: Int) async throws -> Candidate {
        try check()
        guard let candidate = Candidate.samples.first(where: { $0.candidateId == id }) else {
            throw APIError.server(status: 404, message: "Candidate not found.")
        }
        return candidate
    }

    // MARK: - Voting guide

    func savedCandidates() async throws -> [SavedCandidate] {
        try check()
        return SavedCandidate.samples
    }

    func saveCandidate(candidateId: Int) async throws -> SavedCandidate {
        let candidate = try await candidate(id: candidateId)
        return SavedCandidate(savedCandidateId: 99, candidateId: candidateId, dateSaved: Date(), candidate: candidate)
    }

    func deleteSavedCandidate(savedCandidateId: Int) async throws {
        try check()
    }
}

// MARK: - Sample data

nonisolated extension Position {
    static let pittMeadowsMayor = Position(
        positionId: 1,
        name: "Mayor",
        seatsAvailable: 1,
        municipalityId: 1,
        municipalityName: "Pitt Meadows"
    )

    static let burnabySchoolTrustee = Position(
        positionId: 6,
        name: "School Trustee",
        seatsAvailable: 7,
        municipalityId: 2,
        municipalityName: "Burnaby"
    )

    static let samples = [pittMeadowsMayor, burnabySchoolTrustee]
}

nonisolated extension Municipality {
    static let pittMeadows = Municipality(
        municipalityId: 1,
        name: "Pitt Meadows",
        province: "British Columbia",
        electionDate: "2026-10-17",
        description: "A small city on the north side of the Fraser River.",
        logoUrl: nil,
        positions: [.pittMeadowsMayor]
    )

    static let burnaby = Municipality(
        municipalityId: 2,
        name: "Burnaby",
        province: "British Columbia",
        electionDate: "2026-10-17",
        description: "A city in Metro Vancouver, home to Simon Fraser University.",
        logoUrl: nil,
        positions: [.burnabySchoolTrustee]
    )

    static let samples = [pittMeadows, burnaby]
}

nonisolated extension Candidate {
    static let eleanorVasquez = Candidate(
        candidateId: 1,
        name: "Eleanor Vasquez",
        biography: "Eleanor Vasquez is running for Mayor of Pitt Meadows.",
        photoUrl: nil,
        website: "https://example.com/eleanor-vasquez",
        email: "eleanor.vasquez@example.com",
        positionId: 1,
        positionName: "Mayor",
        municipalityId: 1,
        municipalityName: "Pitt Meadows"
    )

    static let weiZhang = Candidate(
        candidateId: 2,
        name: "Wei Zhang",
        biography: "Wei Zhang is running for School Trustee in Burnaby.",
        photoUrl: nil,
        website: nil,
        email: "wei.zhang@example.com",
        positionId: 6,
        positionName: "School Trustee",
        municipalityId: 2,
        municipalityName: "Burnaby"
    )

    static let samples = [eleanorVasquez, weiZhang]
}

nonisolated extension SavedCandidate {
    static let samples = [
        SavedCandidate(
            savedCandidateId: 1,
            candidateId: Candidate.eleanorVasquez.candidateId,
            dateSaved: Date(timeIntervalSince1970: 1_792_660_075),
            candidate: .eleanorVasquez
        ),
        SavedCandidate(
            savedCandidateId: 2,
            candidateId: Candidate.weiZhang.candidateId,
            dateSaved: Date(timeIntervalSince1970: 1_792_660_075),
            candidate: .weiZhang
        )
    ]
}

nonisolated extension UserProfile {
    static let sample = UserProfile(
        id: "547448f4-0000-0000-0000-000000000000",
        name: "Jane Voter",
        email: "jane@example.com"
    )
}
