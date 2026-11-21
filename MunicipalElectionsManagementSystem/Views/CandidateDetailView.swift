//
//  CandidateDetailView.swift
//  MunicipalElectionsManagementSystem
//

import SwiftUI

// Candidate information from the API, plus Add / Edit / Delete Selection for Firestore.
// Adapts to the space available: photo beside the details on iPad and iPhone landscape,
// stacked vertically on iPhone portrait.
struct CandidateDetailView: View {
    let candidate: Candidate
    let municipality: Municipality

    @Environment(SelectionsViewModel.self) private var selections
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var editorSheet: EditorSheet?
    @State private var showDeleteConfirmation = false
    @State private var actionError: String?

    private var savedSelection: CandidateSelection? {
        selections.selection(forCandidateId: candidate.candidateId)
    }

    // Side by side when there's width to spare: any iPad, or an iPhone turned sideways.
    private var isWide: Bool {
        horizontalSizeClass == .regular || verticalSizeClass == .compact
    }

    var body: some View {
        ScrollView {
            Group {
                if isWide {
                    HStack(alignment: .top, spacing: 32) {
                        VStack(spacing: 16) {
                            CandidatePhotoView(photoUrl: candidate.photoUrl, size: 220)
                            selectionActions
                        }
                        .frame(width: 240)

                        VStack(alignment: .leading, spacing: 20) {
                            summary
                            biography
                            contact
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .top, spacing: 16) {
                            CandidatePhotoView(photoUrl: candidate.photoUrl, size: 120)
                            summary
                        }
                        selectionActions
                        biography
                        contact
                    }
                }
            }
            .padding()
            // Keeps lines readable on a 13-inch iPad in landscape.
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(candidate.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editorSheet) { sheet in
            SelectionEditorView(mode: sheet.mode)
        }
        .confirmationDialog(
            "Remove \(candidate.name) from your selections?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                Task { await deleteSelection() }
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

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(candidate.name)
                .font(.title2.bold())
            Label(candidate.positionName, systemImage: "person.text.rectangle")
            Label(candidate.municipalityName, systemImage: "building.columns")
            Label(municipality.formattedElectionDate, systemImage: "calendar")
                .foregroundStyle(.secondary)
        }
    }

    private var biography: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Biography")
                .font(.title3.bold())
            Text(candidate.biography)
        }
    }

    @ViewBuilder
    private var contact: some View {
        if candidate.website != nil || candidate.email != nil {
            VStack(alignment: .leading, spacing: 8) {
                Text("Contact")
                    .font(.title3.bold())
                if let website = candidate.website, let url = URL(string: website) {
                    Link(destination: url) {
                        Label(website, systemImage: "globe")
                    }
                }
                if let email = candidate.email, let url = URL(string: "mailto:\(email)") {
                    Link(destination: url) {
                        Label(email, systemImage: "envelope")
                    }
                }
            }
        }
    }

    // Add Selection, or Edit / Delete Selection once saved.
    private var selectionActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let savedSelection {
                Label("In your selections", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
                if !savedSelection.notes.isEmpty {
                    Text(savedSelection.notes)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                // Buttons side by side if they fit, otherwise stacked.
                ViewThatFits(in: .horizontal) {
                    HStack {
                        editButton(savedSelection)
                        deleteButton
                    }
                    VStack(alignment: .leading) {
                        editButton(savedSelection)
                        deleteButton
                    }
                }
            } else {
                Button {
                    editorSheet = EditorSheet(mode: .add(candidate))
                } label: {
                    Label("Add Selection", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!selections.hasLoaded || addBlockedReason != nil)

                if let addBlockedReason {
                    Text(addBlockedReason)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if !selections.hasLoaded {
                    Text(selections.errorMessage ?? "Loading your selections…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Why this candidate can't be added right now (e.g. the seat limit is reached).
    private var addBlockedReason: String? {
        guard selections.hasLoaded else { return nil }
        return selections.addError(for: candidate, notes: "")
    }

    private func editButton(_ selection: CandidateSelection) -> some View {
        Button {
            editorSheet = EditorSheet(mode: .edit(selection))
        } label: {
            Label("Edit Selection", systemImage: "pencil")
        }
        .buttonStyle(.bordered)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            Label("Delete Selection", systemImage: "trash")
        }
        .buttonStyle(.bordered)
    }

    private func deleteSelection() async {
        guard let savedSelection else { return }
        do {
            try await selections.delete(savedSelection)
        } catch {
            actionError = error.localizedDescription
        }
    }
}

// Wraps the editor mode so it can drive .sheet(item:), which needs Identifiable.
private struct EditorSheet: Identifiable {
    let mode: SelectionEditorView.Mode

    var id: String {
        switch mode {
        case .add(let candidate): "add-\(candidate.candidateId)"
        case .edit(let selection): "edit-\(selection.id)"
        }
    }
}

#Preview("Not Saved") {
    NavigationStack {
        CandidateDetailView(candidate: .weiZhang, municipality: .pittMeadows)
    }
    .environment(SelectionsViewModel.preview(.pittMeadows, selections: []))
}

#Preview("Saved") {
    NavigationStack {
        CandidateDetailView(candidate: .eleanorVasquez, municipality: .burnaby)
    }
    .environment(SelectionsViewModel.preview())
}
