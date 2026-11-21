//
//  CandidatesView.swift
//  MunicipalElectionsManagementSystem
//

import SwiftUI

// Candidate directory for one municipality. Pushed inside a NavigationStack;
// the parent registers the CandidateRoute destination.
//
// Adaptive layout:
// - iPhone portrait: single-column list.
// - iPhone landscape: list rows show extra details (biography excerpt, contact) across the width.
// - iPad (portrait and landscape): grid of cards; the adaptive columns add more cards per row
//   as the width grows, so landscape gets more columns than portrait.
struct CandidatesView: View {
    @Environment(SessionViewModel.self) private var session
    @Environment(SelectionsViewModel.self) private var selections
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
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
        } else if horizontalSizeClass == .regular {
            grid
        } else {
            List(viewModel.candidates) { candidate in
                NavigationLink(value: route(for: candidate)) {
                    CandidateRow(
                        candidate: candidate,
                        showsDetails: verticalSizeClass == .compact,
                        isSelected: isSelected(candidate)
                    )
                }
            }
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 16)], spacing: 16) {
                ForEach(viewModel.candidates) { candidate in
                    NavigationLink(value: route(for: candidate)) {
                        CandidateCard(candidate: candidate, isSelected: isSelected(candidate))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func route(for candidate: Candidate) -> CandidateRoute {
        CandidateRoute(candidate: candidate, municipality: viewModel.municipality)
    }

    private func isSelected(_ candidate: Candidate) -> Bool {
        selections.selection(forCandidateId: candidate.candidateId) != nil
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

// A candidate plus their municipality, so the detail screen can show the election date.
struct CandidateRoute: Hashable {
    let candidate: Candidate
    let municipality: Municipality
}

// List row. `showsDetails` (iPhone landscape) uses the extra width for a biography
// excerpt and contact details.
struct CandidateRow: View {
    let candidate: Candidate
    var showsDetails = false
    var isSelected = false

    var body: some View {
        HStack(alignment: showsDetails ? .top : .center, spacing: 12) {
            CandidatePhotoView(photoUrl: candidate.photoUrl)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(candidate.name)
                        .font(.headline)
                    if isSelected {
                        SelectedBadge()
                    }
                }
                Text(candidate.positionName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 160, alignment: .leading)

            if showsDetails {
                VStack(alignment: .leading, spacing: 4) {
                    Text(candidate.biography)
                        .font(.callout)
                        .lineLimit(2)
                    if let contact = candidate.email ?? candidate.website {
                        Text(contact)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 4)
    }
}

// Grid card for iPad.
struct CandidateCard: View {
    let candidate: Candidate
    var isSelected = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                CandidatePhotoView(photoUrl: candidate.photoUrl, size: 72)
                VStack(alignment: .leading, spacing: 4) {
                    Text(candidate.name)
                        .font(.headline)
                    Text(candidate.positionName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if isSelected {
                        SelectedBadge()
                    }
                }
                Spacer(minLength: 0)
            }
            Text(candidate.biography)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
        .contentShape(.rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// Marks a candidate that's already in My Candidate Selections.
struct SelectedBadge: View {
    var body: some View {
        Label("Selected", systemImage: "checkmark.circle.fill")
            .labelStyle(.iconOnly)
            .foregroundStyle(.green)
            .accessibilityLabel("In your selections")
    }
}

#Preview {
    NavigationStack {
        CandidatesView(api: MockAPIClient(), municipality: .burnaby)
    }
    .environment(SessionViewModel())
    .environment(SelectionsViewModel.preview())
}
