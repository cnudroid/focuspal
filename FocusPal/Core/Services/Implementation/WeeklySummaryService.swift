//
//  WeeklySummaryService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Errors that can occur in the weekly summary service
enum WeeklySummaryServiceError: Error, LocalizedError {
    case childNotFound
    case invalidDateRange

    var errorDescription: String? {
        switch self {
        case .childNotFound: return "Child not found"
        case .invalidDateRange: return "Invalid date range provided"
        }
    }
}

/// Service to generate weekly summary data for email notifications
class WeeklySummaryService {

    // MARK: - Properties

    private let activityRepository: ActivityRepositoryProtocol
    private let childRepository: ChildRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let pointsRepository: PointsRepositoryProtocol
    private let rewardsRepository: RewardsRepositoryProtocol
    private let achievementRepository: AchievementRepositoryProtocol

    // MARK: - Initialization

    init(
        activityRepository: ActivityRepositoryProtocol,
        childRepository: ChildRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol,
        pointsRepository: PointsRepositoryProtocol,
        rewardsRepository: RewardsRepositoryProtocol,
        achievementRepository: AchievementRepositoryProtocol
    ) {
        self.activityRepository = activityRepository
        self.childRepository = childRepository
        self.categoryRepository = categoryRepository
        self.pointsRepository = pointsRepository
        self.rewardsRepository = rewardsRepository
        self.achievementRepository = achievementRepository
    }

    // MARK: - Public Methods

    /// Generate a weekly summary for a specific child
    /// - Parameters:
    ///   - childId: The child's UUID
    ///   - weekStartDate: The start date of the week (typically Monday at 00:00:00)
    /// - Returns: A WeeklySummary containing aggregated data for the week
    /// - Throws: WeeklySummaryServiceError if child not found or data cannot be fetched
    func generateSummary(for childId: UUID, weekStartDate: Date) async throws -> WeeklySummary {
        // Fetch the child
        guard let child = try await childRepository.fetch(by: childId) else {
            throw WeeklySummaryServiceError.childNotFound
        }

        // Calculate week end date
        let calendar = Calendar.current
        let weekEndDate = calendar.date(byAdding: .day, value: 7, to: weekStartDate) ?? weekStartDate

        // Fetch activities for the week
        let dateRange = DateInterval(start: weekStartDate, end: weekEndDate)
        let activities = try await activityRepository.fetch(for: childId, dateRange: dateRange)

        // Calculate activity stats
        let totalActivities = activities.count
        let completedActivities = activities.filter { $0.isComplete }.count
        let incompleteActivities = activities.filter { !$0.isComplete }.count
        let totalMinutes = activities.reduce(0) { $0 + $1.durationMinutes }

        // Fetch points for the week
        let pointsData = try await pointsRepository.fetchChildPoints(for: childId, dateRange: dateRange)
        let pointsEarned = pointsData.reduce(0) { $0 + $1.pointsEarned }
        let pointsDeducted = pointsData.reduce(0) { $0 + $1.pointsDeducted }
        let bonusPoints = pointsData.reduce(0) { $0 + $1.bonusPoints }
        let netPoints = pointsEarned + bonusPoints - pointsDeducted

        // Fetch current tier from weekly reward
        let weeklyReward = try await rewardsRepository.fetchReward(for: childId, weekStartDate: weekStartDate)
        let currentTier = weeklyReward?.tier

        // Calculate top categories
        let topCategories = try await calculateTopCategories(for: childId, activities: activities)

        // Count achievements unlocked this week
        let allAchievements = try await achievementRepository.fetchUnlocked(for: childId)
        let achievementsUnlocked = allAchievements.filter { achievement in
            guard let unlockedDate = achievement.unlockedDate else { return false }
            return unlockedDate >= weekStartDate && unlockedDate < weekEndDate
        }.count

        // Calculate current streak
        let streak = try await calculateStreak(for: childId, currentWeekStart: weekStartDate)

        return WeeklySummary(
            childName: child.name,
            weekStartDate: weekStartDate,
            weekEndDate: weekEndDate,
            totalActivities: totalActivities,
            completedActivities: completedActivities,
            incompleteActivities: incompleteActivities,
            totalMinutes: totalMinutes,
            pointsEarned: pointsEarned,
            pointsDeducted: pointsDeducted,
            netPoints: netPoints,
            currentTier: currentTier,
            topCategories: topCategories,
            achievementsUnlocked: achievementsUnlocked,
            streak: streak
        )
    }

    /// Generate summaries for all children using the current week
    /// - Returns: Array of WeeklySummary for all children
    /// - Throws: Error if data cannot be fetched
    func generateSummariesForAllChildren() async throws -> [WeeklySummary] {
        let children = try await childRepository.fetchAll()

        // Get current week start date
        let (weekStart, _) = WeeklyReward.currentWeekDates()

        var summaries: [WeeklySummary] = []
        for child in children {
            let summary = try await generateSummary(for: child.id, weekStartDate: weekStart)
            summaries.append(summary)
        }

        return summaries
    }

    // MARK: - Private Helpers

    /// Calculate top 3 categories by total minutes
    private func calculateTopCategories(
        for childId: UUID,
        activities: [Activity]
    ) async throws -> [(categoryName: String, minutes: Int)] {
        guard !activities.isEmpty else { return [] }

        // Fetch all categories for the child
        let allCategories = try await categoryRepository.fetchAll(for: childId)
        let categoryMap = Dictionary(uniqueKeysWithValues: allCategories.map { ($0.id, $0) })

        // Group activities by category and sum minutes
        var categoryMinutes: [UUID: Int] = [:]
        for activity in activities {
            categoryMinutes[activity.categoryId, default: 0] += activity.durationMinutes
        }

        // Sort by minutes descending and take top 3
        let topThree = categoryMinutes
            .sorted { $0.value > $1.value }
            .prefix(3)
            .compactMap { (categoryId, minutes) -> (categoryName: String, minutes: Int)? in
                guard let category = categoryMap[categoryId] else { return nil }
                return (category.name, minutes)
            }

        return Array(topThree)
    }

    /// Calculate the current streak of consecutive weeks with earned tiers
    private func calculateStreak(for childId: UUID, currentWeekStart: Date) async throws -> Int {
        let allRewards = try await rewardsRepository.fetchAll(for: childId)

        // Filter to only rewards with tiers, sorted by date descending
        let tieredRewards = allRewards
            .filter { $0.tier != nil }
            .sorted { $0.weekStartDate > $1.weekStartDate }

        guard !tieredRewards.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var previousWeekStart: Date?

        for reward in tieredRewards {
            if let previous = previousWeekStart {
                // Calculate days between this reward's week and the previous one
                let daysBetween = calendar.dateComponents([.day], from: reward.weekStartDate, to: previous).day ?? 0

                if daysBetween == 7 {
                    // Consecutive weeks
                    streak += 1
                } else {
                    // Streak broken
                    break
                }
            } else {
                // First reward (most recent)
                streak = 1
            }

            previousWeekStart = reward.weekStartDate
        }

        return streak
    }
}
