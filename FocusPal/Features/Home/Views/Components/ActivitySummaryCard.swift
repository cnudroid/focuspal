//
//  ActivitySummaryCard.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Compact card displaying an activity summary with icon, name, duration, and mood.
struct ActivitySummaryCard: View {
    let activity: Activity
    let category: Category?

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(Color(hex: category?.colorHex ?? "#4A90D9"))
                    .frame(width: 44, height: 44)

                Image(systemName: category?.iconName ?? "circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Category name
                Text(category?.name ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                // Time info
                HStack(spacing: 8) {
                    Text(formatTime(activity.startTime))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text("\(activity.durationMinutes) min")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if activity.mood != .none {
                        Text(activity.mood.emoji)
                            .font(.caption)
                    }
                }
            }

            Spacer()

            // Chevron for details
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Simplified summary card for quick display
struct CompactActivityCard: View {
    let iconName: String
    let colorHex: String
    let categoryName: String
    let durationMinutes: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color(hex: colorHex))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(categoryName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(durationMinutes) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview("Activity Summary") {
    VStack(spacing: 12) {
        let testChild = Child(name: "Test", age: 8)
        let testCategory = Category(
            name: "Homework",
            iconName: "book.fill",
            colorHex: "#4A90D9",
            childId: testChild.id
        )
        let testActivity = Activity(
            categoryId: testCategory.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-1800),
            endTime: Date(),
            mood: .happy
        )

        ActivitySummaryCard(
            activity: testActivity,
            category: testCategory
        )

        CompactActivityCard(
            iconName: "gamecontroller.fill",
            colorHex: "#4ECDC4",
            categoryName: "Playing",
            durationMinutes: 45
        )
    }
    .padding()
    .background(Color(.systemBackground))
}
