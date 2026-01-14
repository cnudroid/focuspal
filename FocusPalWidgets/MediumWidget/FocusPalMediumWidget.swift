//
//  FocusPalMediumWidget.swift
//  FocusPalWidgets
//
//  Medium home screen widget with progress and quick actions.
//

import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct MediumWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MediumWidgetEntry {
        MediumWidgetEntry(
            date: Date(),
            childName: "Emma",
            streak: 7,
            todayMinutes: 45,
            categories: [
                CategoryProgress(id: UUID(), name: "Homework", iconName: "book.fill", colorHex: "#4A90D9", minutes: 30, goalMinutes: 60),
                CategoryProgress(id: UUID(), name: "Reading", iconName: "text.book.closed.fill", colorHex: "#50C878", minutes: 15, goalMinutes: 30)
            ],
            quickCategories: [
                QuickCategory(id: UUID(), name: "Homework", iconName: "book.fill", colorHex: "#4A90D9", durationMinutes: 30),
                QuickCategory(id: UUID(), name: "Reading", iconName: "text.book.closed.fill", colorHex: "#50C878", durationMinutes: 20),
                QuickCategory(id: UUID(), name: "Practice", iconName: "music.note", colorHex: "#FF6B6B", durationMinutes: 15)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MediumWidgetEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MediumWidgetEntry>) -> Void) {
        let entry = createEntry()

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    private func createEntry() -> MediumWidgetEntry {
        let widgetData = WidgetData.load() ?? .empty

        return MediumWidgetEntry(
            date: Date(),
            childName: widgetData.childName,
            streak: widgetData.currentStreak,
            todayMinutes: widgetData.todayTotalMinutes,
            categories: widgetData.todayCategories,
            quickCategories: widgetData.topCategories
        )
    }
}

// MARK: - Timeline Entry

struct MediumWidgetEntry: TimelineEntry {
    let date: Date
    let childName: String
    let streak: Int
    let todayMinutes: Int
    let categories: [CategoryProgress]
    let quickCategories: [QuickCategory]
}

// MARK: - Widget View

struct MediumWidgetView: View {
    var entry: MediumWidgetProvider.Entry

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Stats
            VStack(alignment: .leading, spacing: 8) {
                // Child name
                Text(entry.childName)
                    .font(.headline)
                    .lineLimit(1)

                // Streak
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(entry.streak)")
                        .font(.title2.bold())
                        .foregroundStyle(.orange)
                }

                // Today's time
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("\(entry.todayMinutes) min")
                        .font(.subheadline.bold())
                }

                Spacer()

                // Mini progress bars for categories
                if !entry.categories.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(entry.categories.prefix(2)) { category in
                            HStack(spacing: 4) {
                                Image(systemName: category.iconName)
                                    .font(.caption2)
                                    .foregroundStyle(Color(hex: category.colorHex) ?? .blue)
                                Text("\(category.minutes)m")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Divider()

            // Right side - Quick Actions
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Start")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                ForEach(entry.quickCategories.prefix(3)) { category in
                    Link(destination: URL(string: "\(WidgetConstants.DeepLink.timerWithCategory)\(category.id.uuidString)")!) {
                        HStack(spacing: 8) {
                            Image(systemName: category.iconName)
                                .font(.caption)
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(Color(hex: category.colorHex) ?? .blue)
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 0) {
                                Text(category.name)
                                    .font(.caption.bold())
                                    .lineLimit(1)
                                Text("\(category.durationMinutes) min")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "play.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }

                if entry.quickCategories.isEmpty {
                    Text("No categories set up")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Configuration

struct FocusPalMediumWidget: Widget {
    let kind: String = WidgetConstants.WidgetKind.medium

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MediumWidgetProvider()) { entry in
            MediumWidgetView(entry: entry)
        }
        .configurationDisplayName("Focus Dashboard")
        .description("See your progress and quickly start timers.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    FocusPalMediumWidget()
} timeline: {
    MediumWidgetEntry(
        date: Date(),
        childName: "Emma",
        streak: 7,
        todayMinutes: 45,
        categories: [
            CategoryProgress(id: UUID(), name: "Homework", iconName: "book.fill", colorHex: "#4A90D9", minutes: 30, goalMinutes: 60)
        ],
        quickCategories: [
            QuickCategory(id: UUID(), name: "Homework", iconName: "book.fill", colorHex: "#4A90D9", durationMinutes: 30),
            QuickCategory(id: UUID(), name: "Reading", iconName: "text.book.closed.fill", colorHex: "#50C878", durationMinutes: 20)
        ]
    )
}
