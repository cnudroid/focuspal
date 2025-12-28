//
//  HomeView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Main home screen view displaying today's summary and quick actions.
struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var activityLogViewModel: ActivityLogViewModel
    @Binding var selectedTab: AppTab
    let currentChild: Child

    init(selectedTab: Binding<AppTab>, currentChild: Child) {
        _selectedTab = selectedTab
        self.currentChild = currentChild
        _viewModel = StateObject(wrappedValue: HomeViewModel())
        _activityLogViewModel = StateObject(wrappedValue: ActivityLogViewModel(child: currentChild))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Points display card at the top
                    PointsDisplayCard(
                        points: viewModel.todayPoints,
                        trend: viewModel.pointsTrend
                    ) {
                        viewModel.pointsDetailTapped()
                    }
                    .padding(.horizontal)

                    // Weekly progress card
                    WeeklyProgressCard(weeklyPoints: viewModel.weeklyPoints) {
                        viewModel.pointsDetailTapped()
                    }
                    .padding(.horizontal)

                    // Quick stats section
                    QuickStatsCard(stats: viewModel.todayStats)

                    // Quick action buttons
                    HStack(spacing: 16) {
                        QuickActionButton(
                            title: "Start Timer",
                            icon: "timer",
                            color: .blue
                        ) {
                            selectedTab = .timer
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
                await viewModel.loadData(for: currentChild)
                await viewModel.loadPoints()
                await activityLogViewModel.loadActivities()
            }
            .refreshable {
                await viewModel.loadData(for: currentChild)
                await viewModel.loadPoints()
            }
            .sheet(isPresented: $viewModel.showingQuickLog) {
                QuickLogView(viewModel: activityLogViewModel)
            }
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(.home), currentChild: Child(name: "Test", age: 8))
}
