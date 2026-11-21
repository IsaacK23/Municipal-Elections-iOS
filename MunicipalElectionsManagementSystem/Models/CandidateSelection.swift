//
//  CandidateSelection.swift
//  MunicipalElectionsManagementSystem
//

import Foundation

// One candidate the user has saved, stored in the Firestore "CandidateSelections"
// collection. `id` is the Firestore document id; it is filled in by the service
// after a read or an add and is not stored as a field inside the document.
nonisolated struct CandidateSelection: Identifiable, Hashable, Sendable {
    static let maxNotesLength = 500

    var id: String
    // Always lowercase, to match the signed-in email the security rules compare against.
    let userEmail: String
    let candidateId: Int
    let candidateName: String
    // Absolute URL from the API, so the selections list can show the photo without another request.
    let photoUrl: String?
    // Used to enforce the seat limit for each position (e.g. at most 8 councillors).
    let positionId: Int
    let positionName: String
    // The municipality identifier; selections are always read for one municipality.
    let municipalityId: Int
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
        notes: String
    ) -> CandidateSelection {
        let now = Date()
        return CandidateSelection(
            id: "",
            userEmail: userEmail.lowercased(),
            candidateId: candidate.candidateId,
            candidateName: candidate.name,
            photoUrl: candidate.photoUrl,
            positionId: candidate.positionId,
            positionName: candidate.positionName,
            municipalityId: candidate.municipalityId,
            municipalityName: candidate.municipalityName,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            dateCreated: now,
            dateModified: now
        )
    }
}
