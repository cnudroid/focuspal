//
//  RewardCard.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Card displaying an individual weekly reward with redemption capability.
struct RewardCard: View {
    let reward: WeeklyReward
    let onRedeem: (() -> Void)?
    let isRedeemable: Bool

    @State private var isPressed = false
    @State private var showConfetti = false

    init(reward: WeeklyReward, isRedeemable: Bool = true, onRedeem: (() -> Void)? = nil) {
        self.reward = reward
        self.isRedeemable = isRedeemable && !reward.isRedeemed && reward.tier != nil
        self.onRedeem = onRedeem
    }

    private var tierColor: Color {
        guard let tier = reward.tier else { return .gray }
        return Color(hex: tier.colorHex)
    }

    private var statusText: String {
        if reward.isRedeemed {
            return "Redeemed"
        } else if reward.tier != nil {
            return "Ready to claim!"
        } else {
            return "Keep going!"
        }
    }

    private var statusIcon: String {
        if reward.isRedeemed {
            return "checkmark.seal.fill"
        } else if reward.tier != nil {
            return "gift.fill"
        } else {
            return "hourglass"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with tier badge and status
            HStack {
                if let tier = reward.tier {
                    TierBadge(tier: tier, isUnlocked: true, isCompact: true)
                } else {
                    Text("No tier")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color(.systemGray5)))
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.caption)
                    Text(statusText)
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(reward.isRedeemed ? .green : (reward.tier != nil ? tierColor : .secondary))
            }

            // Points and week info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)

                    Text("\(reward.totalPoints)")
                        .font(.title2.weight(.bold))

                    Text("points earned")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text(weekDateString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Tier description or encouragement
            if let tier = reward.tier {
                Text(tier.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            } else {
                let pointsNeeded = RewardTier.bronze.pointsRequired - reward.totalPoints
                Text("Earn \(pointsNeeded) more points to unlock Bronze!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Redeem button
            if isRedeemable {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                        showConfetti = true
                        onRedeem?()
                    }
                } label: {
                    HStack {
                        Image(systemName: "gift.fill")
                        Text("Claim Reward")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [tierColor, tierColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                }
                .buttonStyle(.plain)
            } else if reward.isRedeemed, let redeemedDate = reward.redeemedDate {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Claimed on \(formattedDate(redeemedDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            reward.tier != nil && !reward.isRedeemed
                                ? tierColor.opacity(0.3)
                                : Color.clear,
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .overlay(
            Group {
                if showConfetti {
                    ConfettiView(tier: reward.tier ?? .bronze)
                        .allowsHitTesting(false)
                }
            }
        )
        .onChange(of: showConfetti) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showConfetti = false
                }
            }
        }
    }

    private var weekDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let start = formatter.string(from: reward.weekStartDate)
        let end = formatter.string(from: reward.weekEndDate)

        return "\(start) - \(end)"
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

/// Confetti celebration effect when claiming rewards.
private struct ConfettiView: View {
    let tier: RewardTier

    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    particle.shape
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .rotationEffect(.degrees(particle.rotation))
                        .opacity(particle.opacity)
                }
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }

    private func createParticles() {
        let colors: [Color] = [
            Color(hex: tier.colorHex),
            .yellow,
            .orange,
            .pink,
            Color(hex: tier.colorHex).opacity(0.7)
        ]

        particles = (0..<30).map { _ in
            ConfettiParticle(
                color: colors.randomElement()!,
                position: CGPoint(x: CGFloat.random(in: 50...300), y: -20),
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
        }
    }

    private func animateParticles() {
        for i in particles.indices {
            let delay = Double.random(in: 0...0.3)
            let duration = Double.random(in: 1.0...2.0)

            withAnimation(.easeOut(duration: duration).delay(delay)) {
                particles[i].position.y += CGFloat.random(in: 200...400)
                particles[i].position.x += CGFloat.random(in: -50...50)
                particles[i].rotation += Double.random(in: 180...540)
                particles[i].opacity = 0
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    var position: CGPoint
    let size: CGFloat
    var rotation: Double
    var opacity: Double

    var shape: some Shape {
        if Bool.random() {
            return AnyShape(Circle())
        } else {
            return AnyShape(RoundedRectangle(cornerRadius: 2))
        }
    }
}

private struct AnyShape: Shape {
    private let _path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

/// Compact reward card for list views.
struct CompactRewardCard: View {
    let reward: WeeklyReward
    let onTap: (() -> Void)?

    init(reward: WeeklyReward, onTap: (() -> Void)? = nil) {
        self.reward = reward
        self.onTap = onTap
    }

    private var tierColor: Color {
        guard let tier = reward.tier else { return .gray }
        return Color(hex: tier.colorHex)
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                // Tier icon
                ZStack {
                    Circle()
                        .fill(tierColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    if let tier = reward.tier {
                        Image(systemName: tier == .platinum ? "crown.fill" : "medal.fill")
                            .font(.title3)
                            .foregroundColor(tierColor)
                    } else {
                        Image(systemName: "circle.dashed")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(reward.tier?.name ?? "No Tier")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(reward.tier != nil ? tierColor : .secondary)

                        if reward.isRedeemed {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }

                    Text("\(reward.totalPoints) points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Reward Cards") {
    ScrollView {
        VStack(spacing: 16) {
            Text("Full Reward Cards")
                .font(.headline)

            RewardCard(
                reward: WeeklyReward(
                    childId: UUID(),
                    weekStartDate: Date(),
                    weekEndDate: Date(),
                    totalPoints: 175,
                    tier: .bronze,
                    isRedeemed: false
                )
            )

            RewardCard(
                reward: WeeklyReward(
                    childId: UUID(),
                    weekStartDate: Date(),
                    weekEndDate: Date(),
                    totalPoints: 580,
                    tier: .gold,
                    isRedeemed: true,
                    redeemedDate: Date()
                )
            )

            RewardCard(
                reward: WeeklyReward(
                    childId: UUID(),
                    weekStartDate: Date(),
                    weekEndDate: Date(),
                    totalPoints: 50,
                    tier: nil,
                    isRedeemed: false
                )
            )

            Divider()

            Text("Compact Cards")
                .font(.headline)

            CompactRewardCard(
                reward: WeeklyReward(
                    childId: UUID(),
                    weekStartDate: Date(),
                    weekEndDate: Date(),
                    totalPoints: 320,
                    tier: .silver,
                    isRedeemed: true
                )
            )

            CompactRewardCard(
                reward: WeeklyReward(
                    childId: UUID(),
                    weekStartDate: Date(),
                    weekEndDate: Date(),
                    totalPoints: 1050,
                    tier: .platinum,
                    isRedeemed: false
                )
            )
        }
        .padding()
    }
    .background(Color(.systemBackground))
}
