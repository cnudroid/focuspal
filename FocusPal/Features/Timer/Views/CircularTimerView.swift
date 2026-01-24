//
//  CircularTimerView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Modern circular timer with ring-style progress indicator.
/// Clean, engaging design with smooth animations.
struct CircularTimerView: View {
    let progress: Double
    let remainingTime: TimeInterval
    let state: TimerState
    var isRestoring: Bool = false

    // Animation states
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var showMilestone: Bool = false
    @State private var lastMilestone: Double = 1.0
    @State private var showCompletion: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                // Background with subtle gradient
                backgroundCircle(size: size)

                // Track ring (background)
                trackRing(size: size)

                // Progress ring
                progressRing(size: size)

                // Glow effect behind progress
                if state == .running {
                    glowEffect(size: size)
                }

                // Center content
                centerContent(size: size)

                // Tick marks
                tickMarks(size: size)

                // Milestone celebration
                if showMilestone {
                    milestoneEffect
                }

                // Completion celebration
                if showCompletion {
                    completionEffect
                }
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .scaleEffect(pulseScale)
        .onAppear {
            if state == .running {
                startAnimations()
            }
        }
        .onChange(of: state) { newState in
            if newState == .running {
                startAnimations()
            } else if newState == .completed {
                triggerCompletion()
            } else {
                stopAnimations()
            }
        }
        .onChange(of: progress) { newProgress in
            checkMilestone(newProgress)
        }
    }

    // MARK: - Background

    private func backgroundCircle(size: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
    }

    // MARK: - Track Ring

    private func trackRing(size: CGFloat) -> some View {
        Circle()
            .stroke(
                Color(.systemGray5),
                style: StrokeStyle(lineWidth: 20, lineCap: .round)
            )
            .frame(width: size * 0.75, height: size * 0.75)
    }

    // MARK: - Progress Ring

    private func progressRing(size: CGFloat) -> some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(
                AngularGradient(
                    colors: progressColors,
                    center: .center,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(270)
                ),
                style: StrokeStyle(lineWidth: 20, lineCap: .round)
            )
            .frame(width: size * 0.75, height: size * 0.75)
            .rotationEffect(.degrees(-90))
            .scaleEffect(x: -1, y: 1) // Clockwise
            .shadow(color: progressColors.first?.opacity(0.4) ?? .clear, radius: 8, x: 0, y: 4)
    }

    // MARK: - Glow Effect

    private func glowEffect(size: CGFloat) -> some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(
                progressColors.first ?? .blue,
                style: StrokeStyle(lineWidth: 24, lineCap: .round)
            )
            .frame(width: size * 0.75, height: size * 0.75)
            .rotationEffect(.degrees(-90))
            .scaleEffect(x: -1, y: 1)
            .blur(radius: 12)
            .opacity(glowOpacity)
    }

    // MARK: - Center Content

    private func centerContent(size: CGFloat) -> some View {
        VStack(spacing: 8) {
            // Time display
            Text(formattedTime)
                .font(.system(size: size * 0.15, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(timeTextColor)

            // State label
            Text(stateLabel)
                .font(.system(size: size * 0.045, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(2)

            // Progress percentage
            if state == .running || state == .paused {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.04, weight: .medium, design: .rounded))
                    .foregroundColor(progressColors.first)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Tick Marks

    private func tickMarks(size: CGFloat) -> some View {
        ForEach(0..<12, id: \.self) { index in
            RoundedRectangle(cornerRadius: 1)
                .fill(index % 3 == 0 ? Color(.systemGray2) : Color(.systemGray4))
                .frame(width: index % 3 == 0 ? 3 : 2, height: index % 3 == 0 ? 12 : 8)
                .offset(y: -size * 0.44)
                .rotationEffect(.degrees(Double(index) * 30))
        }
    }

    // MARK: - Milestone Effect

    private var milestoneEffect: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Image(systemName: ["star.fill", "sparkle", "heart.fill"][index % 3])
                    .font(.system(size: 16))
                    .foregroundColor([.yellow, .orange, .pink, .purple][index % 4])
                    .offset(
                        x: cos(Double(index) * .pi / 4) * 80,
                        y: sin(Double(index) * .pi / 4) * 80
                    )
                    .scaleEffect(showMilestone ? 1.2 : 0)
                    .opacity(showMilestone ? 1 : 0)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showMilestone)
    }

    // MARK: - Completion Effect

    private var completionEffect: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { index in
                TimerConfettiPiece(index: index, isActive: showCompletion)
            }
        }
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
        case .idle: return "Ready"
        case .running: return "Focusing"
        case .paused: return "Paused"
        case .completed: return "Done!"
        }
    }

    private var progressColors: [Color] {
        switch state {
        case .idle:
            return [.blue, .cyan]
        case .running:
            if progress > 0.5 {
                return [.blue, .cyan]
            } else if progress > 0.25 {
                return [.orange, .yellow]
            } else {
                return [.red, .orange]
            }
        case .paused:
            return [.orange, .yellow]
        case .completed:
            return [.green, .mint]
        }
    }

    private var timeTextColor: Color {
        switch state {
        case .idle: return .primary
        case .running: return .primary
        case .paused: return .orange
        case .completed: return .green
        }
    }

    // MARK: - Animation Control

    private func startAnimations() {
        // Pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.02
        }
        // Glow
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.6
        }
    }

    private func stopAnimations() {
        withAnimation(.easeOut(duration: 0.3)) {
            pulseScale = 1.0
            glowOpacity = 0.3
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

    private func triggerCompletion() {
        showCompletion = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showCompletion = false
        }
    }
}

// MARK: - Confetti Piece

struct TimerConfettiPiece: View {
    let index: Int
    let isActive: Bool

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0

    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

    var body: some View {
        Image(systemName: ["star.fill", "circle.fill", "heart.fill", "sparkle"][index % 4])
            .font(.system(size: CGFloat.random(in: 10...16)))
            .foregroundColor(colors[index % colors.count])
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onChange(of: isActive) { active in
                if active {
                    animate()
                }
            }
    }

    private func animate() {
        let angle = Double(index) * (360.0 / 16.0) * .pi / 180
        let distance: CGFloat = CGFloat.random(in: 80...140)

        offset = .zero
        rotation = 0
        opacity = 1

        withAnimation(.easeOut(duration: 1.5)) {
            offset = CGSize(
                width: cos(angle) * distance,
                height: sin(angle) * distance
            )
            rotation = Double.random(in: 180...720)
        }

        withAnimation(.easeIn(duration: 0.5).delay(1.0)) {
            opacity = 0
        }
    }
}

// MARK: - Previews

#Preview("Running") {
    CircularTimerView(
        progress: 0.75,
        remainingTime: 1125,
        state: .running
    )
    .frame(width: 300, height: 300)
    .padding()
}

#Preview("Half Time") {
    CircularTimerView(
        progress: 0.45,
        remainingTime: 675,
        state: .running
    )
    .frame(width: 300, height: 300)
    .padding()
}

#Preview("Low Time") {
    CircularTimerView(
        progress: 0.15,
        remainingTime: 135,
        state: .running
    )
    .frame(width: 300, height: 300)
    .padding()
}

#Preview("Idle") {
    CircularTimerView(
        progress: 1.0,
        remainingTime: 1500,
        state: .idle
    )
    .frame(width: 300, height: 300)
    .padding()
}

#Preview("Completed") {
    CircularTimerView(
        progress: 0.0,
        remainingTime: 0,
        state: .completed
    )
    .frame(width: 300, height: 300)
    .padding()
}
