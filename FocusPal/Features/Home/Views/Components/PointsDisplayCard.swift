//
//  PointsDisplayCard.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Represents the trend direction for points display
enum PointsTrend {
    case up
    case down
    case neutral

    var iconName: String {
        switch self {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .neutral: return "minus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .up: return Color.fpSuccess
        case .down: return Color.fpError
        case .neutral: return Color(.systemGray3)
        }
    }
}

/// Card displaying today's points with trend indicator.
/// Tappable to navigate to detailed points view.
struct PointsDisplayCard: View {
    let points: ChildPoints?
    let trend: PointsTrend
    var onTap: (() -> Void)?

    /// Computed total points from the ChildPoints model
    private var totalPoints: Int {
        points?.totalPoints ?? 0
    }

    /// Breakdown text showing earned, bonus, and deducted
    private var breakdownText: String {
        guard let points = points else { return "No points yet" }
        if points.bonusPoints > 0 && points.pointsDeducted > 0 {
            return "+\(points.pointsEarned) earned, +\(points.bonusPoints) bonus, -\(points.pointsDeducted)"
        } else if points.bonusPoints > 0 {
            return "+\(points.pointsEarned) earned, +\(points.bonusPoints) bonus"
        } else if points.pointsDeducted > 0 {
            return "+\(points.pointsEarned) earned, -\(points.pointsDeducted)"
        } else if points.pointsEarned > 0 {
            return "+\(points.pointsEarned) earned today"
        } else {
            return "Complete activities to earn points!"
        }
    }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 16) {
                // Star icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#FFD700").opacity(0.3),
                                    Color(hex: "#FFA500").opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "star.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "#FFD700"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("\(totalPoints)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        Text("points")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        // Trend indicator
                        Image(systemName: trend.iconName)
                            .font(.system(size: 16))
                            .foregroundColor(trend.color)
                    }

                    Text(breakdownText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Chevron indicator for tap action
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Points Display Card Variants") {
    VStack(spacing: 16) {
        // With points earned, trending up
        PointsDisplayCard(
            points: ChildPoints(
                childId: UUID(),
                date: Date(),
                pointsEarned: 45,
                pointsDeducted: 0,
                bonusPoints: 10
            ),
            trend: .up
        ) {
            print("Tapped!")
        }

        // With some deductions, trending down
        PointsDisplayCard(
            points: ChildPoints(
                childId: UUID(),
                date: Date(),
                pointsEarned: 30,
                pointsDeducted: 15,
                bonusPoints: 5
            ),
            trend: .down
        )

        // No activity yet, neutral
        PointsDisplayCard(
            points: ChildPoints(
                childId: UUID(),
                date: Date(),
                pointsEarned: 0,
                pointsDeducted: 0,
                bonusPoints: 0
            ),
            trend: .neutral
        )

        // Nil points (loading state)
        PointsDisplayCard(
            points: nil,
            trend: .neutral
        )
    }
    .padding()
    .background(Color(.systemBackground))
}
