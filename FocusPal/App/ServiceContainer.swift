//
//  ServiceContainer.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// Dependency injection container that provides access to all app services.
/// This container manages the lifecycle of services and repositories,
/// ensuring proper initialization order and singleton behavior where appropriate.
@MainActor
class ServiceContainer: ObservableObject {

    // MARK: - Repositories

    lazy var childRepository: ChildRepositoryProtocol = {
        CoreDataChildRepository(context: PersistenceController.shared.container.viewContext)
    }()

    lazy var activityRepository: ActivityRepositoryProtocol = {
        CoreDataActivityRepository(context: PersistenceController.shared.container.viewContext)
    }()

    lazy var categoryRepository: CategoryRepositoryProtocol = {
        CoreDataCategoryRepository(context: PersistenceController.shared.container.viewContext)
    }()

    lazy var achievementRepository: AchievementRepositoryProtocol = {
        CoreDataAchievementRepository(context: PersistenceController.shared.container.viewContext)
    }()

    lazy var timeGoalRepository: TimeGoalRepositoryProtocol = {
        CoreDataTimeGoalRepository(context: PersistenceController.shared.container.viewContext)
    }()

    // MARK: - Services

    lazy var timerService: TimerServiceProtocol = {
        TimerService(notificationService: notificationService)
    }()

    lazy var multiChildTimerManager: MultiChildTimerManager = {
        MultiChildTimerManager(notificationService: notificationService)
    }()

    lazy var activityService: ActivityServiceProtocol = {
        ActivityService(repository: activityRepository)
    }()

    lazy var categoryService: CategoryServiceProtocol = {
        CategoryService(repository: categoryRepository)
    }()

    lazy var analyticsService: AnalyticsServiceProtocol = {
        AnalyticsService(activityService: activityService, categoryService: categoryService)
    }()

    lazy var notificationService: NotificationServiceProtocol = {
        NotificationService()
    }()

    lazy var syncService: SyncServiceProtocol = {
        SyncService(cloudKitManager: CloudKitManager())
    }()

    lazy var timeGoalService: TimeGoalServiceProtocol = {
        TimeGoalService(
            activityService: activityService,
            notificationService: notificationService
        )
    }()

    lazy var achievementService: AchievementServiceProtocol = {
        AchievementService(repository: achievementRepository)
    }()

    // MARK: - Initialization

    init() {
        // Additional setup can be performed here
    }
}
