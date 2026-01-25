//
//  TaskCard.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Kid-friendly task card with large touch targets and colorful design.
struct TaskCard: View {
    let task: ScheduledTask
    let category: Category?
    let isActive: Bool
    let onStart: () -> Void
    let onComplete: () -> Void

    @State private var isPressed = false

    private var cardColor: Color {
        if let hex = category?.colorHex {
            return Color(hex: hex)
        }
        return .blue
    }

    var body: some View {
        Button {
            if isActive || !task.isUpcoming {
                onStart()
            }
        } label: {
            VStack(spacing: 12) {
                // Header row with icon and status
                HStack {
                    // Category icon
                    ZStack {
                        Circle()
                            .fill(cardColor.opacity(0.2))
                            .frame(width: 50, height: 50)

                        Image(systemName: category?.iconName ?? "circle.fill")
                            .font(.title2)
                            .foregroundColor(cardColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            // Time
                            Label(task.scheduledDate.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            // Duration
                            Text("\(task.durationMinutes) min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Status indicator or action button
                    if isActive {
                        activeIndicator
                    } else if task.isInstanceCompleted {
                        completedIndicator
                    } else if task.isUpcoming {
                        upcomingIndicator
                    }
                }

                // Active task progress bar
                if isActive {
                    progressBar
                }

                // Start button for active tasks
                if isActive {
                    startButton
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: isActive ? cardColor.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? cardColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(BounceButtonStyle())
        .disabled(task.isInstanceCompleted)
    }

    // MARK: - Subviews

    private var activeIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            Text("NOW")
                .font(.caption.bold())
                .foregroundColor(.green)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.15))
        .cornerRadius(12)
    }

    private var completedIndicator: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.title2)
            .foregroundColor(.green)
    }

    private var upcomingIndicator: some View {
        Image(systemName: "clock")
            .font(.title2)
            .foregroundColor(.secondary.opacity(0.5))
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(cardColor.opacity(0.2))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(cardColor)
                    .frame(width: geometry.size.width * progressPercentage, height: 8)
            }
        }
        .frame(height: 8)
    }

    private var startButton: some View {
        Button(action: onStart) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.headline)
                Text("Start Timer")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(cardColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .buttonStyle(BounceButtonStyle())
    }

    private var progressPercentage: Double {
        let now = Date()
        let elapsed = now.timeIntervalSince(task.scheduledDate)
        return min(max(elapsed / task.duration, 0), 1)
    }
}

// MARK: - Compact Task Card

/// Smaller task card for upcoming tasks list.
struct CompactTaskCard: View {
    let task: ScheduledTask
    let category: Category?
    let onTap: () -> Void

    private var cardColor: Color {
        if let hex = category?.colorHex {
            return Color(hex: hex)
        }
        return .blue
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(cardColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: category?.iconName ?? "circle.fill")
                        .font(.body)
                        .foregroundColor(cardColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(task.scheduledDate.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Duration badge
                Text("\(task.durationMinutes)m")
                    .font(.caption.weight(.medium))
                    .foregroundColor(cardColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(cardColor.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
}

#Preview("Active Task") {
    TaskCardPreviewWrapper()
}

private struct TaskCardPreviewWrapper: View {
    let childId = UUID()
    let categoryId = UUID()

    var body: some View {
        VStack(spacing: 16) {
            TaskCard(
                task: ScheduledTask(
                    id: UUID(),
                    childId: childId,
                    categoryId: categoryId,
                    title: "Reading Time",
                    scheduledDate: Date(),
                    duration: 1800,
                    isCompleted: false,
                    calendarSource: .app
                ),
                category: Category.defaultCategories(for: childId).first,
                isActive: true,
                onStart: {},
                onComplete: {}
            )

            CompactTaskCard(
                task: ScheduledTask(
                    id: UUID(),
                    childId: childId,
                    categoryId: categoryId,
                    title: "Math Practice",
                    scheduledDate: Date().addingTimeInterval(3600),
                    duration: 1200,
                    isCompleted: false,
                    calendarSource: .app
                ),
                category: Category.defaultCategories(for: childId).first,
                onTap: {}
            )
        }
        .padding()
    }
}
