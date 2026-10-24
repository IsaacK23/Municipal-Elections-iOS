import Foundation
import Observation

@MainActor
@Observable
final class CandidateDetailViewModel {
    let candidate: Candidate

    private(set) var isSaving = false
    private(set) var message: String?
    private(set) var errorMessage: String?

    private let api: any APIClientProtocol

    init(candidate: Candidate, api: any APIClientProtocol) {
        self.candidate = candidate
        self.api = api
    }

    // POST /api/savedcandidates
    func addToGuide(session: SessionViewModel) async {
        isSaving = true
        message = nil
        errorMessage = nil

        do {
            _ = try await api.saveCandidate(candidateId: candidate.candidateId)
            message = "Added to your voting guide."
        } catch APIError.unauthorized {
            // token expired, back to login
            session.logout()
        } catch APIError.server(409, _) {
            // 409 = already saved
            message = "Already in your voting guide."
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}
