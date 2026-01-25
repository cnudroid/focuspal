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
    @State private var selectedBadge: AchievementDisplayItem?

    init(
        rewardsService: RewardsServiceProtocol? = nil,
        achievementService: AchievementServiceProtocol? = nil,
        currentChild: Child? = nil
    ) {
        _viewModel = StateObject(wrappedValue: RewardsViewModel(
            rewardsService: rewardsService,
            achievementService: achievementService,
            child: currentChild
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background (respects child preferences)
                ChildPreferenceBackground(child: viewModel.child, screenType: .rewards)

                ScrollView {
                    VStack(spacing: 20) {
                        // Mascot with encouraging message
                        ClockMascot(
                        size: 100,
                        message: rewardsMascotMessage,
                        mood: rewardsMascotMood
                    )
                    .padding(.top, 8)

                    // Week header with date range
                    weekHeader

                    // My Badges section (unlocked achievements)
                    if !viewModel.unlockedBadges.isEmpty {
                        myBadgesSection
                    }

                    // Tier progress section
                    TierProgressView(
                        currentPoints: viewModel.currentPoints,
                        currentTier: viewModel.currentTier
                    )
                    .padding(.horizontal)

                    // Coming Up section (achievements close to unlock)
                    if !viewModel.comingUpAchievements.isEmpty {
                        comingUpSection
                    }

                    // Encouragement message
                    encouragementBanner

                    // Tab selector for available rewards vs history vs badges
                    Picker("View", selection: $selectedTab) {
                        Text("This Week").tag(0)
                        Text("Badges").tag(1)
                        Text("History").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Content based on selection
                    if selectedTab == 0 {
                        currentWeekContent
                    } else if selectedTab == 1 {
                        badgesContent
                    } else {
                        historyContent
                    }
                }
                .padding(.bottom, 24)
                }
            }
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
            .sheet(item: $selectedBadge) { badge in
                BadgeDetailView(
                    badge: badge,
                    childName: viewModel.child.name,
                    onShare: {
                        viewModel.shareAchievement(badge)
                    }
                )
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let image = viewModel.shareImage {
                    ShareSheet(items: [image])
                }
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

    // MARK: - Badges Section

    private var myBadgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Badges")
                    .font(.headline)

                Spacer()

                if viewModel.unlockedBadges.count > 4 {
                    Button {
                        selectedTab = 1 // Switch to badges tab
                    } label: {
                        Text("See All")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.unlockedBadges.prefix(6)) { badge in
                        BadgeItemView(badge: badge, isNew: viewModel.recentlyUnlockedBadges.contains { $0.id == badge.id })
                            .onTapGesture {
                                selectedBadge = badge
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }

    private var comingUpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Coming Up")
                    .font(.headline)

                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal)

            ForEach(viewModel.comingUpAchievements) { achievement in
                ComingUpAchievementRow(achievement: achievement)
            }
        }
        .padding(.vertical, 8)
    }

    private var badgesContent: some View {
        VStack(spacing: 16) {
            // Unlocked badges
            if !viewModel.unlockedBadges.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Unlocked (\(viewModel.unlockedBadges.count))")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(viewModel.unlockedBadges) { badge in
                            BadgeGridItem(badge: badge, isUnlocked: true, isNew: viewModel.recentlyUnlockedBadges.contains { $0.id == badge.id })
                                .onTapGesture {
                                    selectedBadge = badge
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Locked badges
            let lockedBadges = viewModel.achievements.filter { !$0.isUnlocked }
            if !lockedBadges.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Locked (\(lockedBadges.count))")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(lockedBadges) { badge in
                            BadgeGridItem(badge: badge, isUnlocked: false, isNew: false)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Empty state
            if viewModel.achievements.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "trophy")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)

                    Text("No badges yet!")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Complete activities to earn badges")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
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

// MARK: - Mascot Helpers

extension RewardsView {
    var rewardsMascotMessage: String {
        if viewModel.isMaxTier {
            return "You're a superstar!"
        } else if viewModel.currentTier != nil {
            return "Amazing progress!"
        } else if viewModel.currentPoints > 0 {
            return "Keep earning points!"
        } else {
            return "Let's earn rewards!"
        }
    }

    var rewardsMascotMood: ClockMascot.MascotMood {
        if viewModel.isMaxTier {
            return .celebrating
        } else if viewModel.currentTier != nil {
            return .excited
        } else if viewModel.currentPoints > 0 {
            return .encouraging
        } else {
            return .happy
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

// MARK: - Badge Item View (Horizontal Scroll)

private struct BadgeItemView: View {
    let badge: AchievementDisplayItem
    let isNew: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    Text(badge.emoji)
                        .font(.system(size: 30))
                }
                .badgeWiggle(isNew: isNew)

                if isNew {
                    NewBadgeIndicator()
                        .offset(x: 5, y: -5)
                }
            }

            Text(badge.name)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 70)
        }
    }
}

// MARK: - Coming Up Achievement Row

private struct ComingUpAchievementRow: View {
    let achievement: AchievementDisplayItem

    private var progressText: String {
        let remaining = 100 - achievement.progress
        return "\(remaining)% more to go"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Locked badge with grayscale
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 50, height: 50)

                Text(achievement.emoji)
                    .font(.system(size: 24))
                    .grayscale(0.8)

                // Lock overlay
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Circle().fill(Color.gray))
                    .offset(x: 18, y: 18)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.name)
                    .font(.subheadline.weight(.medium))

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray4))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (Double(achievement.progress) / 100), height: 8)
                    }
                }
                .frame(height: 8)

                Text(progressText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(achievement.progress)%")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.purple)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Badge Grid Item

private struct BadgeGridItem: View {
    let badge: AchievementDisplayItem
    let isUnlocked: Bool
    let isNew: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(
                            isUnlocked
                                ? LinearGradient(
                                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 70, height: 70)

                    Text(badge.emoji)
                        .font(.system(size: 34))
                        .grayscale(isUnlocked ? 0 : 1)
                        .opacity(isUnlocked ? 1 : 0.5)

                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Circle().fill(Color.gray.opacity(0.8)))
                            .offset(x: 22, y: 22)
                    }
                }
                .badgeWiggle(isNew: isNew)

                if isNew && isUnlocked {
                    NewBadgeIndicator()
                        .offset(x: 5, y: -5)
                }
            }

            Text(badge.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isUnlocked ? .primary : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if !isUnlocked && badge.progress > 0 {
                Text("\(badge.progress)%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    RewardsView()
}
