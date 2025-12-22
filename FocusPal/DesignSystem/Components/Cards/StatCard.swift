//
//  StatCard.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Card displaying a single statistic value.
struct StatCard: View {
    let title: String
    let value: String
    let unit: String?
    let icon: String
    let trend: StatTrend?
    let color: Color

    init(
        title: String,
        value: String,
        unit: String? = nil,
        icon: String,
        trend: StatTrend? = nil,
        color: Color = .accentColor
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.icon = icon
        self.trend = trend
        self.color = color
    }

    var body: some View {
        VStack(spacing: FPSpacing.sm) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            // Value with unit
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)

                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            // Trend indicator
            if let trend = trend {
                TrendIndicator(trend: trend)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(FPSpacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .cardShadow()
    }
}

// MARK: - Trend

enum StatTrend {
    case up(percentage: Int)
    case down(percentage: Int)
    case neutral

    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .neutral: return .secondary
        }
    }

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "arrow.right"
        }
    }
}

struct TrendIndicator: View {
    let trend: StatTrend

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trend.icon)

            switch trend {
            case .up(let percentage):
                Text("+\(percentage)%")
            case .down(let percentage):
                Text("-\(percentage)%")
            case .neutral:
                Text("0%")
            }
        }
        .font(.caption2)
        .foregroundColor(trend.color)
    }
}

#Preview {
    HStack(spacing: 12) {
        StatCard(
            title: "Total Time",
            value: "2.5",
            unit: "hrs",
            icon: "clock.fill",
            trend: .up(percentage: 15)
        )

        StatCard(
            title: "Balance",
            value: "82",
            unit: "%",
            icon: "scale.3d",
            trend: nil,
            color: .green
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
