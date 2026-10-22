//
//  Position.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation

nonisolated struct Position: Codable, Identifiable, Hashable, Sendable {
    let positionId: Int
    let name: String
    let seatsAvailable: Int
    let municipalityId: Int
    let municipalityName: String

    var id: Int { positionId }
}
