//
//  MeView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Me tab showing child's avatar, points, progress, and access to parent controls.
struct MeView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    let currentChild: Child

    @State private var todayPoints: Int = 0
    @State private var weeklyPoints: Int = 0
    @State private var currentStreak: Int = 0
    @State private var completedActivities: Int = 0
    @State private var totalMinutes: Int = 0
    @State private var unlockedBadges: [AchievementDisplayItem] = []
    @State private var showingBackgroundSettings = false
    @State private var isLoading = false
    @State private var childPreferences: ChildPreferences

    init(currentChild: Child) {
        self.currentChild = currentChild
        _childPreferences = State(initialValue: currentChild.preferences)
    }

    /// Child object with currently selected preferences for live preview
    private var childWithCurrentPreferences: Child {
        var child = currentChild
        child.preferences = childPreferences
        return child
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background (respects child preferences)
                ChildPreferenceBackground(child: childWithCurrentPreferences, screenType: .me)

                ScrollView {
                VStack(spacing: 24) {
                    // Avatar section
                    AvatarSection(child: currentChild)

                    // Today's points card
                    TodayPointsCard(points: todayPoints, weeklyTotal: weeklyPoints)
                        .padding(.horizontal)

                    // Quick stats row
                    quickStatsRow
                        .padding(.horizontal)

                    // Streak display
                    StreakDisplay(currentStreak: currentStreak, isActive: currentStreak > 0)
                        .padding(.horizontal)

                    // Badges preview
                    if !unlockedBadges.isEmpty {
                        badgesPreviewSection
                    }

                    // Customize background button
                    customizeBackgroundButton
                        .padding(.horizontal)

                    Spacer().frame(height: 20)
                }
                .padding(.vertical)
                }
            }
            .navigationTitle("Me")
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
            .sheet(isPresented: $showingBackgroundSettings) {
                NavigationStack {
                    BackgroundSettingsView(
                        preferences: $childPreferences,
                        themeColor: currentChild.themeColor
                    )
                    .navigationTitle("Background")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingBackgroundSettings = false
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var quickStatsRow: some View {
        HStack(spacing: 16) {
            SimpleProgressView(
                title: "Activities",
                value: completedActivities,
                icon: "checkmark.circle.fill",
                color: .green
            )

            SimpleProgressView(
                title: "Minutes",
                value: totalMinutes,
                icon: "clock.fill",
                color: .blue
            )

            SimpleProgressView(
                title: "Badges",
                value: unlockedBadges.count,
                icon: "trophy.fill",
                color: .purple
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var badgesPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "medal.fill")
                    .foregroundColor(.purple)
                Text("My Badges")
                    .font(.headline)

                Spacer()

                if unlockedBadges.count > 5 {
                    Text("See all")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(unlockedBadges.prefix(5)) { badge in
                        BadgePreviewItem(badge: badge)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var customizeBackgroundButton: some View {
        Button {
            showingBackgroundSettings = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Customize Background")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)

                    Text(childPreferences.backgroundStyle.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true

        // Load points
        do {
            let points = try await serviceContainer.pointsService.getTodayPoints(for: currentChild.id)
            todayPoints = points.totalPoints
            weeklyPoints = try await serviceContainer.pointsService.getWeeklyPoints(for: currentChild.id)
        } catch {
            print("Error loading points: \(error)")
        }

        // Load activities for stats
        do {
            let activities = try await serviceContainer.activityService.fetchTodayActivities(for: currentChild)
            completedActivities = activities.count
            totalMinutes = activities.reduce(0) { $0 + $1.durationMinutes }
        } catch {
            print("Error loading activities: \(error)")
        }

        // Load badges
        do {
            let achievements = try await serviceContainer.achievementService.fetchUnlockedAchievements(for: currentChild)
            unlockedBadges = achievements.compactMap { achievement -> AchievementDisplayItem? in
                guard let type = AchievementType(rawValue: achievement.achievementTypeId) else {
                    return nil
                }
                return AchievementDisplayItem(
                    id: achievement.id,
                    name: type.name,
                    description: type.description,
                    iconName: type.iconName,
                    emoji: type.emoji,
                    isUnlocked: true,
                    progress: 100,
                    unlockedDate: achievement.unlockedDate
                )
            }
        } catch {
            print("Error loading achievements: \(error)")
        }

        // TODO: Calculate streak from activity history
        currentStreak = completedActivities > 0 ? 1 : 0

        isLoading = false
    }
}

// MARK: - Badge Preview Item

struct BadgePreviewItem: View {
    let badge: AchievementDisplayItem

    var body: some View {
        VStack(spacing: 8) {
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

#Preview {
    MeView(currentChild: Child(name: "Emma", age: 8, themeColor: "pink"))
        .environmentObject(ServiceContainer())
}
