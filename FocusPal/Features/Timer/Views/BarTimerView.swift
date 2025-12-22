//
//  BarTimerView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Bar/linear countdown timer visualization.
struct BarTimerView: View {
    let progress: Double
    let remainingTime: TimeInterval
    let state: TimerState

    var body: some View {
        VStack(spacing: 24) {
            // Time display
            Text(formattedTime)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))

                    // Progress
                    RoundedRectangle(cornerRadius: 12)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 24)

            // State label
            Text(stateLabel)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var stateLabel: String {
        switch state {
        case .idle: return "Ready to Start"
        case .running: return "Focus Time"
        case .paused: return "Paused"
        case .completed: return "Great Job!"
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
    BarTimerView(
        progress: 0.6,
        remainingTime: 450,
        state: .running
    )
    .frame(height: 200)
}
