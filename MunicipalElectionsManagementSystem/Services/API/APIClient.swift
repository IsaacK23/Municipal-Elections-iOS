//
//  APIClient.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation

// View models depend on this protocol so previews can use MockAPIClient instead.
// Election data is always requested for one municipality, identified by its slug,
// so the API itself only ever returns that municipality's records.
nonisolated protocol APIClientProtocol: Sendable {
    // Auth
    func register(name: String, email: String, password: String) async throws -> AuthResponse
    func login(email: String, password: String) async throws -> AuthResponse
    func me() async throws -> UserProfile

    // Municipalities
    func municipalities() async throws -> [Municipality]
    func municipality(slug: String) async throws -> Municipality

    // Positions and candidates for one municipality
    func positions(slug: String) async throws -> [Position]
    func candidates(slug: String, search: String?, positionId: Int?) async throws -> [Candidate]
    func candidate(slug: String, id: Int) async throws -> Candidate
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
        let body = try JSONEncoder().encode(LoginRequest(userName: email, password: password))
        return try await request("/auth/login", method: "POST", body: body)
    }

    func me() async throws -> UserProfile {
        try await request("/auth/me", requiresAuth: true)
    }

    // MARK: - Municipalities

    func municipalities() async throws -> [Municipality] {
        try await request("/municipalities")
    }

    func municipality(slug: String) async throws -> Municipality {
        try await request("/municipalities/\(try pathSegment(slug))")
    }

    // MARK: - Positions and candidates

    func positions(slug: String) async throws -> [Position] {
        try await request("/\(try pathSegment(slug))/positions", requiresAuth: true)
    }

    func candidates(slug: String, search: String?, positionId: Int?) async throws -> [Candidate] {
        var queryItems: [URLQueryItem] = []
        if let search, !Validators.isBlank(search) {
            queryItems.append(URLQueryItem(name: "search", value: search.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        if let positionId {
            queryItems.append(URLQueryItem(name: "positionId", value: String(positionId)))
        }
        return try await request("/\(try pathSegment(slug))/candidates", queryItems: queryItems, requiresAuth: true)
    }

    func candidate(slug: String, id: Int) async throws -> Candidate {
        try await request("/\(try pathSegment(slug))/candidates/\(id)", requiresAuth: true)
    }

    // MARK: - Helpers

    // Slugs are lowercase letters, digits and hyphens. Anything else would let a caller
    // change the route (e.g. "../"), so it is rejected before the request is built.
    private func pathSegment(_ slug: String) throws -> String {
        guard slug.range(of: "^[a-z0-9]+(-[a-z0-9]+)*$", options: .regularExpression) != nil else {
            throw APIError.network(URLError(.badURL))
        }
        return slug
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
