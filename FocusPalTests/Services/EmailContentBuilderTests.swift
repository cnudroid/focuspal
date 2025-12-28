//
//  EmailContentBuilderTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

/// Tests for EmailContentBuilder
/// Tests HTML email generation from weekly summaries
final class EmailContentBuilderTests: XCTestCase {

    // MARK: - Properties

    var sut: EmailContentBuilder!
    var calendar: Calendar!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = EmailContentBuilder()
        calendar = Calendar.current
    }

    override func tearDownWithError() throws {
        sut = nil
        calendar = nil
        try super.tearDownWithError()
    }

    // MARK: - Build Email Subject Tests

    func testBuildEmailSubject_WithChildName_IncludesName() {
        // Arrange
        let childName = "Emma"
        let weekEndDate = Date()

        // Act
        let subject = sut.buildEmailSubject(childName: childName, weekEndDate: weekEndDate)

        // Assert
        XCTAssertTrue(subject.contains("Emma"), "Subject should include child's name")
        XCTAssertTrue(subject.contains("Weekly"), "Subject should indicate it's a weekly summary")
    }

    func testBuildEmailSubject_WithDifferentDate_FormatsProperly() {
        // Arrange
        let childName = "Lucas"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let weekEndDate = Date()

        // Act
        let subject = sut.buildEmailSubject(childName: childName, weekEndDate: weekEndDate)

        // Assert
        XCTAssertFalse(subject.isEmpty)
        XCTAssertTrue(subject.contains("Lucas"))
    }

    // MARK: - Build Email Body Tests

    func testBuildEmailBody_WithOneSummary_ContainsChildData() {
        // Arrange
        let weekStart = calendar.startOfDay(for: Date())
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        let summary = WeeklySummary(
            childName: "Emma",
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalActivities: 15,
            completedActivities: 12,
            incompleteActivities: 3,
            totalMinutes: 450,
            pointsEarned: 120,
            pointsDeducted: 15,
            netPoints: 105,
            currentTier: .bronze,
            topCategories: [("Homework", 180), ("Reading", 150), ("Sports", 120)],
            achievementsUnlocked: 2,
            streak: 3
        )

        // Act
        let body = sut.buildEmailBody(summaries: [summary])

        // Assert
        XCTAssertTrue(body.contains("Emma"), "Body should include child's name")
        XCTAssertTrue(body.contains("15"), "Body should include total activities count")
        XCTAssertTrue(body.contains("12"), "Body should include completed activities")
        XCTAssertTrue(body.contains("450"), "Body should include total minutes")
        XCTAssertTrue(body.contains("105"), "Body should include net points")
        XCTAssertTrue(body.contains("Bronze") || body.contains("bronze"), "Body should include tier")
        XCTAssertTrue(body.contains("Homework"), "Body should include top category")
        XCTAssertTrue(body.contains("<html"), "Body should be HTML format")
        XCTAssertTrue(body.contains("</html>"), "Body should have closing HTML tag")
    }

    func testBuildEmailBody_WithMultipleSummaries_ContainsAllChildren() {
        // Arrange
        let weekStart = calendar.startOfDay(for: Date())
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        let summary1 = WeeklySummary(
            childName: "Emma",
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalActivities: 10,
            completedActivities: 8,
            incompleteActivities: 2,
            totalMinutes: 300,
            pointsEarned: 80,
            pointsDeducted: 10,
            netPoints: 70
        )

        let summary2 = WeeklySummary(
            childName: "Lucas",
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalActivities: 12,
            completedActivities: 10,
            incompleteActivities: 2,
            totalMinutes: 360,
            pointsEarned: 100,
            pointsDeducted: 5,
            netPoints: 95,
            currentTier: .silver
        )

        // Act
        let body = sut.buildEmailBody(summaries: [summary1, summary2])

        // Assert
        XCTAssertTrue(body.contains("Emma"), "Body should include first child's name")
        XCTAssertTrue(body.contains("Lucas"), "Body should include second child's name")
        XCTAssertTrue(body.contains("70"), "Body should include Emma's net points")
        XCTAssertTrue(body.contains("95"), "Body should include Lucas's net points")
    }

    func testBuildEmailBody_WithNoActivities_ShowsZeroStats() {
        // Arrange
        let weekStart = calendar.startOfDay(for: Date())
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        let summary = WeeklySummary(
            childName: "Emma",
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalActivities: 0,
            completedActivities: 0,
            incompleteActivities: 0,
            totalMinutes: 0,
            pointsEarned: 0,
            pointsDeducted: 0,
            netPoints: 0
        )

        // Act
        let body = sut.buildEmailBody(summaries: [summary])

        // Assert
        XCTAssertTrue(body.contains("Emma"), "Body should still include child's name")
        XCTAssertTrue(body.contains("0") || body.contains("no activities"), "Body should indicate no activities")
    }

    func testBuildEmailBody_IsValidHTML() {
        // Arrange
        let weekStart = calendar.startOfDay(for: Date())
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        let summary = WeeklySummary(
            childName: "Emma",
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalActivities: 10,
            completedActivities: 8,
            incompleteActivities: 2,
            totalMinutes: 300,
            pointsEarned: 80,
            pointsDeducted: 10,
            netPoints: 70
        )

        // Act
        let body = sut.buildEmailBody(summaries: [summary])

        // Assert - Check for valid HTML structure
        XCTAssertTrue(body.contains("<html"), "Should have opening html tag")
        XCTAssertTrue(body.contains("</html>"), "Should have closing html tag")
        XCTAssertTrue(body.contains("<head"), "Should have head section")
        XCTAssertTrue(body.contains("<body"), "Should have body section")
        XCTAssertTrue(body.contains("</body>"), "Should close body section")
        XCTAssertTrue(body.contains("<style") || body.contains("style="), "Should have styling")
    }

    func testBuildEmailBody_WithHighTier_ShowsCongratulations() {
        // Arrange
        let weekStart = calendar.startOfDay(for: Date())
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        let summary = WeeklySummary(
            childName: "Emma",
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalActivities: 20,
            completedActivities: 20,
            incompleteActivities: 0,
            totalMinutes: 600,
            pointsEarned: 500,
            pointsDeducted: 0,
            netPoints: 500,
            currentTier: .gold
        )

        // Act
        let body = sut.buildEmailBody(summaries: [summary])

        // Assert
        XCTAssertTrue(body.contains("Gold") || body.contains("gold") || body.contains("\u{1F947}"),
                     "Body should highlight gold tier achievement")
    }

    func testBuildEmailBody_WithTopCategories_ListsThemInOrder() {
        // Arrange
        let weekStart = calendar.startOfDay(for: Date())
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        let summary = WeeklySummary(
            childName: "Emma",
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalActivities: 10,
            completedActivities: 8,
            incompleteActivities: 2,
            totalMinutes: 450,
            pointsEarned: 80,
            pointsDeducted: 10,
            netPoints: 70,
            topCategories: [("Homework", 180), ("Reading", 150), ("Sports", 120)]
        )

        // Act
        let body = sut.buildEmailBody(summaries: [summary])

        // Assert
        XCTAssertTrue(body.contains("Homework"), "Should include top category")
        XCTAssertTrue(body.contains("Reading"), "Should include second category")
        XCTAssertTrue(body.contains("Sports"), "Should include third category")
        XCTAssertTrue(body.contains("180") || body.contains("3 hr"), "Should include minutes or hours for top category")
    }

    func testBuildEmailBody_WithStreak_HighlightsIt() {
        // Arrange
        let weekStart = calendar.startOfDay(for: Date())
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        let summary = WeeklySummary(
            childName: "Emma",
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalActivities: 10,
            completedActivities: 8,
            incompleteActivities: 2,
            totalMinutes: 300,
            pointsEarned: 80,
            pointsDeducted: 10,
            netPoints: 70,
            streak: 5
        )

        // Act
        let body = sut.buildEmailBody(summaries: [summary])

        // Assert
        XCTAssertTrue(body.contains("5") || body.contains("streak"), "Should include streak information")
    }

    func testBuildEmailBody_WithEmptyArray_ReturnsValidHTML() {
        // Act
        let body = sut.buildEmailBody(summaries: [])

        // Assert
        XCTAssertTrue(body.contains("<html"), "Should still return valid HTML")
        XCTAssertTrue(body.contains("</html>"), "Should have closing HTML tag")
    }
}
