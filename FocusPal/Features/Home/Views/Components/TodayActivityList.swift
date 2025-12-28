//
//  TodayActivityList.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// List of today's activities displayed on the home screen.
struct TodayActivityList: View {
    let activities: [ActivityDisplayItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Activities")
                .font(.headline)
                .padding(.horizontal)

            if activities.isEmpty {
                EmptyActivityView()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(activities) { activity in
                        ActivityRowView(activity: activity)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ActivityRowView: View {
    let activity: ActivityDisplayItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.iconName)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color(hex: activity.colorHex))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.categoryName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(activity.timeRange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(activity.durationMinutes) min")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct EmptyActivityView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No activities yet today")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Start a timer or log an activity to get started!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

/// Display model for activity list items
struct ActivityDisplayItem: Identifiable {
    let id: UUID
    let categoryName: String
    let iconName: String
    let colorHex: String
    let durationMinutes: Int
    let timeRange: String
    let startTime: Date // For sorting
    let isComplete: Bool

    init(
        id: UUID,
        categoryName: String,
        iconName: String,
        colorHex: String,
        durationMinutes: Int,
        timeRange: String,
        startTime: Date = Date(),
        isComplete: Bool = true
    ) {
        self.id = id
        self.categoryName = categoryName
        self.iconName = iconName
        self.colorHex = colorHex
        self.durationMinutes = durationMinutes
        self.timeRange = timeRange
        self.startTime = startTime
        self.isComplete = isComplete
    }
}

#Preview {
    TodayActivityList(activities: [
        ActivityDisplayItem(
            id: UUID(),
            categoryName: "Homework",
            iconName: "book.fill",
            colorHex: "#4A90D9",
            durationMinutes: 45,
            timeRange: "2:00 PM - 2:45 PM"
        )
    ])
}
