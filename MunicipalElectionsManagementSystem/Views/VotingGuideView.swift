import SwiftUI

// my voting guide tab: saved candidates, swipe left to remove
struct VotingGuideView: View {
    @Environment(SessionViewModel.self) private var session
    @State private var viewModel: VotingGuideViewModel
    private let api: any APIClientProtocol  // passed on to the detail screen

    init(api: any APIClientProtocol = APIClient()) {
        self.api = api
        _viewModel = State(initialValue: VotingGuideViewModel(api: api))
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.isLoading && viewModel.saved.isEmpty {
                    ProgressView()
                } else if let message = viewModel.errorMessage {
                    ErrorStateView(message: message) {
                        Task { await viewModel.load(session: session) }
                    }
                } else if viewModel.saved.isEmpty {
                    Text("No saved candidates yet. Add some from the Candidates tab.")
                        .foregroundStyle(.secondary)
                }

                ForEach(viewModel.saved) { item in
                    NavigationLink(value: item.candidate) {
                        CandidateRow(candidate: item.candidate)
                    }
                }
                .onDelete { offsets in
                    Task { await viewModel.remove(at: offsets, session: session) }
                }
            }
            .navigationTitle("My Voting Guide")
            .navigationDestination(for: Candidate.self) { candidate in
                CandidateDetailView(candidate: candidate, api: api)
            }
            // reload each time the tab opens so new saves show up
            .onAppear {
                Task { await viewModel.load(session: session) }
            }
        }
    }
}

#Preview {
    VotingGuideView(api: MockAPIClient())
        .environment(SessionViewModel())
}
