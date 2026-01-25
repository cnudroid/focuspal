//
//  EmailCompatibleContentBuilderTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

/// Tests for EmailCompatibleContentBuilder
/// Tests email-compatible HTML generation with table-based layouts
final class EmailCompatibleContentBuilderTests: XCTestCase {

    // MARK: - Properties

    var sut: EmailCompatibleContentBuilder!
    var calendar: Calendar!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = EmailCompatibleContentBuilder()
        calendar = Calendar.current
    }

    override func tearDownWithError() throws {
        sut = nil
        calendar = nil
        try super.tearDownWithError()
    }

    // MARK: - Helper Methods

    private func makeWeeklySummary(
        childName: String = "Emma",
        totalActivities: Int = 10,
        completedActivities: Int = 8,
        totalMinutes: Int = 300,
        netPoints: Int = 70,
        currentTier: RewardTier? = nil,
        topCategories: [(categoryName: String, minutes: Int)] = [],
        achievementsUnlocked: Int = 0,
        streak: Int = 0
    ) -> WeeklySummary {
        let weekStart = calendar.startOfDay(for: Date())
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        return WeeklySummary(
            childName: childName,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalActivities: totalActivities,
            completedActivities: completedActivities,
            incompleteActivities: totalActivities - completedActivities,
            totalMinutes: totalMinutes,
            pointsEarned: netPoints,
            pointsDeducted: 0,
            netPoints: netPoints,
            currentTier: currentTier,
            topCategories: topCategories,
            achievementsUnlocked: achievementsUnlocked,
            streak: streak
        )
    }

    // MARK: - Table Layout Tests

    func testBuildBody_UsesTableLayout() {
        // Arrange
        let summary = makeWeeklySummary()

        // Act
        let html = sut.buildEmailBody(summaries: [summary])

        // Assert
        XCTAssertTrue(html.contains("<table"), "HTML should use table elements for layout")
        XCTAssertTrue(html.contains("</table>"), "HTML should close table elements")
        XCTAssertTrue(html.contains("<tr"), "HTML should use table row elements")
        XCTAssertTrue(html.contains("<td"), "HTML should use table cell elements")
    }

    func testBuildBody_HasInlineStyles() {
        // Arrange
        let summary = makeWeeklySummary()

        // Act
        let html = sut.buildEmailBody(summaries: [summary])

        // Assert
        XCTAssertTrue(html.contains("style=\""), "HTML should use inline styles")

        // Count style attributes - should have many for email compatibility
        let styleCount = html.components(separatedBy: "style=\"").count - 1
        XCTAssertGreaterThan(styleCount, 10, "Should have many inline style attributes")
    }

    func testBuildBody_NoGridOrFlexbox() {
        // Arrange
        let summary = makeWeeklySummary()

        // Act
        let html = sut.buildEmailBody(summaries: [summary])

        // Assert - Grid and Flexbox break in Outlook
        XCTAssertFalse(html.contains("display: grid"), "Should not use CSS grid (breaks in Outlook)")
        XCTAssertFalse(html.contains("display:grid"), "Should not use CSS grid without space")
        XCTAssertFalse(html.contains("display: flex"), "Should not use flexbox (breaks in Outlook)")
        XCTAssertFalse(html.contains("display:flex"), "Should not use flexbox without space")
    }

    func testBuildBody_NoLinearGradient() {
        // Arrange
        let summary = makeWeeklySummary()

        // Act
        let html = sut.buildEmailBody(summaries: [summary])

        // Assert - Gradients don't work in email clients
        XCTAssertFalse(html.contains("linear-gradient"), "Should not use CSS gradients")
        XCTAssertFalse(html.contains("radial-gradient"), "Should not use radial gradients")
    }

    func testBuildBody_UsesWebSafeFonts() {
        // Arrange
        let summary = makeWeeklySummary()

        // Act
        let html = sut.buildEmailBody(summaries: [summary])

        // Assert - Should use web-safe fonts
        XCTAssertTrue(
            html.contains("Arial") || html.contains("Helvetica") || html.contains("sans-serif"),
            "Should use web-safe fonts"
        )
    }

    func testBuildBody_HasFixedContainerWidth() {
        // Arrange
        let summary = makeWeeklySummary()

        // Act
        let html = sut.buildEmailBody(summaries: [summary])

        // Assert - Fixed width for consistent email rendering
        XCTAssertTrue(
            html.contains("width=\"600\"") || html.contains("width=\"600") || html.contains("width: 600"),
            "Should have fixed container width for email compatibility"
        )
    }

    func testBuildBody_UsesSolidColors() {
        // Arrange
        let summary = makeWeeklySummary(currentTier: .gold)

        // Act
        let html = sut.buildEmailBody(summaries: [summary])

        // Assert - Should use solid hex colors
        let hexColorPattern = "#[0-9A-Fa-f]{6}"
        let regex = try? NSRegularExpression(pattern: hexColorPattern)
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex?.numberOfMatches(in: html, range: range) ?? 0

        XCTAssertGreaterThan(matches, 5, "Should use solid hex colors")
    }

    // MARK: - Content Tests

    func testBuildBody_ContainsChildName() {
        // Arrange
        let summary = makeWeeklySummary(childName: "TestChild")

        // Act
        let html = sut.buildEmailBody(summaries: [summary])

        // Assert
        XCTAssertTrue(html.contains("TestChild"), "Should include child name in email body")
    }

    func testBuildBody_ContainsStats() {
        // Arrange
        let summary = makeWeeklySummary(
            totalActivities: 15,
            completedActivities: 12,
            totalMinutes: 450,
            netPoints: 105
        )

        // Act
        let html = sut.buildEmailBody(summaries: [summary])

        // Assert
        XCTAssertTrue(html.contains("15"), "Should include total activities")
        XCTAssertTrue(html.contains("12"), "Should include completed activities")
        XCTAssertTrue(html.contains("105"), "Should include net points")
    }

    func testBuildBody_WithTier_ShowsTierBadge() {
        // Arrange
        let summary = makeWeeklySummary(currentTier: .gold)

        // Act
        let html = sut.buildEmailBody(summaries: [summary])

        // Assert
        XCTAssertTrue(
            html.contains("Gold") || html.contains("gold"),
            "Should include tier name"
        )
        XCTAssertTrue(
            html.contains("Tier") || html.contains("tier") || html.contains("Achieved"),
            "Should indicate tier achievement"
        )
    }

    func testBuildBody_WithCategories_ListsTopCategories() {
        // Arrange
        let summary = makeWeeklySummary(
            topCategories: [
                (categoryName: "Homework", minutes: 180),
                (categoryName: "Reading", minutes: 120)
            ]
        )

        // Act
        let html = sut.buildEmailBody(summaries: [summary])

        // Assert
        XCTAssertTrue(html.contains("Homework"), "Should include first category")
        XCTAssertTrue(html.contains("Reading"), "Should include second category")
    }

    func testBuildBody_WithHighlights_ShowsStreakAndAchievements() {
        // Arrange
        let summary = makeWeeklySummary(
            achievementsUnlocked: 2,
            streak: 3
        )

        // Act
        let html = sut.buildEmailBody(summaries: [summary])

        // Assert
        XCTAssertTrue(
            html.contains("2") && (html.contains("achievement") || html.contains("Achievement")),
            "Should include achievements count"
        )
        XCTAssertTrue(
            html.contains("3") && (html.contains("streak") || html.contains("Streak") || html.contains("week")),
            "Should include streak count"
        )
    }

    func testBuildBody_WithEmptySummaries_ReturnsValidHTML() {
        // Act
        let html = sut.buildEmailBody(summaries: [])

        // Assert
        XCTAssertTrue(html.contains("<html"), "Should return valid HTML")
        XCTAssertTrue(html.contains("</html>"), "Should have closing HTML tag")
        XCTAssertTrue(
            html.contains("No activity") || html.contains("no activity") || html.contains("available"),
            "Should indicate no data"
        )
    }

    func testBuildBody_MultipleSummaries_IncludesAllChildren() {
        // Arrange
        let summaries = [
            makeWeeklySummary(childName: "Emma"),
            makeWeeklySummary(childName: "Lucas")
        ]

        // Act
        let html = sut.buildEmailBody(summaries: summaries)

        // Assert
        XCTAssertTrue(html.contains("Emma"), "Should include first child")
        XCTAssertTrue(html.contains("Lucas"), "Should include second child")
    }

    // MARK: - Subject Line Tests

    func testBuildEmailSubject_IncludesChildName() {
        // Arrange
        let childName = "Emma"
        let weekEndDate = Date()

        // Act
        let subject = sut.buildEmailSubject(childName: childName, weekEndDate: weekEndDate)

        // Assert
        XCTAssertTrue(subject.contains("Emma"), "Subject should include child name")
    }

    func testBuildEmailSubject_IncludesFocusPal() {
        // Arrange
        let childName = "Emma"
        let weekEndDate = Date()

        // Act
        let subject = sut.buildEmailSubject(childName: childName, weekEndDate: weekEndDate)

        // Assert
        XCTAssertTrue(subject.contains("FocusPal"), "Subject should include app name")
    }

    func testBuildEmailSubject_IncludesReport() {
        // Arrange
        let childName = "Emma"
        let weekEndDate = Date()

        // Act
        let subject = sut.buildEmailSubject(childName: childName, weekEndDate: weekEndDate)

        // Assert
        XCTAssertTrue(
            subject.contains("Report") || subject.contains("Summary"),
            "Subject should indicate it's a report"
        )
    }

    // MARK: - HTML Validation Tests

    func testBuildBody_HasValidDoctype() {
        // Arrange
        let summary = makeWeeklySummary()

        // Act
        let html = sut.buildEmailBody(summaries: [summary])

        // Assert
        XCTAssertTrue(html.hasPrefix("<!DOCTYPE"), "Should start with DOCTYPE declaration")
    }

    func testBuildBody_HasMetaTags() {
        // Arrange
        let summary = makeWeeklySummary()

        // Act
        let html = sut.buildEmailBody(summaries: [summary])

        // Assert
        XCTAssertTrue(html.contains("charset"), "Should specify character encoding")
        XCTAssertTrue(html.contains("viewport"), "Should have viewport meta tag")
    }

    func testBuildBody_EscapesSpecialCharacters() {
        // Arrange
        let summary = makeWeeklySummary(childName: "Test<>\"'&Child")

        // Act
        let html = sut.buildEmailBody(summaries: [summary])

        // Assert - Should escape HTML special characters
        XCTAssertFalse(html.contains("<>\"'&Child"), "Should escape special characters in child name")
        XCTAssertTrue(
            html.contains("&lt;") || html.contains("&gt;") || html.contains("&amp;") ||
            html.contains("&quot;") || html.contains("&#39;"),
            "Should contain escaped characters"
        )
    }
}
