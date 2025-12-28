//
//  RewardsViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// ViewModel for the Rewards screen.
/// Manages weekly reward progress, tier calculations, and reward redemption.
@MainActor
class RewardsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentProgress: WeeklyRewardProgress?
    @Published var weeklyRewards: [WeeklyReward] = []
    @Published var rewardHistory: RewardHistory?
    @Published var unredeemedRewards: [WeeklyReward] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showRedemptionSuccess = false
    @Published var lastRedeemedTier: RewardTier?

    // MARK: - Dependencies

    private let rewardsService: RewardsServiceProtocol?
    private let child: Child

    // MARK: - Computed Properties

    /// Current tier achieved this week
    var currentTier: RewardTier? {
        currentProgress?.tier
    }

    /// Next tier to achieve
    var nextTier: RewardTier? {
        currentProgress?.nextTier
    }

    /// Points earned this week
    var currentPoints: Int {
        currentProgress?.points ?? 0
    }

    /// Points needed to reach next tier
    var pointsToNextTier: Int {
        currentProgress?.pointsToNext ?? RewardTier.bronze.pointsRequired
    }

    /// Progress percentage to next tier
    var progressPercentage: Double {
        currentProgress?.progressPercentage ?? 0
    }

    /// Whether platinum has been achieved
    var isMaxTier: Bool {
        currentProgress?.isMaxTier ?? false
    }

    /// Week date range formatted string
    var weekDateRangeString: String {
        guard let progress = currentProgress else {
            return "This Week"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let start = formatter.string(from: progress.weekStartDate)
        let end = formatter.string(from: progress.weekEndDate)

        return "\(start) - \(end)"
    }

    /// Past weeks' rewards (excluding current week)
    var pastWeekRewards: [WeeklyReward] {
        weeklyRewards.filter { !$0.isCurrentWeek }
    }

    /// Encouraging message based on current progress
    var encouragementMessage: String {
        if let tier = currentTier {
            switch tier {
            case .platinum:
                return "Amazing! You've reached the highest tier!"
            case .gold:
                return "Incredible progress! Platinum is within reach!"
            case .silver:
                return "Great job! Keep going for Gold!"
            case .bronze:
                return "Nice start! Silver awaits!"
            }
        } else {
            let pointsNeeded = RewardTier.bronze.pointsRequired - currentPoints
            if pointsNeeded <= 20 {
                return "Almost there! Just \(pointsNeeded) more points to Bronze!"
            } else if currentPoints > 0 {
                return "You're making progress! Keep it up!"
            } else {
                return "Start earning points to unlock rewards!"
            }
        }
    }

    // MARK: - Initialization

    init(
        rewardsService: RewardsServiceProtocol? = nil,
        child: Child? = nil
    ) {
        self.rewardsService = rewardsService
        self.child = child ?? Child(name: "Test Child", age: 8)

        print("RewardsViewModel initialized for child: \(self.child.name) (\(self.child.id))")
    }

    // MARK: - Public Methods

    /// Load all rewards data
    func loadData() async {
        guard rewardsService != nil else {
            // Service not available yet, use mock data for preview
            loadMockData()
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            async let progressTask = loadCurrentProgress()
            async let historyTask = loadWeeklyRewards()
            async let statsTask = loadRewardHistory()
            async let unredeemedTask = loadUnredeemedRewards()

            _ = await (progressTask, historyTask, statsTask, unredeemedTask)
        }

        isLoading = false
    }

    /// Redeem a weekly reward
    func redeemReward(_ reward: WeeklyReward) async {
        guard let service = rewardsService else {
            errorMessage = "Rewards service not available"
            return
        }

        guard !reward.isRedeemed else {
            errorMessage = "This reward has already been redeemed"
            return
        }

        guard reward.tier != nil else {
            errorMessage = "No tier achieved for this reward"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await service.redeemReward(reward.id)
            lastRedeemedTier = reward.tier
            showRedemptionSuccess = true

            // Reload data to update UI
            await loadData()
        } catch {
            errorMessage = "Failed to redeem reward: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Check if a tier is unlocked (achieved this week)
    func isTierUnlocked(_ tier: RewardTier) -> Bool {
        guard let currentTier = currentTier else { return false }
        return tier.pointsRequired <= currentTier.pointsRequired
    }

    /// Check if a tier is the current tier
    func isCurrentTierLevel(_ tier: RewardTier) -> Bool {
        currentTier == tier
    }

    // MARK: - Private Methods

    private func loadCurrentProgress() async {
        guard let service = rewardsService else { return }

        do {
            currentProgress = try await service.getCurrentWeekProgress(for: child.id)
        } catch {
            print("Failed to load current progress: \(error)")
        }
    }

    private func loadWeeklyRewards() async {
        guard let service = rewardsService else { return }

        do {
            weeklyRewards = try await service.getWeeklyRewards(for: child.id)
        } catch {
            print("Failed to load weekly rewards: \(error)")
        }
    }

    private func loadRewardHistory() async {
        guard let service = rewardsService else { return }

        do {
            rewardHistory = try await service.getRewardHistory(for: child.id)
        } catch {
            print("Failed to load reward history: \(error)")
        }
    }

    private func loadUnredeemedRewards() async {
        guard let service = rewardsService else { return }

        do {
            unredeemedRewards = try await service.getUnredeemedRewards(for: child.id)
        } catch {
            print("Failed to load unredeemed rewards: \(error)")
        }
    }

    /// Load mock data when service is not available
    private func loadMockData() {
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()

        // Mock current progress
        currentProgress = WeeklyRewardProgress(
            points: 175,
            tier: .bronze,
            nextTier: .silver,
            pointsToNext: 75,
            progressPercentage: 50,
            weekStartDate: weekStart,
            weekEndDate: weekEnd
        )

        // Mock weekly rewards history
        let calendar = Calendar.current
        weeklyRewards = [
            WeeklyReward(
                childId: child.id,
                weekStartDate: calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!,
                weekEndDate: calendar.date(byAdding: .weekOfYear, value: -1, to: weekEnd)!,
                totalPoints: 320,
                tier: .silver,
                isRedeemed: true,
                redeemedDate: calendar.date(byAdding: .day, value: -3, to: Date())
            ),
            WeeklyReward(
                childId: child.id,
                weekStartDate: calendar.date(byAdding: .weekOfYear, value: -2, to: weekStart)!,
                weekEndDate: calendar.date(byAdding: .weekOfYear, value: -2, to: weekEnd)!,
                totalPoints: 580,
                tier: .gold,
                isRedeemed: true,
                redeemedDate: calendar.date(byAdding: .day, value: -10, to: Date())
            ),
            WeeklyReward(
                childId: child.id,
                weekStartDate: calendar.date(byAdding: .weekOfYear, value: -3, to: weekStart)!,
                weekEndDate: calendar.date(byAdding: .weekOfYear, value: -3, to: weekEnd)!,
                totalPoints: 150,
                tier: .bronze,
                isRedeemed: false
            )
        ]

        // Mock reward history
        rewardHistory = RewardHistory(
            childId: child.id,
            totalPointsAllTime: 1225,
            totalWeeksCompleted: 4,
            bronzeTiersEarned: 2,
            silverTiersEarned: 1,
            goldTiersEarned: 1,
            platinumTiersEarned: 0,
            longestStreak: 3,
            currentStreak: 2
        )

        // Mock unredeemed rewards
        unredeemedRewards = weeklyRewards.filter { !$0.isRedeemed && $0.tier != nil }
    }
}
