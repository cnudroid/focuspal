//
//  FocusPalLargeWidget.swift
//  FocusPalWidgets
//
//  Large home screen widget with weekly overview and activities.
//

import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct LargeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LargeWidgetEntry {
        LargeWidgetEntry(
            date: Date(),
            childName: "Emma",
            streak: 7,
            todayMinutes: 45,
            totalPoints: 1250,
            weeklyMinutes: [30, 45, 60, 25, 40, 55, 45],
            recentActivities: [
                RecentActivity(id: UUID(), categoryName: "Homework", iconName: "book.fill", colorHex: "#4A90D9", durationMinutes: 30, completedAt: Date()),
                RecentActivity(id: UUID(), categoryName: "Reading", iconName: "text.book.closed.fill", colorHex: "#50C878", durationMinutes: 15, completedAt: Date().addingTimeInterval(-3600))
            ],
            quickCategories: [
                QuickCategory(id: UUID(), name: "Homework", iconName: "book.fill", colorHex: "#4A90D9", durationMinutes: 30),
                QuickCategory(id: UUID(), name: "Reading", iconName: "text.book.closed.fill", colorHex: "#50C878", durationMinutes: 20)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LargeWidgetEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LargeWidgetEntry>) -> Void) {
        let entry = createEntry()

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    private func createEntry() -> LargeWidgetEntry {
        let widgetData = WidgetData.load() ?? .empty

        return LargeWidgetEntry(
            date: Date(),
            childName: widgetData.childName,
            streak: widgetData.currentStreak,
            todayMinutes: widgetData.todayTotalMinutes,
            totalPoints: widgetData.totalPoints,
            weeklyMinutes: widgetData.weeklyMinutes,
            recentActivities: widgetData.recentActivities,
            quickCategories: widgetData.topCategories
        )
    }
}

// MARK: - Timeline Entry

struct LargeWidgetEntry: TimelineEntry {
    let date: Date
    let childName: String
    let streak: Int
    let todayMinutes: Int
    let totalPoints: Int
    let weeklyMinutes: [Int]
    let recentActivities: [RecentActivity]
    let quickCategories: [QuickCategory]
}

// MARK: - Widget View

struct LargeWidgetView: View {
    var entry: LargeWidgetProvider.Entry

    private let weekDays = ["M", "T", "W", "T", "F", "S", "S"]

    private var maxWeeklyMinutes: Int {
        max(entry.weeklyMinutes.max() ?? 1, 1)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.childName)
                        .font(.headline)
                    Text("Weekly Overview")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Stats badges
                HStack(spacing: 12) {
                    StatBadge(icon: "flame.fill", value: "\(entry.streak)", color: .orange)
                    StatBadge(icon: "star.fill", value: "\(entry.totalPoints)", color: .yellow)
                }
            }

            // Weekly chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index == 6 ? Color.blue : Color.blue.opacity(0.5))
                            .frame(height: CGFloat(entry.weeklyMinutes[index]) / CGFloat(maxWeeklyMinutes) * 50)
                            .frame(minHeight: 4)

                        // Day label
                        Text(weekDays[index])
                            .font(.caption2)
                            .foregroundStyle(index == 6 ? .primary : .secondary)
                    }
                }
            }
            .frame(height: 70)

            Divider()

            // Bottom section
            HStack(alignment: .top, spacing: 16) {
                // Recent activities
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recent")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    if entry.recentActivities.isEmpty {
                        Text("No activities yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(entry.recentActivities.prefix(3)) { activity in
                            HStack(spacing: 6) {
                                Image(systemName: activity.iconName)
                                    .font(.caption2)
                                    .foregroundStyle(Color(hex: activity.colorHex) ?? .blue)
                                Text(activity.categoryName)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(activity.durationMinutes)m")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Divider()

                // Quick actions
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quick Start")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ForEach(entry.quickCategories.prefix(3)) { category in
                        Link(destination: URL(string: "\(WidgetConstants.DeepLink.timerWithCategory)\(category.id.uuidString)")!) {
                            HStack(spacing: 6) {
                                Image(systemName: category.iconName)
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: category.colorHex) ?? .blue)
                                Text(category.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "play.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            Text(value)
                .font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Widget Configuration

struct FocusPalLargeWidget: Widget {
    let kind: String = WidgetConstants.WidgetKind.large

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LargeWidgetProvider()) { entry in
            LargeWidgetView(entry: entry)
        }
        .configurationDisplayName("Weekly Focus")
        .description("See your weekly progress and recent activities.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemLarge) {
    FocusPalLargeWidget()
} timeline: {
    LargeWidgetEntry(
        date: Date(),
        childName: "Emma",
        streak: 7,
        todayMinutes: 45,
        totalPoints: 1250,
        weeklyMinutes: [30, 45, 60, 25, 40, 55, 45],
        recentActivities: [
            RecentActivity(id: UUID(), categoryName: "Homework", iconName: "book.fill", colorHex: "#4A90D9", durationMinutes: 30, completedAt: Date())
        ],
        quickCategories: [
            QuickCategory(id: UUID(), name: "Homework", iconName: "book.fill", colorHex: "#4A90D9", durationMinutes: 30)
        ]
    )
}
