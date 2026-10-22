//
//  Validators.swift
//  MunicipalElectionsManagementSystem
//
//  Created by Isaac Kehler on 2026-10-22.
//

import Foundation

// Each function returns nil (or an empty array) when the value is valid,
// otherwise the message(s) to show under the field.
nonisolated enum Validators {
    static let maxNameLength = 100
    static let minPasswordLength = 6
    static let emailPattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"

    static func isBlank(_ value: String) -> Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func requiredError(_ value: String, fieldName: String) -> String? {
        isBlank(value) ? "\(fieldName) is required." : nil
    }

    static func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.range(of: emailPattern, options: .regularExpression) != nil
    }

    static func emailError(_ value: String) -> String? {
        if let error = requiredError(value, fieldName: "Email") {
            return error
        }
        return isValidEmail(value) ? nil : "Enter a valid email address."
    }

    static func nameError(_ value: String) -> String? {
        if let error = requiredError(value, fieldName: "Name") {
            return error
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count > maxNameLength ? "Name must be \(maxNameLength) characters or fewer." : nil
    }

    // Matches the server's password rules. ASP.NET Identity only counts
    // ASCII A-Z, a-z and 0-9, so anything else is non-alphanumeric.
    static func passwordErrors(_ value: String) -> [String] {
        var errors: [String] = []
        if value.count < minPasswordLength {
            errors.append("At least \(minPasswordLength) characters.")
        }
        if !value.contains(where: { ("A"..."Z").contains($0) }) {
            errors.append("At least one uppercase letter (A-Z).")
        }
        if !value.contains(where: { ("a"..."z").contains($0) }) {
            errors.append("At least one lowercase letter (a-z).")
        }
        if !value.contains(where: { ("0"..."9").contains($0) }) {
            errors.append("At least one digit (0-9).")
        }
        if !value.contains(where: { !isASCIILetterOrDigit($0) }) {
            errors.append("At least one symbol, such as ! or #.")
        }
        return errors
    }

    static func confirmPasswordError(password: String, confirmPassword: String) -> String? {
        if isBlank(confirmPassword) {
            return "Confirm Password is required."
        }
        return password == confirmPassword ? nil : "Passwords do not match."
    }

    private static func isASCIILetterOrDigit(_ character: Character) -> Bool {
        ("A"..."Z").contains(character) || ("a"..."z").contains(character) || ("0"..."9").contains(character)
    }
}
