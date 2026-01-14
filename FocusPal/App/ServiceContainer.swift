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

    // MARK: - Navigation State

    /// Category ID to auto-select when navigating to Timer tab from Schedule or Siri
    @Published var pendingTimerCategoryId: UUID?

    /// Flag indicating we should navigate to Timer tab (from Siri)
    @Published var pendingSiriTimerNavigation: Bool = false

    /// Flag to auto-start timer after category selection (for Siri)
    @Published var shouldAutoStartTimer: Bool = false

    /// Tab to navigate to from deep link (widget tap)
    @Published var pendingDeepLinkTab: AppTab?

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

    lazy var pointsRepository: PointsRepositoryProtocol = {
        CoreDataPointsRepository(context: PersistenceController.shared.container.viewContext)
    }()

    lazy var rewardsRepository: RewardsRepositoryProtocol = {
        CoreDataRewardsRepository(context: PersistenceController.shared.container.viewContext)
    }()

    lazy var parentRepository: ParentRepositoryProtocol = {
        CoreDataParentRepository(context: PersistenceController.shared.container.viewContext)
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

    lazy var pointsService: PointsServiceProtocol = {
        PointsService(repository: pointsRepository)
    }()

    lazy var rewardsService: RewardsServiceProtocol = {
        RewardsService(repository: rewardsRepository)
    }()

    lazy var weeklySummaryService: WeeklySummaryService = {
        WeeklySummaryService(
            activityRepository: activityRepository,
            childRepository: childRepository,
            categoryRepository: categoryRepository,
            pointsRepository: pointsRepository,
            rewardsRepository: rewardsRepository,
            achievementRepository: achievementRepository
        )
    }()

    lazy var emailService: EmailService = {
        EmailService()
    }()

    lazy var emailContentBuilder: EmailContentBuilder = {
        EmailContentBuilder()
    }()

    lazy var weeklyEmailScheduler: WeeklyEmailScheduler = {
        WeeklyEmailScheduler(
            summaryService: weeklySummaryService,
            contentBuilder: emailContentBuilder,
            emailService: emailService,
            parentRepository: parentRepository
        )
    }()

    // MARK: - Initialization

    init() {
        // Additional setup can be performed here
    }

    // MARK: - App Lifecycle

    /// Call this on app launch to check and send weekly emails if due
    func checkWeeklyEmailOnLaunch() {
        Task {
            await weeklyEmailScheduler.checkAndSendIfDue()
        }
    }

    /// Update widget data for the currently active child
    func updateWidgetData() {
        Task {
            do {
                // Get the active child
                guard let activeChild = try await childRepository.fetchActiveChild() else {
                    print("📊 No active child for widget update")
                    return
                }

                // Update widget data
                await WidgetDataService.shared.updateWidgetData(
                    for: activeChild,
                    activityService: activityService,
                    pointsService: pointsService,
                    timerManager: multiChildTimerManager
                )
            } catch {
                print("❌ Failed to update widget data: \(error)")
            }
        }
    }
}
