//
//  Candidate.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation

nonisolated struct Candidate: Codable, Identifiable, Hashable, Sendable {
    let candidateId: Int
    let name: String
    let biography: String
    let photoUrl: String?
    let website: String?
    let email: String?
    let positionId: Int
    let positionName: String
    let municipalityId: Int
    let municipalityName: String

    var id: Int { candidateId }
}
