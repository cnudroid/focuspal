//
//  EmailContentBuilder.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Builds formatted email content from weekly summaries
class EmailContentBuilder {

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// Build the email subject line
    /// - Parameters:
    ///   - childName: Name of the child
    ///   - weekEndDate: End date of the week
    /// - Returns: Formatted subject string
    func buildEmailSubject(childName: String, weekEndDate: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: weekEndDate)

        return "FocusPal Weekly Summary for \(childName) - \(dateString)"
    }

    /// Build the HTML email body
    /// - Parameter summaries: Array of weekly summaries for children
    /// - Returns: HTML-formatted email body
    func buildEmailBody(summaries: [WeeklySummary]) -> String {
        guard !summaries.isEmpty else {
            return buildEmptyEmailBody()
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        var html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    max-width: 600px;
                    margin: 0 auto;
                    padding: 20px;
                    background-color: #f5f5f5;
                }
                .header {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 30px;
                    border-radius: 10px 10px 0 0;
                    text-align: center;
                }
                .header h1 {
                    margin: 0;
                    font-size: 28px;
                }
                .container {
                    background-color: white;
                    border-radius: 0 0 10px 10px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                    overflow: hidden;
                }
                .greeting {
                    padding: 20px 30px;
                    font-size: 16px;
                }
                .child-summary {
                    margin: 20px 30px;
                    padding: 20px;
                    background-color: #f8f9fa;
                    border-radius: 8px;
                    border-left: 4px solid #667eea;
                }
                .child-name {
                    font-size: 24px;
                    font-weight: bold;
                    color: #667eea;
                    margin-bottom: 15px;
                }
                .stats-grid {
                    display: grid;
                    grid-template-columns: repeat(2, 1fr);
                    gap: 15px;
                    margin: 15px 0;
                }
                .stat-card {
                    background-color: white;
                    padding: 15px;
                    border-radius: 6px;
                    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
                }
                .stat-label {
                    font-size: 12px;
                    color: #666;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                }
                .stat-value {
                    font-size: 28px;
                    font-weight: bold;
                    color: #333;
                    margin-top: 5px;
                }
                .tier-badge {
                    display: inline-block;
                    padding: 8px 16px;
                    border-radius: 20px;
                    font-weight: bold;
                    margin: 10px 0;
                }
                .tier-bronze { background-color: #CD7F32; color: white; }
                .tier-silver { background-color: #C0C0C0; color: #333; }
                .tier-gold { background-color: #FFD700; color: #333; }
                .tier-platinum { background-color: #E5E4E2; color: #333; }
                .categories-list {
                    margin: 15px 0;
                }
                .category-item {
                    display: flex;
                    justify-content: space-between;
                    padding: 10px;
                    background-color: white;
                    margin: 5px 0;
                    border-radius: 4px;
                }
                .highlight {
                    background-color: #fff3cd;
                    border-left: 4px solid #ffc107;
                    padding: 15px;
                    margin: 15px 0;
                    border-radius: 4px;
                }
                .footer {
                    text-align: center;
                    padding: 20px;
                    color: #666;
                    font-size: 14px;
                }
                @media only screen and (max-width: 600px) {
                    .stats-grid {
                        grid-template-columns: 1fr;
                    }
                }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>📊 FocusPal Weekly Summary</h1>
            </div>
            <div class="container">
                <div class="greeting">
                    <p>Hello! Here's your weekly activity summary for your amazing kids.</p>
                </div>
        """

        // Add each child's summary
        for summary in summaries {
            html += buildChildSummaryHTML(summary)
        }

        html += """
                <div class="footer">
                    <p>Keep up the great work! 🌟</p>
                    <p style="font-size: 12px; color: #999;">
                        This is an automated weekly summary from FocusPal.
                    </p>
                </div>
            </div>
        </body>
        </html>
        """

        return html
    }

    // MARK: - Private Helpers

    private func buildChildSummaryHTML(_ summary: WeeklySummary) -> String {
        var html = """
            <div class="child-summary">
                <div class="child-name">\(summary.childName)</div>

        """

        // Date range
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let weekRange = "\(dateFormatter.string(from: summary.weekStartDate)) - \(dateFormatter.string(from: summary.weekEndDate))"
        html += "<p style='color: #666; font-size: 14px;'>\(weekRange)</p>\n"

        // Tier badge if earned
        if let tier = summary.currentTier {
            html += """
                <div class="tier-badge tier-\(tier.rawValue)">
                    \(tier.emoji) \(tier.name) Tier Achieved!
                </div>
            """
        }

        // Stats grid
        html += """
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-label">Total Activities</div>
                    <div class="stat-value">\(summary.totalActivities)</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Completed</div>
                    <div class="stat-value" style="color: #28a745;">\(summary.completedActivities)</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Total Time</div>
                    <div class="stat-value">\(formatMinutesAsHours(summary.totalMinutes))</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Points Earned</div>
                    <div class="stat-value" style="color: #667eea;">\(summary.netPoints)</div>
                </div>
            </div>
        """

        // Highlights section
        if summary.streak > 0 || summary.achievementsUnlocked > 0 {
            html += "<div class='highlight'><strong>🎉 Highlights:</strong><br>"
            if summary.streak > 0 {
                html += "🔥 \(summary.streak) week streak!<br>"
            }
            if summary.achievementsUnlocked > 0 {
                html += "🏆 \(summary.achievementsUnlocked) new achievement\(summary.achievementsUnlocked > 1 ? "s" : "") unlocked!<br>"
            }
            html += "</div>"
        }

        // Top categories
        if !summary.topCategories.isEmpty {
            html += """
                <div style="margin-top: 15px;">
                    <strong style="color: #666;">📚 Top Categories:</strong>
                    <div class="categories-list">
            """

            for (index, category) in summary.topCategories.enumerated() {
                let medal = index == 0 ? "🥇" : (index == 1 ? "🥈" : "🥉")
                html += """
                    <div class="category-item">
                        <span>\(medal) \(category.categoryName)</span>
                        <span style="font-weight: bold; color: #667eea;">\(formatMinutesAsHours(category.minutes))</span>
                    </div>
                """
            }

            html += """
                    </div>
                </div>
            """
        }

        // Completion rate
        if summary.totalActivities > 0 {
            let completionRate = String(format: "%.0f", summary.completionRate)
            html += """
                <div style="margin-top: 15px; padding: 10px; background-color: white; border-radius: 4px;">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span style="color: #666;">Completion Rate:</span>
                        <span style="font-weight: bold; color: #28a745;">\(completionRate)%</span>
                    </div>
                    <div style="background-color: #e9ecef; height: 8px; border-radius: 4px; margin-top: 8px; overflow: hidden;">
                        <div style="background-color: #28a745; height: 100%; width: \(completionRate)%;"></div>
                    </div>
                </div>
            """
        }

        html += "</div>\n"
        return html
    }

    private func buildEmptyEmailBody() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="font-family: Arial, sans-serif; padding: 20px;">
            <h1>FocusPal Weekly Summary</h1>
            <p>No activity data available for this week.</p>
        </body>
        </html>
        """
    }

    private func formatMinutesAsHours(_ minutes: Int) -> String {
        let hours = Double(minutes) / 60.0
        if hours < 1 {
            return "\(minutes) min"
        } else {
            return String(format: "%.1f hr", hours)
        }
    }
}
