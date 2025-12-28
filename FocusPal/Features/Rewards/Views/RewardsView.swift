//
//  RewardsView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Main rewards view displaying weekly progress, tier status, and reward history.
struct RewardsView: View {
    @StateObject private var viewModel: RewardsViewModel
    @State private var selectedTab = 0
    @State private var showRedemptionSheet = false
    @State private var selectedReward: WeeklyReward?

    init(rewardsService: RewardsServiceProtocol? = nil, currentChild: Child? = nil) {
        _viewModel = StateObject(wrappedValue: RewardsViewModel(
            rewardsService: rewardsService,
            child: currentChild
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Week header with date range
                    weekHeader

                    // Tier progress section
                    TierProgressView(
                        currentPoints: viewModel.currentPoints,
                        currentTier: viewModel.currentTier
                    )
                    .padding(.horizontal)

                    // Encouragement message
                    encouragementBanner

                    // Tab selector for available rewards vs history
                    Picker("View", selection: $selectedTab) {
                        Text("This Week").tag(0)
                        Text("History").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Content based on selection
                    if selectedTab == 0 {
                        currentWeekContent
                    } else {
                        historyContent
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Rewards")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.unredeemedRewards.count > 0 {
                        Button {
                            showRedemptionSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "gift.fill")
                                Text("\(viewModel.unredeemedRewards.count)")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.orange))
                        }
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
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
            .alert("Reward Claimed!", isPresented: $viewModel.showRedemptionSuccess) {
                Button("Awesome!") {
                    viewModel.showRedemptionSuccess = false
                }
            } message: {
                if let tier = viewModel.lastRedeemedTier {
                    Text("You've claimed your \(tier.name) reward! Great job this week!")
                }
            }
            .sheet(isPresented: $showRedemptionSheet) {
                unredeemedRewardsSheet
            }
            .sheet(item: $selectedReward) { reward in
                rewardDetailSheet(reward: reward)
            }
        }
    }

    // MARK: - View Components

    private var weekHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("This Week")
                    .font(.title2.weight(.bold))

                Text(viewModel.weekDateRangeString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Current tier badge
            if let tier = viewModel.currentTier {
                TierBadge(tier: tier, isUnlocked: true, isCurrent: true, isCompact: false)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("Aim for Bronze!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var encouragementBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: encouragementIcon)
                .font(.title2)
                .foregroundColor(.white)

            Text(viewModel.encouragementMessage)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: encouragementGradientColors,
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var encouragementIcon: String {
        if viewModel.isMaxTier {
            return "crown.fill"
        } else if viewModel.currentTier != nil {
            return "flame.fill"
        } else if viewModel.currentPoints > 0 {
            return "arrow.up.circle.fill"
        } else {
            return "sparkles"
        }
    }

    private var encouragementGradientColors: [Color] {
        if let tier = viewModel.currentTier {
            return [Color(hex: tier.colorHex), Color(hex: tier.colorHex).opacity(0.7)]
        }
        return [.blue, .blue.opacity(0.7)]
    }

    private var currentWeekContent: some View {
        VStack(spacing: 16) {
            // Available rewards for unlocked tiers
            VStack(alignment: .leading, spacing: 12) {
                Text("Available Rewards")
                    .font(.headline)
                    .padding(.horizontal)

                if viewModel.currentTier != nil {
                    ForEach(unlockedTiers, id: \.self) { tier in
                        tierRewardRow(tier: tier)
                    }
                } else {
                    // No tier yet - show what they're working towards
                    lockedRewardsPreview
                }
            }

            // Upcoming tiers preview
            if !lockedTiers.isEmpty && viewModel.currentTier != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Keep Going!")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(lockedTiers.prefix(2), id: \.self) { tier in
                        lockedTierRow(tier: tier)
                    }
                }
            }

            // Stats summary
            if let history = viewModel.rewardHistory {
                statsCard(history: history)
            }
        }
    }

