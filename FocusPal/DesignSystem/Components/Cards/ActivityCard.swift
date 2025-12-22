//
//  ActivityCard.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Card displaying an activity with category info and duration.
struct ActivityCard: View {
    let categoryName: String
    let iconName: String
    let colorHex: String
    let duration: String
    let timeRange: String
    let onTap: (() -> Void)?

    init(
        categoryName: String,
        iconName: String,
        colorHex: String,
        duration: String,
        timeRange: String,
        onTap: (() -> Void)? = nil
    ) {
        self.categoryName = categoryName
        self.iconName = iconName
        self.colorHex = colorHex
        self.duration = duration
        self.timeRange = timeRange
        self.onTap = onTap
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: FPSpacing.md) {
                // Category icon
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(hex: colorHex))
                    .cornerRadius(12)

                // Info
                VStack(alignment: .leading, spacing: FPSpacing.xxxs) {
                    Text(categoryName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(timeRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Duration
                Text(duration)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(FPSpacing.md)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .cardShadow()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        ActivityCard(
            categoryName: "Homework",
            iconName: "book.fill",
            colorHex: "#4A90D9",
            duration: "45 min",
            timeRange: "2:00 PM - 2:45 PM"
        ) { }

        ActivityCard(
            categoryName: "Reading",
            iconName: "text.book.closed.fill",
            colorHex: "#7B68EE",
            duration: "30 min",
            timeRange: "3:00 PM - 3:30 PM",
            onTap: nil
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
