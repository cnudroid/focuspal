//
//  PieChart.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import Charts

/// Modern pie chart view using Swift Charts (iOS 17+).
@available(iOS 17.0, *)
struct PieChartView: View {
    let categories: [CategoryBreakdownItem]

    var body: some View {
        VStack(spacing: 16) {
            // Pie Chart with donut style
            Chart(categories) { item in
                SectorMark(
                    angle: .value("Minutes", item.minutes),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.5
                )
                .foregroundStyle(Color(hex: item.colorHex))
                .cornerRadius(4)
                .annotation(position: .overlay) {
                    if item.percentage >= 10 {
                        Text("\(item.percentage)%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .chartLegend(position: .bottom, alignment: .center, spacing: 16) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(categories) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: item.colorHex))
                                .frame(width: 10, height: 10)

                            Text(item.categoryName)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        PieChartView(categories: [
            CategoryBreakdownItem(categoryName: "Homework", colorHex: "#4A90D9", minutes: 60, percentage: 33),
            CategoryBreakdownItem(categoryName: "Reading", colorHex: "#7B68EE", minutes: 45, percentage: 25),
            CategoryBreakdownItem(categoryName: "Screen Time", colorHex: "#FF6B6B", minutes: 75, percentage: 42)
        ])
        .frame(height: 250)
        .padding()
    }
}
