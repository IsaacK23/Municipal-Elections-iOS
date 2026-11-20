//
//  Position.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation

nonisolated struct Position: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    // How many candidates a voter may choose for this position (e.g. 1 mayor, 5 councillors).
    let seatsAvailable: Int
    let municipalityId: Int
    let candidateCount: Int
}
