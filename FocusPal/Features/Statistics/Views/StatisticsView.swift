//
//  StatisticsView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Main statistics view with charts and insights.
struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Daily").tag(0)
                    Text("Weekly").tag(1)
                    Text("Achievements").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content based on selection
                TabView(selection: $selectedTab) {
                    DailyChartView(data: viewModel.dailyData)
                        .tag(0)

                    WeeklyChartView(data: viewModel.weeklyData)
                        .tag(1)

                    AchievementsView(achievements: viewModel.achievements)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Statistics")
            .task {
                await viewModel.loadData()
            }
        }
    }
}

#Preview {
    StatisticsView()
}
