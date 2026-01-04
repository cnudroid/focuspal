//
//  TaskSchedulerViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import SwiftUI

/// ViewModel for parent task scheduling interface.
@MainActor
final class TaskSchedulerViewModel: ObservableObject {
    @Published var upcomingDays: [DaySchedule] = []
    @Published var recurringTasks: [ScheduledTask] = []
    @Published var availableCalendars: [ExternalCalendar] = []
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var errorMessage: String?
    @Published var calendarAccessStatus: CalendarAccessStatus = .notDetermined
    @Published var taskBeingEdited: ScheduledTask?

    private let calendarService: CalendarServiceProtocol
    private let child: Child

    struct DaySchedule: Identifiable {
        let id = UUID()
        let date: Date
        let tasks: [ScheduledTask]

        var dayName: String {
            if Calendar.current.isDateInToday(date) {
                return "Today"
            } else if Calendar.current.isDateInTomorrow(date) {
                return "Tomorrow"
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
    }

    init(calendarService: CalendarServiceProtocol? = nil, child: Child) {
        self.child = child
        self.calendarService = calendarService ?? CalendarService()
        self.calendarAccessStatus = self.calendarService.checkCalendarAccess()
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        errorMessage = nil

        // Load upcoming week
        let calendar = Calendar.current
        var days: [DaySchedule] = []

        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) {
                do {
                    let tasks = try await calendarService.fetchTasks(for: child, date: date)
                    days.append(DaySchedule(date: date, tasks: tasks))
                } catch {
                    days.append(DaySchedule(date: date, tasks: []))
                }
            }
        }

        upcomingDays = days

        // Load recurring tasks
        do {
            let allTasks = try await calendarService.fetchUpcomingTasks(for: child)
            recurringTasks = allTasks.filter { $0.isRecurring }
        } catch {
            errorMessage = error.localizedDescription
        }

        // Load categories
        loadCategories()

        isLoading = false
    }

    func loadCalendars() async {
        do {
            availableCalendars = try await calendarService.fetchAvailableCalendars()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static let globalCategoryKey = "globalCategories"

    private func loadCategories() {
        // Load from UserDefaults using CategoryData for serialization
        // Categories are stored globally, not per-child
        if let data = UserDefaults.standard.data(forKey: Self.globalCategoryKey),
           let savedData = try? JSONDecoder().decode([ScheduleCategoryData].self, from: data) {
            categories = savedData.map { $0.toCategory(childId: child.id) }
        } else {
            categories = Category.defaultCategories(for: child.id)
        }
    }

    // MARK: - Task Management

    func addTaskForDate(_ date: Date) {
        let calendar = Calendar.current
        let scheduledDate = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date) ?? date

        taskBeingEdited = ScheduledTask(
            childId: child.id,
            categoryId: categories.first?.id ?? UUID(),
            title: "",
            scheduledDate: scheduledDate,
            calendarSource: .app
        )
    }

    func addRecurringTask() {
        let scheduledDate = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()

        taskBeingEdited = ScheduledTask(
            childId: child.id,
            categoryId: categories.first?.id ?? UUID(),
            title: "",
            scheduledDate: scheduledDate,
            isRecurring: true,
            recurrenceRule: RecurrenceRule(frequency: .daily, interval: 1),
            calendarSource: .app
        )
    }

    func saveTask(_ task: ScheduledTask) async {
        do {
            // Check if task exists
            let allTasks = try await calendarService.fetchUpcomingTasks(for: child)
            if allTasks.contains(where: { $0.id == task.id }) {
                _ = try await calendarService.updateTask(task)
            } else {
                _ = try await calendarService.createTask(task)
            }
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTask(_ task: ScheduledTask) async {
        do {
            try await calendarService.deleteTask(task.id)
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeTask(_ task: ScheduledTask) async {
        do {
            try await calendarService.completeTask(task.id)
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Calendar Access

    func requestCalendarAccess() async {
        do {
            let granted = try await calendarService.requestCalendarAccess()
            calendarAccessStatus = granted ? .authorized : .denied
            if granted {
                await loadCalendars()
            }
        } catch {
            calendarAccessStatus = .denied
            errorMessage = error.localizedDescription
        }
    }

    func syncCalendar(_ calendar: ExternalCalendar) async {
        isSyncing = true
        do {
            _ = try await calendarService.syncFromCalendar(calendar.id, for: child)
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSyncing = false
    }
}

// MARK: - CategoryData for UserDefaults persistence

private struct ScheduleCategoryData: Codable {
    let id: UUID
    let name: String
    let iconName: String
    let colorHex: String
    let isActive: Bool
    let sortOrder: Int
    let isSystem: Bool
    let recommendedDuration: TimeInterval
    let categoryType: String?
    let pointsMultiplier: Double?

    func toCategory(childId: UUID) -> Category {
        Category(
            id: id,
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            isActive: isActive,
            sortOrder: sortOrder,
            isSystem: isSystem,
            childId: childId,
            recommendedDuration: recommendedDuration,
            categoryType: CategoryType(rawValue: categoryType ?? "task") ?? .task,
            pointsMultiplier: pointsMultiplier ?? 1.0
        )
    }
}
