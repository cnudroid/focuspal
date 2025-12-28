//
//  AchievementCard.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Card displaying an achievement badge.
struct AchievementCard: View {
    let name: String
    let description: String
    let icon: String
    let emoji: String
    let isUnlocked: Bool
    let progress: Double?
    let unlockedDate: Date?

    init(
        name: String,
        description: String,
        icon: String,
        emoji: String = "",
        isUnlocked: Bool,
        progress: Double? = nil,
        unlockedDate: Date? = nil
    ) {
        self.name = name
        self.description = description
        self.icon = icon
        self.emoji = emoji
        self.isUnlocked = isUnlocked
        self.progress = progress
        self.unlockedDate = unlockedDate
    }

    var body: some View {
        HStack(spacing: FPSpacing.md) {
            // Badge
            ZStack {
                Circle()
                    .fill(
                        isUnlocked
                            ? LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color(.systemGray4), Color(.systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 56, height: 56)

                if !emoji.isEmpty {
                    Text(emoji)
                        .font(.title)
                        .opacity(isUnlocked ? 1.0 : 0.5)
                } else {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isUnlocked ? .white : .secondary)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: FPSpacing.xxs) {
                Text(name)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                if let progress = progress, !isUnlocked {
                    ProgressView(value: progress, total: 100)
                        .tint(.accentColor)

                    Text("\(Int(progress))% complete")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if let date = unlockedDate, isUnlocked {
                    Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(FPSpacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .cardShadow()
    }
}

#Preview {
    VStack(spacing: 12) {
        AchievementCard(
            name: "First Timer",
            description: "Complete your first timed activity",
            icon: "star.fill",
            emoji: "🎯",
            isUnlocked: true,
            unlockedDate: Date()
        )

        AchievementCard(
            name: "3-Day Streak",
            description: "Log activities for 3 days in a row",
            icon: "flame.fill",
            emoji: "🔥",
            isUnlocked: false,
            progress: 66
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
