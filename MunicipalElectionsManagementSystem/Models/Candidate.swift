//
//  Candidate.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation

nonisolated struct Candidate: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    // The candidate's biography. The API calls it "profile".
    let profile: String
    let website: String?
    let email: String?
    let positionId: Int
    let positionName: String
    let municipalityId: Int
    // Relative to the API host, e.g. "/api/burnaby/images/5". Use APIConfig.imageURL(for:).
    let photoUrl: String?
}
