//
//  DailyTasksViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// Display model for daily task items with point information
struct DailyTaskItem: Identifiable {
    let id: UUID
    let activityId: UUID
    let categoryName: String
    let iconName: String
    let colorHex: String
    let durationMinutes: Int
    let timeRange: String
    let startTime: Date
    let isComplete: Bool
    let pointsEarned: Int
    let bonusPoints: Int
    let pointsDeducted: Int

    /// Net points for this task
    var netPoints: Int {
        pointsEarned + bonusPoints - pointsDeducted
    }

    /// Description of point breakdown
    var pointsDescription: String {
        if !isComplete {
            return "-5 pts (incomplete)"
        } else if bonusPoints > 0 {
            return "+\(pointsEarned + bonusPoints) pts (+\(bonusPoints) bonus)"
        } else {
            return "+\(pointsEarned) pts"
        }
    }
}

/// ViewModel for the Daily Tasks screen.
/// Manages today's activities with their associated point values.
@MainActor
class DailyTasksViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var tasks: [DailyTaskItem] = []
    @Published var todayPoints: ChildPoints?
    @Published var transactions: [PointsTransaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var streakDays: Int = 0

    // MARK: - Dependencies

    private let activityService: ActivityServiceProtocol
    private let categoryService: CategoryServiceProtocol
    private let pointsService: PointsServiceProtocol?
    private let currentChild: Child
    private var categories: [Category] = []

    private static let globalCategoryKey = "globalCategories"

    // MARK: - Computed Properties

    /// Today's date formatted for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    /// Total points earned today
    var totalEarned: Int {
        todayPoints?.pointsEarned ?? 0
    }

    /// Total points deducted today
    var totalDeducted: Int {
        todayPoints?.pointsDeducted ?? 0
    }

    /// Total bonus points today
    var totalBonus: Int {
        todayPoints?.bonusPoints ?? 0
    }

    /// Net points for today
    var netPoints: Int {
        todayPoints?.totalPoints ?? 0
    }

    /// Whether today was a positive day
    var isPositiveDay: Bool {
        netPoints > 0
    }

    /// Whether there are no tasks today
    var isEmpty: Bool {
        tasks.isEmpty
    }

    /// Number of completed tasks
    var completedCount: Int {
        tasks.filter { $0.isComplete }.count
    }

    /// Number of incomplete tasks
    var incompleteCount: Int {
        tasks.filter { !$0.isComplete }.count
    }

    // MARK: - Initialization

    init(
        activityService: ActivityServiceProtocol? = nil,
        categoryService: CategoryServiceProtocol? = nil,
        pointsService: PointsServiceProtocol? = nil,
        child: Child? = nil
    ) {
        // Use real services with CoreData repositories by default
        let activityRepo = CoreDataActivityRepository(context: PersistenceController.shared.container.viewContext)
        let categoryRepo = CoreDataCategoryRepository(context: PersistenceController.shared.container.viewContext)

        self.activityService = activityService ?? ActivityService(repository: activityRepo)
        self.categoryService = categoryService ?? CategoryService(repository: categoryRepo)
        self.pointsService = pointsService
        self.currentChild = child ?? Child(name: "Test", age: 8)

        Task {
            await loadCategories()
        }
    }

    // MARK: - Public Methods

    /// Load all data for today's tasks view
    func loadData() async {
        isLoading = true
        errorMessage = nil

        await loadCategories()
        await loadTodayActivities()
        await loadTodayPoints()
        await loadTransactions()

        isLoading = false
    }

    /// Refresh data
    func refresh() async {
        await loadData()
    }

    // MARK: - Private Methods

    private func loadCategories() async {
        // Load categories from shared storage first, then fall back to defaults
        if let data = UserDefaults.standard.data(forKey: Self.globalCategoryKey),
           let decoded = try? JSONDecoder().decode([CategoryData].self, from: data) {
            categories = decoded.map { $0.toCategory(childId: currentChild.id) }.filter { $0.isActive }
        } else {
            categories = Category.defaultCategories(for: currentChild.id)
        }
    }

    private func loadTodayActivities() async {
        do {
            let activities = try await activityService.fetchTodayActivities(for: currentChild)

            // Map activities to display items with point calculations
            tasks = activities.map { activity in
                let (earned, bonus, deducted) = calculatePointsForActivity(activity)

                return DailyTaskItem(
                    id: UUID(),
                    activityId: activity.id,
                    categoryName: categoryName(for: activity.categoryId),
                    iconName: categoryIcon(for: activity.categoryId),
                    colorHex: categoryColor(for: activity.categoryId),
                    durationMinutes: activity.durationMinutes,
                    timeRange: formatTimeRange(start: activity.startTime, end: activity.endTime),
                    startTime: activity.startTime,
                    isComplete: activity.isComplete,
                    pointsEarned: earned,
                    bonusPoints: bonus,
                    pointsDeducted: deducted
                )
            }.sorted { $0.startTime > $1.startTime }
        } catch {
            errorMessage = "Failed to load activities: \(error.localizedDescription)"
        }
    }

    private func loadTodayPoints() async {
        guard let pointsService = pointsService else {
            // Create default points if service not available
            todayPoints = ChildPoints(
                childId: currentChild.id,
                date: Date(),
                pointsEarned: tasks.reduce(0) { $0 + $1.pointsEarned },
                pointsDeducted: tasks.reduce(0) { $0 + $1.pointsDeducted },
                bonusPoints: tasks.reduce(0) { $0 + $1.bonusPoints }
            )
            return
        }

        do {
            todayPoints = try await pointsService.getTodayPoints(for: currentChild.id)
        } catch {
            errorMessage = "Failed to load points: \(error.localizedDescription)"
        }
    }

    private func loadTransactions() async {
        guard let pointsService = pointsService else {
            transactions = []
            return
        }

        do {
            // Get today's transactions only
            let allTransactions = try await pointsService.getTransactionHistory(for: currentChild.id, limit: 50)
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            transactions = allTransactions.filter { transaction in
                calendar.isDate(transaction.timestamp, inSameDayAs: today)
            }
        } catch {
            errorMessage = "Failed to load transactions: \(error.localizedDescription)"
        }
    }

    /// Calculate points for an activity based on completion status
    private func calculatePointsForActivity(_ activity: Activity) -> (earned: Int, bonus: Int, deducted: Int) {
        if activity.isComplete {
            // Base points for completion
            let earned = 10

            // Check for early finish bonus (finished before expected duration)
            let category = categories.first { $0.id == activity.categoryId }
            let expectedDuration = category?.recommendedDuration ?? (25 * 60)
            let bonus = activity.duration < expectedDuration ? 5 : 0

            return (earned, bonus, 0)
        } else {
            // Penalty for incomplete activity
            return (0, 0, 5)
        }
    }

    private func categoryName(for categoryId: UUID) -> String {
        categories.first { $0.id == categoryId }?.name ?? "Unknown"
    }

    private func categoryIcon(for categoryId: UUID) -> String {
        categories.first { $0.id == categoryId }?.iconName ?? "circle.fill"
    }

    private func categoryColor(for categoryId: UUID) -> String {
        categories.first { $0.id == categoryId }?.colorHex ?? "#888888"
    }

    private func formatTimeRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}
