//
//  SelectionEditorView.swift
//  MunicipalElectionsManagementSystem
//

import SwiftUI

// Sheet for adding a candidate to My Candidate Selections, or editing a saved selection's notes.
// The draft notes live in this view's @State, so they survive rotation while the sheet is open.
struct SelectionEditorView: View {
    enum Mode {
        case add(Candidate)
        case edit(CandidateSelection)
    }

    @Environment(SelectionsViewModel.self) private var selections
    @Environment(\.dismiss) private var dismiss
    @State private var notes: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    private let mode: Mode

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add:
            _notes = State(initialValue: "")
        case .edit(let selection):
            _notes = State(initialValue: selection.notes)
        }
    }

    private var isAdding: Bool {
        if case .add = mode { return true }
        return false
    }

    private var notesCount: Int {
        notes.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    private var notesError: String? {
        Validators.notesError(notes)
    }

    // Problems that block saving before the user even taps Save (duplicate, seat limit).
    private var blockingError: String? {
        if case .add(let candidate) = mode {
            return selections.addError(for: candidate, notes: notes)
        }
        return notesError
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    header
                }

                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 140)
                        .accessibilityLabel("Notes")
                } header: {
                    Text("Notes (optional)")
                } footer: {
                    HStack(alignment: .top) {
                        if let notesError {
                            Text(notesError)
                                .foregroundStyle(.red)
                        } else {
                            Text("Why you chose this candidate, questions to ask, and so on.")
                        }
                        Spacer()
                        Text("\(notesCount)/\(CandidateSelection.maxNotesLength)")
                            .monospacedDigit()
                            .foregroundStyle(notesError == nil ? Color.secondary : Color.red)
                    }
                }

                if let message = errorMessage ?? (notesError == nil ? blockingError : nil) {
                    Section {
                        Label(message, systemImage: "exclamationmark.circle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isAdding ? "Add Selection" : "Edit Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task { await save() }
                        }
                        .disabled(blockingError != nil)
                    }
                }
            }
            // Don't lose typed notes to an accidental swipe-down.
            .interactiveDismissDisabled(isSaving || !Validators.isBlank(notes))
        }
    }

    @ViewBuilder
    private var header: some View {
        switch mode {
        case .add(let candidate):
            summary(name: candidate.name, photoUrl: candidate.photoUrl,
                    position: candidate.positionName, municipality: candidate.municipalityName,
                    positionId: candidate.positionId)
        case .edit(let selection):
            summary(name: selection.candidateName, photoUrl: selection.photoUrl,
                    position: selection.positionName, municipality: selection.municipalityName,
                    positionId: nil)
        }
    }

    private func summary(name: String, photoUrl: String?, position: String, municipality: String, positionId: Int?) -> some View {
        HStack(spacing: 12) {
            CandidatePhotoView(photoUrl: photoUrl, size: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                Text("\(position) · \(municipality)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let positionId, let remaining = selections.remainingSeats(forPositionId: positionId) {
                    Text(remaining == 1 ? "1 \(position) spot left" : "\(remaining) \(position) spots left")
                        .font(.caption)
                        .foregroundStyle(remaining == 0 ? Color.red : Color.secondary)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            switch mode {
            case .add(let candidate):
                try await selections.add(candidate, notes: notes)
            case .edit(let selection):
                try await selections.update(selection, notes: notes)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("Add") {
    SelectionEditorView(mode: .add(.marcusLeeSample))
        .environment(SelectionsViewModel.preview())
}

#Preview("Edit") {
    SelectionEditorView(mode: .edit(CandidateSelection.samples[0]))
        .environment(SelectionsViewModel.preview())
}

private extension Candidate {
    static let marcusLeeSample = Candidate(
        candidateId: 3, name: "Marcus Lee", biography: "", photoUrl: nil, website: nil, email: nil,
        positionId: 8, positionName: "Councilor", municipalityId: 3, municipalityName: "Burnaby"
    )
}
