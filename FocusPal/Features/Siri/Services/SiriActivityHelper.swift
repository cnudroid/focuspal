//
//  SiriActivityHelper.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Helper service for Siri intents to access activity data.
/// Provides shared logic for querying activities and calculating statistics.
@available(iOS 16.0, *)
@MainActor
class SiriActivityHelper {

    // MARK: - Singleton

    static let shared = SiriActivityHelper()

    // MARK: - Private Properties

    private var activityService: ActivityServiceProtocol {
        let context = PersistenceController.shared.container.viewContext
        let repository = CoreDataActivityRepository(context: context)
        return ActivityService(repository: repository)
    }

    private var childRepository: ChildRepositoryProtocol {
        CoreDataChildRepository(context: PersistenceController.shared.container.viewContext)
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Get total focus time for today across all children or a specific child
    func getTodayTotalTime(for childId: UUID? = nil) async throws -> TimeInterval {
        let children: [Child]

        if let childId = childId {
            if let child = try await childRepository.fetchAll().first(where: { $0.id == childId }) {
                children = [child]
            } else {
                return 0
            }
        } else {
            children = try await childRepository.fetchAll()
        }

        var totalSeconds: TimeInterval = 0

        for child in children {
            let activities = try await activityService.fetchTodayActivities(for: child)
            totalSeconds += activities.reduce(0) { $0 + $1.duration }
        }

        return totalSeconds
    }

    /// Get the current streak (consecutive days with activities)
    func getCurrentStreak(for childId: UUID? = nil) async throws -> Int {
        let children: [Child]

        if let childId = childId {
            if let child = try await childRepository.fetchAll().first(where: { $0.id == childId }) {
                children = [child]
            } else {
                return 0
            }
        } else {
            children = try await childRepository.fetchAll()
        }

        if children.isEmpty {
            return 0
        }

        // Fetch activities for the past year
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today)!
        let dateRange = DateInterval(start: oneYearAgo, end: Date())

        var allActivityDates: Set<Date> = []

        for child in children {
            let activities = try await activityService.fetchActivities(for: child, dateRange: dateRange)
            for activity in activities {
                let dayStart = calendar.startOfDay(for: activity.startTime)
                allActivityDates.insert(dayStart)
            }
        }

        if allActivityDates.isEmpty {
            return 0
        }

        // Calculate current streak counting backwards from today
        var currentStreak = 0

        for i in 0..<365 {
            let checkDate = calendar.date(byAdding: .day, value: -i, to: today)!
            if allActivityDates.contains(checkDate) {
                currentStreak += 1
            } else {
                break
            }
        }

        return currentStreak
    }

    /// Log a manual activity entry
    func logActivity(
        childId: UUID,
        categoryId: UUID,
        durationMinutes: Int
    ) async throws -> Activity {
        let context = PersistenceController.shared.container.viewContext
        let repository = CoreDataActivityRepository(context: context)

        let endTime = Date()
        let startTime = endTime.addingTimeInterval(-TimeInterval(durationMinutes * 60))

        let activity = Activity(
            categoryId: categoryId,
            childId: childId,
            startTime: startTime,
            endTime: endTime,
            isManualEntry: true,
            isComplete: true
        )

        return try await repository.create(activity)
    }

    /// Get the first child if only one exists, nil if multiple or none
    func getSingleChild() async throws -> Child? {
        let children = try await childRepository.fetchAll()
        return children.count == 1 ? children.first : nil
    }

    /// Get all children
    func getAllChildren() async throws -> [Child] {
        try await childRepository.fetchAll()
    }

    // MARK: - Formatting Helpers

    /// Format time interval as human-readable string
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 && minutes > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") and \(minutes) minute\(minutes == 1 ? "" : "s")"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else if minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            return "0 minutes"
        }
    }

    /// Format streak as human-readable string
    static func formatStreak(_ days: Int) -> String {
        switch days {
        case 0:
            return "no streak yet"
        case 1:
            return "1 day"
        default:
            return "\(days) days"
        }
    }
}
