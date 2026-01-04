//
//  MockCalendarService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Mock implementation of CalendarServiceProtocol for testing and previews.
final class MockCalendarService: CalendarServiceProtocol {
    private var tasks: [ScheduledTask] = []
    private var accessStatus: CalendarAccessStatus = .authorized

    // MARK: - Test Configuration

    func setAccessStatus(_ status: CalendarAccessStatus) {
        accessStatus = status
    }

    func setTasks(_ tasks: [ScheduledTask]) {
        self.tasks = tasks
    }

    // MARK: - CalendarServiceProtocol

    func requestCalendarAccess() async throws -> Bool {
        return accessStatus == .authorized
    }

    func checkCalendarAccess() -> CalendarAccessStatus {
        return accessStatus
    }

    func fetchAvailableCalendars() async throws -> [ExternalCalendar] {
        return [
            ExternalCalendar(
                id: "mock-calendar-1",
                title: "Home",
                colorHex: "#4A90D9",
                source: .iosCalendar
            ),
            ExternalCalendar(
                id: "mock-calendar-2",
                title: "School",
                colorHex: "#6B9B37",
                source: .iosCalendar
            )
        ]
    }

    func syncFromCalendar(_ calendarId: String, for child: Child) async throws -> [ScheduledTask] {
        // Return some mock synced tasks
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        return [
            ScheduledTask(
                childId: child.id,
                categoryId: UUID(),
                title: "Math Homework",
                scheduledDate: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: tomorrow)!,
                duration: 30 * 60,
                externalCalendarId: "ext-1",
                calendarSource: .iosCalendar
            ),
            ScheduledTask(
                childId: child.id,
                categoryId: UUID(),
                title: "Piano Practice",
                scheduledDate: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: tomorrow)!,
                duration: 30 * 60,
                externalCalendarId: "ext-2",
                calendarSource: .iosCalendar
            )
        ]
    }

    func createTask(_ task: ScheduledTask) async throws -> ScheduledTask {
        tasks.append(task)
        return task
    }

    func updateTask(_ task: ScheduledTask) async throws -> ScheduledTask {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
        return task
    }

    func deleteTask(_ taskId: UUID) async throws {
        tasks.removeAll { $0.id == taskId }
    }

    func fetchTasks(for child: Child, date: Date) async throws -> [ScheduledTask] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return tasks.filter { task in
            task.childId == child.id &&
            task.scheduledDate >= startOfDay &&
            task.scheduledDate < endOfDay
        }.sorted { $0.scheduledDate < $1.scheduledDate }
    }

    func fetchTasks(for child: Child, dateRange: DateInterval) async throws -> [ScheduledTask] {
        return tasks.filter { task in
            task.childId == child.id &&
            task.scheduledDate >= dateRange.start &&
            task.scheduledDate <= dateRange.end
        }.sorted { $0.scheduledDate < $1.scheduledDate }
    }

    func fetchUpcomingTasks(for child: Child) async throws -> [ScheduledTask] {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        let dateRange = DateInterval(start: startDate, end: endDate)
        return try await fetchTasks(for: child, dateRange: dateRange)
    }

    func completeTask(_ taskId: UUID) async throws {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            if !tasks[index].isRecurring {
                tasks[index].isCompleted = true
            }
        }
    }

    func completeTaskInstance(_ taskId: UUID, for date: Date) async throws {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            if tasks[index].isRecurring {
                let dateKey = ScheduledTask.dateKey(for: date)
                tasks[index].completedDates.insert(dateKey)
            } else {
                tasks[index].isCompleted = true
            }
        }
    }

    func scheduleReminder(for task: ScheduledTask) async throws {
        // No-op for mock
    }

    func cancelReminder(for taskId: UUID) async throws {
        // No-op for mock
    }

    func generateRecurringInstances(for task: ScheduledTask, in dateRange: DateInterval) -> [ScheduledTask] {
        guard task.isRecurring else {
            return task.scheduledDate >= dateRange.start && task.scheduledDate <= dateRange.end ? [task] : []
        }

        // Generate a few instances for testing
        var instances: [ScheduledTask] = []
        var currentDate = task.scheduledDate
        let calendar = Calendar.current

        for _ in 0..<5 {
            if currentDate >= dateRange.start && currentDate <= dateRange.end {
                var instance = task
                instance.scheduledDate = currentDate
                instances.append(instance)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return instances
    }

    // MARK: - Sample Data

    static func withSampleTasks(for child: Child) -> MockCalendarService {
        let service = MockCalendarService()
        let today = Date()
        let calendar = Calendar.current

        let sampleTasks = [
            ScheduledTask(
                childId: child.id,
                categoryId: UUID(),
                title: "Morning Reading",
                scheduledDate: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today)!,
                duration: 20 * 60,
                calendarSource: .app
            ),
            ScheduledTask(
                childId: child.id,
                categoryId: UUID(),
                title: "Math Homework",
                scheduledDate: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: today)!,
                duration: 25 * 60,
                calendarSource: .app
            ),
            ScheduledTask(
                childId: child.id,
                categoryId: UUID(),
                title: "Piano Practice",
                scheduledDate: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: today)!,
                duration: 30 * 60,
                isRecurring: true,
                recurrenceRule: RecurrenceRule(frequency: .daily, interval: 1),
                calendarSource: .app
            )
        ]

        service.tasks = sampleTasks
        return service
    }
}
