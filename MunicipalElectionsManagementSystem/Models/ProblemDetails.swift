//
//  ProblemDetails.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation

nonisolated struct ProblemDetails: Codable, Sendable {
    let title: String?
    let status: Int?
    let errors: [String: [String]]?
}
