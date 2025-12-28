//
//  DailySummaryCard.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Card component showing summary of daily points
struct DailySummaryCard: View {
    let totalEarned: Int
    let totalBonus: Int
    let totalDeducted: Int
    let streakDays: Int
    let completedCount: Int
    let incompleteCount: Int

    @State private var showAnimation = false

    /// Net points for the day
    private var netPoints: Int {
        totalEarned + totalBonus - totalDeducted
    }

    /// Whether this is a positive day
    private var isPositiveDay: Bool {
        netPoints > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with net points
            headerSection

            Divider()
                .padding(.horizontal)

            // Point breakdown
            breakdownSection

            // Streak indicator (if applicable)
            if streakDays > 1 {
                Divider()
                    .padding(.horizontal)
                streakSection
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.fpSecondaryBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
                showAnimation = true
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            // Celebratory icon for positive days
            if isPositiveDay && showAnimation {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .scaleEffect(showAnimation ? 1.0 : 0.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(Double(index) * 0.1), value: showAnimation)
                    }
                }
            }

            Text("Today's Points")
                .font(.subheadline)
                .foregroundColor(.fpTextSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(netPoints >= 0 ? "+\(netPoints)" : "\(netPoints)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(netPoints >= 0 ? .fpSuccess : .fpError)
                    .scaleEffect(showAnimation ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showAnimation)

                Text("pts")
                    .font(.title3)
                    .foregroundColor(.fpTextTertiary)
            }

            // Activity summary
            HStack(spacing: 16) {
                Label("\(completedCount) done", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.fpSuccess)

                if incompleteCount > 0 {
                    Label("\(incompleteCount) incomplete", systemImage: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.fpWarning)
                }
            }
        }
        .padding()
    }

    private var breakdownSection: some View {
        HStack(spacing: 0) {
            // Earned column
            VStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(.fpSuccess)

                Text("+\(totalEarned + totalBonus)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.fpSuccess)

                Text("Earned")
                    .font(.caption)
                    .foregroundColor(.fpTextSecondary)

                if totalBonus > 0 {
                    Text("(+\(totalBonus) bonus)")
                        .font(.caption2)
                        .foregroundColor(.fpSuccess.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)

            // Divider
            Rectangle()
                .fill(Color.fpTextTertiary.opacity(0.3))
                .frame(width: 1)
                .padding(.vertical, 8)

            // Deducted column
            VStack(spacing: 4) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(totalDeducted > 0 ? .fpError : .fpTextTertiary)

                Text("-\(totalDeducted)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(totalDeducted > 0 ? .fpError : .fpTextTertiary)

                Text("Deducted")
                    .font(.caption)
                    .foregroundColor(.fpTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
    }

    private var streakSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.title3)
                .foregroundColor(.orange)
                .scaleEffect(showAnimation ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showAnimation)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streakDays) Day Streak!")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.fpTextPrimary)

                Text("Keep up the great work!")
                    .font(.caption)
                    .foregroundColor(.fpTextSecondary)
            }

            Spacer()

            // Streak stars
            HStack(spacing: 2) {
                ForEach(0..<min(streakDays, 5), id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.1), .yellow.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

// MARK: - Preview

#Preview("Positive Day") {
    DailySummaryCard(
        totalEarned: 30,
        totalBonus: 10,
        totalDeducted: 5,
        streakDays: 3,
        completedCount: 4,
        incompleteCount: 1
    )
    .padding()
}

#Preview("Perfect Day") {
    DailySummaryCard(
        totalEarned: 50,
        totalBonus: 15,
        totalDeducted: 0,
        streakDays: 7,
        completedCount: 5,
        incompleteCount: 0
    )
    .padding()
}

#Preview("Negative Day") {
    DailySummaryCard(
        totalEarned: 10,
        totalBonus: 0,
        totalDeducted: 20,
        streakDays: 0,
        completedCount: 1,
        incompleteCount: 4
    )
    .padding()
}
