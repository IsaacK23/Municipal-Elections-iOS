//
//  MySelectionsView.swift
//  MunicipalElectionsManagementSystem
//

import SwiftUI

// "My Candidate Selections": the user's saved candidates for their municipality, from Firestore.
// Shown inside a NavigationStack provided by MainTabView.
struct MySelectionsView: View {
    @Environment(SelectionsViewModel.self) private var selections
    @Environment(MunicipalitySettingsViewModel.self) private var settings
    @State private var editing: CandidateSelection?
    @State private var pendingDelete: CandidateSelection?
    @State private var actionError: String?

    private var municipalityName: String {
        settings.municipality?.name ?? ""
    }

    // Selections grouped under each position, in ballot order.
    private var groups: [(position: Position, items: [CandidateSelection])] {
        let positions = settings.municipality?.positions ?? []
        return positions.compactMap { position in
            let items = selections.selections.filter { $0.positionId == position.positionId }
            return items.isEmpty ? nil : (position, items)
        }
    }

    // Selections whose position no longer exists on the server, so they aren't silently hidden.
    private var ungrouped: [CandidateSelection] {
        let known = Set((settings.municipality?.positions ?? []).map(\.positionId))
        return selections.selections.filter { !known.contains($0.positionId) }
    }

    var body: some View {
        content
            .navigationTitle("My Candidate Selections")
            .navigationSubtitle("City: \(municipalityName)")
            // The full screen name doesn't fit as a large title on iPhone.
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await selections.refresh()
            }
            .sheet(item: $editing) { selection in
                SelectionEditorView(mode: .edit(selection))
            }
            .confirmationDialog(
                "Remove this candidate from your selections?",
                isPresented: Binding(
                    get: { pendingDelete != nil },
                    set: { if !$0 { pendingDelete = nil } }
                ),
                titleVisibility: .visible,
                presenting: pendingDelete
            ) { selection in
                Button("Remove \(selection.candidateName)", role: .destructive) {
                    Task { await delete(selection) }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert(
                "Couldn't Remove Selection",
                isPresented: Binding(
                    get: { actionError != nil },
                    set: { if !$0 { actionError = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(actionError ?? "")
            }
    }

    @ViewBuilder
    private var content: some View {
        if let message = selections.errorMessage, selections.selections.isEmpty {
            ErrorStateView(message: message) {
                Task { await selections.refresh() }
            }
        } else if !selections.hasLoaded {
            ProgressView("Loading your selections…")
        } else if selections.selections.isEmpty {
            ContentUnavailableView {
                Label("No Selections Yet", systemImage: "checklist")
            } description: {
                Text("Open a candidate in the Candidates tab and tap Add Selection to save them here.")
            }
        } else {
            List {
                // A refresh failed but older data is still shown.
                if let message = selections.errorMessage {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }

                ForEach(groups, id: \.position.positionId) { group in
                    Section {
                        ForEach(group.items) { selection in
                            row(for: selection)
                        }
                    } header: {
                        Text(group.position.name)
                    } footer: {
                        Text("\(group.items.count) of \(group.position.seatsAvailable) selected")
                    }
                }

                if !ungrouped.isEmpty {
                    Section("Other") {
                        ForEach(ungrouped) { selection in
                            row(for: selection)
                        }
                    }
                }
            }
        }
    }

    private func row(for selection: CandidateSelection) -> some View {
        SelectionRow(selection: selection)
            .contentShape(.rect)
            .onTapGesture { editing = selection }
            .swipeActions(edge: .trailing) {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    pendingDelete = selection
                }
                Button("Edit", systemImage: "pencil") {
                    editing = selection
                }
                .tint(.blue)
            }
            .contextMenu {
                Button("Edit Notes", systemImage: "pencil") { editing = selection }
                Button("Remove", systemImage: "trash", role: .destructive) {
                    pendingDelete = selection
                }
            }
            .accessibilityAction(named: "Edit Notes") { editing = selection }
            .accessibilityAction(named: "Remove") { pendingDelete = selection }
    }

    private func delete(_ selection: CandidateSelection) async {
        do {
            try await selections.delete(selection)
        } catch {
            actionError = error.localizedDescription
        }
    }
}

// One saved selection: photo, name, position, municipality, notes and date saved.
struct SelectionRow: View {
    let selection: CandidateSelection

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CandidatePhotoView(photoUrl: selection.photoUrl, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(selection.candidateName)
                    .font(.headline)
                Text("\(selection.positionName) · \(selection.municipalityName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !selection.notes.isEmpty {
                    Text(selection.notes)
                        .font(.callout)
                        .padding(.top, 2)
                }

                Text("Saved \(selection.dateCreated.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        MySelectionsView()
    }
    .environment(SelectionsViewModel.preview())
    .environment(MunicipalitySettingsViewModel.preview())
}

#Preview("Empty") {
    NavigationStack {
        MySelectionsView()
    }
    .environment(SelectionsViewModel.preview(selections: []))
    .environment(MunicipalitySettingsViewModel.preview())
}
