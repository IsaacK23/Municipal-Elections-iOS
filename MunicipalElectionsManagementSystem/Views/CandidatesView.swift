import SwiftUI

// candidates tab: search by name, filter by municipality and position
struct CandidatesView: View {
    @State private var viewModel: CandidatesViewModel
    private let api: any APIClientProtocol  // passed on to the detail screen

    init(api: any APIClientProtocol = APIClient()) {
        self.api = api
        _viewModel = State(initialValue: CandidatesViewModel(api: api))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Search by name", text: $viewModel.searchText)

                    Picker("Municipality", selection: $viewModel.municipalityId) {
                        Text("All").tag(0)
                        ForEach(viewModel.municipalities) { municipality in
                            Text(municipality.name).tag(municipality.municipalityId)
                        }
                    }

                    Picker("Position", selection: $viewModel.positionId) {
                        Text("All").tag(0)
                        ForEach(viewModel.positions) { position in
                            Text("\(position.municipalityName) - \(position.name)").tag(position.positionId)
                        }
                    }

                    Button("Search") {
                        Task { await viewModel.load() }
                    }
                }

                Section {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if let message = viewModel.errorMessage {
                        ErrorStateView(message: message) {
                            Task { await viewModel.load() }
                        }
                    } else if viewModel.candidates.isEmpty {
                        Text("No candidates found.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(viewModel.candidates) { candidate in
                        NavigationLink(value: candidate) {
                            CandidateRow(candidate: candidate)
                        }
                    }
                }
            }
            .navigationTitle("Candidates")
            .navigationDestination(for: Candidate.self) { candidate in
                CandidateDetailView(candidate: candidate, api: api)
            }
            // fill the pickers, then load the candidates
            .onAppear {
                Task {
                    await viewModel.loadMunicipalities()
                    await viewModel.load()
                }
            }
        }
    }
}

#Preview {
    CandidatesView(api: MockAPIClient())
        .environment(SessionViewModel())
}