    private var unlockedTiers: [RewardTier] {
        RewardTier.sortedByPoints.filter { viewModel.isTierUnlocked($0) }
    }

    private var lockedTiers: [RewardTier] {
        RewardTier.sortedByPoints.filter { !viewModel.isTierUnlocked($0) }
    }

    private func tierRewardRow(tier: RewardTier) -> some View {
        HStack(spacing: 12) {
            TierBadge(tier: tier, isUnlocked: true, isCurrent: viewModel.isCurrentTierLevel(tier), isCompact: true)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(tier.name) Reward")
                    .font(.subheadline.weight(.medium))

                Text(tier.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var lockedRewardsPreview: some View {
        VStack(spacing: 12) {
            ForEach(RewardTier.sortedByPoints.prefix(2), id: \.self) { tier in
                lockedTierRow(tier: tier)
            }

            Text("Earn \(RewardTier.bronze.pointsRequired - viewModel.currentPoints) more points to unlock your first reward!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private func lockedTierRow(tier: RewardTier) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)

                Image(systemName: "lock.fill")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(tier.name) Reward")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("\(tier.pointsRequired - viewModel.currentPoints) more points needed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(tier.pointsRequired) pts")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func statsCard(history: RewardHistory) -> some View {
        VStack(spacing: 16) {
            Text("All-Time Stats")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 24) {
                RewardStatItem(
                    value: "\(history.totalPointsAllTime)",
                    label: "Total Points",
                    icon: "star.fill"
                )

                RewardStatItem(
                    value: "\(history.totalTiersEarned)",
                    label: "Tiers Earned",
                    icon: "medal.fill"
                )

                RewardStatItem(
                    value: "\(history.currentStreak)",
                    label: "Week Streak",
                    icon: "flame.fill"
                )
            }

            // Tier breakdown
            HStack(spacing: 16) {
                ForEach(RewardTier.sortedByPoints, id: \.self) { tier in
                    VStack(spacing: 4) {
                        Text("\(history.count(for: tier))")
                            .font(.title3.weight(.bold))
                            .foregroundColor(Color(hex: tier.colorHex))

                        Text(tier.name)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var historyContent: some View {
        VStack(spacing: 12) {
            if viewModel.pastWeekRewards.isEmpty {
                EmptyRewardHistory()
            } else {
                RewardHistorySectionHeader(
                    title: "Past Weeks",
                    subtitle: "\(viewModel.pastWeekRewards.count) weeks tracked"
                )

                ForEach(viewModel.pastWeekRewards) { reward in
                    WeeklyRewardHistoryRow(reward: reward) {
                        selectedReward = reward
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var unredeemedRewardsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("You have \(viewModel.unredeemedRewards.count) unclaimed rewards!")
                        .font(.headline)
                        .padding(.top)

                    ForEach(viewModel.unredeemedRewards) { reward in
                        RewardCard(reward: reward, isRedeemable: true) {
                            Task {
                                await viewModel.redeemReward(reward)
                            }
                            showRedemptionSheet = false
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Unclaimed Rewards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showRedemptionSheet = false
                    }
                }
            }
        }
    }

    private func rewardDetailSheet(reward: WeeklyReward) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Large tier display
                    if let tier = reward.tier {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: tier.colorHex).opacity(0.4),
                                                Color(hex: tier.colorHex).opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)

                                Image(systemName: tier == .platinum ? "crown.fill" : "medal.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(hex: tier.colorHex))
                            }

                            Text(tier.name)
                                .font(.title.weight(.bold))
                                .foregroundColor(Color(hex: tier.colorHex))

                            Text(tier.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }

                    RewardCard(reward: reward, isRedeemable: !reward.isRedeemed && reward.tier != nil) {
                        Task {
                            await viewModel.redeemReward(reward)
                        }
                        selectedReward = nil
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 24)
            }
            .navigationTitle("Reward Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedReward = nil
                    }
                }
            }
        }
    }
}

// MARK: - Reward Stat Item

private struct RewardStatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    RewardsView()
}
