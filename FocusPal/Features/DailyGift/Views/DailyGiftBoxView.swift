//
//  DailyGiftBoxView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import UIKit

/// Daily surprise gift box shown to kids on first app open each day
struct DailyGiftBoxView: View {
    let childName: String
    let giftContent: DailyGiftContent
    let onDismiss: () -> Void

    @State private var boxShake = false
    @State private var boxOpened = false
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var contentScale: CGFloat = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.3),
                    Color.blue.opacity(0.2),
                    Color.pink.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Confetti layer
            if showConfetti {
                GiftConfettiView()
            }

            VStack(spacing: 32) {
                Spacer()

                // Greeting
                if !boxOpened {
                    greetingSection
                } else {
                    revealGreeting
                }

                // Gift box or revealed content
                if !boxOpened {
                    giftBoxSection
                } else {
                    revealedContentSection
                }

                Spacer()

                // Button
                if !boxOpened {
                    openButton
                } else if showContent {
                    dismissButton
                }
            }
            .padding()
        }
    }

    // MARK: - Greeting Section

    private var greetingSection: some View {
        VStack(spacing: 12) {
            Text("Good \(timeOfDayGreeting)!")
                .font(.title.weight(.bold))
                .foregroundColor(.primary)

            Text("\(childName), you have a gift!")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var revealGreeting: some View {
        VStack(spacing: 8) {
            Text("Your Daily Rewards!")
                .font(.title.weight(.bold))
                .foregroundColor(.primary)

            Text("Great job, \(childName)!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .transition(.opacity.combined(with: .scale))
    }

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }

    // MARK: - Gift Box Section

    private var giftBoxSection: some View {
        VStack(spacing: 0) {
            // Gift box lid
            GiftBoxLid()
                .frame(width: 180, height: 50)
                .offset(y: boxShake ? -5 : 0)

            // Gift box body
            GiftBoxBody()
                .frame(width: 200, height: 150)
        }
        .shake($boxShake)
        .onAppear {
            startShakeAnimation()
        }
    }

    // MARK: - Revealed Content Section

    private var revealedContentSection: some View {
        VStack(spacing: 24) {
            // Check if there's any progress to show
            let hasProgress = giftContent.pointsYesterday > 0 ||
                              giftContent.currentStreak > 0 ||
                              giftContent.activitiesCompleted > 0 ||
                              !giftContent.newBadges.isEmpty

            if hasProgress {
                // Points earned
                if giftContent.pointsYesterday > 0 {
                    GiftRewardRow(
                        emoji: "⭐",
                        title: "Points Earned",
                        value: "+\(giftContent.pointsYesterday)",
                        color: .yellow
                    )
                }

                // Streak
                if giftContent.currentStreak > 0 {
                    GiftRewardRow(
                        emoji: "🔥",
                        title: "Day Streak",
                        value: "\(giftContent.currentStreak) days",
                        color: .orange
                    )
                }

                // Activities completed
                if giftContent.activitiesCompleted > 0 {
                    GiftRewardRow(
                        emoji: "✅",
                        title: "Activities Done",
                        value: "\(giftContent.activitiesCompleted)",
                        color: .green
                    )
                }

                // New badges
                if !giftContent.newBadges.isEmpty {
                    VStack(spacing: 12) {
                        Text("New Badges!")
                            .font(.headline)
                            .foregroundColor(.purple)

                        HStack(spacing: 16) {
                            ForEach(giftContent.newBadges, id: \.self) { badge in
                                Text(badge)
                                    .font(.system(size: 40))
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.purple.opacity(0.1))
                    )
                }
            } else {
                // Fun empty state with surprise content for kids
                EmptyGiftSurprise()
            }

            // Encouragement message
            if let message = giftContent.encouragementMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
        .scaleEffect(contentScale)
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Buttons

    private var openButton: some View {
        Button {
            openGift()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                Text("Open My Gift!")
            }
            .font(.title3.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.pink, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(25)
            .shadow(color: .purple.opacity(0.4), radius: 10, y: 5)
        }
        .buttonStyle(BounceButtonStyle())
    }

    private var dismissButton: some View {
        Button {
            onDismiss()
        } label: {
            HStack(spacing: 8) {
                Text("Let's Go!")
                Image(systemName: "arrow.right")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(Color.blue)
            .cornerRadius(25)
        }
        .buttonStyle(BounceButtonStyle())
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Animations

    private func startShakeAnimation() {
        // Periodic shake to entice opening
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            if boxOpened {
                timer.invalidate()
                return
            }
            withAnimation(.easeInOut(duration: 0.5)) {
                boxShake = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                boxShake = false
            }
        }
    }

    private func openGift() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()

        // Open animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            boxOpened = true
        }

        // Show confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showConfetti = true

            // Success haptic
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }

        // Reveal content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showContent = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                contentScale = 1.0
            }
        }
    }
}

// MARK: - Gift Content Model

struct DailyGiftContent {
    let pointsYesterday: Int
    let currentStreak: Int
    let activitiesCompleted: Int
    let newBadges: [String]  // Emoji strings
    let encouragementMessage: String?

    static var empty: DailyGiftContent {
        DailyGiftContent(
            pointsYesterday: 0,
            currentStreak: 0,
            activitiesCompleted: 0,
            newBadges: [],
            encouragementMessage: "Start a timer to earn your first reward!"
        )
    }
}

// MARK: - Empty Gift Surprise

/// Fun surprise content shown when there's no activity data yet
struct EmptyGiftSurprise: View {
    @State private var selectedSurprise = Int.random(in: 0..<surpriseContent.count)
    @State private var bouncing = false

    private static let surpriseContent: [(emoji: String, title: String, message: String)] = [
        ("🌟", "You're a Star!", "Every champion starts somewhere. Today could be YOUR day!"),
        ("🚀", "Ready for Liftoff!", "Your adventure awaits! Start a timer and blast off!"),
        ("🦸", "Hero in Training!", "Even superheroes practice. What will you master today?"),
        ("🌈", "Rainbow Day!", "Make today colorful! Try something fun and new!"),
        ("🎨", "Creative Genius!", "Your imagination is your superpower!"),
        ("🦋", "Transformation Time!", "Small steps lead to big changes!"),
        ("🎪", "Fun Awaits!", "The circus of learning is in town!"),
        ("🏆", "Future Champion!", "Trophies are earned one day at a time!"),
        ("🎸", "Rock Star Mode!", "You've got the talent, now show the world!"),
        ("🧙", "Magic Maker!", "You have the power to make amazing things happen!"),
        ("🌻", "Grow Today!", "Every flower starts as a tiny seed!"),
        ("🎯", "Aim High!", "Set your sights on something awesome today!")
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Large animated emoji
            Text(Self.surpriseContent[selectedSurprise].emoji)
                .font(.system(size: 80))
                .scaleEffect(bouncing ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                    value: bouncing
                )
                .onAppear { bouncing = true }

            // Inspiring title
            Text(Self.surpriseContent[selectedSurprise].title)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)

            // Motivational message
            Text(Self.surpriseContent[selectedSurprise].message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Fun emoji row
            HStack(spacing: 12) {
                ForEach(["✨", "💪", "🎉"], id: \.self) { emoji in
                    Text(emoji)
                        .font(.title)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.1),
                            Color.blue.opacity(0.1),
                            Color.pink.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

// MARK: - Gift Box Components

struct GiftBoxLid: View {
    var body: some View {
        ZStack {
            // Lid shape
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color.pink.opacity(0.9), Color.pink],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Ribbon on top
            Rectangle()
                .fill(Color.yellow)
                .frame(width: 30)

            // Bow
            Circle()
                .fill(Color.yellow)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.orange, lineWidth: 2)
                )
        }
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }
}

struct GiftBoxBody: View {
    var body: some View {
        ZStack {
            // Box shape
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.pink, Color.pink.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Vertical ribbon
            Rectangle()
                .fill(Color.yellow)
                .frame(width: 30)

            // Horizontal ribbon
            Rectangle()
                .fill(Color.yellow)
                .frame(height: 30)

            // Question mark
            Text("?")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
        }
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

// MARK: - Gift Reward Row

struct GiftRewardRow: View {
    let emoji: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundColor(color)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Gift Confetti

struct GiftConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle)
                }
            }
            .onAppear {
                createConfetti(in: geometry.size)
            }
        }
    }

    private func createConfetti(in size: CGSize) {
        let colors: [Color] = [.pink, .purple, .yellow, .orange, .blue, .green, .red]

        // Create particles from center-top
        particles = (0..<50).map { _ in
            let startX = size.width / 2 + CGFloat.random(in: -50...50)
            let startY = size.height / 2 - 100

            return ConfettiParticle(
                color: colors.randomElement()!,
                shapeType: Int.random(in: 0...2),
                size: CGFloat.random(in: 8...16),
                x: startX,
                y: startY,
                targetX: CGFloat.random(in: 0...size.width),
                targetY: size.height + 50,
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
        }

        // Animate each particle
        for i in particles.indices {
            let delay = Double.random(in: 0...0.3)
            let duration = Double.random(in: 1.5...2.5)

            withAnimation(.easeOut(duration: duration).delay(delay)) {
                particles[i].x = particles[i].targetX
                particles[i].y = particles[i].targetY
                particles[i].rotation += Double.random(in: 180...540)
            }

            withAnimation(.easeIn(duration: 0.5).delay(delay + duration - 0.5)) {
                particles[i].opacity = 0
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let shapeType: Int  // 0 = Circle, 1 = Rectangle, 2 = Capsule
    let size: CGFloat
    var x: CGFloat
    var y: CGFloat
    let targetX: CGFloat
    let targetY: CGFloat
    var rotation: Double
    var opacity: Double
}

private struct ConfettiPiece: View {
    let particle: ConfettiParticle

    var body: some View {
        Group {
            switch particle.shapeType {
            case 0:
                Circle()
                    .fill(particle.color)
            case 1:
                Rectangle()
                    .fill(particle.color)
            default:
                Capsule()
                    .fill(particle.color)
            }
        }
        .frame(width: particle.size, height: particle.size)
        .rotationEffect(.degrees(particle.rotation))
        .position(x: particle.x, y: particle.y)
        .opacity(particle.opacity)
    }
}

// MARK: - Preview

#Preview("Gift Box - Unopened") {
    DailyGiftBoxView(
        childName: "Emma",
        giftContent: DailyGiftContent(
            pointsYesterday: 85,
            currentStreak: 5,
            activitiesCompleted: 4,
            newBadges: ["🔥", "📚"],
            encouragementMessage: "You're on a roll! Keep it up!"
        ),
        onDismiss: {}
    )
}

#Preview("Gift Box - Empty") {
    DailyGiftBoxView(
        childName: "Max",
        giftContent: .empty,
        onDismiss: {}
    )
}
