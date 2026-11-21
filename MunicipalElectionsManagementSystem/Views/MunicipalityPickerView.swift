//
//  MunicipalityPickerView.swift
//  MunicipalElectionsManagementSystem
//

import SwiftUI

// Lets the user choose the municipality they live in.
// Shown full screen on first login, and as a sheet from Profile to change it.
// Expects to be inside a NavigationStack.
struct MunicipalityPickerView: View {
    enum Mode {
        case firstLogin
        case change
    }

    @Environment(SessionViewModel.self) private var session
    @Environment(MunicipalitySettingsViewModel.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MunicipalitiesViewModel
    @State private var selectedId: Int?
    private let mode: Mode

    init(api: any APIClientProtocol = APIClient(), mode: Mode) {
        self.mode = mode
        _viewModel = State(initialValue: MunicipalitiesViewModel(api: api))
    }

    private var selectedMunicipality: Municipality? {
        viewModel.municipalities.first { $0.municipalityId == selectedId }
    }

    // In change mode, saving the current city again is pointless.
    private var canSave: Bool {
        guard let selectedId, !settings.isSaving else { return false }
        return mode == .firstLogin || selectedId != settings.municipality?.municipalityId
    }

    var body: some View {
        content
            .navigationTitle(mode == .firstLogin ? "Your Municipality" : "Change Municipality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .task {
                selectedId = selectedId ?? settings.municipality?.municipalityId
                if viewModel.municipalities.isEmpty {
                    await viewModel.load()
                }
            }
            .alert(
                "Couldn't Save",
                isPresented: Binding(
                    get: { settings.saveError != nil },
                    set: { if !$0 { settings.clearSaveError() } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(settings.saveError ?? "")
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
            List {
                Section {
                    ForEach(viewModel.municipalities) { municipality in
                        Button {
                            selectedId = municipality.municipalityId
                        } label: {
                            row(for: municipality)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selectedId == municipality.municipalityId ? .isSelected : [])
                    }
                } header: {
                    Text("Where do you live?")
                } footer: {
                    Text(mode == .firstLogin
                         ? "You'll only see candidates and election information for this municipality. You can change it later in Profile."
                         : "Candidates, positions and your saved selections will switch to the new municipality.")
                }
            }
        }
    }

    private func row(for municipality: Municipality) -> some View {
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
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(municipality.name)
                    .font(.headline)
                Text("Election: \(municipality.formattedElectionDate)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if selectedId == municipality.municipalityId {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(.rect)
        .padding(.vertical, 4)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        switch mode {
        case .firstLogin:
            // Lets a user who logged in with the wrong account get back out.
            ToolbarItem(placement: .cancellationAction) {
                Button("Log Out") { session.logout() }
            }
        case .change:
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            if settings.isSaving {
                ProgressView()
            } else {
                Button(mode == .firstLogin ? "Continue" : "Save") {
                    guard let selectedMunicipality else { return }
                    Task {
                        if await settings.select(selectedMunicipality), mode == .change {
                            dismiss()
                        }
                    }
                }
                .disabled(!canSave)
            }
        }
    }
}

#Preview("First Login") {
    NavigationStack {
        MunicipalityPickerView(api: MockAPIClient(), mode: .firstLogin)
    }
    .environment(SessionViewModel())
    .environment(MunicipalitySettingsViewModel.preview())
}
