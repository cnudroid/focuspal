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

    init(
        selectedTab: Binding<AppTab>,
        currentChild: Child,
        activityService: ActivityServiceProtocol? = nil,
        categoryService: CategoryServiceProtocol? = nil,
        pointsService: PointsServiceProtocol? = nil
    ) {
        _selectedTab = selectedTab
        self.currentChild = currentChild
        _viewModel = StateObject(wrappedValue: HomeViewModel(
            activityService: activityService,
            categoryService: categoryService,
            pointsService: pointsService
        ))
        _activityLogViewModel = StateObject(wrappedValue: ActivityLogViewModel(child: currentChild))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Mascot greeting
                    ClockMascot(
                        size: 100,
                        message: greetingMessage,
                        mood: mascotMood
                    )
                    .padding(.top, 8)

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
                            // Timer is now an overlay, trigger via ViewModel
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

    // MARK: - Mascot Helpers

    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = currentChild.name

        if viewModel.todayStats.activitiesCount == 0 {
            if hour < 12 {
                return "Good morning, \(name)!"
            } else if hour < 17 {
                return "Ready to focus, \(name)?"
            } else {
                return "Evening, \(name)!"
            }
        } else if viewModel.todayStats.activitiesCount >= 3 {
            return "You're on fire, \(name)!"
        } else {
            return "Keep going, \(name)!"
        }
    }

    private var mascotMood: ClockMascot.MascotMood {
        if viewModel.todayStats.activitiesCount >= 3 {
            return .celebrating
        } else if viewModel.todayStats.activitiesCount > 0 {
            return .excited
        } else {
            return .happy
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(.today), currentChild: Child(name: "Test", age: 8))
}
