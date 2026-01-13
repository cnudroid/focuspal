//
//  FocusPalWidgets.swift
//  FocusPalWidgets
//
//  Timer Live Activity for lock screen display.
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Widget Bundle

@main
struct FocusPalWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FocusPalTimerLiveActivity()
    }
}

// MARK: - Live Activity Widget

struct FocusPalTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusPalTimerAttributes.self) { context in
            // Lock Screen View
            TimerLockScreenView(
                childName: context.attributes.childName,
                categoryName: context.attributes.categoryName,
                categoryIconName: context.attributes.categoryIconName,
                categoryColorHex: context.attributes.categoryColorHex,
                remainingTime: context.state.remainingTime,
                totalDuration: context.attributes.totalDuration,
                isPaused: context.state.isPaused,
                timerEndDate: context.state.timerEndDate
            )
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatTime(context.state.remainingTime))
                        .font(.title2.bold())
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.attributes.childName) - \(context.attributes.categoryName)")
                        .font(.caption)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                Text(formatTime(context.state.remainingTime))
                    .font(.caption.bold())
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}

// MARK: - Lock Screen View

struct TimerLockScreenView: View {
    let childName: String
    let categoryName: String
    let categoryIconName: String
    let categoryColorHex: String
    let remainingTime: TimeInterval
    let totalDuration: TimeInterval
    let isPaused: Bool
    let timerEndDate: Date

    private var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return remainingTime / totalDuration
    }

    private var categoryColor: Color {
        Color(hex: categoryColorHex) ?? .blue
    }

    private var timerColor: Color {
        if isPaused { return .orange }
        if progress > 0.5 { return .green }
        if progress > 0.25 { return .yellow }
        return .red
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Category icon with progress ring
                ZStack {
                    Circle()
                        .stroke(categoryColor.opacity(0.3), lineWidth: 3)
                        .frame(width: 44, height: 44)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(categoryColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                    Image(systemName: isPaused ? "pause.fill" : categoryIconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isPaused ? .orange : categoryColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(childName)
                        .font(.headline)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(isPaused ? .orange : .green)
                            .frame(width: 6, height: 6)
                        Text(isPaused ? "Paused" : categoryName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isPaused {
                    Text(formatTime(remainingTime))
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.orange)
                } else {
                    Text(timerInterval: Date()...timerEndDate, countsDown: true)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(timerColor)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)
                    Capsule()
                        .fill(timerColor)
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .activityBackgroundTint(.black)
    }
}

// MARK: - Helper Function

private func formatTime(_ seconds: TimeInterval) -> String {
    let totalSeconds = Int(max(0, seconds))
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let secs = totalSeconds % 60

    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    } else {
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        let length = hexSanitized.count
        guard length == 6 || length == 8 else { return nil }
        if length == 6 {
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        } else {
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        }
    }
}

// MARK: - Preview

#Preview("Lock Screen", as: .content, using: FocusPalTimerAttributes(
    childName: "Emma",
    categoryName: "Homework",
    categoryIconName: "book.fill",
    categoryColorHex: "#4A90D9",
    childId: UUID(),
    totalDuration: 1800
)) {
    FocusPalTimerLiveActivity()
} contentStates: {
    FocusPalTimerAttributes.ContentState(
        remainingTime: 1200,
        isPaused: false,
        timerEndDate: Date().addingTimeInterval(1200),
        totalDuration: 1800
    )
}
