import Foundation
import Observation

@MainActor
@Observable
final class VotingGuideViewModel {
    private(set) var saved: [SavedCandidate] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let api: any APIClientProtocol

    init(api: any APIClientProtocol) {
        self.api = api
    }

    // GET /api/savedcandidates
    func load(session: SessionViewModel) async {
        isLoading = true
        errorMessage = nil

        do {
            saved = try await api.savedCandidates()
        } catch APIError.unauthorized {
            // token expired, back to login
            session.logout()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func remove(at offsets: IndexSet, session: SessionViewModel) async {
        // get the items first, the list can change while we wait
        let toRemove = offsets.compactMap { index in
            saved.indices.contains(index) ? saved[index] : nil
        }

        // take them off the screen right away
        saved.removeAll { item in toRemove.contains(item) }

        for item in toRemove {
            do {
                try await api.deleteSavedCandidate(savedCandidateId: item.savedCandidateId)
            } catch APIError.unauthorized {
                session.logout()
                return
            } catch {
                errorMessage = error.localizedDescription
                // put back anything that didn't delete
                await load(session: session)
                return
            }
        }
    }
}
