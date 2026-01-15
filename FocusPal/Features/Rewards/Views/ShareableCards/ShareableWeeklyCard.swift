//
//  ShareableWeeklyCard.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Shareable weekly summary card for social media
struct ShareableWeeklyCard: View {
    let childName: String
    let totalMinutes: Int
    let streak: Int
    let tier: RewardTier?
    let points: Int

    private var tierColor: Color {
        guard let tier = tier else { return .gray }
        return Color(hex: tier.colorHex)
    }

    private var gradientColors: [Color] {
        if let tier = tier {
            return [Color(hex: tier.colorHex), Color(hex: tier.colorHex).opacity(0.7)]
        }
        return [Color(hex: "#4A90D9"), Color(hex: "#357ABD")]
    }

    private var formattedTime: String {
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative elements
            decorativeElements

            // Main content
            VStack(spacing: 40) {
                // Trophy/Medal
                medalSection

                // Child name and title
                headerSection

                // Stats grid
                statsSection

                // Branding
                brandingSection
            }
            .padding(80)
        }
        .frame(width: 1080, height: 1080)
    }

    // MARK: - Medal Section

    private var medalSection: some View {
        ZStack {
            // Glow
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 180, height: 180)
                .blur(radius: 20)

            // Medal background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white, Color.white.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
                .shadow(color: .black.opacity(0.2), radius: 15, y: 8)

            // Medal icon/emoji
            if let tier = tier {
                Text(tier.emoji)
                    .font(.system(size: 70))
            } else {
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Weekly Champion!")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

            Text(childName)
                .font(.system(size: 52, weight: .bold))
                .foregroundColor(.white)

            if let tier = tier {
                Text("\(tier.name) Medal Earned!")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 40) {
            // Focus time
            statItem(
                emoji: "📚",
                value: formattedTime,
                label: "focused"
            )

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 2, height: 80)

            // Streak
            statItem(
                emoji: "🔥",
                value: "\(streak)",
                label: streak == 1 ? "day streak" : "day streak"
            )

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 2, height: 80)

            // Points
            statItem(
                emoji: "⭐",
                value: "\(points)",
                label: "points"
            )
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
        )
    }

    private func statItem(emoji: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 36))

            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    // MARK: - Branding Section

    private var brandingSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.8))

            Text("FocusPal")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.top, 20)
    }

    // MARK: - Decorative Elements

    private var decorativeElements: some View {
        GeometryReader { geometry in
            // Circles
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 250, height: 250)
                .offset(x: -100, y: -100)

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 350, height: 350)
                .offset(
                    x: geometry.size.width - 150,
                    y: geometry.size.height - 150
                )

            // Stars
            ForEach(0..<8, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: CGFloat.random(in: 12...24)))
                    .foregroundColor(.white.opacity(Double.random(in: 0.1...0.25)))
                    .offset(
                        x: CGFloat.random(in: 40...geometry.size.width - 40),
                        y: CGFloat.random(in: 40...geometry.size.height - 40)
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview("Weekly Card - Gold") {
    ShareableWeeklyCard(
        childName: "Emma",
        totalMinutes: 330,
        streak: 7,
        tier: .gold,
        points: 580
    )
    .scaleEffect(0.3)
}

#Preview("Weekly Card - Bronze") {
    ShareableWeeklyCard(
        childName: "Max",
        totalMinutes: 120,
        streak: 3,
        tier: .bronze,
        points: 150
    )
    .scaleEffect(0.3)
}

#Preview("Weekly Card - No Tier") {
    ShareableWeeklyCard(
        childName: "Sophie",
        totalMinutes: 45,
        streak: 1,
        tier: nil,
        points: 50
    )
    .scaleEffect(0.3)
}
