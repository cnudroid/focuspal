//
//  DailyChartView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import Charts

/// Daily statistics view with pie chart breakdown.
struct DailyChartView: View {
    let data: DailyStatistics

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Total time card
                VStack(spacing: 8) {
                    Text("\(data.totalMinutes)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))

                    Text("minutes today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 8)
                .padding(.horizontal)

                // Pie chart
                if #available(iOS 17.0, *) {
                    PieChartView(categories: data.categoryBreakdown)
                        .frame(height: 250)
                        .padding()
                } else {
                    SimplePieChart(categories: data.categoryBreakdown)
                        .frame(height: 250)
                        .padding()
                }

                // Balance meter
                BalanceMeter(score: data.balanceScore)
                    .padding(.horizontal)

                // Category list
                VStack(alignment: .leading, spacing: 12) {
                    Text("By Category")
                        .font(.headline)

                    ForEach(data.categoryBreakdown) { item in
                        CategoryBreakdownRow(item: item)
                    }
                }
                .padding()
            }
            .padding(.vertical)
        }
    }
}

struct CategoryBreakdownRow: View {
    let item: CategoryBreakdownItem

    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: item.colorHex))
                .frame(width: 12, height: 12)

            Text(item.categoryName)
                .font(.subheadline)

            Spacer()

            Text("\(item.minutes) min")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("(\(item.percentage)%)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// Fallback pie chart for iOS 16
struct SimplePieChart: View {
    let categories: [CategoryBreakdownItem]

    var body: some View {
        GeometryReader { geometry in
            let total = categories.reduce(0) { $0 + $1.minutes }
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 20

            ZStack {
                var startAngle = Angle.degrees(-90)

                ForEach(categories) { item in
                    let endAngle = startAngle + Angle.degrees(Double(item.minutes) / Double(total) * 360)

                    Path { path in
                        path.move(to: center)
                        path.addArc(
                            center: center,
                            radius: radius,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            clockwise: false
                        )
                    }
                    .fill(Color(hex: item.colorHex))

                    let _ = (startAngle = endAngle)
                }
            }
        }
    }
}

/// Data model for daily statistics
struct DailyStatistics {
    var totalMinutes: Int = 0
    var categoryBreakdown: [CategoryBreakdownItem] = []
    var balanceScore: Int = 0

    static let empty = DailyStatistics()
}

struct CategoryBreakdownItem: Identifiable {
    let id = UUID()
    let categoryName: String
    let colorHex: String
    let minutes: Int
    let percentage: Int
}

#Preview {
    DailyChartView(data: DailyStatistics(
        totalMinutes: 180,
        categoryBreakdown: [
            CategoryBreakdownItem(categoryName: "Homework", colorHex: "#4A90D9", minutes: 60, percentage: 33),
            CategoryBreakdownItem(categoryName: "Reading", colorHex: "#7B68EE", minutes: 45, percentage: 25),
            CategoryBreakdownItem(categoryName: "Screen Time", colorHex: "#FF6B6B", minutes: 75, percentage: 42)
        ],
        balanceScore: 72
    ))
}
