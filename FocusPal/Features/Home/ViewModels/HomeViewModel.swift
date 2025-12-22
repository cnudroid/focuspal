//
//  HomeViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// ViewModel for the Home screen.
/// Manages today's statistics and activity list.
@MainActor
class HomeViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var todayStats: TodayStats = .empty
    @Published var todayActivities: [ActivityDisplayItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let activityService: ActivityServiceProtocol
    private let categoryService: CategoryServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        activityService: ActivityServiceProtocol? = nil,
        categoryService: CategoryServiceProtocol? = nil
    ) {
        // Use provided services or get from ServiceContainer
        self.activityService = activityService ?? MockActivityService()
        self.categoryService = categoryService ?? MockCategoryService()
    }

    // MARK: - Public Methods

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load today's activities
            // In production, get current child from repository
            let mockChild = Child(name: "Test", age: 8)

            let activities = try await activityService.fetchTodayActivities(for: mockChild)

            // Convert to display items
            todayActivities = activities.map { activity in
                ActivityDisplayItem(
                    id: activity.id,
                    categoryName: "Category",  // Fetch from category service
                    iconName: "circle.fill",
                    colorHex: "#4A90D9",
                    durationMinutes: activity.durationMinutes,
                    timeRange: formatTimeRange(start: activity.startTime, end: activity.endTime)
                )
            }

            // Calculate stats
            let totalMinutes = activities.reduce(0) { $0 + $1.durationMinutes }
            todayStats = TodayStats(
                totalMinutes: totalMinutes,
                activitiesCount: activities.count,
                balanceScore: 75  // Calculate from analytics service
            )

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func startTimerTapped() {
        // Navigate to timer screen
        // In production, use coordinator pattern
    }

    func quickLogTapped() {
        // Show quick log sheet
        // In production, present modal
    }

    // MARK: - Private Methods

    private func formatTimeRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

/// Mock category service for development
private class MockCategoryService: CategoryServiceProtocol {
    func fetchCategories(for child: Child) async throws -> [Category] { [] }
    func fetchActiveCategories(for child: Child) async throws -> [Category] { [] }
    func createCategory(_ category: Category) async throws -> Category { category }
    func updateCategory(_ category: Category) async throws -> Category { category }
    func deleteCategory(_ categoryId: UUID) async throws { }
    func reorderCategories(_ categoryIds: [UUID]) async throws { }
    func createDefaultCategories(for child: Child) async throws -> [Category] { [] }
}
