import Foundation
import Observation

@MainActor
@Observable
final class MunicipalitiesViewModel {
    private(set) var municipalities: [Municipality] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let api: any APIClientProtocol

    init(api: any APIClientProtocol) {
        self.api = api
    }

    // GET /api/municipalities
    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            municipalities = try await api.municipalities()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
