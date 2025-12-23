//
//  HomeViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// ViewModel for the Home screen.
/// Manages today's statistics and activity list with real-time data loading.
@MainActor
class HomeViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var todayStats: TodayStats = .empty
    @Published var todayActivities: [ActivityDisplayItem] = []
    @Published var recentActivities: [Activity] = []
    @Published var currentChild: Child?
    @Published var todayGoalMinutes: Int = 0
    @Published var currentStreak: Int = 0
    @Published var todayAchievements: [Achievement] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Navigation state
    @Published var shouldNavigateToTimer = false
    @Published var showingQuickLog = false

    // MARK: - Dependencies

    private let activityService: ActivityServiceProtocol
    private let categoryService: CategoryServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var categoryCache: [UUID: Category] = [:]

    // MARK: - Computed Properties

    var greetingText: String {
        guard let child = currentChild else { return "Hello!" }
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting = switch hour {
        case 0..<12: "Good Morning"
        case 12..<17: "Good Afternoon"
        default: "Good Evening"
        }
        return "\(greeting), \(child.name)!"
    }

    var goalProgress: Double {
        guard todayGoalMinutes > 0 else { return 0.0 }
        return min(Double(todayStats.totalMinutes) / Double(todayGoalMinutes), 1.0)
    }

    // MARK: - Initialization

    init(
        activityService: ActivityServiceProtocol? = nil,
        categoryService: CategoryServiceProtocol? = nil
    ) {
        // Use provided services or get from ServiceContainer
        self.activityService = activityService ?? MockActivityService()
        self.categoryService = categoryService ?? SimpleMockCategoryService()
    }

    // MARK: - Public Methods

    /// Load data using the current child or a default child if none set
    func loadData() async {
        // Use current child or create a default one for development
        let child = currentChild ?? Child(name: "Default", age: 8)
        await loadData(for: child)
    }

    func loadData(for child: Child) async {
        isLoading = true
        errorMessage = nil
        currentChild = child

        do {
            // Load categories first to build cache
            let categories = try await categoryService.fetchActiveCategories(for: child)
            categoryCache = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })

            // Load today's activities
            let activities = try await activityService.fetchTodayActivities(for: child)

            // Convert to display items with category information
            todayActivities = activities.map { activity in
                let category = categoryCache[activity.categoryId]
                return ActivityDisplayItem(
                    id: activity.id,
                    categoryName: category?.name ?? "Unknown",
                    iconName: category?.iconName ?? "circle.fill",
                    colorHex: category?.colorHex ?? "#4A90D9",
                    durationMinutes: activity.durationMinutes,
                    timeRange: formatTimeRange(start: activity.startTime, end: activity.endTime),
                    startTime: activity.startTime
                )
            }

            // Get recent activities (limit to 5, sorted by start time descending)
            recentActivities = Array(
                activities
                    .sorted { $0.startTime > $1.startTime }
                    .prefix(5)
            )

            // Calculate stats
            todayStats = calculateTodayStats(from: activities)

            // Calculate streak (simplified for now - in production would check historical data)
            currentStreak = activities.isEmpty ? 0 : 1

            // Default goal of 120 minutes (2 hours) - in production load from user preferences
            todayGoalMinutes = 120

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func startTimerTapped() {
        shouldNavigateToTimer = true
    }

    func quickLogTapped() {
        showingQuickLog = true
    }

    func resetNavigation() {
        shouldNavigateToTimer = false
        showingQuickLog = false
    }

    // MARK: - Private Methods

    private func calculateTodayStats(from activities: [Activity]) -> TodayStats {
        let totalMinutes = activities.reduce(0) { $0 + $1.durationMinutes }
        let activitiesCount = activities.count

        // Calculate balance score (simplified)
        // In production, this would use category weights and recommended durations
        let balanceScore = calculateBalanceScore(from: activities)

        return TodayStats(
            totalMinutes: totalMinutes,
            activitiesCount: activitiesCount,
            balanceScore: balanceScore
        )
    }

    private func calculateBalanceScore(from activities: [Activity]) -> Int {
        guard !activities.isEmpty else { return 0 }

        // Group activities by category
        var categoryMinutes: [UUID: Int] = [:]
        for activity in activities {
            categoryMinutes[activity.categoryId, default: 0] += activity.durationMinutes
        }

        // Calculate variance - lower variance means better balance
        let totalMinutes = Double(activities.reduce(0) { $0 + $1.durationMinutes })
        let categoryCount = Double(categoryMinutes.count)

        guard categoryCount > 0 else { return 0 }

        let averagePerCategory = totalMinutes / categoryCount
        let variance = categoryMinutes.values.reduce(0.0) { sum, minutes in
            let diff = Double(minutes) - averagePerCategory
            return sum + (diff * diff)
        } / categoryCount

        // Convert variance to a score (0-100)
        // Lower variance = higher score
        let maxVariance = averagePerCategory * averagePerCategory
        let normalizedVariance = min(variance / maxVariance, 1.0)
        let score = Int((1.0 - normalizedVariance) * 100)

        return max(0, min(100, score))
    }

    private func formatTimeRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

/// Mock category service for development
private class SimpleMockCategoryService: CategoryServiceProtocol {
    func fetchCategories(for child: Child) async throws -> [Category] { [] }
    func fetchActiveCategories(for child: Child) async throws -> [Category] { [] }
    func createCategory(_ category: Category) async throws -> Category { category }
    func updateCategory(_ category: Category) async throws -> Category { category }
    func deleteCategory(_ categoryId: UUID) async throws { }
    func reorderCategories(_ categoryIds: [UUID]) async throws { }
    func createDefaultCategories(for child: Child) async throws -> [Category] { [] }
}
