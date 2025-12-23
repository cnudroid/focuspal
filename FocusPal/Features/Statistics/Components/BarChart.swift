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

    private var maxMinutes: Int {
        dailyData.map(\.minutes).max() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Activity")
                .font(.headline)
                .padding(.horizontal)

            Chart(dailyData) { item in
                BarMark(
                    x: .value("Day", item.dayLabel),
                    y: .value("Minutes", item.minutes)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(6)
                .annotation(position: .top) {
                    if item.minutes > 0 {
                        Text("\(item.minutes)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let stringValue = value.as(String.self) {
                            Text(stringValue)
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...(maxMinutes + 20))
        }
        .padding()
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
