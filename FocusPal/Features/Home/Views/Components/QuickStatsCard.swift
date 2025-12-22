//
//  QuickStatsCard.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Card displaying quick statistics for today.
struct QuickStatsCard: View {
    let stats: TodayStats

    var body: some View {
        VStack(spacing: 16) {
            Text("Today's Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 24) {
                StatItem(
                    value: "\(stats.totalMinutes)",
                    label: "Minutes",
                    icon: "clock.fill"
                )

                StatItem(
                    value: "\(stats.activitiesCount)",
                    label: "Activities",
                    icon: "list.bullet"
                )

                StatItem(
                    value: "\(stats.balanceScore)%",
                    label: "Balance",
                    icon: "scale.3d"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Data structure for today's statistics
struct TodayStats {
    var totalMinutes: Int = 0
    var activitiesCount: Int = 0
    var balanceScore: Int = 0

    static let empty = TodayStats()
}

#Preview {
    QuickStatsCard(stats: TodayStats(totalMinutes: 120, activitiesCount: 5, balanceScore: 75))
}
