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
    private let currentChild: Child
    private var rawActivities: [Activity] = []  // Store raw activities for updates

    private static let globalCategoryKey = "globalCategories"

    // MARK: - Initialization

    init(
        activityService: ActivityServiceProtocol? = nil,
        categoryService: CategoryServiceProtocol? = nil,
        child: Child? = nil
    ) {
        // Use real services with CoreData repositories by default
        let activityRepo = CoreDataActivityRepository(context: PersistenceController.shared.container.viewContext)
        let categoryRepo = CoreDataCategoryRepository(context: PersistenceController.shared.container.viewContext)

        self.activityService = activityService ?? ActivityService(repository: activityRepo)
        self.categoryService = categoryService ?? CategoryService(repository: categoryRepo)
        self.currentChild = child ?? Child(name: "Test", age: 8)

        print("📋 ActivityLogViewModel initialized for child: \(self.currentChild.name) (\(self.currentChild.id))")

        Task {
            await loadCategories()
        }
    }

    // MARK: - Public Methods

    func loadActivities() async {
        isLoading = true
        errorMessage = nil

        do {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: selectedDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            let dateRange = DateInterval(start: startOfDay, end: endOfDay)

            print("📋 Loading activities for child: \(currentChild.id)")
            print("   Date range: \(startOfDay) to \(endOfDay)")

            let fetchedActivities = try await activityService.fetchActivities(
                for: currentChild,
                dateRange: dateRange
            )

            print("📋 Fetched \(fetchedActivities.count) activities")

            rawActivities = fetchedActivities
            activities = fetchedActivities.map { activity in
                ActivityDisplayItem(
                    id: activity.id,
                    categoryName: categoryName(for: activity.categoryId),
                    iconName: categoryIcon(for: activity.categoryId),
                    colorHex: categoryColor(for: activity.categoryId),
                    durationMinutes: activity.durationMinutes,
                    timeRange: formatTimeRange(start: activity.startTime, end: activity.endTime),
                    startTime: activity.startTime,
                    isComplete: activity.isComplete
                )
            }
        } catch {
            print("❌ Error loading activities: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func logActivity(category: Category, duration: TimeInterval) async {
        do {
            _ = try await activityService.logActivity(
                category: category,
                duration: duration,
                child: currentChild,
                isComplete: true  // Manual quick log is always complete
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
        do {
            let endTime = startTime.addingTimeInterval(duration)

            // Clean up notes - treat empty string as nil
            let cleanedNotes = notes?.trimmingCharacters(in: .whitespaces)
            let finalNotes = (cleanedNotes?.isEmpty ?? true) ? nil : cleanedNotes

            // First log the activity to create it in the system
            let activity = try await activityService.logActivity(
                category: category,
                duration: duration,
                child: currentChild,
                isComplete: true  // Manual entries are always complete
            )

            // Then update it with manual entry details
            let manualActivity = Activity(
                id: activity.id,
                categoryId: category.id,
                childId: currentChild.id,
                startTime: startTime,
                endTime: endTime,
                notes: finalNotes,
                mood: mood,
                isManualEntry: true,
                isComplete: true,
                createdDate: activity.createdDate,
                syncStatus: activity.syncStatus
            )

            _ = try await activityService.updateActivity(manualActivity)
            await loadActivities()
        } catch {
            errorMessage = error.localizedDescription
        }
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

    /// Mark an incomplete activity as complete
    func markActivityComplete(_ activityId: UUID) async {
        guard let activity = rawActivities.first(where: { $0.id == activityId }) else { return }

        var updatedActivity = activity
        updatedActivity.isComplete = true

        do {
            _ = try await activityService.updateActivity(updatedActivity)
            await loadActivities()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private Methods

    private func loadCategories() async {
        // Load categories from shared storage first, then fall back to defaults
        if let data = UserDefaults.standard.data(forKey: Self.globalCategoryKey),
           let decoded = try? JSONDecoder().decode([CategoryData].self, from: data) {
            categories = decoded.map { $0.toCategory(childId: currentChild.id) }
        } else {
            categories = Category.defaultCategories(for: currentChild.id)
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

// MARK: - CategoryData for UserDefaults persistence

private struct CategoryData: Codable {
    let id: UUID
    let name: String
    let iconName: String
    let colorHex: String
    let isActive: Bool
    let sortOrder: Int
    let isSystem: Bool
    let recommendedDuration: TimeInterval

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
            recommendedDuration: recommendedDuration
        )
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
