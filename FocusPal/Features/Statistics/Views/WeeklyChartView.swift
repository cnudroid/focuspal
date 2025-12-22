//
//  WeeklyChartView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import Charts

/// Weekly statistics view with bar chart.
struct WeeklyChartView: View {
    let data: WeeklyStatistics

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary cards
                HStack(spacing: 16) {
                    SummaryCard(
                        title: "Total Time",
                        value: "\(data.totalMinutes)",
                        unit: "min",
                        icon: "clock.fill"
                    )

                    SummaryCard(
                        title: "Daily Average",
                        value: "\(data.averageMinutesPerDay)",
                        unit: "min",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .padding(.horizontal)

                // Bar chart
                if #available(iOS 17.0, *) {
                    BarChartView(dailyData: data.dailyBreakdown)
                        .frame(height: 250)
                        .padding()
                } else {
                    SimpleBarChart(dailyData: data.dailyBreakdown)
                        .frame(height: 250)
                        .padding()
                }

                // Streak info
                StreakCard(currentStreak: data.currentStreak, longestStreak: data.longestStreak)
                    .padding(.horizontal)

                // Weekly insights
                VStack(alignment: .leading, spacing: 12) {
                    Text("Insights")
                        .font(.headline)

                    ForEach(data.insights, id: \.self) { insight in
                        InsightRow(text: insight)
                    }
                }
                .padding()
            }
            .padding(.vertical)
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4)
    }
}

struct StreakCard: View {
    let currentStreak: Int
    let longestStreak: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Current Streak")
                        .font(.subheadline)
                }

                Text("\(currentStreak) days")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Best: \(longestStreak) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4)
    }
}

struct InsightRow: View {
    let text: String

    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)

            Text(text)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

/// Fallback bar chart for iOS 16
struct SimpleBarChart: View {
    let dailyData: [DailyBarData]

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(dailyData) { day in
                VStack {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: 30, height: CGFloat(day.minutes) / 2)

                    Text(day.dayLabel)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

/// Data model for weekly statistics
struct WeeklyStatistics {
    var totalMinutes: Int = 0
    var averageMinutesPerDay: Int = 0
    var dailyBreakdown: [DailyBarData] = []
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var insights: [String] = []

    static let empty = WeeklyStatistics()
}

struct DailyBarData: Identifiable {
    let id = UUID()
    let dayLabel: String
    let minutes: Int
    let date: Date
}

#Preview {
    WeeklyChartView(data: WeeklyStatistics(
        totalMinutes: 840,
        averageMinutesPerDay: 120,
        dailyBreakdown: [
            DailyBarData(dayLabel: "Mon", minutes: 100, date: Date()),
            DailyBarData(dayLabel: "Tue", minutes: 130, date: Date()),
            DailyBarData(dayLabel: "Wed", minutes: 90, date: Date()),
            DailyBarData(dayLabel: "Thu", minutes: 150, date: Date()),
            DailyBarData(dayLabel: "Fri", minutes: 120, date: Date()),
            DailyBarData(dayLabel: "Sat", minutes: 140, date: Date()),
            DailyBarData(dayLabel: "Sun", minutes: 110, date: Date())
        ],
        currentStreak: 5,
        longestStreak: 12,
        insights: ["Great job staying consistent!", "Reading time is up 20% from last week"]
    ))
}
