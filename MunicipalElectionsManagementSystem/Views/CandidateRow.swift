import SwiftUI

// one candidate in a list: photo, name, position and municipality
struct CandidateRow: View {
    let candidate: Candidate

    var body: some View {
        HStack {
            // placeholder if there is no photo
            AsyncImage(url: ImageURL.make(candidate.photoUrl)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.gray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(candidate.name)
                    .font(.headline)
                Text(candidate.positionName)
                    .font(.subheadline)
                Text(candidate.municipalityName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    List {
        CandidateRow(candidate: .eleanorVasquez)
    }
}
