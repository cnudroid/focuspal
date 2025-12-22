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
        Chart(categories) { item in
            SectorMark(
                angle: .value("Minutes", item.minutes),
                innerRadius: .ratio(0.5),
                angularInset: 1.5
            )
            .foregroundStyle(Color(hex: item.colorHex))
            .cornerRadius(4)
        }
        .chartLegend(position: .bottom, alignment: .center)
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
