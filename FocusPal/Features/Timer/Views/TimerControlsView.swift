//
//  TimerControlsView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Control buttons for the timer (start, pause, resume, stop).
struct TimerControlsView: View {
    let state: TimerState
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    let onCompleteEarly: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                switch state {
                case .idle:
                    PrimaryActionButton(
                        title: "Start",
                        icon: "play.fill",
                        color: .blue,
                        action: onStart
                    )

                case .running:
                    SecondaryActionButton(
                        icon: "stop.fill",
                        action: onStop
                    )

                    PrimaryActionButton(
                        title: "Pause",
                        icon: "pause.fill",
                        color: .orange,
                        action: onPause
                    )

                case .paused:
                    SecondaryActionButton(
                        icon: "stop.fill",
                        action: onStop
                    )

                    PrimaryActionButton(
                        title: "Resume",
                        icon: "play.fill",
                        color: .green,
                        action: onResume
                    )

                case .completed:
                    PrimaryActionButton(
                        title: "Done",
                        icon: "checkmark",
                        color: .green,
                        action: onStop
                    )
                }
            }

            // Complete Early button - shown when running or paused
            if state == .running || state == .paused {
                Button(action: onCompleteEarly) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("I'm Done!")
                    }
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(24)
                }
            }
        }
    }
}

struct PrimaryActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(width: 140, height: 56)
            .background(color)
            .cornerRadius(28)
        }
    }
}

struct SecondaryActionButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.secondary)
                .frame(width: 56, height: 56)
                .background(Color(.systemGray5))
                .cornerRadius(28)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        TimerControlsView(state: .idle, onStart: {}, onPause: {}, onResume: {}, onStop: {}, onCompleteEarly: {})
        TimerControlsView(state: .running, onStart: {}, onPause: {}, onResume: {}, onStop: {}, onCompleteEarly: {})
        TimerControlsView(state: .paused, onStart: {}, onPause: {}, onResume: {}, onStop: {}, onCompleteEarly: {})
        TimerControlsView(state: .completed, onStart: {}, onPause: {}, onResume: {}, onStop: {}, onCompleteEarly: {})
    }
}
