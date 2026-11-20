//
//  MunicipalitiesView.swift
//  MunicipalElectionsManagementSystem
//

import SwiftUI

struct MunicipalitiesView: View {
    @State private var viewModel: MunicipalitiesViewModel
    private let api: any APIClientProtocol

    init(api: any APIClientProtocol = APIClient()) {
        self.api = api
        _viewModel = State(initialValue: MunicipalitiesViewModel(api: api))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Municipalities")
                .navigationDestination(for: Municipality.self) { municipality in
                    CandidatesView(api: api, municipality: municipality)
                }
                .navigationDestination(for: CandidateRoute.self) { route in
                    CandidateDetailView(candidate: route.candidate, municipality: route.municipality)
                }
                .task {
                    if viewModel.municipalities.isEmpty {
                        await viewModel.load()
                    }
                }
                .refreshable {
                    await viewModel.load()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let message = viewModel.errorMessage, viewModel.municipalities.isEmpty {
            ErrorStateView(message: message) {
                Task { await viewModel.load() }
            }
        } else if viewModel.isLoading && viewModel.municipalities.isEmpty {
            ProgressView()
        } else {
            List(viewModel.municipalities) { municipality in
                NavigationLink(value: municipality) {
                    HStack(spacing: 12) {
                        // Placeholder icon if there is no logo or it fails to load.
                        AsyncImage(url: APIConfig.imageURL(for: municipality.logoUrl)) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "building.columns")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(.gray)
                        }
                        .frame(width: 50, height: 50)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(municipality.name)
                                .font(.headline)
                            Text("Election: \(municipality.formattedElectionDate)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// A candidate plus the municipality it belongs to, so the detail screen
// can show the municipality name (the candidate DTO only has its id).
struct CandidateRoute: Hashable {
    let candidate: Candidate
    let municipality: Municipality
}

#Preview {
    MunicipalitiesView(api: MockAPIClient())
        .environment(SessionViewModel())
}

#Preview("Error") {
    MunicipalitiesView(api: MockAPIClient(shouldFail: true))
        .environment(SessionViewModel())
}
