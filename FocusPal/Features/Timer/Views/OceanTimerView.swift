//
//  OceanTimerView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Ocean Adventure themed timer with fish, bubbles, and water effects.
/// Water level visually drains as time passes.
struct OceanTimerView: View {
    let progress: Double
    let remainingTime: TimeInterval
    let state: TimerState

    // Animation states
    @State private var bubblePhase: CGFloat = 0
    @State private var fishOffset: CGFloat = 0
    @State private var wavePhase: Double = 0
    @State private var showMilestone: Bool = false
    @State private var lastMilestone: Double = 1.0

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                // Ocean background
                oceanBackground(size: size)

                // Water fill (drains as time passes)
                waterFill(size: size)

                // Animated bubbles
                bubblesLayer(size: size)

                // Swimming fish
                fishLayer(size: size)

                // Glass dome overlay
                glassDome(size: size)

                // Time display
                timeDisplay(size: size)

                // Treasure chest at bottom (appears when complete)
                if state == .completed {
                    treasureChest(size: size)
                }

                // Milestone celebration
                if showMilestone {
                    milestoneEffect
                }
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .clipShape(Circle())
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: progress) { newProgress in
            checkMilestone(newProgress)
        }
        .onChange(of: state) { newState in
            if newState == .running {
                startAnimations()
            }
        }
    }

    // MARK: - Ocean Background

    private func oceanBackground(size: CGFloat) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.3, blue: 0.5),
                        Color(red: 0.05, green: 0.2, blue: 0.4),
                        Color(red: 0.02, green: 0.1, blue: 0.25)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size, height: size)
    }

    // MARK: - Water Fill

    private func waterFill(size: CGFloat) -> some View {
        let waterHeight = size * progress

        return ZStack {
            // Water body
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: waterColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size, height: waterHeight)
                .offset(y: (size - waterHeight) / 2)

            // Wavy top surface
            WaveShape(amplitude: 8.0, frequency: 3.0, phase: wavePhase)
                .fill(waterColors.first ?? .cyan)
                .frame(width: size, height: 20)
                .offset(y: -waterHeight / 2 + (size - waterHeight) / 2)
        }
        .opacity(0.7)
    }

    // MARK: - Bubbles Layer

    private func bubblesLayer(size: CGFloat) -> some View {
        Canvas { context, canvasSize in
            let bubbleData: [(x: CGFloat, size: CGFloat, speed: Double)] = [
                (-0.35, 8, 2.5), (-0.2, 6, 3.0), (-0.05, 10, 2.0), (0.1, 7, 2.8),
                (0.25, 9, 2.2), (0.35, 6, 3.2), (0.0, 8, 2.6), (-0.15, 7, 2.9)
            ]

            for (index, bubble) in bubbleData.enumerated() {
                let xPos = canvasSize.width / 2 + bubble.x * size
                let baseY = canvasSize.height * 0.8
                let yOffset = state == .running
                    ? (bubblePhase + CGFloat(index) * 30).truncatingRemainder(dividingBy: size * 0.6)
                    : 0

                let bubblePath = Circle().path(in: CGRect(
                    x: xPos - bubble.size / 2,
                    y: baseY - yOffset - bubble.size / 2,
                    width: bubble.size,
                    height: bubble.size
                ))

                context.opacity = state == .running ? 0.5 : 0.3
                context.fill(bubblePath, with: .color(.white.opacity(0.6)))
            }
        }
    }

    // MARK: - Fish Layer

    private func fishLayer(size: CGFloat) -> some View {
        let waterHeight = size * progress
        let fishY = (size - waterHeight) / 2 - waterHeight * 0.3

        return ZStack {
            // Fish 1 - swimming right
            Image(systemName: "fish.fill")
                .font(.system(size: 20))
                .foregroundColor(fishColor)
                .offset(x: fishOffset - size / 3, y: fishY)
                .opacity(progress > 0.2 ? 1 : 0)

            // Fish 2 - swimming left (mirrored)
            Image(systemName: "fish.fill")
                .font(.system(size: 16))
                .foregroundColor(fishColor.opacity(0.7))
                .scaleEffect(x: -1)
                .offset(x: -fishOffset + size / 4, y: fishY + 30)
                .opacity(progress > 0.4 ? 1 : 0)
        }
    }

    // MARK: - Glass Dome

    private func glassDome(size: CGFloat) -> some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .white.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 6
                )
                .frame(width: size - 4, height: size - 4)

            // Glass shine
            Circle()
                .trim(from: 0.1, to: 0.3)
                .stroke(Color.white.opacity(0.4), lineWidth: 3)
                .frame(width: size * 0.85, height: size * 0.85)
                .rotationEffect(.degrees(-45))
        }
    }

    // MARK: - Time Display

    private func timeDisplay(size: CGFloat) -> some View {
        VStack(spacing: 4) {
            Text(formattedTime)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)

            Text(stateLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .textCase(.uppercase)
                .tracking(1)
        }
        .offset(y: -size * 0.1)
    }

    // MARK: - Treasure Chest

    private func treasureChest(size: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Image(systemName: "shippingbox.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
            }
            .padding(.bottom, size * 0.15)
        }
        .frame(width: size, height: size)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Milestone Effect

    private var milestoneEffect: some View {
        Canvas { context, size in
            let positions: [(CGFloat, CGFloat)] = [
                (-35, -25), (35, -20), (-25, 35), (30, 30),
                (-45, 5), (45, -5)
            ]
            for pos in positions {
                let dropPath = Circle().path(in: CGRect(
                    x: size.width / 2 + pos.0 - 5,
                    y: size.height / 2 + pos.1 - 5,
                    width: 10,
                    height: 10
                ))
                context.opacity = showMilestone ? 1.0 : 0.0
                context.fill(dropPath, with: .color(.cyan))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showMilestone)
    }

    // MARK: - Helpers

    private var formattedTime: String {
        let totalSeconds = Int(remainingTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var stateLabel: String {
        switch state {
        case .idle: return "Ready to Dive"
        case .running: return "Exploring"
        case .paused: return "Floating"
        case .completed: return "Treasure Found!"
        }
    }

    private var waterColors: [Color] {
        switch state {
        case .idle: return [.cyan.opacity(0.8), .blue]
        case .running:
            if progress > 0.5 {
                return [.cyan, .blue]
            } else if progress > 0.25 {
                return [.teal, .blue]
            } else {
                return [.orange.opacity(0.6), .blue]
            }
        case .paused: return [.purple.opacity(0.6), .indigo]
        case .completed: return [.green.opacity(0.8), .mint]
        }
    }

    private var fishColor: Color {
        switch state {
        case .completed: return .yellow
        default: return .orange
        }
    }

    private func startAnimations() {
        guard state == .running else { return }

        // Bubble animation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            bubblePhase = 300
        }

        // Fish swimming
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            fishOffset = 100
        }

        // Wave animation
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            wavePhase = .pi * 2
        }
    }

    private func checkMilestone(_ newProgress: Double) {
        let milestones = [0.75, 0.5, 0.25]
        for milestone in milestones {
            if lastMilestone > milestone && newProgress <= milestone {
                triggerMilestone()
                lastMilestone = milestone
                break
            }
        }
        if newProgress > lastMilestone {
            lastMilestone = 1.0
        }
    }

    private func triggerMilestone() {
        showMilestone = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showMilestone = false
        }
    }
}

// MARK: - Previews

#Preview("Ocean - Idle") {
    OceanTimerView(
        progress: 1.0,
        remainingTime: 1500,
        state: .idle
    )
    .frame(width: 300, height: 300)
    .background(Color.black)
}

#Preview("Ocean - Running 75%") {
    OceanTimerView(
        progress: 0.75,
        remainingTime: 1125,
        state: .running
    )
    .frame(width: 300, height: 300)
    .background(Color.black)
}

#Preview("Ocean - Running 25%") {
    OceanTimerView(
        progress: 0.25,
        remainingTime: 375,
        state: .running
    )
    .frame(width: 300, height: 300)
    .background(Color.black)
}

#Preview("Ocean - Completed") {
    OceanTimerView(
        progress: 0.0,
        remainingTime: 0,
        state: .completed
    )
    .frame(width: 300, height: 300)
    .background(Color.black)
}
