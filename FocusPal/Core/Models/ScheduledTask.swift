//
//  ScheduledTask.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Represents a scheduled task/activity for a child
struct ScheduledTask: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    let childId: UUID
    let categoryId: UUID
    var title: String
    var scheduledDate: Date
    var duration: TimeInterval  // Duration in seconds
    var isRecurring: Bool
    var recurrenceRule: RecurrenceRule?
    var reminderMinutesBefore: Int  // Minutes before to send notification
    var isCompleted: Bool
    var externalCalendarId: String?  // ID from iOS/Google Calendar if synced
    var calendarSource: CalendarSource
    var notes: String?
    let createdDate: Date
    /// For recurring tasks: dates (as strings "yyyy-MM-dd") when the task was completed
    var completedDates: Set<String>

    init(
        id: UUID = UUID(),
        childId: UUID,
        categoryId: UUID,
        title: String,
        scheduledDate: Date,
        duration: TimeInterval = 25 * 60,  // Default 25 minutes
        isRecurring: Bool = false,
        recurrenceRule: RecurrenceRule? = nil,
        reminderMinutesBefore: Int = 5,
        isCompleted: Bool = false,
        externalCalendarId: String? = nil,
        calendarSource: CalendarSource = .app,
        notes: String? = nil,
        createdDate: Date = Date(),
        completedDates: Set<String> = []
    ) {
        self.id = id
        self.childId = childId
        self.categoryId = categoryId
        self.title = title
        self.scheduledDate = scheduledDate
        self.duration = duration
        self.isRecurring = isRecurring
        self.recurrenceRule = recurrenceRule
        self.reminderMinutesBefore = reminderMinutesBefore
        self.isCompleted = isCompleted
        self.externalCalendarId = externalCalendarId
        self.calendarSource = calendarSource
        self.notes = notes
        self.createdDate = createdDate
        self.completedDates = completedDates
    }

    /// Date string key for the current scheduled date (used for per-date completion tracking)
    var scheduledDateKey: String {
        Self.dateKey(for: scheduledDate)
    }

    /// Convert a date to a string key for completion tracking
    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// Whether this specific instance is completed (for recurring tasks, checks the date)
    var isInstanceCompleted: Bool {
        if isRecurring {
            return completedDates.contains(scheduledDateKey)
        }
        return isCompleted
    }

    /// End time of the scheduled task
    var endDate: Date {
        scheduledDate.addingTimeInterval(duration)
    }

    /// Duration in minutes
    var durationMinutes: Int {
        Int(duration / 60)
    }

    /// Whether the task is scheduled for today
    var isToday: Bool {
        Calendar.current.isDateInToday(scheduledDate)
    }

    /// Whether the task is upcoming (not yet started)
    var isUpcoming: Bool {
        scheduledDate > Date()
    }

    /// Whether the task is currently active (in progress)
    var isActive: Bool {
        let now = Date()
        return scheduledDate <= now && now <= endDate
    }

    /// Whether the task is overdue (past end time and not completed)
    var isOverdue: Bool {
        !isInstanceCompleted && endDate < Date()
    }

    /// Whether this task instance can be completed by a child (only active or overdue tasks)
    var canBeCompletedByChild: Bool {
        !isInstanceCompleted && (isActive || isOverdue)
    }

    /// Time until task starts (nil if already started)
    var timeUntilStart: TimeInterval? {
        let interval = scheduledDate.timeIntervalSinceNow
        return interval > 0 ? interval : nil
    }

    /// Formatted time range string
    var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: scheduledDate)) - \(formatter.string(from: endDate))"
    }
}

/// Source of the scheduled task
enum CalendarSource: String, Codable, CaseIterable {
    case app = "app"              // Created in FocusPal
    case iosCalendar = "ios"      // Synced from iOS Calendar
    case googleCalendar = "google" // Synced from Google Calendar

    var displayName: String {
        switch self {
        case .app: return "FocusPal"
        case .iosCalendar: return "iOS Calendar"
        case .googleCalendar: return "Google Calendar"
        }
    }

    var iconName: String {
        switch self {
        case .app: return "timer"
        case .iosCalendar: return "calendar"
        case .googleCalendar: return "g.circle.fill"
        }
    }
}

/// Recurrence rule for recurring tasks
struct RecurrenceRule: Codable, Equatable, Hashable {
    var frequency: RecurrenceFrequency
    var interval: Int  // e.g., every 2 weeks
    var daysOfWeek: [Int]?  // 1 = Sunday, 7 = Saturday
    var endDate: Date?

    init(
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        daysOfWeek: [Int]? = nil,
        endDate: Date? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.endDate = endDate
    }

    /// Human-readable description of the recurrence
    var description: String {
        switch frequency {
        case .daily:
            return interval == 1 ? "Daily" : "Every \(interval) days"
        case .weekly:
            if let days = daysOfWeek, !days.isEmpty {
                let dayNames = days.map { dayName(for: $0) }.joined(separator: ", ")
                return "Weekly on \(dayNames)"
            }
            return interval == 1 ? "Weekly" : "Every \(interval) weeks"
        case .monthly:
            return interval == 1 ? "Monthly" : "Every \(interval) months"
        }
    }

    private func dayName(for day: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        var components = DateComponents()
        components.weekday = day
        if let date = Calendar.current.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) {
            return formatter.string(from: date)
        }
        return ""
    }
}

/// Frequency of recurrence
enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}
