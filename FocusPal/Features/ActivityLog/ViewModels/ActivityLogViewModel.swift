//
//  ActivityLogViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// ViewModel for the Activity Log screen.
/// Manages activity list and logging operations.
@MainActor
class ActivityLogViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var activities: [ActivityDisplayItem] = []
    @Published var categories: [Category] = []
    @Published var selectedDate = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let activityService: ActivityServiceProtocol
    private let categoryService: CategoryServiceProtocol

    // MARK: - Initialization

    init(
        activityService: ActivityServiceProtocol? = nil,
        categoryService: CategoryServiceProtocol? = nil
    ) {
        self.activityService = activityService ?? MockActivityService()
        self.categoryService = categoryService ?? MockCategoryServiceImpl()

        loadCategories()
    }

    // MARK: - Public Methods

    func loadActivities() async {
        isLoading = true
        errorMessage = nil

        do {
            let mockChild = Child(name: "Test", age: 8)
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: selectedDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            let dateRange = DateInterval(start: startOfDay, end: endOfDay)

            let fetchedActivities = try await activityService.fetchActivities(
                for: mockChild,
                dateRange: dateRange
            )

            activities = fetchedActivities.map { activity in
                ActivityDisplayItem(
                    id: activity.id,
                    categoryName: categoryName(for: activity.categoryId),
                    iconName: categoryIcon(for: activity.categoryId),
                    colorHex: categoryColor(for: activity.categoryId),
                    durationMinutes: activity.durationMinutes,
                    timeRange: formatTimeRange(start: activity.startTime, end: activity.endTime)
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func logActivity(category: Category, duration: TimeInterval) async {
        do {
            let mockChild = Child(name: "Test", age: 8)
            _ = try await activityService.logActivity(
                category: category,
                duration: duration,
                child: mockChild
            )
            await loadActivities()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logManualActivity(
        category: Category,
        startTime: Date,
        duration: TimeInterval,
        notes: String?,
        mood: Mood
    ) async {
        // Manual entry implementation
        await logActivity(category: category, duration: duration)
    }

    func deleteActivities(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let activityId = activities[index].id
                try? await activityService.deleteActivity(activityId)
            }
            await loadActivities()
        }
    }

    // MARK: - Private Methods

    private func loadCategories() {
        categories = [
            Category(name: "Homework", iconName: "book.fill", colorHex: "#4A90D9", childId: UUID()),
            Category(name: "Reading", iconName: "text.book.closed.fill", colorHex: "#7B68EE", childId: UUID()),
            Category(name: "Screen Time", iconName: "tv.fill", colorHex: "#FF6B6B", childId: UUID()),
            Category(name: "Playing", iconName: "gamecontroller.fill", colorHex: "#4ECDC4", childId: UUID()),
            Category(name: "Sports", iconName: "figure.run", colorHex: "#45B7D1", childId: UUID()),
            Category(name: "Music", iconName: "music.note", colorHex: "#F7DC6F", childId: UUID())
        ]
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

// Mock implementation
private class MockCategoryServiceImpl: CategoryServiceProtocol {
    func fetchCategories(for child: Child) async throws -> [Category] { [] }
    func fetchActiveCategories(for child: Child) async throws -> [Category] { [] }
    func createCategory(_ category: Category) async throws -> Category { category }
    func updateCategory(_ category: Category) async throws -> Category { category }
    func deleteCategory(_ categoryId: UUID) async throws { }
    func reorderCategories(_ categoryIds: [UUID]) async throws { }
    func createDefaultCategories(for child: Child) async throws -> [Category] { [] }
}
