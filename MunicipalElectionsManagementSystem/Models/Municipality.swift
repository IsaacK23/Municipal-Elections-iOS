//
//  Municipality.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation

nonisolated struct Municipality: Codable, Identifiable, Hashable, Sendable {
    let municipalityId: Int
    let name: String
    let province: String
    let electionDate: String
    let description: String?
    let logoUrl: String?
    let positions: [Position]

    var id: Int { municipalityId }

    // electionDate is a plain calendar date ("2026-10-17"). Parsing it as ISO 8601
    // would treat it as midnight UTC and show the day before in Pacific time.
    var electionDay: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter.date(from: electionDate)
    }

    // e.g. "Saturday, October 17, 2026"
    var formattedElectionDate: String {
        guard let electionDay else { return electionDate }
        return electionDay.formatted(date: .complete, time: .omitted)
    }
}
