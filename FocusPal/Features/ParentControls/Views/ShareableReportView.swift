//
//  ShareableReportView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// SwiftUI view optimized for PDF rendering of weekly reports
/// Professional layout with header, stats cards, tier badge, categories, and progress bar
struct ShareableReportView: View {
    let summary: WeeklySummary

    // MARK: - Constants

    private enum Layout {
        static let pageWidth: CGFloat = 612   // Letter size in points
        static let pageHeight: CGFloat = 792  // Letter size in points
        static let margin: CGFloat = 40
        static let sectionSpacing: CGFloat = 24
    }

    private enum Colors {
        static let primary = Color(hex: "#667eea")
        static let secondary = Color(hex: "#764ba2")
        static let success = Color(hex: "#28a745")
        static let background = Color(hex: "#f8f9fa")
        static let text = Color(hex: "#333333")
        static let textSecondary = Color(hex: "#666666")
    }

    // MARK: - Date Formatting

    private var weekRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: summary.weekStartDate)
        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "MMM d, yyyy"
        let end = endFormatter.string(from: summary.weekEndDate)
        return "\(start) - \(end)"
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            VStack(spacing: Layout.sectionSpacing) {
                childInfoSection
                statsCardsSection
                topCategoriesSection
                completionRateSection
                highlightsSection
            }
            .padding(Layout.margin)

            Spacer(minLength: 0)

            footerSection
        }
        .frame(width: Layout.pageWidth, height: Layout.pageHeight)
        .background(Color.white)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 24))
                Text("FocusPal Weekly Report")
                    .font(.system(size: 24, weight: .bold))
            }
            .foregroundColor(.white)

            Text("Week of \(weekRangeString)")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            LinearGradient(
                colors: [Colors.primary, Colors.secondary],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    // MARK: - Child Info Section

    private var childInfoSection: some View {
        HStack(spacing: 16) {
            // Child avatar placeholder
            ZStack {
                Circle()
                    .fill(Colors.primary.opacity(0.1))
                    .frame(width: 60, height: 60)

                Text(String(summary.childName.prefix(1)).uppercased())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Colors.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(summary.childName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Colors.text)

                if let tier = summary.currentTier {
                    tierBadge(tier)
                }
            }

            Spacer()
        }
        .padding()
        .background(Colors.background)
        .cornerRadius(12)
    }

    private func tierBadge(_ tier: RewardTier) -> some View {
        HStack(spacing: 4) {
            Text(tier.emoji)
                .font(.system(size: 14))
            Text("\(tier.name) Tier")
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(hex: tier.colorHex).opacity(0.2))
        .foregroundColor(Color(hex: tier.colorHex))
        .cornerRadius(16)
    }

    // MARK: - Stats Cards Section

    private var statsCardsSection: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "checkmark.circle.fill",
                value: "\(summary.totalActivities)",
                label: "Activities",
                color: Colors.primary
            )

            statCard(
                icon: "star.fill",
                value: "\(summary.netPoints)",
                label: "Points",
                color: Color(hex: "#FFD700")
            )

            statCard(
                icon: "clock.fill",
                value: formatTime(summary.totalMinutes),
                label: "Total Time",
                color: Colors.success
            )
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Colors.text)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Colors.background)
        .cornerRadius(12)
    }

    private func formatTime(_ minutes: Int) -> String {
        let hours = Double(minutes) / 60.0
        if hours >= 1 {
            return String(format: "%.1fhr", hours)
        }
        return "\(minutes)m"
    }

    // MARK: - Top Categories Section

    private var topCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Categories")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Colors.text)

            if summary.topCategories.isEmpty {
                Text("No category data available")
                    .font(.system(size: 12))
                    .foregroundColor(Colors.textSecondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(summary.topCategories.prefix(3).enumerated()), id: \.offset) { index, category in
                    categoryRow(
                        rank: index + 1,
                        name: category.categoryName,
                        minutes: category.minutes
                    )
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Colors.background)
        .cornerRadius(12)
    }

    private func categoryRow(rank: Int, name: String, minutes: Int) -> some View {
        HStack {
            Text(rankMedal(rank))
                .font(.system(size: 16))

            Text(name)
                .font(.system(size: 14))
                .foregroundColor(Colors.text)

            Spacer()

            Text(formatMinutesForCategory(minutes))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Colors.primary)
        }
        .padding(.vertical, 4)
    }

    private func rankMedal(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)."
        }
    }

    private func formatMinutesForCategory(_ minutes: Int) -> String {
        let hours = Double(minutes) / 60.0
        if hours >= 1 {
            return String(format: "%.1f hrs", hours)
        }
        return "\(minutes) min"
    }

    // MARK: - Completion Rate Section

    private var completionRateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Completion Rate")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Colors.text)

                Spacer()

                Text(String(format: "%.0f%%", summary.completionRate))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Colors.success)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#e9ecef"))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Colors.success)
                        .frame(width: geometry.size.width * (summary.completionRate / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Colors.background)
        .cornerRadius(12)
    }

    // MARK: - Highlights Section

    private var highlightsSection: some View {
        Group {
            if summary.achievementsUnlocked > 0 || summary.streak > 0 {
                HStack(spacing: 16) {
                    if summary.achievementsUnlocked > 0 {
                        highlightItem(
                            icon: "🏆",
                            value: "\(summary.achievementsUnlocked)",
                            label: summary.achievementsUnlocked == 1 ? "Achievement" : "Achievements"
                        )
                    }

                    if summary.streak > 0 {
                        highlightItem(
                            icon: "🔥",
                            value: "\(summary.streak)",
                            label: summary.streak == 1 ? "Week Streak" : "Weeks Streak"
                        )
                    }
                }
            }
        }
    }

    private func highlightItem(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Colors.text)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(Colors.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#fff3cd"))
        .cornerRadius(8)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 4) {
            Text("Generated by FocusPal")
                .font(.system(size: 10))
                .foregroundColor(Colors.textSecondary)

            Text(formattedCurrentDate)
                .font(.system(size: 10))
                .foregroundColor(Colors.textSecondary)
        }
        .padding(.bottom, 16)
    }

    private var formattedCurrentDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

// MARK: - Preview

#Preview("Report with Data") {
    ShareableReportView(
        summary: WeeklySummary(
            childName: "Emma",
            weekStartDate: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
            weekEndDate: Date(),
            totalActivities: 15,
            completedActivities: 12,
            incompleteActivities: 3,
            totalMinutes: 450,
            pointsEarned: 500,
            pointsDeducted: 50,
            netPoints: 450,
            currentTier: .gold,
            topCategories: [
                (categoryName: "Homework", minutes: 210),
                (categoryName: "Reading", minutes: 120),
                (categoryName: "Sports", minutes: 90)
            ],
            achievementsUnlocked: 2,
            streak: 3
        )
    )
    .previewLayout(.fixed(width: 612, height: 792))
}

#Preview("Report without Tier") {
    ShareableReportView(
        summary: WeeklySummary(
            childName: "Max",
            weekStartDate: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
            weekEndDate: Date(),
            totalActivities: 5,
            completedActivities: 3,
            incompleteActivities: 2,
            totalMinutes: 90,
            pointsEarned: 60,
            pointsDeducted: 10,
            netPoints: 50,
            currentTier: nil,
            topCategories: [
                (categoryName: "Reading", minutes: 60),
                (categoryName: "Music", minutes: 30)
            ],
            achievementsUnlocked: 0,
            streak: 0
        )
    )
    .previewLayout(.fixed(width: 612, height: 792))
}
