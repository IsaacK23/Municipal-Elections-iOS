//
//  APIConfig.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation

nonisolated enum APIConfig {
    // Root of the MEMS.Api host, without "/api".
    // Production: the Azure App Service running MEMS.Api with SQLite.
    // Local: the Aspire YARP gateway (port 5001) in front of MEMS.Api.
    static let host = "http://localhost:5001"

    static let baseURL = host + "/api"

    // The API returns image URLs relative to its host ("/api/burnaby/images/5").
    static func imageURL(for path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http") {
            return URL(string: path)
        }
        return URL(string: host + path)
    }
}
