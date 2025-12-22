//
//  Animations.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Design system animation presets.
struct FPAnimation {

    // MARK: - Duration

    static let durationFast: Double = 0.15
    static let durationNormal: Double = 0.3
    static let durationSlow: Double = 0.5

    // MARK: - Standard Animations

    static let fast = Animation.easeInOut(duration: durationFast)
    static let normal = Animation.easeInOut(duration: durationNormal)
    static let slow = Animation.easeInOut(duration: durationSlow)

    // MARK: - Spring Animations

    static let springLight = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let springMedium = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.5)

    // MARK: - Semantic Animations

    static let buttonPress = springLight
    static let cardHover = normal
    static let modalPresent = springMedium
    static let listReorder = springMedium
    static let timerTick = fast

    // MARK: - Timer Specific

    static let timerProgress = Animation.linear(duration: 0.1)
    static let timerComplete = Animation.spring(response: 0.6, dampingFraction: 0.5)
}

// MARK: - View Extensions

extension View {
    func fpAnimation(_ animation: Animation = FPAnimation.normal) -> some View {
        self.animation(animation, value: UUID())
    }

    func pulseAnimation() -> some View {
        self.modifier(PulseAnimationModifier())
    }

    func celebrationAnimation() -> some View {
        self.modifier(CelebrationAnimationModifier())
    }
}

// MARK: - Animation Modifiers

struct PulseAnimationModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct CelebrationAnimationModifier: ViewModifier {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(FPAnimation.springBouncy) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
}

// MARK: - Transition Presets

extension AnyTransition {
    static let fpSlideUp = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .bottom).combined(with: .opacity)
    )

    static let fpScale = AnyTransition.scale.combined(with: .opacity)

    static let fpFade = AnyTransition.opacity
}
