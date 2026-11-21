//
//  APIConfig.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation

nonisolated enum APIConfig {
    // The A1 ASP.NET Core Web API on Azure App Service (SQLite).
    // Local development: "http://localhost:5211/api"
    static let baseURL = "https://mems-isaac-cali-bfgehyf7f0h0fbhm.westus3-01.azurewebsites.net/api"

    // The API builds photo URLs from the incoming request. Behind Azure's proxy that can come back
    // as http://, which App Transport Security blocks, so non-local URLs are upgraded to https.
    static func imageURL(for urlString: String?) -> URL? {
        guard let urlString, var components = URLComponents(string: urlString) else { return nil }
        if components.scheme == "http", components.host != "localhost", components.host != "127.0.0.1" {
            components.scheme = "https"
        }
        return components.url
    }
}
