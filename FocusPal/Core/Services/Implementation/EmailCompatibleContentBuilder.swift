//
//  EmailCompatibleContentBuilder.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Builds email-compatible HTML content using table-based layouts
/// Designed for maximum compatibility with email clients (Outlook, Gmail, Apple Mail)
///
/// Key compatibility features:
/// - Table-based layout (no CSS Grid/Flexbox)
/// - All styles inline (`style=""` attributes)
/// - Solid colors instead of gradients
/// - Web-safe fonts (Arial, Helvetica)
/// - Fixed widths for consistent rendering
final class EmailCompatibleContentBuilder {

    // MARK: - Constants

    private enum Layout {
        static let containerWidth = 600
        static let cardPadding = 20
        static let sectionSpacing = 20
    }

    private enum Colors {
        static let primary = "#667eea"
        static let primaryDark = "#5a6fd6"
        static let success = "#28a745"
        static let warning = "#ffc107"
        static let background = "#f5f5f5"
        static let cardBackground = "#f8f9fa"
        static let white = "#ffffff"
        static let textPrimary = "#333333"
        static let textSecondary = "#666666"
        static let textMuted = "#999999"
        static let border = "#e9ecef"
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// Build email subject line for weekly report
    /// - Parameters:
    ///   - childName: Name of the child
    ///   - weekEndDate: End date of the report week
    /// - Returns: Formatted email subject
    func buildEmailSubject(childName: String, weekEndDate: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: weekEndDate)

        return "FocusPal Weekly Report for \(childName) - \(dateString)"
    }

    /// Build email-compatible HTML body from weekly summaries
    /// - Parameter summaries: Array of weekly summaries
    /// - Returns: HTML string compatible with major email clients
    func buildEmailBody(summaries: [WeeklySummary]) -> String {
        guard !summaries.isEmpty else {
            return buildEmptyEmailBody()
        }

        var html = """
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>FocusPal Weekly Report</title>
        </head>
        <body style="margin: 0; padding: 0; background-color: \(Colors.background); font-family: Arial, Helvetica, sans-serif;">
            <!-- Main Container Table -->
            <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: \(Colors.background);">
                <tr>
                    <td align="center" style="padding: 20px 0;">
                        <!-- Content Table -->
                        <table border="0" cellpadding="0" cellspacing="0" width="\(Layout.containerWidth)" style="background-color: \(Colors.white); border-radius: 8px;">
                            \(buildHeader())
                            \(buildGreeting())
        """

        // Add each child's summary
        for summary in summaries {
            html += buildChildSummarySection(summary)
        }

        html += """
                            \(buildFooter())
                        </table>
                    </td>
                </tr>
            </table>
        </body>
        </html>
        """

        return html
    }

    // MARK: - Private Section Builders

    private func buildHeader() -> String {
        """
        <!-- Header -->
        <tr>
            <td align="center" bgcolor="\(Colors.primary)" style="padding: 30px 20px; border-radius: 8px 8px 0 0;">
                <table border="0" cellpadding="0" cellspacing="0">
                    <tr>
                        <td align="center" style="color: \(Colors.white); font-size: 28px; font-weight: bold; font-family: Arial, Helvetica, sans-serif;">
                            FocusPal Weekly Report
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        """
    }

    private func buildGreeting() -> String {
        """
        <!-- Greeting -->
        <tr>
            <td style="padding: 20px 30px;">
                <p style="margin: 0; font-size: 16px; color: \(Colors.textPrimary); line-height: 1.6; font-family: Arial, Helvetica, sans-serif;">
                    Hello! Here's your weekly activity summary.
                </p>
            </td>
        </tr>
        """
    }

    private func buildChildSummarySection(_ summary: WeeklySummary) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let weekRange = "\(dateFormatter.string(from: summary.weekStartDate)) - \(dateFormatter.string(from: summary.weekEndDate))"

        var html = """
        <!-- Child Summary Card -->
        <tr>
            <td style="padding: 0 30px 20px 30px;">
                <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: \(Colors.cardBackground); border-radius: 8px; border-left: 4px solid \(Colors.primary);">
                    <!-- Child Name -->
                    <tr>
                        <td style="padding: 20px 20px 10px 20px;">
                            <span style="font-size: 24px; font-weight: bold; color: \(Colors.primary); font-family: Arial, Helvetica, sans-serif;">\(escapeHTML(summary.childName))</span>
                        </td>
                    </tr>
                    <!-- Date Range -->
                    <tr>
                        <td style="padding: 0 20px 15px 20px;">
                            <span style="font-size: 14px; color: \(Colors.textSecondary); font-family: Arial, Helvetica, sans-serif;">\(weekRange)</span>
                        </td>
                    </tr>
        """

