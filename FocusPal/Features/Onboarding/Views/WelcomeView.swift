//
//  WelcomeView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Welcome screen in onboarding flow.
struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon/illustration
            Image(systemName: "timer.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 16) {
                Text("Welcome to FocusPal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Help your child develop healthy habits by tracking activities and balancing their time.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Features list
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "timer", title: "Visual Timers", description: "Fun countdown timers for focused activities")
                FeatureRow(icon: "chart.bar.fill", title: "Track Progress", description: "See daily and weekly activity summaries")
                FeatureRow(icon: "star.fill", title: "Earn Rewards", description: "Unlock achievements for staying balanced")
            }
            .padding(.horizontal)

            Spacer()

            // Continue button
            Button(action: onContinue) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    WelcomeView { }
}
