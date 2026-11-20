//
//  CandidatesView.swift
//  MunicipalElectionsManagementSystem
//

import SwiftUI

// Candidate directory for one municipality. Pushed inside a NavigationStack;
// the parent registers the CandidateRoute destination.
struct CandidatesView: View {
    @Environment(SessionViewModel.self) private var session
    @State private var viewModel: CandidatesViewModel

    init(api: any APIClientProtocol = APIClient(), municipality: Municipality) {
        _viewModel = State(initialValue: CandidatesViewModel(api: api, municipality: municipality))
    }

    var body: some View {
        content
            .navigationTitle("Candidates")
            .navigationSubtitle("City: \(viewModel.municipality.name)")
            .searchable(text: $viewModel.searchText, prompt: "Search by name")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    positionMenu
                }
            }
            .task {
                await viewModel.loadPositions(session: session)
            }
            // Re-runs (and cancels the previous request) whenever the search or filter changes.
            .task(id: viewModel.queryKey) {
                // Short pause so typing a name doesn't send a request per keystroke.
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                await viewModel.loadCandidates(session: session)
            }
            .refreshable {
                await viewModel.loadCandidates(session: session)
            }
    }

    @ViewBuilder
    private var content: some View {
        if let message = viewModel.errorMessage, viewModel.candidates.isEmpty {
            ErrorStateView(message: message) {
                Task { await viewModel.loadCandidates(session: session) }
            }
        } else if viewModel.isLoading && viewModel.candidates.isEmpty {
            ProgressView()
        } else if viewModel.candidates.isEmpty {
            ContentUnavailableView {
                Label("No Candidates", systemImage: "person.3")
            } description: {
                Text(viewModel.hasActiveFilter
                     ? "No candidates match your search."
                     : "No candidates have registered in \(viewModel.municipality.name) yet.")
            } actions: {
                if viewModel.hasActiveFilter {
                    Button("Clear Filters") { viewModel.clearFilters() }
                }
            }
        } else {
            List(viewModel.candidates) { candidate in
                NavigationLink(value: CandidateRoute(candidate: candidate, municipality: viewModel.municipality)) {
                    CandidateRow(candidate: candidate)
                }
            }
        }
    }

    private var positionMenu: some View {
        Menu {
            Picker("Position", selection: $viewModel.selectedPositionId) {
                Text("All Positions").tag(Int?.none)
                ForEach(viewModel.positions) { position in
                    Text(position.name).tag(Optional(position.id))
                }
            }
        } label: {
            Label("Filter by Position", systemImage: viewModel.selectedPositionId == nil
                  ? "line.3.horizontal.decrease.circle"
                  : "line.3.horizontal.decrease.circle.fill")
        }
    }
}

struct CandidateRow: View {
    let candidate: Candidate

    var body: some View {
        HStack(spacing: 12) {
            CandidatePhotoView(photoUrl: candidate.photoUrl)
            VStack(alignment: .leading, spacing: 4) {
                Text(candidate.name)
                    .font(.headline)
                Text(candidate.positionName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        CandidatesView(api: MockAPIClient(), municipality: .burnaby)
    }
    .environment(SessionViewModel())
}
