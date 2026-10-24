import SwiftUI

// municipalities tab: logo, name and election date
struct MunicipalitiesView: View {
    @State private var viewModel: MunicipalitiesViewModel

    init(api: any APIClientProtocol = APIClient()) {
        _viewModel = State(initialValue: MunicipalitiesViewModel(api: api))
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.isLoading {
                    ProgressView()
                }

                if let message = viewModel.errorMessage {
                    ErrorStateView(message: message) {
                        Task { await viewModel.load() }
                    }
                }

                ForEach(viewModel.municipalities) { municipality in
                    HStack {
                        // placeholder if there is no logo
                        AsyncImage(url: ImageURL.make(municipality.logoUrl)) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "building.columns")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(.gray)
                        }
                        .frame(width: 50, height: 50)

                        VStack(alignment: .leading) {
                            Text(municipality.name)
                                .font(.headline)
                            Text(municipality.formattedElectionDate)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Municipalities")
            .onAppear {
                Task { await viewModel.load() }
            }
        }
    }
}

#Preview {
    MunicipalitiesView(api: MockAPIClient())
        .environment(SessionViewModel())
}
