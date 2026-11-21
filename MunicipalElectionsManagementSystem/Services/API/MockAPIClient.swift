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

    // Same response as the real API for an unknown municipality.
    private func requireMunicipality(_ id: Int) throws {
        guard Municipality.samples.contains(where: { $0.municipalityId == id }) else {
            throw APIError.server(status: 404, message: "Municipality not found.")
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

    // MARK: - Municipalities

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

    // MARK: - Positions and candidates

    func positions(municipalityId: Int) async throws -> [Position] {
        try check()
        try requireMunicipality(municipalityId)
        return Position.samples.filter { $0.municipalityId == municipalityId }
    }

    func candidates(municipalityId: Int, search: String?, positionId: Int?) async throws -> [Candidate] {
        try check()
        try requireMunicipality(municipalityId)
        let term = search ?? ""
        return Candidate.samples.filter { candidate in
            candidate.municipalityId == municipalityId
                && (positionId == nil || candidate.positionId == positionId)
                && (Validators.isBlank(term) || candidate.name.localizedCaseInsensitiveContains(term))
        }
    }

    func candidate(id: Int, municipalityId: Int) async throws -> Candidate {
        let candidates = try await candidates(municipalityId: municipalityId, search: nil, positionId: nil)
        guard let candidate = candidates.first(where: { $0.candidateId == id }) else {
            throw APIError.server(status: 404, message: "Candidate not found.")
        }
        return candidate
    }
}

// MARK: - Sample data

nonisolated extension Position {
    static let burnabyMayor = Position(
        positionId: 7, name: "Mayor", seatsAvailable: 1, municipalityId: 3, municipalityName: "Burnaby"
    )
    static let burnabyCouncillor = Position(
        positionId: 8, name: "Councilor", seatsAvailable: 8, municipalityId: 3, municipalityName: "Burnaby"
    )
    static let pittMeadowsMayor = Position(
        positionId: 1, name: "Mayor", seatsAvailable: 1, municipalityId: 1, municipalityName: "Pitt Meadows"
    )

    static let samples = [burnabyMayor, burnabyCouncillor, pittMeadowsMayor]
}

nonisolated extension Municipality {
    static let burnaby = Municipality(
        municipalityId: 3,
        name: "Burnaby",
        province: "British Columbia",
        electionDate: "2026-10-17",
        description: "A city in Metro Vancouver, home to Simon Fraser University.",
        logoUrl: nil,
        positions: [.burnabyMayor, .burnabyCouncillor]
    )

    static let pittMeadows = Municipality(
        municipalityId: 1,
        name: "Pitt Meadows",
        province: "British Columbia",
        electionDate: "2026-10-17",
        description: "A small city on the north side of the Fraser River.",
        logoUrl: nil,
        positions: [.pittMeadowsMayor]
    )

    static let samples = [burnaby, pittMeadows]
}

nonisolated extension Candidate {
    static let eleanorVasquez = Candidate(
        candidateId: 1,
        name: "Eleanor Vasquez",
        biography: "Eleanor Vasquez has served on Burnaby council for eight years and is running for Mayor "
            + "on a platform of affordable housing and better transit.",
        photoUrl: nil,
        website: "https://example.com/eleanor-vasquez",
        email: "eleanor.vasquez@example.com",
        positionId: 7,
        positionName: "Mayor",
        municipalityId: 3,
        municipalityName: "Burnaby"
    )

    static let carolinePrice = Candidate(
        candidateId: 27,
        name: "Caroline Price",
        biography: "Caroline Price is running for Councilor in Burnaby.",
        photoUrl: nil,
        website: nil,
        email: "caroline.price@example.com",
        positionId: 8,
        positionName: "Councilor",
        municipalityId: 3,
        municipalityName: "Burnaby"
    )

    static let weiZhang = Candidate(
        candidateId: 2,
        name: "Wei Zhang",
        biography: "Wei Zhang is running for Mayor of Pitt Meadows.",
        photoUrl: nil,
        website: nil,
        email: "wei.zhang@example.com",
        positionId: 1,
        positionName: "Mayor",
        municipalityId: 1,
        municipalityName: "Pitt Meadows"
    )

    static let samples = [eleanorVasquez, carolinePrice, weiZhang]
}

nonisolated extension UserProfile {
    static let sample = UserProfile(
        id: "547448f4-0000-0000-0000-000000000000",
        name: "Jane Voter",
        email: "jane@example.com"
    )
}
