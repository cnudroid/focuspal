//
//  CircularTimerView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Circular countdown timer visualization.
struct CircularTimerView: View {
    let progress: Double
    let remainingTime: TimeInterval
    let state: TimerState

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 20)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(
                        lineWidth: 20,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)

            // Time display
            VStack(spacing: 8) {
                Text(formattedTime)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(stateLabel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var stateLabel: String {
        switch state {
        case .idle: return "Ready"
        case .running: return "Focus Time"
        case .paused: return "Paused"
        case .completed: return "Complete!"
        }
    }

    private var progressColor: Color {
        switch state {
        case .idle: return .gray
        case .running: return .blue
        case .paused: return .orange
        case .completed: return .green
        }
    }
}

#Preview {
    CircularTimerView(
        progress: 0.75,
        remainingTime: 300,
        state: .running
    )
    .frame(width: 300, height: 300)
}
