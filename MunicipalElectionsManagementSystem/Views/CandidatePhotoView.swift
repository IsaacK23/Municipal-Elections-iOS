//
//  CandidatePhotoView.swift
//  MunicipalElectionsManagementSystem
//

import SwiftUI

// Candidate photo from the API, with a person placeholder while loading,
// when the candidate has no photo, or when the image fails to load.
struct CandidatePhotoView: View {
    let photoUrl: String?
    var size: CGFloat = 56

    var body: some View {
        AsyncImage(url: APIConfig.imageURL(for: photoUrl)) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .padding(size * 0.1)
            }
        }
        .frame(width: size, height: size)
        .background(.quaternary)
        .clipShape(.rect(cornerRadius: size * 0.2))
        .accessibilityHidden(true)
    }
}

#Preview {
    CandidatePhotoView(photoUrl: nil, size: 120)
}
