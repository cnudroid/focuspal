//
//  FocusPalSmallWidget.swift
//  FocusPalWidgets
//
//  Small home screen widget showing streak and today's focus time.
//

import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct SmallWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SmallWidgetEntry {
        SmallWidgetEntry(
            date: Date(),
            childName: "Emma",
            streak: 7,
            todayMinutes: 45,
            hasActiveTimer: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SmallWidgetEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SmallWidgetEntry>) -> Void) {
        let entry = createEntry()

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    private func createEntry() -> SmallWidgetEntry {
        let widgetData = WidgetData.load() ?? .empty

        return SmallWidgetEntry(
            date: Date(),
            childName: widgetData.childName,
            streak: widgetData.currentStreak,
            todayMinutes: widgetData.todayTotalMinutes,
            hasActiveTimer: widgetData.activeTimer != nil
        )
    }
}

// MARK: - Timeline Entry

struct SmallWidgetEntry: TimelineEntry {
    let date: Date
    let childName: String
    let streak: Int
    let todayMinutes: Int
    let hasActiveTimer: Bool
}

// MARK: - Widget View

struct SmallWidgetView: View {
    var entry: SmallWidgetProvider.Entry

    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with child name
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundStyle(.blue)
                Text(entry.childName)
                    .font(.caption.bold())
                    .lineLimit(1)
            }

            Spacer()

            // Streak display
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(entry.streak)")
                    .font(.title.bold())
                    .foregroundStyle(.orange)
                Text("day\(entry.streak == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Today's time
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Text("\(entry.todayMinutes) min")
                    .font(.subheadline.bold())
                Text("today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Active timer indicator
            if entry.hasActiveTimer {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text("Timer active")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Configuration

struct FocusPalSmallWidget: Widget {
    let kind: String = WidgetConstants.WidgetKind.small

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SmallWidgetProvider()) { entry in
            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Focus Summary")
        .description("See your streak and today's focus time.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    FocusPalSmallWidget()
} timeline: {
    SmallWidgetEntry(date: Date(), childName: "Emma", streak: 7, todayMinutes: 45, hasActiveTimer: false)
    SmallWidgetEntry(date: Date(), childName: "Emma", streak: 7, todayMinutes: 60, hasActiveTimer: true)
}
