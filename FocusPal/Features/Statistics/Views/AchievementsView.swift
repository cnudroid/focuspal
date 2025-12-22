//
//  AchievementsView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// View displaying earned and available achievements.
struct AchievementsView: View {
    let achievements: [AchievementDisplayItem]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Unlocked achievements
                VStack(alignment: .leading, spacing: 16) {
                    Text("Unlocked")
                        .font(.headline)

                    let unlocked = achievements.filter { $0.isUnlocked }
                    if unlocked.isEmpty {
                        Text("Complete activities to earn achievements!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(unlocked) { achievement in
                                AchievementBadge(achievement: achievement)
                            }
                        }
                    }
                }

                Divider()

                // In progress achievements
                VStack(alignment: .leading, spacing: 16) {
                    Text("In Progress")
                        .font(.headline)

                    let inProgress = achievements.filter { !$0.isUnlocked }
                    ForEach(inProgress) { achievement in
                        AchievementProgressRow(achievement: achievement)
                    }
                }
            }
            .padding()
        }
    }
}

struct AchievementBadge: View {
    let achievement: AchievementDisplayItem

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: achievement.iconName)
                    .font(.title2)
                    .foregroundColor(.white)
            }

            Text(achievement.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
}

struct AchievementProgressRow: View {
    let achievement: AchievementDisplayItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 50, height: 50)

                Image(systemName: achievement.iconName)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                ProgressView(value: achievement.progress, total: 100)
                    .tint(.accentColor)

                Text("\(Int(achievement.progress))% complete")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

/// Display model for achievements
struct AchievementDisplayItem: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let iconName: String
    let isUnlocked: Bool
    let progress: Double
    let unlockedDate: Date?
}

#Preview {
    AchievementsView(achievements: [
        AchievementDisplayItem(
            id: UUID(),
            name: "First Timer",
            description: "Complete your first activity",
            iconName: "star.fill",
            isUnlocked: true,
            progress: 100,
            unlockedDate: Date()
        ),
        AchievementDisplayItem(
            id: UUID(),
            name: "3-Day Streak",
            description: "Log activities for 3 days in a row",
            iconName: "flame.fill",
            isUnlocked: false,
            progress: 66,
            unlockedDate: nil
        )
    ])
}
