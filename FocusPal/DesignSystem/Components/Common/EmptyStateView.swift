//
//  EmptyStateView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Empty state view with icon, title, message, and optional action.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: FPSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            VStack(spacing: FPSpacing.xs) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(FPSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    static let noActivities = EmptyStateView(
        icon: "calendar.badge.plus",
        title: "No Activities Yet",
        message: "Start a timer or log an activity to see your progress here.",
        actionTitle: "Start Timer"
    ) { }

    static let noAchievements = EmptyStateView(
        icon: "star.circle",
        title: "No Achievements Yet",
        message: "Complete activities to earn badges and rewards!",
        actionTitle: nil,
        action: nil
    )

    static let noChildren = EmptyStateView(
        icon: "person.circle",
        title: "No Profiles Yet",
        message: "Create a child profile to get started.",
        actionTitle: "Add Profile"
    ) { }
}

#Preview {
    VStack {
        EmptyStateView.noActivities
    }
}
