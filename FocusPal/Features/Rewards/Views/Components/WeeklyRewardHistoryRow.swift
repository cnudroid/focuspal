//
//  WeeklyRewardHistoryRow.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Row component displaying a past week's reward summary.
struct WeeklyRewardHistoryRow: View {
    let reward: WeeklyReward
    let onTap: (() -> Void)?

    @State private var isExpanded = false

    init(reward: WeeklyReward, onTap: (() -> Void)? = nil) {
        self.reward = reward
        self.onTap = onTap
    }

    private var tierColor: Color {
        guard let tier = reward.tier else { return .gray }
        return Color(hex: tier.colorHex)
    }

    private var weekDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let start = formatter.string(from: reward.weekStartDate)
        let end = formatter.string(from: reward.weekEndDate)

        return "\(start) - \(end)"
    }

    private var relativeWeekString: String {
        let calendar = Calendar.current
        let now = Date()

        if reward.isCurrentWeek {
            return "This Week"
        }

        let weeksDiff = calendar.dateComponents([.weekOfYear], from: reward.weekStartDate, to: now).weekOfYear ?? 0

        if weeksDiff == 1 {
            return "Last Week"
        } else {
            return "\(weeksDiff) weeks ago"
        }
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
            onTap?()
        } label: {
            VStack(spacing: 0) {
                // Main row content
                HStack(spacing: 12) {
                    // Tier indicator
                    ZStack {
                        Circle()
                            .fill(tierColor.opacity(0.15))
                            .frame(width: 50, height: 50)

                        if let tier = reward.tier {
                            VStack(spacing: 0) {
                                Image(systemName: tier == .platinum ? "crown.fill" : "medal.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(tierColor)
                            }
                        } else {
                            Image(systemName: "minus")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    }

                    // Week info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(relativeWeekString)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)

                            if reward.isCurrentWeek {
                                Text("LIVE")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.green))
                            }
                        }

                        Text(weekDateString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Points and status
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("\(reward.totalPoints)")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.primary)
                        }

                        if let tier = reward.tier {
                            HStack(spacing: 4) {
                                if reward.isRedeemed {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                    Text("Claimed")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else {
                                    Text(tier.name)
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(tierColor)
                                }
                            }
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()

                // Expanded details
                if isExpanded {
                    VStack(spacing: 12) {
                        Divider()
                            .padding(.horizontal)

                        // Detailed stats
                        HStack(spacing: 24) {
                            StatColumn(
                                icon: "star.fill",
                                iconColor: .yellow,
                                value: "\(reward.totalPoints)",
                                label: "Points"
                            )

                            if let tier = reward.tier {
                                StatColumn(
                                    icon: tier == .platinum ? "crown.fill" : "medal.fill",
                                    iconColor: tierColor,
                                    value: tier.name,
                                    label: "Tier"
                                )
                            }

                            StatColumn(
                                icon: reward.isRedeemed ? "checkmark.seal.fill" : "gift.fill",
                                iconColor: reward.isRedeemed ? .green : .orange,
                                value: reward.isRedeemed ? "Yes" : "No",
                                label: "Claimed"
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom)

                        // Tier progress for that week
                        if let tier = reward.tier {
                            Text(tier.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }

                        // Redemption date if applicable
                        if reward.isRedeemed, let date = reward.redeemedDate {
                            HStack {
                                Image(systemName: "calendar.badge.checkmark")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Text("Claimed on \(formattedDate(date))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.bottom)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

/// Column for displaying a stat in the expanded view.
private struct StatColumn: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)

            Text(value)
                .font(.subheadline.weight(.semibold))

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Section header for grouping rewards history.
struct RewardHistorySectionHeader: View {
    let title: String
    let subtitle: String?

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

/// Empty state for when there's no reward history.
struct EmptyRewardHistory: View {
    @State private var bouncing = false

    private static let encouragements = [
        (emoji: "🌟", message: "Your reward adventure starts today!"),
        (emoji: "🚀", message: "Ready to earn some awesome rewards?"),
        (emoji: "🏆", message: "Future trophies await you!"),
        (emoji: "🎯", message: "Set your sights on success!"),
        (emoji: "✨", message: "Magic happens when you focus!")
    ]

    private var randomEncouragement: (emoji: String, message: String) {
        Self.encouragements[abs(Date().hashValue) % Self.encouragements.count]
    }

    var body: some View {
        VStack(spacing: 20) {
            // Fun animated emoji instead of boring icon
            Text(randomEncouragement.emoji)
                .font(.system(size: 60))
                .scaleEffect(bouncing ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: bouncing
                )
                .onAppear { bouncing = true }

            VStack(spacing: 8) {
                Text("Your Journey Begins!")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(randomEncouragement.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Encouraging emoji row
            HStack(spacing: 16) {
                ForEach(["💪", "🌈", "🎉"], id: \.self) { emoji in
                    Text(emoji)
                        .font(.title2)
                }
            }

            Text("Complete focus sessions to fill this page with achievements!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.05),
                            Color.blue.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .padding(.horizontal)
    }
}

#Preview("Reward History Rows") {
    ScrollView {
        VStack(spacing: 12) {
            RewardHistorySectionHeader(
                title: "Recent Weeks",
                subtitle: "Your reward journey"
            )

            let calendar = Calendar.current
            let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()

            // Current week
            WeeklyRewardHistoryRow(
                reward: WeeklyReward(
                    childId: UUID(),
                    weekStartDate: weekStart,
                    weekEndDate: weekEnd,
                    totalPoints: 175,
                    tier: .bronze,
                    isRedeemed: false
                )
            )
            .padding(.horizontal)

            // Last week - silver, redeemed
            WeeklyRewardHistoryRow(
                reward: WeeklyReward(
                    childId: UUID(),
                    weekStartDate: calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!,
                    weekEndDate: calendar.date(byAdding: .weekOfYear, value: -1, to: weekEnd)!,
                    totalPoints: 320,
                    tier: .silver,
                    isRedeemed: true,
                    redeemedDate: Date()
                )
            )
            .padding(.horizontal)

            // 2 weeks ago - gold
            WeeklyRewardHistoryRow(
                reward: WeeklyReward(
                    childId: UUID(),
                    weekStartDate: calendar.date(byAdding: .weekOfYear, value: -2, to: weekStart)!,
                    weekEndDate: calendar.date(byAdding: .weekOfYear, value: -2, to: weekEnd)!,
                    totalPoints: 580,
                    tier: .gold,
                    isRedeemed: true
                )
            )
            .padding(.horizontal)

            // 3 weeks ago - no tier
            WeeklyRewardHistoryRow(
                reward: WeeklyReward(
                    childId: UUID(),
                    weekStartDate: calendar.date(byAdding: .weekOfYear, value: -3, to: weekStart)!,
                    weekEndDate: calendar.date(byAdding: .weekOfYear, value: -3, to: weekEnd)!,
                    totalPoints: 45,
                    tier: nil,
                    isRedeemed: false
                )
            )
            .padding(.horizontal)

            Divider()
                .padding(.vertical)

            EmptyRewardHistory()
        }
    }
    .background(Color(.systemBackground))
}
