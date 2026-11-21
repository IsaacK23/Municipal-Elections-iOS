//
//  FirestoreService.swift
//  MunicipalElectionsManagementSystem
//

import Foundation
import FirebaseFirestore

// Live Firestore implementation. Follows the Firebase lecture's dictionary
// approach: documents are written and read as [String: Any], with dates stored
// as Firestore Timestamps. The user must be signed in to Firebase Auth first
// (SessionViewModel does that on login), because the security rules check request.auth.
//
// Firestore's client is internally thread-safe, so this is marked @unchecked Sendable.
final class FirestoreService: FirestoreSelectionsServicing, @unchecked Sendable {
    private let database = Firestore.firestore()
    private let collectionName = "CandidateSelections"

    private var collection: CollectionReference {
        database.collection(collectionName)
    }

    func selections(userEmail: String, municipalityName: String) async throws -> [CandidateSelection] {
        let snapshot = try await collection
            .whereField("userEmail", isEqualTo: userEmail)
            .whereField("municipalityName", isEqualTo: municipalityName)
            .getDocuments()

        return snapshot.documents
            .compactMap { Self.selection(from: $0) }
            .sorted { $0.dateCreated > $1.dateCreated }
    }

    func add(_ selection: CandidateSelection) async throws -> CandidateSelection {
        let reference = collection.document()
        try await reference.setData(Self.data(from: selection))
        var saved = selection
        saved.id = reference.documentID
        return saved
    }

    func update(_ selection: CandidateSelection) async throws {
        guard !selection.id.isEmpty else { throw FirestoreServiceError.missingId }
        try await collection.document(selection.id).setData(Self.data(from: selection), merge: true)
    }

    func delete(id: String) async throws {
        try await collection.document(id).delete()
    }

    func isSaved(userEmail: String, candidateId: Int) async throws -> Bool {
        let snapshot = try await collection
            .whereField("userEmail", isEqualTo: userEmail)
            .whereField("candidateId", isEqualTo: candidateId)
            .limit(to: 1)
            .getDocuments()
        return !snapshot.documents.isEmpty
    }

    // MARK: - Mapping between CandidateSelection and Firestore dictionaries

    private static func data(from selection: CandidateSelection) -> [String: Any] {
        [
            "userEmail": selection.userEmail,
            "candidateId": selection.candidateId,
            "candidateName": selection.candidateName,
            "positionName": selection.positionName,
            "municipalityName": selection.municipalityName,
            "notes": selection.notes,
            "dateCreated": Timestamp(date: selection.dateCreated),
            "dateModified": Timestamp(date: selection.dateModified)
        ]
    }

    private static func selection(from document: QueryDocumentSnapshot) -> CandidateSelection? {
        let data = document.data()
        guard
            let userEmail = data["userEmail"] as? String,
            let candidateId = (data["candidateId"] as? Int) ?? (data["candidateId"] as? NSNumber)?.intValue,
            let candidateName = data["candidateName"] as? String,
            let positionName = data["positionName"] as? String,
            let municipalityName = data["municipalityName"] as? String
        else { return nil }

        let notes = data["notes"] as? String ?? ""
        let dateCreated = (data["dateCreated"] as? Timestamp)?.dateValue() ?? Date()
        let dateModified = (data["dateModified"] as? Timestamp)?.dateValue() ?? dateCreated

        return CandidateSelection(
            id: document.documentID,
            userEmail: userEmail,
            candidateId: candidateId,
            candidateName: candidateName,
            positionName: positionName,
            municipalityName: municipalityName,
            notes: notes,
            dateCreated: dateCreated,
            dateModified: dateModified
        )
    }
}

nonisolated enum FirestoreServiceError: LocalizedError {
    case missingId

    var errorDescription: String? {
        switch self {
        case .missingId:
            return "This selection hasn't been saved yet."
        }
    }
}
