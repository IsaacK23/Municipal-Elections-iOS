import Foundation

// turns a photoUrl or logoUrl from the api into a full url
enum ImageURL {
    static func make(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }

        // the api already sends full urls
        if path.hasPrefix("http") {
            return URL(string: path)
        }

        // otherwise put the server address in front ("/api" taken off the end)
        let server = String(APIConfig.baseURL.dropLast(4))
        return URL(string: server + path)
    }
}
