//
//  EmailService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import UIKit

/// Errors that can occur in the email service
enum EmailServiceError: Error, LocalizedError {
    case invalidEmail
    case cannotCreateMailtoURL
    case cannotOpenMailApp

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Invalid email address provided"
        case .cannotCreateMailtoURL:
            return "Could not create mailto: URL"
        case .cannotOpenMailApp:
            return "Cannot open mail application"
        }
    }
}

/// Protocol defining the email service interface
protocol EmailServiceProtocol {
    /// Prepare an email for sending via the system mail app
    /// - Parameters:
    ///   - to: Recipient email address(es)
    ///   - subject: Email subject
    ///   - body: Email body (plain text or HTML)
    /// - Returns: mailto: URL to open the mail app
    /// - Throws: EmailServiceError if email cannot be prepared
    func prepareEmail(to: String, subject: String, body: String) throws -> URL

    /// Check if email can be sent (mailto: URLs are available)
    /// - Returns: true if email functionality is available
    func canSendEmail() -> Bool

    /// Open the mail app with the prepared email
    /// - Parameters:
    ///   - to: Recipient email address(es)
    ///   - subject: Email subject
    ///   - body: Email body (plain text or HTML)
    /// - Throws: EmailServiceError if email cannot be opened
    func sendEmail(to: String, subject: String, body: String) async throws
}

/// Concrete implementation of the email service
/// Uses mailto: URL scheme to open the system mail app
class EmailService: EmailServiceProtocol {

    // MARK: - Initialization

    init() {}

    // MARK: - EmailServiceProtocol

    func prepareEmail(to: String, subject: String, body: String) throws -> URL {
        // Validate email address
        guard !to.isEmpty, isValidEmail(to) else {
            throw EmailServiceError.invalidEmail
        }

        // Create mailto: URL with parameters
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = to

        // Add subject and body as query items
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]

        guard let url = components.url else {
            throw EmailServiceError.cannotCreateMailtoURL
        }

        return url
    }

    func canSendEmail() -> Bool {
        // mailto: URLs are always available on iOS devices
        return true
    }

    func sendEmail(to: String, subject: String, body: String) async throws {
        let url = try prepareEmail(to: to, subject: subject, body: body)

        // Open the URL using UIApplication (must be called on main thread)
        await MainActor.run {
            guard UIApplication.shared.canOpenURL(url) else {
                return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    // MARK: - Private Helpers

    /// Validate email address format
    private func isValidEmail(_ email: String) -> Bool {
        // Support comma-separated list of emails
        let emails = email.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        for emailAddress in emails {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: emailAddress) {
                return false
            }
        }

        return true
    }
}
