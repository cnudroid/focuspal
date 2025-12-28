//
//  TierBadge.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// A reusable badge component displaying a reward tier with locked/unlocked states.
struct TierBadge: View {
    let tier: RewardTier
    let isUnlocked: Bool
    let isCurrent: Bool
    let isCompact: Bool

    @State private var isAnimating = false

    init(tier: RewardTier, isUnlocked: Bool = false, isCurrent: Bool = false, isCompact: Bool = false) {
        self.tier = tier
        self.isUnlocked = isUnlocked
        self.isCurrent = isCurrent
        self.isCompact = isCompact
    }

    private var tierColor: Color {
        Color(hex: tier.colorHex)
    }

    private var iconName: String {
        switch tier {
        case .bronze:
            return "medal.fill"
        case .silver:
            return "medal.fill"
        case .gold:
            return "medal.fill"
        case .platinum:
            return "crown.fill"
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
            Image(systemName: iconName)
                .font(.system(size: 14))
                .foregroundColor(isUnlocked ? tierColor : .gray)

            Text(tier.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isUnlocked ? tierColor : .gray)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isUnlocked ? tierColor.opacity(0.15) : Color(.systemGray5))
        )
        .overlay(
            Capsule()
                .strokeBorder(isCurrent ? tierColor : Color.clear, lineWidth: 2)
        )
    }

    private var fullView: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        isUnlocked
                            ? LinearGradient(
                                colors: [
                                    tierColor.opacity(0.4),
                                    tierColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color(.systemGray4),
                                    Color(.systemGray5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 70, height: 70)

                // Glow effect for current tier
                if isCurrent {
                    Circle()
                        .fill(tierColor.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .blur(radius: 8)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                        .animation(
                            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }

                // Icon or lock
                if isUnlocked {
                    Image(systemName: iconName)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [tierColor, tierColor.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: tierColor.opacity(0.5), radius: 4, y: 2)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }

                // Current tier indicator ring
                if isCurrent {
                    Circle()
                        .strokeBorder(tierColor, lineWidth: 3)
                        .frame(width: 75, height: 75)
                }
            }

            VStack(spacing: 2) {
                Text(tier.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isUnlocked ? tierColor : .gray)

                Text("\(tier.pointsRequired) pts")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            if isCurrent {
                isAnimating = true
            }
        }
    }
}

/// Horizontal tier selector showing all tiers with selection state
struct TierSelector: View {
    let currentTier: RewardTier?
    let onTierSelected: ((RewardTier) -> Void)?

    init(currentTier: RewardTier? = nil, onTierSelected: ((RewardTier) -> Void)? = nil) {
        self.currentTier = currentTier
        self.onTierSelected = onTierSelected
    }

    var body: some View {
        HStack(spacing: 16) {
            ForEach(RewardTier.sortedByPoints, id: \.self) { tier in
                TierBadge(
                    tier: tier,
                    isUnlocked: isTierUnlocked(tier),
                    isCurrent: tier == currentTier,
                    isCompact: false
                )
                .onTapGesture {
                    onTierSelected?(tier)
                }
            }
        }
    }

    private func isTierUnlocked(_ tier: RewardTier) -> Bool {
        guard let current = currentTier else { return false }
        return tier.pointsRequired <= current.pointsRequired
    }
}

#Preview("Tier Badge Variants") {
    VStack(spacing: 24) {
        Text("Compact Badges")
            .font(.headline)

        HStack(spacing: 12) {
            TierBadge(tier: .bronze, isUnlocked: true, isCompact: true)
            TierBadge(tier: .silver, isUnlocked: false, isCompact: true)
            TierBadge(tier: .gold, isUnlocked: true, isCurrent: true, isCompact: true)
        }

        Divider()

        Text("Full Badges")
            .font(.headline)

        HStack(spacing: 16) {
            TierBadge(tier: .bronze, isUnlocked: true)
            TierBadge(tier: .silver, isUnlocked: true, isCurrent: true)
            TierBadge(tier: .gold, isUnlocked: false)
            TierBadge(tier: .platinum, isUnlocked: false)
        }

        Divider()

        Text("Tier Selector")
            .font(.headline)

        TierSelector(currentTier: .silver)
    }
    .padding()
    .background(Color(.systemBackground))
}
