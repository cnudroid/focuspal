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

    var body: some View {
        ZStack {
            clockFaceBackground
            hourMarkers
            timeWedgeView
            innerCircle
            timeDisplay
            outerRing
        }
    }

    private var clockFaceBackground: some View {
        Circle()
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var hourMarkers: some View {
        ForEach(0..<12, id: \.self) { index in
            Rectangle()
                .fill(Color(.systemGray3))
                .frame(width: index % 3 == 0 ? 4 : 2, height: index % 3 == 0 ? 15 : 10)
                .offset(y: -125)
                .rotationEffect(.degrees(Double(index) * 30))
        }
    }

    private var timeWedgeView: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            if state == .idle {
                // IDLE: Show filled circle (no stroke edges visible)
                Circle()
                    .fill(wedgeColor)
                    .opacity(0.5)
                    .frame(width: size - 20, height: size - 20)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            } else {
                // RUNNING/PAUSED: Use trim() stroke for animated wedge
                let strokeWidth = (size / 2) - 10

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        wedgeColor,
                        style: StrokeStyle(
                            lineWidth: strokeWidth,
                            lineCap: .butt
                        )
                    )
                    .rotationEffect(.degrees(-90 - (360 * progress)))
                    .opacity(0.9)
                    .frame(width: size, height: size)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }

    private var innerCircle: some View {
        Circle()
            .fill(Color(.systemBackground))
            .frame(width: 160, height: 160)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var timeDisplay: some View {
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
    }

    private var outerRing: some View {
        Circle()
            .stroke(Color(.systemGray4), lineWidth: 3)
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
            return .red
        case .running:
            // Dynamic color based on remaining time
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
        case .running: return .primary
        case .paused: return .orange
        case .completed: return .green
        }
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
