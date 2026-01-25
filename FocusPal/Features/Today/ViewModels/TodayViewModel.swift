//
//  TodayViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// ViewModel for the Today tab.
/// Combines today's tasks, points summary, and mascot mood logic.
@MainActor
class TodayViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var todayTasks: [ScheduledTask] = []
    @Published var activeTasks: [ScheduledTask] = []
    @Published var upcomingTasks: [ScheduledTask] = []
    @Published var completedTasks: [ScheduledTask] = []
    @Published var todayPoints: ChildPoints?
    @Published var todayActivities: [Activity] = []
    @Published var categories: [Category] = []
    @Published var currentStreak: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let calendarService: CalendarServiceProtocol
    private let activityService: ActivityServiceProtocol
    private let categoryService: CategoryServiceProtocol
    var pointsService: PointsServiceProtocol?
    private let child: Child
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        child: Child,
        calendarService: CalendarServiceProtocol? = nil,
        activityService: ActivityServiceProtocol? = nil,
        categoryService: CategoryServiceProtocol? = nil,
        pointsService: PointsServiceProtocol? = nil
    ) {
        self.child = child

        // Initialize services
        self.calendarService = calendarService ?? CalendarService()

        let activityRepo = CoreDataActivityRepository(context: PersistenceController.shared.container.viewContext)
        let categoryRepo = CoreDataCategoryRepository(context: PersistenceController.shared.container.viewContext)

        self.activityService = activityService ?? ActivityService(repository: activityRepo)
        self.categoryService = categoryService ?? CategoryService(repository: categoryRepo)
        self.pointsService = pointsService
    }

    // MARK: - Public Methods

    /// Load all data for the Today tab
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load tasks and activities in parallel
            async let tasksResult = loadTasks()
            async let activitiesResult = loadActivities()
            async let pointsResult = loadPoints()
            async let categoriesResult = loadCategories()

            _ = await (tasksResult, activitiesResult, pointsResult, categoriesResult)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Refresh data
    func refresh() async {
        await loadData()
    }

    // MARK: - Computed Properties

    /// Get the mascot greeting message based on time and activity
    var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = child.name

        if completedTasks.count >= 3 {
            return "You're on fire, \(name)!"
        } else if completedTasks.count > 0 {
            return "Keep going, \(name)!"
        } else if activeTasks.isEmpty && upcomingTasks.isEmpty {
            if hour < 12 {
                return "Good morning, \(name)!"
            } else if hour < 17 {
                return "Ready to focus, \(name)?"
            } else {
                return "Evening, \(name)!"
            }
        } else if !activeTasks.isEmpty {
            return "Time to focus, \(name)!"
        } else {
            if hour < 12 {
                return "Good morning, \(name)!"
            } else if hour < 17 {
                return "Good afternoon, \(name)!"
            } else {
                return "Good evening, \(name)!"
            }
        }
    }

    /// Get the mascot mood based on activity state
    var mascotMood: ClockMascot.MascotMood {
        if completedTasks.count >= 3 {
            return .celebrating
        } else if completedTasks.count > 0 {
            return .excited
        } else if !activeTasks.isEmpty {
            return .encouraging
        } else {
            return .happy
        }
    }

    /// Get the total points earned today
    var pointsEarnedToday: Int {
        todayPoints?.totalPoints ?? 0
    }

    /// Check if there are any tasks for today
    var hasTasks: Bool {
        !todayTasks.isEmpty
    }

    /// Get the next few upcoming tasks (limited to 3)
    var nextUpcomingTasks: [ScheduledTask] {
        Array(upcomingTasks.prefix(3))
    }

    // MARK: - Private Methods

    private func loadTasks() async {
        do {
            let tasks = try await calendarService.fetchTasks(for: child, date: Date())
            todayTasks = tasks

            // Categorize tasks
            activeTasks = tasks.filter { $0.isActive }
            upcomingTasks = tasks.filter { $0.isUpcoming && !$0.isInstanceCompleted }
            completedTasks = tasks.filter { $0.isInstanceCompleted }
        } catch {
            print("Error loading tasks: \(error)")
        }
    }

    private func loadActivities() async {
        do {
            todayActivities = try await activityService.fetchTodayActivities(for: child)
        } catch {
            print("Error loading activities: \(error)")
        }
    }

    private func loadPoints() async {
        guard let pointsService = pointsService else {
            todayPoints = nil
            return
        }

        do {
            todayPoints = try await pointsService.getTodayPoints(for: child.id)
        } catch {
            print("Error loading points: \(error)")
            todayPoints = nil
        }
    }

    private func loadCategories() async {
        do {
            categories = try await categoryService.fetchCategories(for: child)
        } catch {
            print("Error loading categories: \(error)")
            categories = Category.defaultCategories(for: child.id)
        }
    }

    /// Complete a task
    func completeTask(_ task: ScheduledTask) async {
        do {
            if task.isRecurring {
                try await calendarService.completeTaskInstance(task.id, for: task.scheduledDate)
            } else {
                try await calendarService.completeTask(task.id)
            }
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Get category for a task
    func category(for task: ScheduledTask) -> Category? {
        categories.first { $0.id == task.categoryId }
    }
}
