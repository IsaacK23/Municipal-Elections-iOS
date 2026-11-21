//
//  CandidateDetailView.swift
//  MunicipalElectionsManagementSystem
//

import SwiftUI

struct CandidateDetailView: View {
    let candidate: Candidate
    let municipality: Municipality

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                VStack(alignment: .leading, spacing: 8) {
                    Text("Biography")
                        .font(.title3.bold())
                    Text(candidate.biography)
                }

                if candidate.website != nil || candidate.email != nil {
                    contactSection
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(candidate.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            CandidatePhotoView(photoUrl: candidate.photoUrl, size: 120)
            VStack(alignment: .leading, spacing: 6) {
                Text(candidate.name)
                    .font(.title2.bold())
                Label(candidate.positionName, systemImage: "person.text.rectangle")
                Label(municipality.name, systemImage: "building.columns")
                Label(municipality.formattedElectionDate, systemImage: "calendar")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var contactSection: some View {
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

#Preview {
    NavigationStack {
        CandidateDetailView(candidate: .eleanorVasquez, municipality: .burnaby)
    }
}
