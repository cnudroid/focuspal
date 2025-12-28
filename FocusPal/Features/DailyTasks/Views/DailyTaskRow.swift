//
//  DailyTaskRow.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Reusable row component for displaying a daily task with points
struct DailyTaskRow: View {
    let task: DailyTaskItem
    @State private var showPointAnimation = false

    var body: some View {
        HStack(spacing: 12) {
            // Category icon with completion indicator
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: task.iconName)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(hex: task.colorHex))
                    .cornerRadius(12)

                // Completion status indicator
                completionIndicator
            }

            // Task details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(task.categoryName)
                        .font(.headline)
                        .foregroundColor(.fpTextPrimary)

                    if !task.isComplete {
                        Text("incomplete")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.fpWarning)
                            .cornerRadius(4)
                    }
                }

                Text(task.timeRange)
                    .font(.caption)
                    .foregroundColor(.fpTextSecondary)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(task.durationMinutes) min")
                        .font(.caption)
                }
                .foregroundColor(.fpTextTertiary)
            }

            Spacer()

            // Points display
            pointsView
        }
        .padding()
        .background(Color.fpSecondaryBackground)
        .cornerRadius(16)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                showPointAnimation = true
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var completionIndicator: some View {
        if task.isComplete {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.fpSuccess)
                .background(Circle().fill(Color.fpBackground).frame(width: 14, height: 14))
                .offset(x: 4, y: 4)
        } else {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.fpWarning)
                .background(Circle().fill(Color.fpBackground).frame(width: 14, height: 14))
                .offset(x: 4, y: 4)
        }
    }

    @ViewBuilder
    private var pointsView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                if task.bonusPoints > 0 {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }

                Text(pointsText)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(pointsColor)
                    .scaleEffect(showPointAnimation ? 1.0 : 0.5)
                    .opacity(showPointAnimation ? 1.0 : 0.0)
            }

            if task.bonusPoints > 0 {
                Text("+\(task.bonusPoints) bonus")
                    .font(.caption2)
                    .foregroundColor(.fpSuccess)
            }

            Text("pts")
                .font(.caption2)
                .foregroundColor(.fpTextTertiary)
        }
    }

    // MARK: - Computed Properties

    private var pointsText: String {
        let points = task.netPoints
        if points >= 0 {
            return "+\(points)"
        } else {
            return "\(points)"
        }
    }

    private var pointsColor: Color {
        if task.netPoints > 0 {
            return .fpSuccess
        } else if task.netPoints < 0 {
            return .fpError
        } else {
            return .fpTextSecondary
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        DailyTaskRow(task: DailyTaskItem(
            id: UUID(),
            activityId: UUID(),
            categoryName: "Homework",
            iconName: "book.fill",
            colorHex: "#4A90D9",
            durationMinutes: 25,
            timeRange: "2:00 PM - 2:25 PM",
            startTime: Date(),
            isComplete: true,
            pointsEarned: 10,
            bonusPoints: 5,
            pointsDeducted: 0
        ))

        DailyTaskRow(task: DailyTaskItem(
            id: UUID(),
            activityId: UUID(),
            categoryName: "Reading",
            iconName: "text.book.closed.fill",
            colorHex: "#7B68EE",
            durationMinutes: 30,
            timeRange: "3:00 PM - 3:30 PM",
            startTime: Date(),
            isComplete: true,
            pointsEarned: 10,
            bonusPoints: 0,
            pointsDeducted: 0
        ))

        DailyTaskRow(task: DailyTaskItem(
            id: UUID(),
            activityId: UUID(),
            categoryName: "Screen Time",
            iconName: "tv.fill",
            colorHex: "#FF6B6B",
            durationMinutes: 45,
            timeRange: "4:00 PM - 4:45 PM",
            startTime: Date(),
            isComplete: false,
            pointsEarned: 0,
            bonusPoints: 0,
            pointsDeducted: 5
        ))
    }
    .padding()
}
