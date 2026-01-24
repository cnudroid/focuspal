//
//  AnalogTimerView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Analog clock-style countdown timer visualization.
struct AnalogTimerView: View {
    let progress: Double
    let remainingTime: TimeInterval
    let state: TimerState

    var body: some View {
        ZStack {
            // Clock face
            Circle()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10)

            // Hour markers
            ForEach(0..<12) { index in
                Rectangle()
                    .fill(Color(.systemGray3))
                    .frame(width: 2, height: index % 3 == 0 ? 15 : 8)
                    .offset(y: -115)
                    .rotationEffect(.degrees(Double(index) * 30))
            }

            // Remaining time arc (clockwise from top)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor, lineWidth: 8)
                .rotationEffect(.degrees(-90))
                .scaleEffect(x: -1, y: 1) // Flip to make it go clockwise
                .padding(20)
                .animation(.easeInOut(duration: 0.3), value: progress)

            // Center time display
            VStack(spacing: 4) {
                Text(formattedTime)
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                Text(stateLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Clock hand
            Rectangle()
                .fill(progressColor)
                .frame(width: 4, height: 80)
                .offset(y: -40)
                .rotationEffect(.degrees(360 * (1 - progress)))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
    }

    private var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var stateLabel: String {
        switch state {
        case .idle: return "Ready"
        case .running: return "Focusing"
        case .paused: return "Paused"
        case .completed: return "Done!"
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
    AnalogTimerView(
        progress: 0.7,
        remainingTime: 420,
        state: .running
    )
    .frame(width: 280, height: 280)
}
