//
//  EmailServiceTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

/// Tests for EmailService
/// Tests email preparation and mailto: URL generation
final class EmailServiceTests: XCTestCase {

    // MARK: - Properties

    var sut: EmailService!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = EmailService()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    // MARK: - Can Send Email Tests

    func testCanSendEmail_ReturnsTrue() {
        // Act
        let canSend = sut.canSendEmail()

        // Assert
        // mailto: URLs are always available on iOS
        XCTAssertTrue(canSend, "Should always be able to prepare mailto: URLs")
    }

    // MARK: - Prepare Email Tests

    func testPrepareEmail_WithValidParams_ReturnsMailtoURL() throws {
        // Arrange
        let to = "parent@example.com"
        let subject = "FocusPal Weekly Summary"
        let body = "<html><body>Test</body></html>"

        // Act
        let url = try sut.prepareEmail(to: to, subject: subject, body: body)

        // Assert
        XCTAssertNotNil(url, "Should return a URL")
        XCTAssertTrue(url.absoluteString.hasPrefix("mailto:"), "Should be a mailto: URL")
        XCTAssertTrue(url.absoluteString.contains(to), "Should include recipient email")
    }

    func testPrepareEmail_WithSpecialCharacters_EncodesCorrectly() throws {
        // Arrange
        let to = "test@example.com"
        let subject = "Test & Subject"
        let body = "Body with spaces and & special chars"

        // Act
        let url = try sut.prepareEmail(to: to, subject: subject, body: body)

        // Assert
        XCTAssertNotNil(url)
        // URL should be properly encoded
        XCTAssertTrue(url.absoluteString.contains("%"), "Should contain URL encoding")
    }

    func testPrepareEmail_WithEmptyRecipient_ThrowsError() {
        // Arrange
        let to = ""
        let subject = "Test"
        let body = "Test body"

        // Act & Assert
        XCTAssertThrowsError(try sut.prepareEmail(to: to, subject: subject, body: body)) { error in
            guard case EmailServiceError.invalidEmail = error else {
                XCTFail("Expected invalidEmail error, got \(error)")
                return
            }
        }
    }

    func testPrepareEmail_WithInvalidEmail_ThrowsError() {
        // Arrange
        let to = "not-an-email"
        let subject = "Test"
        let body = "Test body"

        // Act & Assert
        XCTAssertThrowsError(try sut.prepareEmail(to: to, subject: subject, body: body)) { error in
            guard case EmailServiceError.invalidEmail = error else {
                XCTFail("Expected invalidEmail error, got \(error)")
                return
            }
        }
    }

    func testPrepareEmail_WithHTMLBody_HandlesCorrectly() throws {
        // Arrange
        let to = "test@example.com"
        let subject = "HTML Email"
        let body = """
        <!DOCTYPE html>
        <html>
        <head><title>Test</title></head>
        <body>
            <h1>Hello</h1>
            <p>This is a test with <strong>HTML</strong> tags.</p>
        </body>
        </html>
        """

        // Act
        let url = try sut.prepareEmail(to: to, subject: subject, body: body)

        // Assert
        XCTAssertNotNil(url)
        XCTAssertTrue(url.absoluteString.contains("mailto:"))
    }

    func testPrepareEmail_WithLongBody_DoesNotFail() throws {
        // Arrange
        let to = "test@example.com"
        let subject = "Long Email"
        let body = String(repeating: "This is a long email body. ", count: 100)

        // Act
        let url = try sut.prepareEmail(to: to, subject: subject, body: body)

        // Assert
        XCTAssertNotNil(url)
    }

    func testPrepareEmail_WithMultipleRecipients_SupportsCommaDelimiter() throws {
        // Arrange
        let to = "parent1@example.com,parent2@example.com"
        let subject = "Test"
        let body = "Test"

        // Act
        let url = try sut.prepareEmail(to: to, subject: subject, body: body)

        // Assert
        XCTAssertNotNil(url)
        XCTAssertTrue(url.absoluteString.contains(to.split(separator: ",")[0]))
    }
}
