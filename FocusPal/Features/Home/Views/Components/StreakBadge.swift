//
//  StreakBadge.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Badge displaying current activity tracking streak with fire icon
struct StreakBadge: View {
    let streakCount: Int
    let isCompact: Bool

    init(streakCount: Int, isCompact: Bool = false) {
        self.streakCount = streakCount
        self.isCompact = isCompact
    }

    private var streakColor: Color {
        switch streakCount {
        case 0:
            return Color(.systemGray3)
        case 1...2:
            return Color(hex: "#FF9500") // Orange
        case 3...6:
            return Color(hex: "#FF6B00") // Dark orange
        default:
            return Color(hex: "#FF3B30") // Red (hot streak!)
        }
    }

    private var streakEmoji: String {
        switch streakCount {
        case 0: return "🔥"
        case 1...2: return "🔥"
        case 3...6: return "🔥🔥"
        default: return "🔥🔥🔥"
        }
    }

    var body: some View {
        if isCompact {
            compactView
        } else {
            fullView
        }
    }

    private var compactView: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14))
                .foregroundColor(streakColor)

            Text("\(streakCount)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(streakColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(streakColor.opacity(0.15))
        )
    }

    private var fullView: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                streakColor.opacity(0.3),
                                streakColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)

                Text(streakEmoji)
                    .font(.system(size: 32))
            }

            VStack(spacing: 2) {
                Text("\(streakCount)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(streakColor)

                Text(streakCount == 1 ? "day" : "days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Current Streak")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

/// Horizontal streak display with motivational message for Home view
struct HomeStreakCard: View {
    let streakCount: Int

    private var motivationText: String {
        switch streakCount {
        case 0:
            return "Start your streak today!"
        case 1:
            return "Great start! Keep it up tomorrow"
        case 2...6:
            return "You're on fire! Keep going"
        case 7...13:
            return "Amazing streak! One week down"
        case 14...29:
            return "Incredible! Two weeks strong"
        default:
            return "Legendary streak! You're unstoppable"
        }
    }

    private var streakColor: Color {
        switch streakCount {
        case 0: return Color(.systemGray3)
        case 1...2: return .orange
        case 3...6: return Color(hex: "#FF6B00")
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Flame icon
            ZStack {
                Circle()
                    .fill(streakColor.opacity(0.2))
                    .frame(width: 56, height: 56)

                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
                    .foregroundColor(streakColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("\(streakCount)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(streakColor)

                    Text(streakCount == 1 ? "Day" : "Days")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Text(motivationText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

#Preview("Streak Badge Variants") {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            StreakBadge(streakCount: 0, isCompact: true)
            StreakBadge(streakCount: 3, isCompact: true)
            StreakBadge(streakCount: 15, isCompact: true)
        }

        HStack(spacing: 16) {
            StreakBadge(streakCount: 1)
            StreakBadge(streakCount: 7)
            StreakBadge(streakCount: 30)
        }

        HomeStreakCard(streakCount: 0)
        HomeStreakCard(streakCount: 5)
        HomeStreakCard(streakCount: 15)
        HomeStreakCard(streakCount: 45)
    }
    .padding()
    .background(Color(.systemBackground))
}
