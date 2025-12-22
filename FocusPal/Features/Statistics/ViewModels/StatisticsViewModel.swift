//
//  StatisticsViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// ViewModel for the Statistics screen.
/// Manages data loading and calculations for charts and insights.
@MainActor
class StatisticsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var dailyData: DailyStatistics = .empty
    @Published var weeklyData: WeeklyStatistics = .empty
    @Published var achievements: [AchievementDisplayItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let activityService: ActivityServiceProtocol

    // MARK: - Initialization

    init(activityService: ActivityServiceProtocol? = nil) {
        self.activityService = activityService ?? MockActivityService()
    }

    // MARK: - Public Methods

    func loadData() async {
        isLoading = true

        await loadDailyData()
        await loadWeeklyData()
        loadAchievements()

        isLoading = false
    }

    // MARK: - Private Methods

    private func loadDailyData() async {
        // Mock data for now
        dailyData = DailyStatistics(
            totalMinutes: 145,
            categoryBreakdown: [
                CategoryBreakdownItem(categoryName: "Homework", colorHex: "#4A90D9", minutes: 60, percentage: 41),
                CategoryBreakdownItem(categoryName: "Reading", colorHex: "#7B68EE", minutes: 30, percentage: 21),
                CategoryBreakdownItem(categoryName: "Screen Time", colorHex: "#FF6B6B", minutes: 45, percentage: 31),
                CategoryBreakdownItem(categoryName: "Playing", colorHex: "#4ECDC4", minutes: 10, percentage: 7)
            ],
            balanceScore: 75
        )
    }

    private func loadWeeklyData() async {
        // Mock data for now
        let calendar = Calendar.current
        let today = Date()

        var dailyBreakdown: [DailyBarData] = []
        let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -6 + i, to: today)!
            let weekday = calendar.component(.weekday, from: date) - 1

            dailyBreakdown.append(DailyBarData(
                dayLabel: dayLabels[weekday],
                minutes: Int.random(in: 60...180),
                date: date
            ))
        }

        let totalMinutes = dailyBreakdown.reduce(0) { $0 + $1.minutes }

        weeklyData = WeeklyStatistics(
            totalMinutes: totalMinutes,
            averageMinutesPerDay: totalMinutes / 7,
            dailyBreakdown: dailyBreakdown,
            currentStreak: 4,
            longestStreak: 7,
            insights: [
                "Homework time is consistent this week",
                "Great balance between activities!"
            ]
        )
    }

    private func loadAchievements() {
        achievements = AchievementType.allCases.map { type in
            let isUnlocked = [.firstTimer].contains(type)
            let progress: Double

            switch type {
            case .firstTimer: progress = 100
            case .streak3Day: progress = 66
            case .streak7Day: progress = 28
            case .homeworkHero: progress = 45
            default: progress = Double.random(in: 0...50)
            }

            return AchievementDisplayItem(
                id: UUID(),
                name: type.name,
                description: type.description,
                iconName: type.iconName,
                isUnlocked: isUnlocked,
                progress: progress,
                unlockedDate: isUnlocked ? Date() : nil
            )
        }
    }
}
