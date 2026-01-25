//
//  SimpleProgressView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Simple progress display for kid-friendly stats.
struct SimpleProgressView: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }

            // Value
            Text("\(value)")
                .font(.title2.bold())
                .foregroundColor(.primary)
                .contentTransition(.numericText())

            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Streak Display

/// Visual streak display with flame animation.
struct StreakDisplay: View {
    let currentStreak: Int
    let isActive: Bool

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 16) {
            // Flame icon with animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.2), .red.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: isActive ? "flame.fill" : "flame")
                    .font(.title)
                    .foregroundColor(isActive ? .orange : .gray)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(currentStreak) Day Streak")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(streakMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .onAppear {
            if isActive {
                withAnimation(
                    .easeInOut(duration: 0.6)
                    .repeatCount(3, autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
        }
    }

    private var streakMessage: String {
        if currentStreak == 0 {
            return "Start a focus session to begin!"
        } else if currentStreak < 3 {
            return "You're building momentum!"
        } else if currentStreak < 7 {
            return "Amazing progress!"
        } else {
            return "You're on fire! Keep it up!"
        }
    }
}

// MARK: - Points Card

/// Simple points display card.
struct TodayPointsCard: View {
    let points: Int
    let weeklyTotal: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Points")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Keep earning!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Points display with star
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)

                    Text("\(points)")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                }
            }

            // Weekly progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("This week: \(weeklyTotal) points")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }

                // Simple progress visualization
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: min(geometry.size.width * progressPercentage, geometry.size.width), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var progressPercentage: CGFloat {
        // Assume 500 points is a good weekly target
        let target = 500.0
        return CGFloat(min(Double(weeklyTotal) / target, 1.0))
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            SimpleProgressView(title: "Activities", value: 5, icon: "checkmark.circle.fill", color: .green)
            SimpleProgressView(title: "Minutes", value: 120, icon: "clock.fill", color: .blue)
            SimpleProgressView(title: "Points", value: 85, icon: "star.fill", color: .yellow)
        }
        .padding(.horizontal)

        StreakDisplay(currentStreak: 5, isActive: true)
            .padding(.horizontal)

        TodayPointsCard(points: 45, weeklyTotal: 230)
            .padding(.horizontal)
    }
}
