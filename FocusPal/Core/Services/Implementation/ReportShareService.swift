//
//  ReportShareService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import UIKit

/// Coordinator service for sharing weekly reports
/// Handles PDF generation, HTML email content, and UIActivityViewController presentation
@MainActor
final class ReportShareService {

    // MARK: - Dependencies

    private let pdfGenerator: PDFReportGeneratorProtocol
    private let emailContentBuilder: EmailCompatibleContentBuilder

    // MARK: - Properties

    /// Temporary PDF URLs that need cleanup
    private var temporaryPDFURLs: [URL] = []

    // MARK: - Initialization

    init(
        pdfGenerator: PDFReportGeneratorProtocol? = nil,
        emailContentBuilder: EmailCompatibleContentBuilder? = nil
    ) {
        self.pdfGenerator = pdfGenerator ?? PDFReportGenerator()
        self.emailContentBuilder = emailContentBuilder ?? EmailCompatibleContentBuilder()
    }

    // MARK: - Public Methods

    /// Share report using UIActivityViewController
    /// - Parameters:
    ///   - summaries: Weekly summaries to share
    ///   - includePDF: Whether to include PDF attachment
    ///   - viewController: View controller to present from
    func shareReport(
        summaries: [WeeklySummary],
        includePDF: Bool = true,
        from viewController: UIViewController
    ) {
        guard !summaries.isEmpty else { return }

        var activityItems: [Any] = []

        // Add HTML content as text
        let htmlContent = emailContentBuilder.buildEmailBody(summaries: summaries)
        activityItems.append(htmlContent)

        // Add PDF if requested
        if includePDF, let pdfURL = generateTemporaryPDF(from: summaries) {
            activityItems.append(pdfURL)
        }

        presentActivityViewController(with: activityItems, from: viewController)
    }

    /// Share report with PDF only
    /// - Parameters:
    ///   - summaries: Weekly summaries to share
    ///   - viewController: View controller to present from
    func sharePDFReport(
        summaries: [WeeklySummary],
        from viewController: UIViewController
    ) {
        guard !summaries.isEmpty else { return }

        guard let pdfURL = generateTemporaryPDF(from: summaries) else {
            print("❌ Failed to generate PDF for sharing")
            return
        }

        presentActivityViewController(with: [pdfURL], from: viewController)
    }

    /// Share report via email (mailto: link with HTML body)
    /// - Parameters:
    ///   - summaries: Weekly summaries to share
    ///   - recipientEmail: Optional recipient email address
    func shareViaEmail(
        summaries: [WeeklySummary],
        recipientEmail: String? = nil
    ) {
        guard !summaries.isEmpty else { return }

        let subject = buildSubject(from: summaries)
        let body = emailContentBuilder.buildEmailBody(summaries: summaries)

        // Build mailto URL
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipientEmail ?? ""

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: stripHTMLForMailto(body))
        ]

        components.queryItems = queryItems

        if let mailtoURL = components.url {
            UIApplication.shared.open(mailtoURL)
        }
    }

    /// Generate PDF data for the given summaries
    /// - Parameter summaries: Weekly summaries to render
    /// - Returns: PDF data or nil if generation fails
    func generatePDFData(from summaries: [WeeklySummary]) -> Data? {
        pdfGenerator.generatePDF(from: summaries)
    }

    /// Generate PDF data for a single summary
    /// - Parameter summary: Weekly summary to render
    /// - Returns: PDF data or nil if generation fails
    func generatePDFData(from summary: WeeklySummary) -> Data? {
        pdfGenerator.generatePDF(from: summary)
    }

    /// Get email-compatible HTML for the given summaries
    /// - Parameter summaries: Weekly summaries to render
    /// - Returns: HTML string
    func getEmailHTML(from summaries: [WeeklySummary]) -> String {
        emailContentBuilder.buildEmailBody(summaries: summaries)
    }

    /// Clean up temporary PDF files
    func cleanupTemporaryFiles() {
        for url in temporaryPDFURLs {
            try? FileManager.default.removeItem(at: url)
        }
        temporaryPDFURLs.removeAll()
    }

    // MARK: - Private Methods

    private func generateTemporaryPDF(from summaries: [WeeklySummary]) -> URL? {
        guard let pdfData = pdfGenerator.generatePDF(from: summaries) else {
            return nil
        }

        let filename = generateFilename(from: summaries)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)
            .appendingPathExtension("pdf")

        do {
            try pdfData.write(to: tempURL)
            temporaryPDFURLs.append(tempURL)
            return tempURL
        } catch {
            print("❌ Failed to write temporary PDF: \(error)")
            return nil
        }
    }

    private func generateFilename(from summaries: [WeeklySummary]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM_d_yyyy"

        if summaries.count == 1, let summary = summaries.first {
            let weekEnd = dateFormatter.string(from: summary.weekEndDate)
            let safeName = summary.childName.replacingOccurrences(of: " ", with: "_")
            return "FocusPal_Report_\(safeName)_\(weekEnd)"
        } else {
            let date = dateFormatter.string(from: Date())
            return "FocusPal_Report_\(date)"
        }
    }

    private func buildSubject(from summaries: [WeeklySummary]) -> String {
        if summaries.count == 1, let summary = summaries.first {
            return emailContentBuilder.buildEmailSubject(
                childName: summary.childName,
                weekEndDate: summary.weekEndDate
            )
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            return "FocusPal Weekly Report - \(dateFormatter.string(from: Date()))"
        }
    }

    private func stripHTMLForMailto(_ html: String) -> String {
        // For mailto, we need plain text. Strip HTML tags but preserve content structure
        var text = html

        // Replace common block elements with newlines
        text = text.replacingOccurrences(of: "</tr>", with: "\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "<br>", with: "\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "<br/>", with: "\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "<br />", with: "\n", options: .caseInsensitive)

        // Remove all HTML tags
        text = text.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )

        // Decode HTML entities
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")

        // Clean up whitespace
        text = text.replacingOccurrences(
            of: "\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func presentActivityViewController(with items: [Any], from viewController: UIViewController) {
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        // iPad support - popover presentation
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        // Cleanup temporary files when activity completes
        activityVC.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.cleanupTemporaryFiles()
        }

        viewController.present(activityVC, animated: true)
    }
}

// MARK: - SwiftUI Integration

extension ReportShareService {

    /// Get the current root view controller for presenting share sheets
    static func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }

        var rootViewController = window.rootViewController
        while let presentedVC = rootViewController?.presentedViewController {
            rootViewController = presentedVC
        }

        return rootViewController
    }
}
