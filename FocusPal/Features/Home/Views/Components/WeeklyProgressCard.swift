//
//  WeeklyProgressCard.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

// MARK: - RewardTier Extensions for UI

/// Extension to add UI-specific properties to the existing RewardTier enum
extension RewardTier {
    /// SwiftUI Color for the tier
    var color: Color {
        Color(hex: colorHex)
    }

    /// SF Symbol icon name for the tier
    var iconName: String {
        switch self {
        case .bronze, .silver, .gold: return "trophy.fill"
        case .platinum: return "crown.fill"
        }
    }
}

/// Helper to handle the "no tier" case in UI
extension Optional where Wrapped == RewardTier {
    /// Display name including nil case
    var displayName: String {
        switch self {
        case .none: return "No Tier"
        case .some(let tier): return tier.name
        }
    }

    /// Color including nil case
    var color: Color {
        switch self {
        case .none: return Color(.systemGray4)
        case .some(let tier): return tier.color
        }
    }

    /// Icon name including nil case
    var iconName: String {
        switch self {
        case .none: return "circle"
        case .some(let tier): return tier.iconName
        }
    }

    /// Points required (0 for nil)
    var pointsRequired: Int {
        switch self {
        case .none: return 0
        case .some(let tier): return tier.pointsRequired
        }
    }
}

/// Card displaying weekly points progress toward reward tiers
struct WeeklyProgressCard: View {
    let weeklyPoints: Int
    var onTap: (() -> Void)?

    /// Current earned tier (nil if below bronze)
    private var currentTier: RewardTier? {
        RewardTier.tier(for: weeklyPoints)
    }

    /// Next tier to reach
    private var nextTier: RewardTier? {
        if let current = currentTier {
            return current.nextTier
        }
        return .bronze  // If no tier yet, next is bronze
    }

    /// Progress toward next tier (0.0 - 1.0)
    private var progressToNextTier: Double {
        guard let next = nextTier else { return 1.0 } // Already at platinum

        let currentTierPoints = currentTier.pointsRequired
        let nextTierPoints = next.pointsRequired
        let pointsInTier = weeklyPoints - currentTierPoints
        let pointsNeeded = nextTierPoints - currentTierPoints

        guard pointsNeeded > 0 else { return 1.0 }
        return min(Double(pointsInTier) / Double(pointsNeeded), 1.0)
    }

    /// Points remaining to reach next tier
    private var pointsToNextTier: Int {
        guard let next = nextTier else { return 0 }
        return max(0, next.pointsRequired - weeklyPoints)
    }

    /// Motivational message based on progress
    private var motivationalMessage: String {
        if currentTier == .platinum {
            return "You've reached the top! Amazing work!"
        } else if progressToNextTier >= 0.75 {
            return "Almost there! Keep going!"
        } else if progressToNextTier >= 0.5 {
            return "Halfway to \(nextTier?.name ?? "next tier")!"
        } else if weeklyPoints == 0 {
            return "Start earning points this week!"
        } else {
            return "\(pointsToNextTier) points to \(nextTier?.name ?? "next tier")"
        }
    }

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(spacing: 16) {
                // Header with trophy and points
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly Progress")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)

                            Text("\(weeklyPoints) points")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Current tier badge (only show if tier is earned)
                    if let tier = currentTier {
                        WeeklyProgressTierBadge(tier: tier, isCompact: true)
                    }
                }

                // Progress bar toward next tier
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(height: 16)

                            // Progress fill with gradient
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: progressGradientColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: max(0, geometry.size.width * progressToNextTier),
                                    height: 16
                                )
                                .animation(.easeOut(duration: 0.5), value: progressToNextTier)
                        }
                    }
                    .frame(height: 16)

                    // Tier markers
                    HStack {
                        Text(currentTier?.name ?? "Start")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(currentTier.color)

                        Spacer()

                        if let next = nextTier {
                            Text(next.name)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(next.color)
                        }
                    }
                }

                // Motivational message
                Text(motivationalMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    /// Colors for the progress bar gradient based on current tier
    private var progressGradientColors: [Color] {
        if let next = nextTier {
            return [currentTier.color, next.color.opacity(0.7)]
        } else {
            // At platinum - show full platinum gradient
            return [Color(hex: "#E5E4E2"), Color(hex: "#B8B8B8")]
        }
    }
}

/// Compact tier badge for display on weekly progress card
struct WeeklyProgressTierBadge: View {
    let tier: RewardTier
    let isCompact: Bool

    init(tier: RewardTier, isCompact: Bool = false) {
        self.tier = tier
        self.isCompact = isCompact
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: tier.iconName)
                .font(.system(size: isCompact ? 14 : 18))
                .foregroundColor(tier.color)

            Text(tier.name)
                .font(isCompact ? .caption : .subheadline)
                .fontWeight(.semibold)
                .foregroundColor(tier.color)
        }
        .padding(.horizontal, isCompact ? 10 : 14)
        .padding(.vertical, isCompact ? 6 : 8)
        .background(
            Capsule()
                .fill(tier.color.opacity(0.15))
        )
        .overlay(
            Capsule()
                .strokeBorder(tier.color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview("Weekly Progress Card Variants") {
    ScrollView {
        VStack(spacing: 16) {
            // No points yet
            WeeklyProgressCard(weeklyPoints: 0)

            // Working toward bronze
            WeeklyProgressCard(weeklyPoints: 45)

            // Just reached bronze
            WeeklyProgressCard(weeklyPoints: 100)

            // Working toward silver
            WeeklyProgressCard(weeklyPoints: 175)

            // At silver, halfway to gold
            WeeklyProgressCard(weeklyPoints: 375)

            // At gold
            WeeklyProgressCard(weeklyPoints: 500)

            // At platinum (max tier)
            WeeklyProgressCard(weeklyPoints: 1250)
        }
        .padding()
    }
    .background(Color(.systemBackground))
}

#Preview("Tier Badges") {
    VStack(spacing: 12) {
        ForEach(RewardTier.allCases, id: \.rawValue) { tier in
            HStack {
                WeeklyProgressTierBadge(tier: tier, isCompact: true)
                Spacer()
                WeeklyProgressTierBadge(tier: tier, isCompact: false)
            }
        }
    }
    .padding()
    .background(Color(.systemBackground))
}
