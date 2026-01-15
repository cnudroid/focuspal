//
//  CelebrationAnimations.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import UIKit

// MARK: - Badge Unlock Animation

/// Animated badge that bounces in with confetti when unlocked
struct AnimatedBadgeUnlock: View {
    let emoji: String
    let name: String
    let colorHex: String
    let showConfetti: Bool

    @State private var scale: CGFloat = 0
    @State private var rotation: Double = -30
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Confetti behind badge
            if showConfetti {
                BadgeConfettiView(colorHex: colorHex)
            }

            // Badge
            VStack(spacing: 8) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color(hex: colorHex).opacity(0.3))
                        .frame(width: 80, height: 80)
                        .blur(radius: 10)

                    // Badge background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: colorHex),
                                    Color(hex: colorHex).opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: Color(hex: colorHex).opacity(0.4), radius: 8, y: 4)

                    // Emoji
                    Text(emoji)
                        .font(.system(size: 36))
                }

                Text(name)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
        }
        .onAppear {
            animateIn()
        }
    }

    private func animateIn() {
        // Bounce in animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            scale = 1.2
            rotation = 10
            opacity = 1
        }

        // Settle animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                rotation = 0
            }
        }
    }
}

// MARK: - Badge Confetti

/// Confetti burst effect for badge unlocks
struct BadgeConfettiView: View {
    let colorHex: String

    @State private var particles: [BadgeConfettiParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.offset.width, y: particle.offset.height)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createAndAnimateParticles()
        }
    }

    private func createAndAnimateParticles() {
        let colors: [Color] = [
            Color(hex: colorHex),
            .yellow,
            .orange,
            .pink,
            .purple
        ]

        // Create particles in a burst pattern
        particles = (0..<20).map { index in
            let angle = Double(index) * (360.0 / 20.0) * .pi / 180
            return BadgeConfettiParticle(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...10),
                offset: .zero,
                targetOffset: CGSize(
                    width: cos(angle) * CGFloat.random(in: 60...120),
                    height: sin(angle) * CGFloat.random(in: 60...120)
                ),
                opacity: 1.0
            )
        }

        // Animate burst
        for i in particles.indices {
            let delay = Double.random(in: 0...0.1)

            withAnimation(.easeOut(duration: 0.8).delay(delay)) {
                particles[i].offset = particles[i].targetOffset
                particles[i].opacity = 0
            }
        }
    }
}

private struct BadgeConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var offset: CGSize
    let targetOffset: CGSize
    var opacity: Double
}

// MARK: - New Badge Indicator

/// "NEW" pill with pulse animation for recently unlocked badges
struct NewBadgeIndicator: View {
    @State private var isPulsing = false

    var body: some View {
        Text("NEW")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.red)
            )
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.8).repeatCount(5, autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Badge Wiggle Animation

/// View modifier for newly unlocked badge wiggle effect
struct BadgeWiggleModifier: ViewModifier {
    @State private var rotation: Double = 0
    let isNew: Bool

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                if isNew {
                    startWiggle()
                }
            }
    }

    private func startWiggle() {
        withAnimation(
            Animation.easeInOut(duration: 0.15)
                .repeatCount(6, autoreverses: true)
        ) {
            rotation = 3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeInOut(duration: 0.1)) {
                rotation = 0
            }
        }
    }
}

extension View {
    func badgeWiggle(isNew: Bool) -> some View {
        modifier(BadgeWiggleModifier(isNew: isNew))
    }
}

// MARK: - Share Button Animation

/// Animated share button with bounce effect
struct AnimatedShareButton: View {
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isPressed = true
            }

            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
                action()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                Text("Share")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Badge Unlock") {
    VStack(spacing: 40) {
        AnimatedBadgeUnlock(
            emoji: "🔥",
            name: "3-Day Streak",
            colorHex: "#FF6B6B",
            showConfetti: true
        )

        AnimatedBadgeUnlock(
            emoji: "📚",
            name: "Homework Hero",
            colorHex: "#4A90D9",
            showConfetti: true
        )
    }
    .padding()
}

#Preview("New Badge Indicator") {
    VStack(spacing: 20) {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(Color.yellow.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(Text("🎯").font(.title))

            NewBadgeIndicator()
                .offset(x: 5, y: -5)
        }

        AnimatedShareButton {
            print("Share tapped")
        }
    }
}
