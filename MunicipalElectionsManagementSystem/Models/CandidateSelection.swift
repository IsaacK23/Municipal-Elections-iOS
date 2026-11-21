//
//  CandidateSelection.swift
//  MunicipalElectionsManagementSystem
//

import Foundation

// One candidate the user has saved, stored in the Firestore "CandidateSelections"
// collection. `id` is the Firestore document id; it is filled in by the service
// after a read or an add and is not stored as a field inside the document.
nonisolated struct CandidateSelection: Identifiable, Hashable, Sendable {
    var id: String
    let userEmail: String
    let candidateId: Int
    let candidateName: String
    let positionName: String
    let municipalityName: String
    var notes: String
    let dateCreated: Date
    var dateModified: Date
}

extension CandidateSelection {
    // Builds a new selection for a candidate in the current municipality.
    // The id is empty until the service saves it and Firestore assigns one.
    static func make(
        from candidate: Candidate,
        userEmail: String,
        municipalityName: String,
        notes: String
    ) -> CandidateSelection {
        let now = Date()
        return CandidateSelection(
            id: "",
            userEmail: userEmail,
            candidateId: candidate.id,
            candidateName: candidate.name,
            positionName: candidate.positionName,
            municipalityName: municipalityName,
            notes: notes,
            dateCreated: now,
            dateModified: now
        )
    }
}
