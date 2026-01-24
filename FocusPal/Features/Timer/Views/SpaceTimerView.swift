//
//  SpaceTimerView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Space Explorer themed timer with rocket, stars, and planet.
/// Makes time visible through a rocket orbiting and fuel gauge depleting.
struct SpaceTimerView: View {
    let progress: Double
    let remainingTime: TimeInterval
    let state: TimerState

    // Animation states
    @State private var starsPhase: CGFloat = 0
    @State private var showMilestone: Bool = false
    @State private var lastMilestone: Double = 1.0

    private let starCount = 20

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                // Deep space background
                spaceBackground(size: size)

                // Twinkling stars
                starsLayer(size: size)

                // Planet (center piece)
                planetView(size: size)

                // Fuel gauge ring (shows progress)
                fuelGaugeRing(size: size)

                // Orbiting rocket
                orbitingRocket(size: size)

                // Time display
                timeDisplay

                // Milestone celebration
                if showMilestone {
                    milestoneEffect
                }
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: progress) { newProgress in
            checkMilestone(newProgress)
        }
    }

    // MARK: - Space Background

    private func spaceBackground(size: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color.black
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
    }

    // MARK: - Stars Layer

    private func starsLayer(size: CGFloat) -> some View {
        Canvas { context, canvasSize in
            for index in 0..<starCount {
                let angle = Double(index) * (360.0 / Double(starCount))
                let distance = CGFloat(0.35 + Double(index % 5) * 0.02) * size
                let starSize = CGFloat(2 + index % 4)
                let twinkleOffset = Double(index) * 0.3
                let opacity = state == .running ? 0.4 + 0.6 * sin(starsPhase + twinkleOffset) : 0.7

                let x = canvasSize.width / 2 + cos(angle * .pi / 180) * distance
                let y = canvasSize.height / 2 + sin(angle * .pi / 180) * distance

                context.opacity = opacity
                context.fill(
                    Circle().path(in: CGRect(x: x - starSize / 2, y: y - starSize / 2, width: starSize, height: starSize)),
                    with: .color(.white)
                )
            }
        }
    }

    // MARK: - Planet View

    private func planetView(size: CGFloat) -> some View {
        ZStack {
            // Planet glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [planetColor.opacity(0.3), .clear],
                        center: .center,
                        startRadius: size * 0.15,
                        endRadius: size * 0.25
                    )
                )
                .frame(width: size * 0.5, height: size * 0.5)

            // Main planet
            Circle()
                .fill(
                    LinearGradient(
                        colors: [planetColor, planetColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.35, height: size * 0.35)
                .shadow(color: planetColor.opacity(0.5), radius: 10)

            // Planet ring (like Saturn)
            Ellipse()
                .stroke(planetColor.opacity(0.4), lineWidth: 3)
                .frame(width: size * 0.5, height: size * 0.12)
                .rotationEffect(.degrees(-20))
        }
    }

    // MARK: - Fuel Gauge Ring

    private func fuelGaugeRing(size: CGFloat) -> some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 8)
                .frame(width: size * 0.85, height: size * 0.85)

            // Fuel gauge (depletes clockwise as time passes)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: fuelGradientColors,
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: size * 0.85, height: size * 0.85)
                .rotationEffect(.degrees(-90))
                .scaleEffect(x: -1, y: 1) // Flip to make it go clockwise
        }
    }

    // MARK: - Orbiting Rocket

    private func orbitingRocket(size: CGFloat) -> some View {
        let orbitRadius = size * 0.42
        // Rocket position based on remaining progress (starts at top, moves clockwise)
        let angle = -90 + (360 * (1 - progress))

        return Image(systemName: "airplane")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .rotationEffect(.degrees(angle + 90)) // Point in direction of travel
            .offset(
                x: cos(angle * .pi / 180) * orbitRadius,
                y: sin(angle * .pi / 180) * orbitRadius
            )
            .shadow(color: .orange, radius: state == .running ? 8 : 0)
    }

    // MARK: - Time Display

    private var timeDisplay: some View {
        VStack(spacing: 2) {
            Text(formattedTime)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)

            Text(stateLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .textCase(.uppercase)
                .tracking(1)
        }
    }

    // MARK: - Milestone Effect

    private var milestoneEffect: some View {
        Canvas { context, size in
            let positions: [(CGFloat, CGFloat)] = [
                (-40, -30), (40, -25), (-30, 40), (35, 35),
                (-50, 10), (50, -10), (0, -50), (0, 50)
            ]
            for (index, pos) in positions.enumerated() {
                let starPath = Path { path in
                    let center = CGPoint(x: size.width / 2 + pos.0, y: size.height / 2 + pos.1)
                    path.addArc(center: center, radius: 4, startAngle: .zero, endAngle: .degrees(360), clockwise: true)
                }
                context.opacity = showMilestone ? 1.0 : 0.0
                context.fill(starPath, with: .color(.yellow))
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
        case .idle: return "Ready for Launch"
        case .running: return "In Orbit"
        case .paused: return "Hovering"
        case .completed: return "Mission Complete!"
        }
    }

    private var planetColor: Color {
        switch state {
        case .idle: return .blue
        case .running:
            if progress > 0.5 { return .blue }
            else if progress > 0.25 { return .purple }
            else { return .orange }
        case .paused: return .purple
        case .completed: return .green
        }
    }

    private var fuelGradientColors: [Color] {
        switch state {
        case .completed: return [.green, .mint]
        case .paused: return [.purple, .indigo]
        default:
            if progress > 0.5 { return [.cyan, .blue] }
            else if progress > 0.25 { return [.orange, .yellow] }
            else { return [.red, .orange] }
        }
    }

    private func startAnimations() {
        guard state == .running else { return }
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            starsPhase = .pi * 2
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

#Preview("Space - Idle") {
    SpaceTimerView(
        progress: 1.0,
        remainingTime: 1500,
        state: .idle
    )
    .frame(width: 300, height: 300)
    .background(Color.black)
}

#Preview("Space - Running 75%") {
    SpaceTimerView(
        progress: 0.75,
        remainingTime: 1125,
        state: .running
    )
    .frame(width: 300, height: 300)
    .background(Color.black)
}

#Preview("Space - Running 25%") {
    SpaceTimerView(
        progress: 0.25,
        remainingTime: 375,
        state: .running
    )
    .frame(width: 300, height: 300)
    .background(Color.black)
}

#Preview("Space - Completed") {
    SpaceTimerView(
        progress: 0.0,
        remainingTime: 0,
        state: .completed
    )
    .frame(width: 300, height: 300)
    .background(Color.black)
}
