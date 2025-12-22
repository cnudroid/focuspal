//
//  BalanceMeter.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Visual balance meter showing activity distribution score.
struct BalanceMeter: View {
    let score: Int

    private var balanceLevel: BalanceLevel {
        switch score {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .fair
        default: return .needsImprovement
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Activity Balance")
                    .font(.headline)

                Spacer()

                Text(balanceLevel.rawValue)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: balanceLevel.color))
            }

            // Meter bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))

                    // Gradient fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.red, .orange, .yellow, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .mask(
                            RoundedRectangle(cornerRadius: 8)
                                .frame(width: geometry.size.width * CGFloat(score) / 100)
                        )

                    // Indicator
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .shadow(radius: 2)
                        .offset(x: geometry.size.width * CGFloat(score) / 100 - 10)
                }
            }
            .frame(height: 16)

            // Labels
            HStack {
                Text("Unbalanced")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(score)%")
                    .font(.caption)
                    .fontWeight(.bold)

                Spacer()

                Text("Balanced")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8)
    }
}

#Preview {
    VStack(spacing: 20) {
        BalanceMeter(score: 85)
        BalanceMeter(score: 65)
        BalanceMeter(score: 45)
        BalanceMeter(score: 25)
    }
    .padding()
    .background(Color(.systemGray6))
}
