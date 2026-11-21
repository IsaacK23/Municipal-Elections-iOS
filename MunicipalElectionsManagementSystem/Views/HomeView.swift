//
//  HomeView.swift
//  MunicipalElectionsManagementSystem
//

import SwiftUI

// Home tab: the configured municipality, its election date and the positions on the ballot.
struct HomeView: View {
    @Environment(SessionViewModel.self) private var session
    @State private var viewModel: HomeViewModel

    init(api: any APIClientProtocol = APIClient(), municipality: Municipality) {
        _viewModel = State(initialValue: HomeViewModel(api: api, municipality: municipality))
    }

    private var municipality: Municipality { viewModel.municipality }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    header
                }

                Section("Election") {
                    LabeledContent("Election Day", value: municipality.formattedElectionDate)
                    LabeledContent("Province", value: municipality.province)
                    if let description = municipality.description, !description.isEmpty {
                        Text(description)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    positionsContent
                } header: {
                    Text("Positions on the Ballot")
                } footer: {
                    Text("You can select up to the number of seats for each position.")
                }
            }
            .navigationTitle("Home")
            .navigationSubtitle("City: \(municipality.name)")
            .task {
                await viewModel.load(session: session)
            }
            .refreshable {
                await viewModel.load(session: session)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            AsyncImage(url: APIConfig.imageURL(for: municipality.logoUrl)) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Image(systemName: "building.columns.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.tint)
                    .padding(8)
            }
            .frame(width: 64, height: 64)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Municipal Elections Companion")
                    .font(.headline)
                Text("City: \(municipality.name)")
                    .font(.title2.bold())
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var positionsContent: some View {
        if let message = viewModel.errorMessage, viewModel.positions.isEmpty {
            ErrorStateView(message: message) {
                Task { await viewModel.load(session: session) }
            }
        } else if viewModel.isLoading && viewModel.positions.isEmpty {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        } else if viewModel.positions.isEmpty {
            Text("No positions have been set up for this election yet.")
                .foregroundStyle(.secondary)
        } else {
            ForEach(viewModel.positions) { position in
                LabeledContent(position.name) {
                    Text(position.seatsAvailable == 1 ? "1 seat" : "\(position.seatsAvailable) seats")
                }
            }
        }
    }
}

#Preview {
    HomeView(api: MockAPIClient(), municipality: .burnaby)
        .environment(SessionViewModel())
}
