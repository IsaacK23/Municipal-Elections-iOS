//
//  SavedCandidate.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation

nonisolated struct SavedCandidate: Codable, Identifiable, Hashable, Sendable {
    let savedCandidateId: Int
    let candidateId: Int
    let dateSaved: Date
    let candidate: Candidate

    var id: Int { savedCandidateId }
}

nonisolated struct SaveCandidateRequest: Codable, Sendable {
    let candidateId: Int
}
