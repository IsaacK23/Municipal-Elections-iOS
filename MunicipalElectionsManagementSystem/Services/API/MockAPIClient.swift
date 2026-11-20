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

    private func municipalityId(for slug: String) throws -> Int {
        guard let municipality = Municipality.samples.first(where: { $0.slug == slug }) else {
            throw APIError.server(status: 404, message: "Municipality not found.")
        }
        return municipality.id
    }

    // MARK: - Auth

    func register(name: String, email: String, password: String) async throws -> AuthResponse {
        try check()
        return AuthResponse(token: "preview-token", userName: email, role: "Voter")
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try check()
        return AuthResponse(token: "preview-token", userName: email, role: "Voter")
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

    func municipality(slug: String) async throws -> Municipality {
        try check()
        guard let municipality = Municipality.samples.first(where: { $0.slug == slug }) else {
            throw APIError.server(status: 404, message: "Municipality not found.")
        }
        return municipality
    }

    // MARK: - Positions and candidates

    func positions(slug: String) async throws -> [Position] {
        try check()
        let id = try municipalityId(for: slug)
        return Position.samples.filter { $0.municipalityId == id }
    }

    func candidates(slug: String, search: String?, positionId: Int?) async throws -> [Candidate] {
        try check()
        let id = try municipalityId(for: slug)
        let term = search ?? ""
        return Candidate.samples.filter { candidate in
            candidate.municipalityId == id
                && (positionId == nil || candidate.positionId == positionId)
                && (Validators.isBlank(term) || candidate.name.localizedCaseInsensitiveContains(term))
        }
    }

    func candidate(slug: String, id: Int) async throws -> Candidate {
        let candidates = try await candidates(slug: slug, search: nil, positionId: nil)
        guard let candidate = candidates.first(where: { $0.id == id }) else {
            throw APIError.server(status: 404, message: "Candidate not found.")
        }
        return candidate
    }
}

// MARK: - Sample data

nonisolated extension Municipality {
    static let burnaby = Municipality(
        id: 1,
        name: "Burnaby",
        slug: "burnaby",
        province: "British Columbia",
        electionDate: "2026-10-17",
        description: "A city in Metro Vancouver, home to Simon Fraser University.",
        themeColor: "#1f6f8b",
        logoUrl: nil
    )

    static let surrey = Municipality(
        id: 2,
        name: "Surrey",
        slug: "surrey",
        province: "British Columbia",
        electionDate: "2026-10-17",
        description: "The second-largest city in British Columbia.",
        themeColor: "#2e7d32",
        logoUrl: nil
    )

    static let samples = [burnaby, surrey]
}

nonisolated extension Position {
    static let burnabyMayor = Position(id: 1, name: "Mayor", seatsAvailable: 1, municipalityId: 1, candidateCount: 2)
    static let burnabyCouncillor = Position(id: 2, name: "Councillor", seatsAvailable: 8, municipalityId: 1, candidateCount: 1)
    static let surreyMayor = Position(id: 3, name: "Mayor", seatsAvailable: 1, municipalityId: 2, candidateCount: 1)

    static let samples = [burnabyMayor, burnabyCouncillor, surreyMayor]
}

nonisolated extension Candidate {
    static let eleanorVasquez = Candidate(
        id: 1,
        name: "Eleanor Vasquez",
        profile: "Eleanor Vasquez has served on Burnaby council for eight years and is running for Mayor "
            + "on a platform of affordable housing and better transit.",
        website: "https://example.com/eleanor-vasquez",
        email: "eleanor.vasquez@example.com",
        positionId: 1,
        positionName: "Mayor",
        municipalityId: 1,
        photoUrl: nil
    )

    static let marcusLee = Candidate(
        id: 2,
        name: "Marcus Lee",
        profile: "Marcus Lee is a small-business owner running for Mayor of Burnaby.",
        website: nil,
        email: "marcus.lee@example.com",
        positionId: 1,
        positionName: "Mayor",
        municipalityId: 1,
        photoUrl: nil
    )

    static let weiZhang = Candidate(
        id: 3,
        name: "Wei Zhang",
        profile: "Wei Zhang is running for Councillor in Burnaby.",
        website: nil,
        email: "wei.zhang@example.com",
        positionId: 2,
        positionName: "Councillor",
        municipalityId: 1,
        photoUrl: nil
    )

    static let priyaSingh = Candidate(
        id: 4,
        name: "Priya Singh",
        profile: "Priya Singh is running for Mayor of Surrey.",
        website: "https://example.com/priya-singh",
        email: nil,
        positionId: 3,
        positionName: "Mayor",
        municipalityId: 2,
        photoUrl: nil
    )

    static let samples = [eleanorVasquez, marcusLee, weiZhang, priyaSingh]
}

nonisolated extension UserProfile {
    static let sample = UserProfile(name: "Jane Voter", email: "jane@example.com")
}
