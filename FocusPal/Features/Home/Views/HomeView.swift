//
//  HomeView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Main home screen view displaying today's summary and quick actions.
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick stats section
                    QuickStatsCard(stats: viewModel.todayStats)

                    // Quick action buttons
                    HStack(spacing: 16) {
                        QuickActionButton(
                            title: "Start Timer",
                            icon: "timer",
                            color: .blue
                        ) {
                            viewModel.startTimerTapped()
                        }

                        QuickActionButton(
                            title: "Quick Log",
                            icon: "plus.circle.fill",
                            color: .green
                        ) {
                            viewModel.quickLogTapped()
                        }
                    }
                    .padding(.horizontal)

                    // Today's activities list
                    TodayActivityList(activities: viewModel.todayActivities)
                }
                .padding(.vertical)
            }
            .navigationTitle("FocusPal")
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }
}

#Preview {
    HomeView()
}
