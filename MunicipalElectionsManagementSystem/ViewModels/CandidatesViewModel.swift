import Foundation
import Observation

@MainActor
@Observable
final class CandidatesViewModel {
    // search and filters from the form, 0 means no filter
    var searchText = ""
    var municipalityId = 0 {
        // the old position might not be in the new municipality
        didSet { positionId = 0 }
    }
    var positionId = 0

    private(set) var candidates: [Candidate] = []
    private(set) var municipalities: [Municipality] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let api: any APIClientProtocol

    init(api: any APIClientProtocol) {
        self.api = api
    }

    // positions for the picker, all of them or just the picked location
    var positions: [Position] {
        var list: [Position] = []
        for municipality in municipalities {
            if municipalityId == 0 || municipality.municipalityId == municipalityId {
                list.append(contentsOf: municipality.positions)
            }
        }
        return list
    }

    // municipalities for the pickers, if this fails the pickers just show All
    func loadMunicipalities() async {
        if municipalities.isEmpty {
            municipalities = (try? await api.municipalities()) ?? []
        }
    }

    // GET /api/candidates if a name was typed
    func load() async {
        isLoading = true
        errorMessage = nil

        let name = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let municipality: Int? = municipalityId == 0 ? nil : municipalityId
        let position: Int? = positionId == 0 ? nil : positionId

        do {
            if name.isEmpty {
                candidates = try await api.candidates(municipalityId: municipality, positionId: position)
            } else {
                candidates = try await api.searchCandidates(name: name, municipalityId: municipality, positionId: position)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
