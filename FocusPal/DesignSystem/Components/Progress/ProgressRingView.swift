//
//  ProgressRingView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Circular progress ring indicator with animated progress display.
/// Shows progress as a percentage with customizable colors and size.
struct ProgressRingView: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let color: Color
    let backgroundColor: Color

    @State private var animatedProgress: Double = 0

    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        color: Color = .blue,
        backgroundColor: Color = Color(.systemGray5)
    ) {
        self.progress = min(max(progress, 0), 1) // Clamp between 0 and 1
        self.lineWidth = lineWidth
        self.color = color
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: animatedProgress)
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

/// Progress ring with percentage text in the center
struct ProgressRingWithLabel: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    let showPercentage: Bool
    let label: String?

    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        color: Color = .blue,
        showPercentage: Bool = true,
        label: String? = nil
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.color = color
        self.showPercentage = showPercentage
        self.label = label
    }

    var body: some View {
        ZStack {
            ProgressRingView(
                progress: progress,
                lineWidth: lineWidth,
                color: color
            )

            VStack(spacing: 4) {
                if showPercentage {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                }

                if let label = label {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview("Basic Ring") {
    VStack(spacing: 40) {
        ProgressRingView(progress: 0.3)
            .frame(width: 100, height: 100)

        ProgressRingView(progress: 0.7, color: .green)
            .frame(width: 100, height: 100)

        ProgressRingView(progress: 1.0, color: .red)
            .frame(width: 100, height: 100)
    }
    .padding()
}

#Preview("Ring with Label") {
    VStack(spacing: 40) {
        ProgressRingWithLabel(
            progress: 0.65,
            label: "Today"
        )
        .frame(width: 150, height: 150)

        ProgressRingWithLabel(
            progress: 0.45,
            color: .orange,
            label: "This Week"
        )
        .frame(width: 150, height: 150)
    }
    .padding()
}
