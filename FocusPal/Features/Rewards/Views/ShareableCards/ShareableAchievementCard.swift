//
//  ShareableAchievementCard.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Shareable achievement card optimized for social media
struct ShareableAchievementCard: View {
    let achievement: AchievementDisplayItem
    let childName: String
    var isStoryFormat: Bool = false

    private var gradientColors: [Color] {
        [
            Color(hex: "#667eea"),
            Color(hex: "#764ba2")
        ]
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative elements
            decorativeElements

            // Main content
            VStack(spacing: isStoryFormat ? 60 : 40) {
                if isStoryFormat {
                    Spacer()
                }

                // Badge
                badgeSection

                // Text content
                textSection

                if isStoryFormat {
                    Spacer()
                    Spacer()
                }

                // Branding
                brandingSection
            }
            .padding(isStoryFormat ? 60 : 80)
        }
        .frame(
            width: isStoryFormat ? 1080 : 1080,
            height: isStoryFormat ? 1920 : 1080
        )
    }

    // MARK: - Badge Section

    private var badgeSection: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: isStoryFormat ? 280 : 220, height: isStoryFormat ? 280 : 220)
                .blur(radius: 30)

            // Badge circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white, Color.white.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: isStoryFormat ? 220 : 180, height: isStoryFormat ? 220 : 180)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)

            // Emoji
            Text(achievement.emoji)
                .font(.system(size: isStoryFormat ? 100 : 80))
        }
    }

    // MARK: - Text Section

    private var textSection: some View {
        VStack(spacing: isStoryFormat ? 24 : 16) {
            Text("Achievement Unlocked!")
                .font(.system(size: isStoryFormat ? 36 : 28, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

            Text(achievement.name)
                .font(.system(size: isStoryFormat ? 56 : 44, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("\(childName) earned this badge!")
                .font(.system(size: isStoryFormat ? 32 : 26, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

            if !achievement.description.isEmpty {
                Text(achievement.description)
                    .font(.system(size: isStoryFormat ? 26 : 22))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Branding Section

    private var brandingSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.system(size: isStoryFormat ? 28 : 24))
                .foregroundColor(.white.opacity(0.8))

            Text("FocusPal")
                .font(.system(size: isStoryFormat ? 32 : 28, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.top, isStoryFormat ? 40 : 20)
    }

    // MARK: - Decorative Elements

    private var decorativeElements: some View {
        GeometryReader { geometry in
            // Top-left circle
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 200, height: 200)
                .offset(x: -80, y: -80)

            // Bottom-right circle
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 300, height: 300)
                .offset(
                    x: geometry.size.width - 100,
                    y: geometry.size.height - 100
                )

            // Sparkles
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat.random(in: 20...40)))
                    .foregroundColor(.white.opacity(Double.random(in: 0.1...0.3)))
                    .offset(
                        x: CGFloat.random(in: 50...geometry.size.width - 50),
                        y: CGFloat.random(in: 50...geometry.size.height - 50)
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview("Achievement Card - Square") {
    ShareableAchievementCard(
        achievement: AchievementDisplayItem(
            id: UUID(),
            name: "3-Day Streak",
            description: "Logged activities for 3 days in a row!",
            iconName: "flame.fill",
            emoji: "🔥",
            isUnlocked: true,
            progress: 100,
            unlockedDate: Date()
        ),
        childName: "Emma"
    )
    .scaleEffect(0.3)
}

#Preview("Achievement Card - Story") {
    ShareableAchievementCard(
        achievement: AchievementDisplayItem(
            id: UUID(),
            name: "Homework Hero",
            description: "Completed 10 hours of homework!",
            iconName: "book.fill",
            emoji: "📚",
            isUnlocked: true,
            progress: 100,
            unlockedDate: Date()
        ),
        childName: "Max",
        isStoryFormat: true
    )
    .scaleEffect(0.2)
}
