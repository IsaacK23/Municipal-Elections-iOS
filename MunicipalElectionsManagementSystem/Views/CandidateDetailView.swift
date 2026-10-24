import SwiftUI

// candidate details: photo, biography, website, email and add to voting guide
struct CandidateDetailView: View {
    @Environment(SessionViewModel.self) private var session
    @State private var viewModel: CandidateDetailViewModel

    init(candidate: Candidate, api: any APIClientProtocol = APIClient()) {
        _viewModel = State(initialValue: CandidateDetailViewModel(candidate: candidate, api: api))
    }

    var body: some View {
        let candidate = viewModel.candidate  // shorter name for the code below

        Form {
            Section {
                // placeholder if there is no photo
                AsyncImage(url: ImageURL.make(candidate.photoUrl)) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.gray)
                }
                .frame(width: 200, height: 200)

                Text(candidate.name)
                    .font(.title2)
                    .fontWeight(.bold)
                Text("\(candidate.positionName), \(candidate.municipalityName)")
                    .foregroundStyle(.secondary)
            }

            Section(header: Text("Biography")) {
                Text(candidate.biography)
            }

            // website and email are optional
            if candidate.website != nil || candidate.email != nil {
                Section(header: Text("Contact")) {
                    if let website = candidate.website {
                        Text(website)
                    }
                    if let email = candidate.email {
                        Text(email)
                    }
                }
            }

            Section {
                Button("Add to Voting Guide") {
                    Task { await viewModel.addToGuide(session: session) }
                }
                .disabled(viewModel.isSaving)

                if let message = viewModel.message {
                    Text(message)
                        .foregroundStyle(.green)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(candidate.name)
    }
}

#Preview {
    NavigationStack {
        CandidateDetailView(candidate: .eleanorVasquez, api: MockAPIClient())
    }
    .environment(SessionViewModel())
}
