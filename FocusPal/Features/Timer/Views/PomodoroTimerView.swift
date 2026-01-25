//
//  PomodoroTimerView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Pomodoro-style timer view inspired by the classic Time Timer design.
/// Features a red wedge that depletes clockwise, clock-face tick marks, and an analog clock hand.
struct PomodoroTimerView: View {
    let progress: Double          // 1.0 → 0.0 (full → empty)
    let remainingTime: TimeInterval
    let state: TimerState

    // Animation states
    @State private var showMilestone: Bool = false
    @State private var lastMilestone: Double = 1.0
    @State private var handPulse: Bool = false
    @State private var showCompletion: Bool = false

    // Pomodoro red color
    private let pomodoroRed = Color(red: 0.9, green: 0.25, blue: 0.25)
    private let pomodoroRedLight = Color(red: 0.95, green: 0.4, blue: 0.4)

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                // Background circle
                backgroundCircle(size: size)

                // Outer ring (border)
                outerRing(size: size)

                // Filled wedge (remaining time)
                filledWedge(size: size)

                // Tick marks (60 minute markers)
                tickMarks(size: size)

                // Center dot
                centerDot(size: size)

                // Clock hand
                clockHand(size: size)

                // Center content (time display)
                centerContent(size: size)

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

    // MARK: - Background Circle

    private func backgroundCircle(size: CGFloat) -> some View {
        Circle()
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }

    // MARK: - Outer Ring

    private func outerRing(size: CGFloat) -> some View {
        Circle()
            .stroke(Color(.systemGray4), lineWidth: 3)
            .frame(width: size * 0.92, height: size * 0.92)
    }

    // MARK: - Filled Wedge

    private func filledWedge(size: CGFloat) -> some View {
        // The wedge shows remaining time, depleting clockwise from 12 o'clock
        Circle()
            .trim(from: 0, to: progress)
            .fill(wedgeColor)
            .frame(width: size * 0.85, height: size * 0.85)
            .rotationEffect(.degrees(-90))
            .scaleEffect(x: -1, y: 1) // Clockwise direction
            .mask(
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: size * 0.425, lineCap: .butt))
                    .frame(width: size * 0.425, height: size * 0.425)
                    .rotationEffect(.degrees(-90))
                    .scaleEffect(x: -1, y: 1)
            )
    }

    // MARK: - Tick Marks

    private func tickMarks(size: CGFloat) -> some View {
        ZStack {
            ForEach(0..<60, id: \.self) { index in
                Rectangle()
                    .fill(tickColor(for: index))
                    .frame(
                        width: index % 5 == 0 ? 2.5 : 1,
                        height: index % 5 == 0 ? 14 : 8
                    )
                    .offset(y: -size * 0.44)
                    .rotationEffect(.degrees(Double(index) * 6))
            }
        }
    }

    private func tickColor(for index: Int) -> Color {
        if index % 5 == 0 {
            return Color(.systemGray2)
        } else {
            return Color(.systemGray4)
        }
    }

    // MARK: - Center Dot

    private func centerDot(size: CGFloat) -> some View {
        Circle()
            .fill(Color(.systemBackground))
            .frame(width: size * 0.12, height: size * 0.12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            .overlay(
                Circle()
                    .fill(pomodoroRed)
                    .frame(width: size * 0.06, height: size * 0.06)
            )
    }

    // MARK: - Clock Hand

    private func clockHand(size: CGFloat) -> some View {
        // Hand points to current position (based on progress)
        // At progress 1.0, hand is at 12 o'clock (0 degrees)
        // At progress 0.0, hand completes full circle back to 12 o'clock
        RoundedRectangle(cornerRadius: 2)
            .fill(pomodoroRed)
            .frame(width: 4, height: size * 0.32)
            .offset(y: -size * 0.16)
            .rotationEffect(.degrees(360 * (1 - progress)))
            .scaleEffect(handPulse ? 1.05 : 1.0)
            .shadow(color: pomodoroRed.opacity(0.3), radius: 2, x: 0, y: 1)
    }

    // MARK: - Center Content

    private func centerContent(size: CGFloat) -> some View {
        VStack(spacing: 4) {
            // Time display
            Text(formattedTime)
                .font(.system(size: size * 0.12, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(timeTextColor)

            // State label
            Text(stateLabel)
                .font(.system(size: size * 0.04, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(1.5)
        }
        .offset(y: size * 0.22)
    }

    // MARK: - Milestone Effect

    private var milestoneEffect: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Image(systemName: ["flame.fill", "star.fill", "heart.fill"][index % 3])
                    .font(.system(size: 18))
                    .foregroundColor([pomodoroRed, .orange, .yellow, pomodoroRedLight][index % 4])
                    .offset(
                        x: cos(Double(index) * .pi / 4) * 85,
                        y: sin(Double(index) * .pi / 4) * 85
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
                PomodoroConfettiPiece(index: index, isActive: showCompletion)
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
        case .running: return "Focus Time"
        case .paused: return "On Break"
        case .completed: return "Complete!"
        }
    }

    private var wedgeColor: Color {
        switch state {
        case .idle:
            return pomodoroRed
        case .running:
            if progress > 0.5 {
                return pomodoroRed
            } else if progress > 0.25 {
                return .orange
            } else {
                return Color(red: 0.85, green: 0.2, blue: 0.2)
            }
        case .paused:
            return pomodoroRedLight
        case .completed:
            return .green
        }
    }

    private var timeTextColor: Color {
        switch state {
        case .idle: return .primary
        case .running: return .primary
        case .paused: return pomodoroRedLight
        case .completed: return .green
        }
    }

    // MARK: - Animation Control

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            handPulse = true
        }
    }

    private func stopAnimations() {
        withAnimation(.easeOut(duration: 0.3)) {
            handPulse = false
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

struct PomodoroConfettiPiece: View {
    let index: Int
    let isActive: Bool

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0

    private let colors: [Color] = [
        Color(red: 0.9, green: 0.25, blue: 0.25),
        .orange,
        .yellow,
        Color(red: 0.95, green: 0.4, blue: 0.4),
        .red
    ]

    var body: some View {
        Image(systemName: ["flame.fill", "circle.fill", "star.fill", "sparkle"][index % 4])
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
    PomodoroTimerView(
        progress: 0.75,
        remainingTime: 1125,
        state: .running
    )
    .frame(width: 300, height: 300)
    .padding()
}

#Preview("Half Time") {
    PomodoroTimerView(
        progress: 0.45,
        remainingTime: 675,
        state: .running
    )
    .frame(width: 300, height: 300)
    .padding()
}

#Preview("Low Time") {
    PomodoroTimerView(
        progress: 0.15,
        remainingTime: 135,
        state: .running
    )
    .frame(width: 300, height: 300)
    .padding()
}

#Preview("Idle") {
    PomodoroTimerView(
        progress: 1.0,
        remainingTime: 1500,
        state: .idle
    )
    .frame(width: 300, height: 300)
    .padding()
}

#Preview("Paused") {
    PomodoroTimerView(
        progress: 0.6,
        remainingTime: 900,
        state: .paused
    )
    .frame(width: 300, height: 300)
    .padding()
}

#Preview("Completed") {
    PomodoroTimerView(
        progress: 0.0,
        remainingTime: 0,
        state: .completed
    )
    .frame(width: 300, height: 300)
    .padding()
}
