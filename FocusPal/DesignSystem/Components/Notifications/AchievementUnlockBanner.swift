//
//  AchievementUnlockBanner.swift
//  FocusPal
//
//  Created by FocusPal Team
//
//  A celebration banner shown when an achievement is unlocked

import SwiftUI

/// Banner view displaying achievement unlock notification
struct AchievementUnlockBanner: View {
    let notification: AchievementNotificationHelper.UnlockNotification
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 16) {
            // Achievement icon
            Image(systemName: notification.iconName)
                .font(.system(size: 32))
                .foregroundColor(.yellow)
                .symbolEffect(.bounce, value: isVisible)

            VStack(alignment: .leading, spacing: 4) {
                Text("Achievement Unlocked!")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.yellow.opacity(0.5), lineWidth: 2)
        )
        .padding(.horizontal)
        .offset(y: isVisible ? 0 : -100)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }

            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                dismissWithAnimation()
            }
        }
    }

    private func dismissWithAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

#Preview {
    VStack {
        Spacer()

        AchievementUnlockBanner(
            notification: AchievementNotificationHelper.UnlockNotification(
                achievement: Achievement(
                    achievementTypeId: AchievementType.firstTimer.rawValue,
                    childId: UUID(),
                    unlockedDate: Date(),
                    targetValue: 1
                )
            ),
            onDismiss: {}
        )

        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.1))
}
