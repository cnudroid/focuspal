//
//  CalendarServiceProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol defining the calendar service interface.
/// Manages scheduled tasks and calendar integration.
protocol CalendarServiceProtocol {
    /// Request calendar access permission
    func requestCalendarAccess() async throws -> Bool

    /// Check current calendar access status
    func checkCalendarAccess() -> CalendarAccessStatus

    /// Fetch available iOS calendars for syncing
    func fetchAvailableCalendars() async throws -> [ExternalCalendar]

    /// Sync events from an external calendar
    func syncFromCalendar(_ calendarId: String, for child: Child) async throws -> [ScheduledTask]

    /// Create a new scheduled task
    func createTask(_ task: ScheduledTask) async throws -> ScheduledTask

    /// Update an existing scheduled task
    func updateTask(_ task: ScheduledTask) async throws -> ScheduledTask

    /// Delete a scheduled task
    func deleteTask(_ taskId: UUID) async throws

    /// Fetch tasks for a specific date
    func fetchTasks(for child: Child, date: Date) async throws -> [ScheduledTask]

    /// Fetch tasks within a date range
    func fetchTasks(for child: Child, dateRange: DateInterval) async throws -> [ScheduledTask]

    /// Fetch upcoming tasks (next 7 days)
    func fetchUpcomingTasks(for child: Child) async throws -> [ScheduledTask]

    /// Mark a task as completed (for non-recurring tasks)
    func completeTask(_ taskId: UUID) async throws

    /// Mark a specific instance of a recurring task as completed
    func completeTaskInstance(_ taskId: UUID, for date: Date) async throws

    /// Schedule a reminder notification for a task
    func scheduleReminder(for task: ScheduledTask) async throws

    /// Cancel a reminder notification
    func cancelReminder(for taskId: UUID) async throws

    /// Generate recurring task instances for a date range
    func generateRecurringInstances(for task: ScheduledTask, in dateRange: DateInterval) -> [ScheduledTask]
}

/// Calendar access status
enum CalendarAccessStatus: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

/// Represents an external calendar that can be synced
struct ExternalCalendar: Identifiable, Equatable {
    let id: String
    let title: String
    let colorHex: String
    let source: CalendarSource
    let isEnabled: Bool

    init(
        id: String,
        title: String,
        colorHex: String,
        source: CalendarSource,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.title = title
        self.colorHex = colorHex
        self.source = source
        self.isEnabled = isEnabled
    }
}
