//
//  BadgeDetailView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Full-screen badge detail view with share functionality
struct BadgeDetailView: View {
    let badge: AchievementDisplayItem
    let childName: String
    let onShare: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showUnlockAnimation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Large badge display
                    badgeHero

                    // Achievement info
                    achievementInfo

                    // Share section
                    if badge.isUnlocked {
                        shareSection
                    } else {
                        progressSection
                    }

                    Spacer(minLength: 40)
                }
                .padding(.vertical, 24)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.1),
                        Color.blue.opacity(0.05),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Badge Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if badge.isUnlocked {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                    showUnlockAnimation = true
                }
            }
        }
    }

    // MARK: - Badge Hero

    private var badgeHero: some View {
        ZStack {
            // Outer glow
            if badge.isUnlocked {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 60,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .scaleEffect(showUnlockAnimation ? 1 : 0.5)
                    .opacity(showUnlockAnimation ? 1 : 0)
            }

            // Badge circle
            ZStack {
                Circle()
                    .fill(
                        badge.isUnlocked
                            ? LinearGradient(
                                colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 160, height: 160)
                    .shadow(color: badge.isUnlocked ? Color.purple.opacity(0.3) : Color.clear, radius: 20)

                Text(badge.emoji)
                    .font(.system(size: 80))
                    .grayscale(badge.isUnlocked ? 0 : 0.8)
                    .opacity(badge.isUnlocked ? 1 : 0.6)

                if !badge.isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.gray.opacity(0.8)))
                        .offset(x: 50, y: 50)
                }
            }
            .scaleEffect(showUnlockAnimation ? 1 : 0.8)
        }
        .frame(height: 250)
    }

    // MARK: - Achievement Info

    private var achievementInfo: some View {
        VStack(spacing: 16) {
            Text(badge.name)
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)

            Text(badge.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if badge.isUnlocked, let date = badge.unlockedDate {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)

                    Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Share Section

    private var shareSection: some View {
        VStack(spacing: 16) {
            Text("Share this achievement!")
                .font(.headline)

            AnimatedShareButton {
                onShare()
                dismiss()
            }

            Text("Let everyone know about \(childName)'s accomplishment")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }

    // MARK: - Progress Section (for locked badges)

    private var progressSection: some View {
        VStack(spacing: 16) {
            Text("Keep going!")
                .font(.headline)

            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray4))
                            .frame(height: 16)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (Double(badge.progress) / 100), height: 16)
                    }
                }
                .frame(height: 16)

                Text("\(badge.progress)% complete")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.purple)
            }
            .padding(.horizontal)

            Text("\(100 - badge.progress)% more to unlock this badge")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview("Unlocked Badge") {
    BadgeDetailView(
        badge: AchievementDisplayItem(
            id: UUID(),
            name: "3-Day Streak",
            description: "Complete activities for 3 days in a row. You're on fire!",
            iconName: "flame.fill",
            emoji: "🔥",
            isUnlocked: true,
            progress: 100,
            unlockedDate: Date()
        ),
        childName: "Emma",
        onShare: {}
    )
}

#Preview("Locked Badge") {
    BadgeDetailView(
        badge: AchievementDisplayItem(
            id: UUID(),
            name: "Reading Champion",
            description: "Read for 10 hours total. Keep reading!",
            iconName: "book.closed.fill",
            emoji: "📖",
            isUnlocked: false,
            progress: 65,
            unlockedDate: nil
        ),
        childName: "Max",
        onShare: {}
    )
}
