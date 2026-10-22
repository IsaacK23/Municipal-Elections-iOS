//
//  APIClient.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation

// View models depend on this protocol so previews can use MockAPIClient instead.
nonisolated protocol APIClientProtocol: Sendable {
    // Auth
    func register(name: String, email: String, password: String) async throws -> AuthResponse
    func login(email: String, password: String) async throws -> AuthResponse
    func me() async throws -> UserProfile

    // Municipalities and positions
    func municipalities() async throws -> [Municipality]
    func municipality(id: Int) async throws -> Municipality
    func positions(municipalityId: Int?) async throws -> [Position]
    func position(id: Int) async throws -> Position

    // Candidates
    func candidates(municipalityId: Int?, positionId: Int?) async throws -> [Candidate]
    func searchCandidates(name: String, municipalityId: Int?, positionId: Int?) async throws -> [Candidate]
    func candidate(id: Int) async throws -> Candidate

    // Voting guide
    func savedCandidates() async throws -> [SavedCandidate]
    func saveCandidate(candidateId: Int) async throws -> SavedCandidate
    func deleteSavedCandidate(savedCandidateId: Int) async throws
}

nonisolated final class APIClient: APIClientProtocol {
    private let session: URLSession
    private let keychain: KeychainService

    init(session: URLSession = .shared, keychain: KeychainService = KeychainService()) {
        self.session = session
        self.keychain = keychain
    }

    // MARK: - Auth

    func register(name: String, email: String, password: String) async throws -> AuthResponse {
        let body = try JSONEncoder().encode(RegisterRequest(name: name, email: email, password: password))
        return try await request("/auth/register", method: "POST", body: body)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = try JSONEncoder().encode(LoginRequest(email: email, password: password))
        return try await request("/auth/login", method: "POST", body: body)
    }

    func me() async throws -> UserProfile {
        try await request("/auth/me", requiresAuth: true)
    }

    // MARK: - Municipalities and positions

    func municipalities() async throws -> [Municipality] {
        try await request("/municipalities")
    }

    func municipality(id: Int) async throws -> Municipality {
        try await request("/municipalities/\(id)")
    }

    func positions(municipalityId: Int?) async throws -> [Position] {
        var queryItems: [URLQueryItem] = []
        if let municipalityId {
            queryItems.append(URLQueryItem(name: "municipalityId", value: String(municipalityId)))
        }
        return try await request("/positions", queryItems: queryItems)
    }

    func position(id: Int) async throws -> Position {
        try await request("/positions/\(id)")
    }

    // MARK: - Candidates

    func candidates(municipalityId: Int?, positionId: Int?) async throws -> [Candidate] {
        let queryItems = filterQueryItems(municipalityId: municipalityId, positionId: positionId)
        return try await request("/candidates", queryItems: queryItems)
    }

    func searchCandidates(name: String, municipalityId: Int?, positionId: Int?) async throws -> [Candidate] {
        let queryItems = [URLQueryItem(name: "name", value: name)]
            + filterQueryItems(municipalityId: municipalityId, positionId: positionId)
        return try await request("/candidates/search", queryItems: queryItems)
    }

    func candidate(id: Int) async throws -> Candidate {
        try await request("/candidates/\(id)")
    }

    // MARK: - Voting guide

    func savedCandidates() async throws -> [SavedCandidate] {
        try await request("/savedcandidates", requiresAuth: true)
    }

    func saveCandidate(candidateId: Int) async throws -> SavedCandidate {
        let body = try JSONEncoder().encode(SaveCandidateRequest(candidateId: candidateId))
        return try await request("/savedcandidates", method: "POST", body: body, requiresAuth: true)
    }

    // Takes the savedCandidateId, not the candidateId. Returns 204 with no body.
    func deleteSavedCandidate(savedCandidateId: Int) async throws {
        _ = try await send("/savedcandidates/\(savedCandidateId)", method: "DELETE", requiresAuth: true)
    }

    // MARK: - Helpers

    private func filterQueryItems(municipalityId: Int?, positionId: Int?) -> [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        if let municipalityId {
            queryItems.append(URLQueryItem(name: "municipalityId", value: String(municipalityId)))
        }
        if let positionId {
            queryItems.append(URLQueryItem(name: "positionId", value: String(positionId)))
        }
        return queryItems
    }

    // Sends the request and decodes the success body into Response.
    private func request<Response: Decodable>(
        _ path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
        requiresAuth: Bool = false
    ) async throws -> Response {
        let data = try await send(path, method: method, queryItems: queryItems, body: body, requiresAuth: requiresAuth)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    // Builds the URLRequest, checks the status code and returns the raw body.
    // Failures are turned into APIError, using ProblemDetails when the server sends one.
    private func send(
        _ path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
        requiresAuth: Bool
    ) async throws -> Data {
        guard var components = URLComponents(string: APIConfig.baseURL + path) else {
            throw APIError.network(URLError(.badURL))
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw APIError.network(URLError(.badURL))
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            urlRequest.httpBody = body
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if requiresAuth {
            guard let token = keychain.readToken() else {
                throw APIError.unauthorized
            }
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let error as URLError {
            throw APIError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.decoding
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return data
        case 401:
            throw APIError.unauthorized
        default:
            let problem = try? JSONDecoder().decode(ProblemDetails.self, from: data)

            if let errors = problem?.errors, !errors.isEmpty {
                let messages = errors.keys.sorted().flatMap { errors[$0] ?? [] }
                throw APIError.validation(messages)
            }

            let message = problem?.title
                ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode).capitalized
            throw APIError.server(status: httpResponse.statusCode, message: message)
        }
    }
}
