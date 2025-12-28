//
//  CircularTimerView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// ADHD-friendly circular timer with disappearing color wedge.
/// Inspired by Time Timer - makes time tangible and visible.
struct CircularTimerView: View {
    let progress: Double
    let remainingTime: TimeInterval
    let state: TimerState
    var isRestoring: Bool = false

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Clock face background
            Circle()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

            // Hour markers
            ForEach(0..<12) { index in
                Rectangle()
                    .fill(Color(.systemGray3))
                    .frame(width: index % 3 == 0 ? 4 : 2, height: index % 3 == 0 ? 15 : 10)
                    .offset(y: -125)
                    .rotationEffect(.degrees(Double(index) * 30))
            }

            // Colored time wedge - the key ADHD timer feature
            // This shrinks as time passes, making time visible
            // Explicitly disable ALL animations on the wedge to prevent animation on view recreation
            TimeWedge(progress: progress)
                .fill(wedgeColor)
                .opacity(state == .idle ? 0.5 : 0.9)
                .transaction { transaction in
                    transaction.animation = nil
                }
                .scaleEffect(isPulsing ? 1.02 : 1.0)
                .animation(
                    state == .running ?
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true) :
                        .none,
                    value: isPulsing
                )

            // Inner circle for clean look
            Circle()
                .fill(Color(.systemBackground))
                .frame(width: 160, height: 160)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)

            // Time display
            VStack(spacing: 4) {
                Text(formattedTime)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(timeTextColor)

                Text(stateLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1.5)
            }

            // Outer ring
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 3)
        }
        .onAppear {
            if state == .running {
                isPulsing = true
            }
        }
        .onChange(of: state) { _ in
            isPulsing = state == .running
        }
    }

    private var formattedTime: String {
        let totalSeconds = Int(remainingTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var stateLabel: String {
        switch state {
        case .idle: return "Ready to Focus"
        case .running: return "Stay Focused"
        case .paused: return "Paused"
        case .completed: return "Great Job!"
        }
    }

    private var wedgeColor: Color {
        switch state {
        case .idle:
            return .red  // Full red, opacity handled separately
        case .running:
            // Gradient from red to orange based on progress
            if progress > 0.5 {
                return .red
            } else if progress > 0.25 {
                return .orange
            } else {
                return .yellow
            }
        case .paused:
            return .orange
        case .completed:
            return .green
        }
    }

    private var timeTextColor: Color {
        switch state {
        case .idle: return .primary
        case .running: return progress < 0.25 ? .red : .primary
        case .paused: return .orange
        case .completed: return .green
        }
    }
}

/// Custom shape for the time wedge that shrinks clockwise
struct TimeWedge: Shape {
    var progress: Double

    // Removed animatableData to prevent automatic animation
    // Animation is controlled at the view level via displayedProgress

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 10
        // Start at 12 o'clock position
        let startAngle = Angle(degrees: -90)
        // End angle goes clockwise (negative direction in SwiftUI)
        let endAngle = Angle(degrees: -90 - (360 * progress))

        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true  // Clockwise in screen coordinates
        )
        path.closeSubpath()
        return path
    }
}

#Preview("Running") {
    CircularTimerView(
        progress: 0.75,
        remainingTime: 1125,
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
