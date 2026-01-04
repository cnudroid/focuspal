//
//  ScheduleViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import SwiftUI

/// ViewModel for managing scheduled tasks display and interactions.
@MainActor
final class ScheduleViewModel: ObservableObject {
    @Published var todayTasks: [ScheduledTask] = []
    @Published var upcomingTasks: [ScheduledTask] = []
    @Published var selectedDate: Date = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingTaskEditor = false
    @Published var taskToEdit: ScheduledTask?
    @Published var calendarAccessStatus: CalendarAccessStatus = .notDetermined

    private let calendarService: CalendarServiceProtocol
    private let child: Child
    private var categories: [Category] = []

    init(calendarService: CalendarServiceProtocol? = nil, child: Child) {
        self.child = child
        self.calendarService = calendarService ?? CalendarService()
        self.calendarAccessStatus = self.calendarService.checkCalendarAccess()
    }

    // MARK: - Data Loading

    func loadTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            async let todayResult = calendarService.fetchTasks(for: child, date: selectedDate)
            async let upcomingResult = calendarService.fetchUpcomingTasks(for: child)

            todayTasks = try await todayResult
            upcomingTasks = try await upcomingResult
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadTasksForDate(_ date: Date) async {
        selectedDate = date
        await loadTasks()
    }

    // MARK: - Task Actions

    func completeTask(_ task: ScheduledTask) async {
        do {
            if task.isRecurring {
                // For recurring tasks, complete only this specific date instance
                try await calendarService.completeTaskInstance(task.id, for: task.scheduledDate)
            } else {
                // For non-recurring tasks, mark the whole task as complete
                try await calendarService.completeTask(task.id)
            }
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTask(_ task: ScheduledTask) async {
        do {
            try await calendarService.deleteTask(task.id)
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func editTask(_ task: ScheduledTask) {
        taskToEdit = task
        showingTaskEditor = true
    }

    func addNewTask() {
        taskToEdit = nil
        showingTaskEditor = true
    }

    // MARK: - Calendar Access

    func requestCalendarAccess() async {
        do {
            let granted = try await calendarService.requestCalendarAccess()
            calendarAccessStatus = granted ? .authorized : .denied
        } catch {
            calendarAccessStatus = .denied
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    var activeTasks: [ScheduledTask] {
        todayTasks.filter { $0.isActive }
    }

    var pendingTasks: [ScheduledTask] {
        todayTasks.filter { $0.isUpcoming && !$0.isInstanceCompleted }
    }

    var completedTasks: [ScheduledTask] {
        todayTasks.filter { $0.isInstanceCompleted }
    }

    var overdueTasks: [ScheduledTask] {
        todayTasks.filter { $0.isOverdue }
    }

    var tasksByTimeSlot: [(String, [ScheduledTask])] {
        let slots: [(String, ClosedRange<Int>)] = [
            ("Morning", 6...11),
            ("Afternoon", 12...16),
            ("Evening", 17...21)
        ]

        return slots.compactMap { (name, hours) in
            let tasks = todayTasks.filter { task in
                let hour = Calendar.current.component(.hour, from: task.scheduledDate)
                return hours.contains(hour) && !task.isInstanceCompleted
            }
            return tasks.isEmpty ? nil : (name, tasks)
        }
    }

    func category(for task: ScheduledTask) -> Category? {
        categories.first { $0.id == task.categoryId }
    }

    func setCategories(_ categories: [Category]) {
        self.categories = categories
    }
}