        // Tier badge if earned
        if let tier = summary.currentTier {
            html += buildTierBadge(tier)
        }

        // Stats grid
        html += buildStatsGrid(summary)

        // Highlights
        if summary.streak > 0 || summary.achievementsUnlocked > 0 {
            html += buildHighlights(summary)
        }

        // Top categories
        if !summary.topCategories.isEmpty {
            html += buildTopCategories(summary.topCategories)
        }

        // Completion rate
        if summary.totalActivities > 0 {
            html += buildCompletionRate(summary.completionRate)
        }

        html += """
                </table>
            </td>
        </tr>
        """

        return html
    }

    private func buildTierBadge(_ tier: RewardTier) -> String {
        """
        <!-- Tier Badge -->
        <tr>
            <td style="padding: 0 20px 15px 20px;">
                <table border="0" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="background-color: \(tier.colorHex); padding: 8px 16px; border-radius: 20px;">
                            <span style="font-size: 14px; font-weight: bold; color: \(tierTextColor(tier)); font-family: Arial, Helvetica, sans-serif;">\(tier.emoji) \(tier.name) Tier Achieved!</span>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        """
    }

    private func buildStatsGrid(_ summary: WeeklySummary) -> String {
        let cellStyle = "background-color: \(Colors.white); padding: 15px; border-radius: 6px; text-align: center;"
        let labelStyle = "font-size: 12px; color: \(Colors.textSecondary); text-transform: uppercase; "
            + "letter-spacing: 0.5px; font-family: Arial, Helvetica, sans-serif;"
        let valueStyle = "font-size: 28px; font-weight: bold; font-family: Arial, Helvetica, sans-serif;"

        return """
        <!-- Stats Grid -->
        <tr>
            <td style="padding: 0 20px 15px 20px;">
                <table border="0" cellpadding="0" cellspacing="10" width="100%">
                    <tr>
                        <!-- Activities -->
                        <td width="50%" style="\(cellStyle)">
                            <span style="\(labelStyle)">Total Activities</span><br/>
                            <span style="\(valueStyle) color: \(Colors.textPrimary);">\(summary.totalActivities)</span>
                        </td>
                        <!-- Completed -->
                        <td width="50%" style="\(cellStyle)">
                            <span style="\(labelStyle)">Completed</span><br/>
                            <span style="\(valueStyle) color: \(Colors.success);">\(summary.completedActivities)</span>
                        </td>
                    </tr>
                    <tr>
                        <!-- Total Time -->
                        <td width="50%" style="\(cellStyle)">
                            <span style="\(labelStyle)">Total Time</span><br/>
                            <span style="\(valueStyle) color: \(Colors.textPrimary);">\(formatMinutesAsHours(summary.totalMinutes))</span>
                        </td>
                        <!-- Points -->
                        <td width="50%" style="\(cellStyle)">
                            <span style="\(labelStyle)">Points Earned</span><br/>
                            <span style="\(valueStyle) color: \(Colors.primary);">\(summary.netPoints)</span>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        """
    }

    private func buildHighlights(_ summary: WeeklySummary) -> String {
        var highlightText = ""
        if summary.streak > 0 {
            highlightText += "🔥 \(summary.streak) week streak! "
        }
        if summary.achievementsUnlocked > 0 {
            let plural = summary.achievementsUnlocked > 1 ? "s" : ""
            highlightText += "🏆 \(summary.achievementsUnlocked) new achievement\(plural) unlocked!"
        }

        return """
        <!-- Highlights -->
        <tr>
            <td style="padding: 0 20px 15px 20px;">
                <table border="0" cellpadding="0" cellspacing="0" width="100%">
                    <tr>
                        <td style="background-color: \(Colors.warning); background-color: #fff3cd; border-left: 4px solid \(Colors.warning); padding: 15px; border-radius: 4px;">
                            <span style="font-size: 14px; color: \(Colors.textPrimary); font-family: Arial, Helvetica, sans-serif;"><strong>Highlights:</strong> \(highlightText)</span>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        """
    }

    private func buildTopCategories(_ categories: [(categoryName: String, minutes: Int)]) -> String {
        let textStyle = "font-size: 14px; color: \(Colors.textPrimary); font-family: Arial, Helvetica, sans-serif;"
        let valueStyle = "font-size: 14px; font-weight: bold; color: \(Colors.primary); font-family: Arial, Helvetica, sans-serif;"

        var categoryRows = ""
        for (index, category) in categories.prefix(3).enumerated() {
            let medal = index == 0 ? "🥇" : (index == 1 ? "🥈" : "🥉")
            let categoryName = escapeHTML(category.categoryName)
            let timeFormatted = formatMinutesAsHours(category.minutes)
            categoryRows += """
            <tr>
                <td style="background-color: \(Colors.white); padding: 10px; border-radius: 4px;">
                    <table border="0" cellpadding="0" cellspacing="0" width="100%">
                        <tr>
                            <td style="\(textStyle)">\(medal) \(categoryName)</td>
                            <td align="right" style="\(valueStyle)">\(timeFormatted)</td>
                        </tr>
                    </table>
                </td>
            </tr>
            <tr><td height="5"></td></tr>
            """
        }

        return """
        <!-- Top Categories -->
        <tr>
            <td style="padding: 0 20px 15px 20px;">
                <span style="font-size: 14px; font-weight: bold; color: \(Colors.textSecondary); font-family: Arial, Helvetica, sans-serif;">📚 Top Categories:</span>
                <table border="0" cellpadding="0" cellspacing="0" width="100%" style="margin-top: 10px;">
                    \(categoryRows)
                </table>
            </td>
        </tr>
        """
    }

    private func buildCompletionRate(_ rate: Double) -> String {
        let percentage = Int(rate)

        return """
        <!-- Completion Rate -->
        <tr>
            <td style="padding: 0 20px 20px 20px;">
                <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: \(Colors.white); padding: 10px; border-radius: 4px;">
                    <tr>
                        <td style="font-size: 14px; color: \(Colors.textSecondary); font-family: Arial, Helvetica, sans-serif;">Completion Rate:</td>
                        <td align="right" style="font-size: 14px; font-weight: bold; color: \(Colors.success); font-family: Arial, Helvetica, sans-serif;">\(percentage)%</td>
                    </tr>
                    <tr>
                        <td colspan="2" style="padding-top: 8px;">
                            <table border="0" cellpadding="0" cellspacing="0" width="100%">
                                <tr>
                                    <td style="background-color: \(Colors.border); border-radius: 4px; height: 8px;">
                                        <table border="0" cellpadding="0" cellspacing="0" width="\(percentage)%">
                                            <tr>
                                                <td style="background-color: \(Colors.success); border-radius: 4px; height: 8px;"></td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        """
    }

    private func buildFooter() -> String {
        """
        <!-- Footer -->
        <tr>
            <td align="center" style="padding: 20px 30px 30px 30px;">
                <p style="margin: 0 0 10px 0; font-size: 14px; color: \(Colors.textSecondary); font-family: Arial, Helvetica, sans-serif;">Keep up the great work! 🌟</p>
                <p style="margin: 0; font-size: 12px; color: \(Colors.textMuted); font-family: Arial, Helvetica, sans-serif;">This is an automated weekly summary from FocusPal.</p>
            </td>
        </tr>
        """
    }

    private func buildEmptyEmailBody() -> String {
        """
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>FocusPal Weekly Report</title>
        </head>
        <body style="margin: 0; padding: 0; background-color: \(Colors.background); font-family: Arial, Helvetica, sans-serif;">
            <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: \(Colors.background);">
                <tr>
                    <td align="center" style="padding: 20px;">
                        <table border="0" cellpadding="0" cellspacing="0" width="\(Layout.containerWidth)" style="background-color: \(Colors.white); border-radius: 8px; padding: 40px;">
                            <tr>
                                <td align="center">
                                    <h1 style="margin: 0 0 20px 0; color: \(Colors.primary); font-family: Arial, Helvetica, sans-serif;">FocusPal Weekly Report</h1>
                                    <p style="margin: 0; color: \(Colors.textSecondary); font-family: Arial, Helvetica, sans-serif;">No activity data available for this week.</p>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </table>
        </body>
        </html>
        """
    }

    // MARK: - Helper Methods

    private func formatMinutesAsHours(_ minutes: Int) -> String {
        let hours = Double(minutes) / 60.0
        if hours < 1 {
            return "\(minutes) min"
        } else {
            return String(format: "%.1f hr", hours)
        }
    }

    private func tierTextColor(_ tier: RewardTier) -> String {
        switch tier {
        case .bronze, .gold, .platinum:
            return Colors.textPrimary
        case .silver:
            return Colors.textPrimary
        }
    }

    private func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
