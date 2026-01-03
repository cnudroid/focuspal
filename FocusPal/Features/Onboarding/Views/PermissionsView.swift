//
//  PermissionsView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import UserNotifications

/// Permissions request screen in onboarding flow.
struct PermissionsView: View {
    let onComplete: () -> Void

    @State private var notificationsGranted = false
    @State private var showingNotificationAlert = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            VStack(spacing: 16) {
                Text("Stay Connected")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Enable notifications to get timer alerts and achievement updates.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Permission cards
            VStack(spacing: 16) {
                PermissionCard(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Timer completion, goal warnings, achievements",
                    isEnabled: notificationsGranted,
                    action: requestNotifications
                )
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 16) {
                Button(action: onComplete) {
                    Text(notificationsGranted ? "Continue" : "Skip for Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(14)
                }

                if !notificationsGranted {
                    Text("You can enable notifications later in Settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func requestNotifications() {
        Task { @MainActor in
            do {
                let center = UNUserNotificationCenter.current()
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                notificationsGranted = granted
            } catch {
                print("Notification permission error: \(error)")
                // Still allow user to continue even if permission request fails
                notificationsGranted = false
            }
        }
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isEnabled ? .green : .accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button("Enable") {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    PermissionsView { }
}
