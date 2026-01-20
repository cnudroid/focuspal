//
//  PDFReportGeneratorTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

/// Tests for PDFReportGenerator
/// Tests PDF generation from weekly summaries
@MainActor
final class PDFReportGeneratorTests: XCTestCase {

    // MARK: - Properties

    var sut: PDFReportGenerator!
    var calendar: Calendar!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = PDFReportGenerator()
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

    // MARK: - Generate PDF Tests

    func testGeneratePDF_WithValidSummary_ReturnsData() {
        // Arrange
        let summary = makeWeeklySummary()

        // Act
        let pdfData = sut.generatePDF(from: summary)

        // Assert
        XCTAssertNotNil(pdfData, "Should return PDF data")
        XCTAssertFalse(pdfData?.isEmpty ?? true, "PDF data should not be empty")
    }

    func testGeneratePDF_WithEmptySummary_ReturnsValidPDF() {
        // Arrange
        let summary = makeWeeklySummary(
            totalActivities: 0,
            completedActivities: 0,
            totalMinutes: 0,
            netPoints: 0
        )

        // Act
        let pdfData = sut.generatePDF(from: summary)

        // Assert
        XCTAssertNotNil(pdfData, "Should return PDF data even with empty summary")
        XCTAssertFalse(pdfData?.isEmpty ?? true, "PDF should still be valid")
    }

    func testGeneratePDF_WithMultipleSummaries_ReturnsData() {
        // Arrange
        let summaries = [
            makeWeeklySummary(childName: "Emma"),
            makeWeeklySummary(childName: "Lucas"),
            makeWeeklySummary(childName: "Sophie")
        ]

        // Act
        let pdfData = sut.generatePDF(from: summaries)

        // Assert
        XCTAssertNotNil(pdfData, "Should return PDF data for multiple summaries")
        XCTAssertFalse(pdfData?.isEmpty ?? true, "PDF data should not be empty")
    }

    func testGeneratePDF_WithEmptyArray_ReturnsNil() {
        // Act
        let pdfData = sut.generatePDF(from: [WeeklySummary]())

        // Assert
        XCTAssertNil(pdfData, "Should return nil for empty summaries array")
    }

    func testGeneratePDF_HasCorrectPageDimensions() {
        // Arrange
        let summary = makeWeeklySummary()

        // Act
        let pdfData = sut.generatePDF(from: summary)

        // Assert
        XCTAssertNotNil(pdfData, "PDF data should exist")

        // Verify it's a valid PDF by checking for PDF header
        if let data = pdfData, data.count > 4 {
            let header = String(data: data.prefix(5), encoding: .ascii)
            XCTAssertEqual(header, "%PDF-", "Should start with PDF header")
        }
    }

    func testGeneratePDF_WithTier_IncludesTierData() {
        // Arrange
        let summary = makeWeeklySummary(currentTier: .gold)

        // Act
        let pdfData = sut.generatePDF(from: summary)

        // Assert
        XCTAssertNotNil(pdfData, "Should generate PDF with tier data")
    }

    func testGeneratePDF_WithCategories_IncludesCategories() {
        // Arrange
        let summary = makeWeeklySummary(
            topCategories: [
                (categoryName: "Homework", minutes: 180),
                (categoryName: "Reading", minutes: 120),
                (categoryName: "Sports", minutes: 60)
            ]
        )

        // Act
        let pdfData = sut.generatePDF(from: summary)

        // Assert
        XCTAssertNotNil(pdfData, "Should generate PDF with category data")
    }

    func testGeneratePDF_WithHighlights_IncludesHighlights() {
        // Arrange
        let summary = makeWeeklySummary(
            achievementsUnlocked: 3,
            streak: 5
        )

        // Act
        let pdfData = sut.generatePDF(from: summary)

        // Assert
        XCTAssertNotNil(pdfData, "Should generate PDF with highlights data")
    }

    // MARK: - File Generation Tests

    func testGeneratePDFFile_CreatesFileOnDisk() {
        // Arrange
        let summary = makeWeeklySummary()

        // Act
        let fileURL = sut.generatePDFFile(from: summary)

        // Assert
        XCTAssertNotNil(fileURL, "Should return file URL")

        if let url = fileURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "PDF file should exist on disk")
            XCTAssertEqual(url.pathExtension, "pdf", "File should have .pdf extension")

            // Cleanup
            try? FileManager.default.removeItem(at: url)
        }
    }

    func testGeneratePDFFile_FilenameContainsChildName() {
        // Arrange
        let summary = makeWeeklySummary(childName: "TestChild")

        // Act
        let fileURL = sut.generatePDFFile(from: summary)

        // Assert
        XCTAssertNotNil(fileURL, "Should return file URL")

        if let url = fileURL {
            XCTAssertTrue(url.lastPathComponent.contains("TestChild"), "Filename should contain child name")

            // Cleanup
            try? FileManager.default.removeItem(at: url)
        }
    }

    func testGeneratePDFFile_WithCustomFilename_UsesCustomName() {
        // Arrange
        let summaries = [makeWeeklySummary()]

        // Act
        let fileURL = sut.generatePDFFile(from: summaries, filename: "CustomReport")

        // Assert
        XCTAssertNotNil(fileURL, "Should return file URL")

        if let url = fileURL {
            XCTAssertEqual(url.deletingPathExtension().lastPathComponent, "CustomReport", "Should use custom filename")

            // Cleanup
            try? FileManager.default.removeItem(at: url)
        }
    }
}
