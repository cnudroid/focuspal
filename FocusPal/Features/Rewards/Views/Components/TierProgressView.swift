//
//  TierProgressView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Horizontal progress bar displaying progress through all reward tiers.
struct TierProgressView: View {
    let currentPoints: Int
    let currentTier: RewardTier?
    let animated: Bool

    @State private var animatedProgress: Double = 0
    @State private var showSparkle = false

    init(currentPoints: Int, currentTier: RewardTier? = nil, animated: Bool = true) {
        self.currentPoints = currentPoints
        self.currentTier = currentTier ?? RewardTier.tier(for: currentPoints)
        self.animated = animated
    }

    private var allTiers: [RewardTier] {
        RewardTier.sortedByPoints
    }

    private var maxPoints: Int {
        RewardTier.platinum.pointsRequired
    }

    private var overallProgress: Double {
        min(Double(currentPoints) / Double(maxPoints), 1.0)
    }

    private var nextTier: RewardTier? {
        if let current = currentTier {
            return current.nextTier
        }
        return .bronze
    }

    private var pointsToNext: Int {
        guard let next = nextTier else { return 0 }
        return max(0, next.pointsRequired - currentPoints)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Points display
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(currentPoints)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    Text("points this week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let next = nextTier {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(pointsToNext) to go")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: next.colorHex))
                        Text("for \(next.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(Color(hex: RewardTier.platinum.colorHex))
                        Text("Max tier!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Progress bar with tier markers
            GeometryReader { geometry in
                let width = geometry.size.width

                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 16)

                    // Gradient progress fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(progressGradient)
                        .frame(width: width * (animated ? animatedProgress : overallProgress), height: 16)

                    // Tier markers
                    ForEach(allTiers, id: \.self) { tier in
                        let position = Double(tier.pointsRequired) / Double(maxPoints)
                        TierMarker(
                            tier: tier,
                            isUnlocked: currentPoints >= tier.pointsRequired,
                            isCurrent: tier == currentTier
                        )
                        .position(x: width * position, y: 8)
                    }

                    // Current position indicator with sparkle
                    if currentPoints > 0 && currentPoints < maxPoints {
                        Circle()
                            .fill(currentPositionColor)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(color: currentPositionColor.opacity(0.5), radius: 4)
                            .position(x: width * (animated ? animatedProgress : overallProgress), y: 8)
                            .overlay(
                                Group {
                                    if showSparkle {
                                        SparkleEffect()
                                            .position(x: width * animatedProgress, y: 8)
                                    }
                                }
                            )
                    }
                }
            }
            .frame(height: 40)

            // Tier labels
            HStack {
                ForEach(allTiers, id: \.self) { tier in
                    Text(tier.name)
                        .font(.caption2)
                        .fontWeight(tier == currentTier ? .bold : .regular)
                        .foregroundColor(currentPoints >= tier.pointsRequired ? Color(hex: tier.colorHex) : .secondary)

                    if tier != .platinum {
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                    animatedProgress = overallProgress
                }

                // Show sparkle when animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    if currentPoints > 0 {
                        showSparkle = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showSparkle = false
                        }
                    }
                }
            }
        }
    }

    private var progressGradient: LinearGradient {
        var colors: [Color] = []

        for tier in allTiers {
            if currentPoints >= tier.pointsRequired {
                colors.append(Color(hex: tier.colorHex))
            }
        }

        if colors.isEmpty {
            colors = [Color(.systemGray4), Color(.systemGray5)]
        } else if colors.count == 1 {
            colors.append(colors[0].opacity(0.7))
        }

        return LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var currentPositionColor: Color {
        if let tier = currentTier {
            return Color(hex: tier.colorHex)
        } else if currentPoints > 0 {
            return Color(hex: RewardTier.bronze.colorHex).opacity(0.7)
        }
        return .gray
    }
}

/// Marker for each tier threshold on the progress bar.
private struct TierMarker: View {
    let tier: RewardTier
    let isUnlocked: Bool
    let isCurrent: Bool

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Glow for current tier
            if isCurrent {
                Circle()
                    .fill(Color(hex: tier.colorHex).opacity(0.3))
                    .frame(width: 32, height: 32)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }

            Circle()
                .fill(isUnlocked ? Color(hex: tier.colorHex) : Color(.systemGray4))
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )

            if isUnlocked {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            if isCurrent {
                isAnimating = true
            }
        }
    }
}

/// Sparkle effect for celebration moments.
private struct SparkleEffect: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
                    .offset(x: CGFloat.random(in: -15...15), y: CGFloat.random(in: -15...15))
                    .rotationEffect(.degrees(Double(index) * 60))
            }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                scale = 1.5
                opacity = 0
            }
        }
    }
}

/// Compact progress indicator for use in headers or cards.
struct CompactTierProgress: View {
    let currentPoints: Int
    let currentTier: RewardTier?
    let nextTier: RewardTier?

    var body: some View {
        HStack(spacing: 12) {
            // Current tier badge
            if let tier = currentTier {
                TierBadge(tier: tier, isUnlocked: true, isCurrent: true, isCompact: true)
            } else {
                Text("No tier yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(.systemGray5)))
            }

            // Progress to next
            if let next = nextTier {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(next.pointsRequired - currentPoints) pts")
                        .font(.caption.weight(.medium))
                        .foregroundColor(Color(hex: next.colorHex))

                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    TierBadge(tier: next, isUnlocked: false, isCompact: true)
                }
            }
        }
    }
}

#Preview("Tier Progress Views") {
    ScrollView {
        VStack(spacing: 24) {
            Text("No Progress")
                .font(.headline)
            TierProgressView(currentPoints: 0, animated: false)

            Text("Below Bronze")
                .font(.headline)
            TierProgressView(currentPoints: 50, animated: false)

            Text("Bronze Achieved")
                .font(.headline)
            TierProgressView(currentPoints: 175, animated: false)

            Text("Silver Achieved")
                .font(.headline)
            TierProgressView(currentPoints: 350, animated: false)

            Text("Gold Achieved")
                .font(.headline)
            TierProgressView(currentPoints: 650, animated: false)

            Text("Platinum Achieved")
                .font(.headline)
            TierProgressView(currentPoints: 1000, animated: false)

            Divider()

            Text("Compact Progress")
                .font(.headline)

            CompactTierProgress(currentPoints: 175, currentTier: .bronze, nextTier: .silver)
            CompactTierProgress(currentPoints: 500, currentTier: .gold, nextTier: .platinum)
            CompactTierProgress(currentPoints: 1000, currentTier: .platinum, nextTier: nil)
        }
        .padding()
    }
    .background(Color(.systemBackground))
}
