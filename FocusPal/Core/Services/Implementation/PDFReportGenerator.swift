//
//  PDFReportGenerator.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import UIKit

/// Protocol for PDF report generation
protocol PDFReportGeneratorProtocol {
    /// Generate PDF data from a weekly summary
    /// - Parameter summary: The weekly summary to render
    /// - Returns: PDF data or nil if generation fails
    @MainActor
    func generatePDF(from summary: WeeklySummary) -> Data?

    /// Generate PDF data from multiple weekly summaries
    /// - Parameter summaries: Array of weekly summaries to render
    /// - Returns: PDF data or nil if generation fails
    @MainActor
    func generatePDF(from summaries: [WeeklySummary]) -> Data?
}

/// Service for generating PDF reports from weekly summaries
/// Uses UIGraphicsPDFRenderer to render SwiftUI views to PDF format
@MainActor
final class PDFReportGenerator: PDFReportGeneratorProtocol {

    // MARK: - Constants

    private enum PageSize {
        /// US Letter size in points (8.5" x 11")
        static let letterWidth: CGFloat = 612
        static let letterHeight: CGFloat = 792
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    func generatePDF(from summary: WeeklySummary) -> Data? {
        generatePDF(from: [summary])
    }

    func generatePDF(from summaries: [WeeklySummary]) -> Data? {
        guard !summaries.isEmpty else {
            return nil
        }

        let pageRect = CGRect(
            x: 0,
            y: 0,
            width: PageSize.letterWidth,
            height: PageSize.letterHeight
        )

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "FocusPal Weekly Report",
            kCGPDFContextAuthor as String: "FocusPal",
            kCGPDFContextCreator as String: "FocusPal iOS App"
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let pdfData = renderer.pdfData { context in
            for summary in summaries {
                context.beginPage()
                renderPage(for: summary, in: context, pageRect: pageRect)
            }
        }

        return pdfData
    }

    // MARK: - Private Methods

    private func renderPage(for summary: WeeklySummary, in context: UIGraphicsPDFRendererContext, pageRect: CGRect) {
        // Create the SwiftUI view for this summary
        let reportView = ShareableReportView(summary: summary)

        // Render SwiftUI view to UIImage
        let imageRenderer = ImageRenderer(content: reportView)
        imageRenderer.scale = 2.0 // Higher resolution for crisp text

        guard let uiImage = imageRenderer.uiImage else {
            return
        }

        // Draw the image into the PDF context
        let imageRect = CGRect(
            x: 0,
            y: 0,
            width: pageRect.width,
            height: pageRect.height
        )

        uiImage.draw(in: imageRect)
    }
}

// MARK: - PDF Data Extension

extension PDFReportGenerator {

    /// Generate PDF and save to a temporary file
    /// - Parameter summary: The weekly summary to render
    /// - Returns: URL to the temporary PDF file, or nil if generation fails
    func generatePDFFile(from summary: WeeklySummary) -> URL? {
        generatePDFFile(from: [summary], filename: generateFilename(for: summary))
    }

    /// Generate PDF and save to a temporary file with custom filename
    /// - Parameters:
    ///   - summaries: Array of weekly summaries to render
    ///   - filename: Custom filename (without extension)
    /// - Returns: URL to the temporary PDF file, or nil if generation fails
    func generatePDFFile(from summaries: [WeeklySummary], filename: String? = nil) -> URL? {
        guard let pdfData = generatePDF(from: summaries) else {
            return nil
        }

        let finalFilename = filename ?? "FocusPal_Report_\(dateString())"
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(finalFilename)
            .appendingPathExtension("pdf")

        do {
            try pdfData.write(to: tempURL)
            return tempURL
        } catch {
            print("❌ Failed to write PDF file: \(error)")
            return nil
        }
    }

    private func generateFilename(for summary: WeeklySummary) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM_d_yyyy"
        let weekEnd = dateFormatter.string(from: summary.weekEndDate)
        let safeName = summary.childName.replacingOccurrences(of: " ", with: "_")
        return "FocusPal_\(safeName)_\(weekEnd)"
    }

    private func dateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return dateFormatter.string(from: Date())
    }
}

// MARK: - Convenience Factory

extension PDFReportGenerator {

    /// Create a PDF generator instance
    static var shared: PDFReportGenerator {
        PDFReportGenerator()
    }
}
