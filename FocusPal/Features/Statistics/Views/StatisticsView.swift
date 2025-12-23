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
                // Time period selector
                Picker("Time Period", selection: $viewModel.selectedTimePeriod) {
                    Text("Today").tag(TimePeriod.today)
                    Text("Week").tag(TimePeriod.week)
                    Text("Month").tag(TimePeriod.month)
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: viewModel.selectedTimePeriod) { _ in
                    Task {
                        await viewModel.loadData()
                    }
                }

                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Trends").tag(1)
                    Text("Achievements").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom)

                // Content based on selection
                TabView(selection: $selectedTab) {
                    // Overview tab - shows daily or aggregated data based on time period
                    Group {
                        if viewModel.selectedTimePeriod == .today {
                            DailyChartView(data: viewModel.dailyData)
                        } else {
                            WeeklyChartView(data: viewModel.weeklyData)
                        }
                    }
                    .tag(0)

                    // Trends tab - always shows weekly/monthly breakdown
                    WeeklyChartView(data: viewModel.weeklyData)
                        .tag(1)

                    // Achievements tab
                    AchievementsView(achievements: viewModel.achievements)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Statistics")
            .task {
                await viewModel.loadData()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
}

#Preview {
    StatisticsView()
}
