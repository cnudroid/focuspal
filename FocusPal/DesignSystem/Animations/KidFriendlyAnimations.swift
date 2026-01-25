//
//  KidFriendlyAnimations.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

// MARK: - Bounce Animation

/// Button style that scales down on press for playful, kid-friendly feedback.
struct BounceButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95
    var response: Double = 0.3
    var dampingFraction: Double = 0.6

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: response, dampingFraction: dampingFraction), value: configuration.isPressed)
    }
}

// MARK: - Wiggle Modifier

/// Playful wiggle effect for badges and achievements.
struct WiggleModifier: ViewModifier {
    @State private var isWiggling = false
    let isActive: Bool
    let duration: Double

    init(isActive: Bool = true, duration: Double = 0.8) {
        self.isActive = isActive
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isWiggling ? 3 : -3))
            .animation(
                isActive ?
                    .easeInOut(duration: duration / 4)
                    .repeatCount(4, autoreverses: true) :
                    .default,
                value: isWiggling
            )
            .onAppear {
                if isActive {
                    isWiggling = true
                }
            }
    }
}

extension View {
    /// Apply a playful wiggle animation.
    func wiggle(isActive: Bool = true, duration: Double = 0.8) -> some View {
        modifier(WiggleModifier(isActive: isActive, duration: duration))
    }
}

// MARK: - Pop In Modifier

/// Pop-in animation for elements appearing on screen.
struct PopInModifier: ViewModifier {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    let delay: Double

    init(delay: Double = 0) {
        self.delay = delay
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .spring(response: 0.4, dampingFraction: 0.6)
                    .delay(delay)
                ) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
}

extension View {
    /// Apply pop-in animation with optional delay.
    func popIn(delay: Double = 0) -> some View {
        modifier(PopInModifier(delay: delay))
    }
}

// MARK: - Celebration Effect

/// Stars and sparkles celebration effect for achievements.
struct CelebrationEffect: View {
    let isActive: Bool
    @State private var particles: [CelebrationParticle] = []

    private struct CelebrationParticle: Identifiable {
        let id = UUID()
        let xOffset: CGFloat
        let yOffset: CGFloat
        let rotation: Double
        let scale: CGFloat
        let icon: String
        let color: Color
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Image(systemName: particle.icon)
                    .font(.caption)
                    .foregroundColor(particle.color)
                    .scaleEffect(particle.scale)
                    .rotationEffect(.degrees(particle.rotation))
                    .offset(x: particle.xOffset, y: particle.yOffset)
            }
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                triggerCelebration()
            }
        }
    }

    private func triggerCelebration() {
        particles = (0..<12).map { _ in
            CelebrationParticle(
                xOffset: CGFloat.random(in: -100...100),
                yOffset: CGFloat.random(in: -100...100),
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.5),
                icon: ["star.fill", "sparkle", "heart.fill", "star.circle.fill"].randomElement()!,
                color: [.yellow, .orange, .pink, .purple, .blue].randomElement()!
            )
        }

        // Clear particles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                particles = []
            }
        }
    }
}

// MARK: - Slide Up Modifier

/// Slide up animation for overlays and sheets.
struct SlideUpModifier: ViewModifier {
    let isPresented: Bool

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .offset(y: isPresented ? 0 : geometry.size.height + 100)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isPresented)
        }
    }
}

extension View {
    /// Apply slide-up animation.
    func slideUp(isPresented: Bool) -> some View {
        modifier(SlideUpModifier(isPresented: isPresented))
    }
}

// MARK: - Count Up Animation

/// Animated number that counts up to a target value.
struct CountUpText: View {
    let targetValue: Int
    let duration: Double
    let prefix: String
    let suffix: String

    @State private var displayValue: Int = 0

    init(_ targetValue: Int, duration: Double = 0.5, prefix: String = "", suffix: String = "") {
        self.targetValue = targetValue
        self.duration = duration
        self.prefix = prefix
        self.suffix = suffix
    }

    var body: some View {
        Text("\(prefix)\(displayValue)\(suffix)")
            .contentTransition(.numericText())
            .onAppear {
                animateToTarget()
            }
            .onChange(of: targetValue) { _ in
                animateToTarget()
            }
    }

    private func animateToTarget() {
        withAnimation(.easeOut(duration: duration)) {
            displayValue = targetValue
        }
    }
}

// MARK: - Pulse Animation

/// Gentle pulse animation for attention-grabbing elements.
struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.9 : 1.0)
            .animation(
                isActive ?
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true) :
                    .default,
                value: isPulsing
            )
            .onAppear {
                if isActive {
                    isPulsing = true
                }
            }
    }
}

extension View {
    /// Apply gentle pulse animation.
    func pulse(isActive: Bool = true) -> some View {
        modifier(PulseModifier(isActive: isActive))
    }
}

// MARK: - Shake Modifier

/// Shake animation for errors or invalid actions.
struct ShakeModifier: ViewModifier {
    @Binding var shake: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: shake ? -10 : 0)
            .animation(
                shake ?
                    .spring(response: 0.1, dampingFraction: 0.3)
                    .repeatCount(4, autoreverses: true) :
                    .default,
                value: shake
            )
            .onChange(of: shake) { newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        shake = false
                    }
                }
            }
    }
}

extension View {
    /// Apply shake animation when binding is true.
    func shake(_ shake: Binding<Bool>) -> some View {
        modifier(ShakeModifier(shake: shake))
    }
}

// MARK: - Previews

#Preview("Button Styles") {
    VStack(spacing: 20) {
        Button("Bounce Button") {}
            .buttonStyle(BounceButtonStyle())
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)

        Text("Wiggle Effect")
            .font(.title)
            .wiggle()

        HStack {
            CountUpText(100, prefix: "+", suffix: " pts")
                .font(.title.bold())
        }
    }
    .padding()
}
