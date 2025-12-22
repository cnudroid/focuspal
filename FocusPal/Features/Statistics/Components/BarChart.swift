//
//  BarChart.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import Charts

/// Modern bar chart view using Swift Charts (iOS 17+).
@available(iOS 17.0, *)
struct BarChartView: View {
    let dailyData: [DailyBarData]

    var body: some View {
        Chart(dailyData) { item in
            BarMark(
                x: .value("Day", item.dayLabel),
                y: .value("Minutes", item.minutes)
            )
            .foregroundStyle(Color.accentColor.gradient)
            .cornerRadius(6)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        BarChartView(dailyData: [
            DailyBarData(dayLabel: "Mon", minutes: 100, date: Date()),
            DailyBarData(dayLabel: "Tue", minutes: 130, date: Date()),
            DailyBarData(dayLabel: "Wed", minutes: 90, date: Date()),
            DailyBarData(dayLabel: "Thu", minutes: 150, date: Date()),
            DailyBarData(dayLabel: "Fri", minutes: 120, date: Date())
        ])
        .frame(height: 250)
        .padding()
    }
}
