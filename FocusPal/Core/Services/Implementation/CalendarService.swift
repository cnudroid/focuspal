//
//  CalendarService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import EventKit
import UserNotifications

/// Service for managing scheduled tasks and iOS calendar integration.
final class CalendarService: CalendarServiceProtocol {
    private let eventStore = EKEventStore()
    private let userDefaults = UserDefaults.standard
    private let tasksKey = "com.focuspal.scheduledTasks"
    private let syncedCalendarsKey = "com.focuspal.syncedCalendars"

    // MARK: - Calendar Access

    func requestCalendarAccess() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await eventStore.requestFullAccessToEvents()
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }

    func checkCalendarAccess() -> CalendarAccessStatus {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized, .fullAccess:
            return .authorized
        case .denied, .writeOnly:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }

    // MARK: - External Calendars

    func fetchAvailableCalendars() async throws -> [ExternalCalendar] {
        guard checkCalendarAccess() == .authorized else {
            return []
        }

        let calendars = eventStore.calendars(for: .event)
        return calendars.map { calendar in
            ExternalCalendar(
                id: calendar.calendarIdentifier,
                title: calendar.title,
                colorHex: hexColor(from: calendar.cgColor),
                source: .iosCalendar,
                isEnabled: true
            )
        }
    }

    func syncFromCalendar(_ calendarId: String, for child: Child) async throws -> [ScheduledTask] {
        guard checkCalendarAccess() == .authorized else {
            throw CalendarServiceError.accessDenied
        }

        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
            throw CalendarServiceError.calendarNotFound
        }

        // Fetch events for the next 30 days
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: startDate)!

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: [calendar]
        )

        let events = eventStore.events(matching: predicate)

        // Convert to scheduled tasks
        var tasks: [ScheduledTask] = []
        let defaultCategoryId = UUID() // Will be mapped by parent

        for event in events {
            let task = ScheduledTask(
                childId: child.id,
                categoryId: defaultCategoryId,
                title: event.title ?? "Untitled",
                scheduledDate: event.startDate,
                duration: event.endDate.timeIntervalSince(event.startDate),
                isRecurring: event.hasRecurrenceRules,
                recurrenceRule: convertRecurrenceRule(event.recurrenceRules?.first),
                reminderMinutesBefore: 5,
                externalCalendarId: event.eventIdentifier,
                calendarSource: .iosCalendar,
                notes: event.notes
            )
            tasks.append(task)
        }

        // Save synced tasks
        var existingTasks = loadTasks()
        for task in tasks {
            if let index = existingTasks.firstIndex(where: { $0.externalCalendarId == task.externalCalendarId }) {
                existingTasks[index] = task
            } else {
                existingTasks.append(task)
            }
        }
        saveTasks(existingTasks)

        return tasks
    }

    // MARK: - Task Management

    func createTask(_ task: ScheduledTask) async throws -> ScheduledTask {
        var tasks = loadTasks()
        tasks.append(task)
        saveTasks(tasks)

        // Schedule reminder if needed
        if task.reminderMinutesBefore > 0 {
            try await scheduleReminder(for: task)
        }

        return task
    }

    func updateTask(_ task: ScheduledTask) async throws -> ScheduledTask {
        var tasks = loadTasks()
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            throw CalendarServiceError.taskNotFound
        }

        // Cancel old reminder
        try await cancelReminder(for: task.id)

        tasks[index] = task
        saveTasks(tasks)

        // Schedule new reminder if needed
        if task.reminderMinutesBefore > 0 && !task.isCompleted {
            try await scheduleReminder(for: task)
        }

        return task
    }

    func deleteTask(_ taskId: UUID) async throws {
        var tasks = loadTasks()
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else {
            throw CalendarServiceError.taskNotFound
        }

        try await cancelReminder(for: taskId)
        tasks.remove(at: index)
        saveTasks(tasks)
    }

    func fetchTasks(for child: Child, date: Date) async throws -> [ScheduledTask] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let dateRange = DateInterval(start: startOfDay, end: endOfDay)

        return try await fetchTasks(for: child, dateRange: dateRange)
    }

    func fetchTasks(for child: Child, dateRange: DateInterval) async throws -> [ScheduledTask] {
        let allTasks = loadTasks().filter { $0.childId == child.id }
        var result: [ScheduledTask] = []

        for task in allTasks {
            if task.isRecurring {
                // Generate instances for recurring tasks
                let instances = generateRecurringInstances(for: task, in: dateRange)
                result.append(contentsOf: instances)
            } else {
                // Include non-recurring tasks if they fall within the date range
                if task.scheduledDate >= dateRange.start && task.scheduledDate <= dateRange.end {
                    result.append(task)
                }
            }
        }

        return result.sorted { $0.scheduledDate < $1.scheduledDate }
    }

    func fetchUpcomingTasks(for child: Child) async throws -> [ScheduledTask] {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        let dateRange = DateInterval(start: startDate, end: endDate)
        return try await fetchTasks(for: child, dateRange: dateRange)
    }

    func completeTask(_ taskId: UUID) async throws {
        var tasks = loadTasks()
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else {
            throw CalendarServiceError.taskNotFound
        }

        // For non-recurring tasks, mark as completed
        if !tasks[index].isRecurring {
            tasks[index].isCompleted = true
            try await cancelReminder(for: taskId)
        }
        // For recurring tasks called without a date, do nothing (use completeTaskInstance instead)

        saveTasks(tasks)
    }

    func completeTaskInstance(_ taskId: UUID, for date: Date) async throws {
        var tasks = loadTasks()
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else {
            throw CalendarServiceError.taskNotFound
        }

        if tasks[index].isRecurring {
            // Add this specific date to the completed dates set
            let dateKey = ScheduledTask.dateKey(for: date)
            tasks[index].completedDates.insert(dateKey)
        } else {
            // For non-recurring tasks, just mark as completed
            tasks[index].isCompleted = true
            try await cancelReminder(for: taskId)
        }

        saveTasks(tasks)
    }

    // MARK: - Notifications

    func scheduleReminder(for task: ScheduledTask) async throws {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Task"
        content.body = "\(task.title) starts in \(task.reminderMinutesBefore) minutes"
        content.sound = .default
        content.categoryIdentifier = "SCHEDULED_TASK"
        content.userInfo = ["taskId": task.id.uuidString]

        let triggerDate = task.scheduledDate.addingTimeInterval(-Double(task.reminderMinutesBefore * 60))
        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "task-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    func cancelReminder(for taskId: UUID) async throws {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["task-\(taskId.uuidString)"])
    }

    // MARK: - Recurring Tasks

    func generateRecurringInstances(for task: ScheduledTask, in dateRange: DateInterval) -> [ScheduledTask] {
        guard task.isRecurring, let rule = task.recurrenceRule else {
            return task.scheduledDate >= dateRange.start && task.scheduledDate <= dateRange.end ? [task] : []
        }

        var instances: [ScheduledTask] = []
        let calendar = Calendar.current

        // Get time components from original task
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: task.scheduledDate)

        // Start from the beginning of the date range or task start date, whichever is later
        var currentDate = max(calendar.startOfDay(for: dateRange.start), calendar.startOfDay(for: task.scheduledDate))

        while currentDate <= dateRange.end {
            // Check end date
            if let endDate = rule.endDate, currentDate > endDate {
                break
            }

            // Check if this date matches the recurrence pattern
            if matchesRecurrencePattern(date: currentDate, task: task, rule: rule) {
                // Create instance with the correct time
                var instanceDate = currentDate
                if let adjustedDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                     minute: timeComponents.minute ?? 0,
                                                     second: timeComponents.second ?? 0,
                                                     of: currentDate) {
                    instanceDate = adjustedDate
                }

                if instanceDate >= dateRange.start && instanceDate <= dateRange.end {
                    var instance = task
                    instance.scheduledDate = instanceDate
                    instances.append(instance)
                }
            }

            // Move to next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return instances
    }

    private func matchesRecurrencePattern(date: Date, task: ScheduledTask, rule: RecurrenceRule) -> Bool {
        let calendar = Calendar.current
        let taskStartDate = calendar.startOfDay(for: task.scheduledDate)
        let currentDate = calendar.startOfDay(for: date)

        // Date must be on or after task start date
        guard currentDate >= taskStartDate else { return false }

        switch rule.frequency {
        case .daily:
            // Check if the number of days since start is divisible by interval
            let daysSinceStart = calendar.dateComponents([.day], from: taskStartDate, to: currentDate).day ?? 0
            return daysSinceStart % rule.interval == 0

        case .weekly:
            // Check if day of week matches
            let weekday = calendar.component(.weekday, from: date)
            if let days = rule.daysOfWeek, !days.isEmpty {
                guard days.contains(weekday) else { return false }
            } else {
                // If no days specified, use the original task's day
                let taskWeekday = calendar.component(.weekday, from: task.scheduledDate)
                guard weekday == taskWeekday else { return false }
            }

            // Check week interval
            let weeksSinceStart = calendar.dateComponents([.weekOfYear], from: taskStartDate, to: currentDate).weekOfYear ?? 0
            return weeksSinceStart % rule.interval == 0

        case .monthly:
            // Check if day of month matches
            let taskDay = calendar.component(.day, from: task.scheduledDate)
            let currentDay = calendar.component(.day, from: date)
            guard taskDay == currentDay else { return false }

            // Check month interval
            let monthsSinceStart = calendar.dateComponents([.month], from: taskStartDate, to: currentDate).month ?? 0
            return monthsSinceStart % rule.interval == 0
        }
    }

    // MARK: - Private Helpers

    private func loadTasks() -> [ScheduledTask] {
        guard let data = userDefaults.data(forKey: tasksKey),
              let tasks = try? JSONDecoder().decode([ScheduledTask].self, from: data) else {
            return []
        }
        return tasks
    }

    private func saveTasks(_ tasks: [ScheduledTask]) {
        if let data = try? JSONEncoder().encode(tasks) {
            userDefaults.set(data, forKey: tasksKey)
        }
    }

    private func hexColor(from cgColor: CGColor?) -> String {
        guard let color = cgColor,
              let components = color.components,
              components.count >= 3 else {
            return "#4A90D9"
        }

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
    }

    private func convertRecurrenceRule(_ ekRule: EKRecurrenceRule?) -> RecurrenceRule? {
        guard let ekRule = ekRule else { return nil }

        let frequency: RecurrenceFrequency
        switch ekRule.frequency {
        case .daily:
            frequency = .daily
        case .weekly:
            frequency = .weekly
        case .monthly:
            frequency = .monthly
        default:
            return nil
        }

        let daysOfWeek = ekRule.daysOfTheWeek?.map { $0.dayOfTheWeek.rawValue }

        return RecurrenceRule(
            frequency: frequency,
            interval: ekRule.interval,
            daysOfWeek: daysOfWeek,
            endDate: ekRule.recurrenceEnd?.endDate
        )
    }
}

// MARK: - Errors

enum CalendarServiceError: LocalizedError {
    case accessDenied
    case calendarNotFound
    case taskNotFound
    case syncFailed

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access is required to sync events"
        case .calendarNotFound:
            return "The selected calendar could not be found"
        case .taskNotFound:
            return "The task could not be found"
        case .syncFailed:
            return "Failed to sync with calendar"
        }
    }
}
