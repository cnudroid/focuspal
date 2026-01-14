//
//  TimerViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// ViewModel for the Timer screen.
/// Manages timer state and coordinates with MultiChildTimerManager for per-child timers.
@MainActor
class TimerViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var timerState: TimerState
    @Published var remainingTime: TimeInterval
    @Published var progress: Double
    @Published var isRestoring: Bool
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category? {
        didSet {
            // Update duration when category changes (only when idle)
            if let category = selectedCategory, timerState == .idle {
                defaultDuration = category.recommendedDuration
                remainingTime = defaultDuration
            }
        }
    }
    @Published var visualizationMode: TimerVisualizationMode = .circular
    @Published var defaultDuration: TimeInterval = 25 * 60  // 25 minutes
    @Published var audioCalloutsEnabled: Bool = true
    @Published var childName: String = "Buddy"
    @Published var timeAdded: TimeInterval = 0
    @Published var pendingCompletionState: ChildTimerState?  // For completion prompt
    @Published var achievementNotifications: [AchievementNotificationHelper.UnlockNotification] = []

    // MARK: - Dependencies

    private let timerManager: MultiChildTimerManager
    private let activityService: ActivityServiceProtocol
    private let pointsService: PointsServiceProtocol?
    private let rewardsService: RewardsServiceProtocol?
    private let achievementService: AchievementServiceProtocol?
    private let audioService = TimerAudioService()
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    private let currentChild: Child

    // MARK: - Points Tracking

    private var consecutiveIncompleteCount: Int = 0

    // MARK: - Initialization

    init(
        timerManager: MultiChildTimerManager? = nil,
        activityService: ActivityServiceProtocol? = nil,
        pointsService: PointsServiceProtocol? = nil,
        rewardsService: RewardsServiceProtocol? = nil,
        achievementService: AchievementServiceProtocol? = nil,
        currentChild: Child? = nil
    ) {
        // Use real services by default
        let activityRepo = CoreDataActivityRepository(context: PersistenceController.shared.container.viewContext)
        let achievementRepo = CoreDataAchievementRepository(context: PersistenceController.shared.container.viewContext)
        let notificationService = NotificationService()

        let manager = timerManager ?? MultiChildTimerManager(notificationService: notificationService)
        let child = currentChild ?? Child(name: "Buddy", age: 8)

        self.timerManager = manager
        self.activityService = activityService ?? ActivityService(repository: activityRepo)
        self.pointsService = pointsService
        self.rewardsService = rewardsService
        self.achievementService = achievementService ?? AchievementService(repository: achievementRepo)
        self.currentChild = child

        // Check for existing timer state BEFORE setting initial values
        // This prevents animation by setting the correct initial progress from the start
        if let existingState = manager.timerState(for: child.id) {
            // Initialize with restored values - no state change will occur
            self._timerState = Published(initialValue: existingState.isPaused ? .paused : (existingState.isCompleted ? .completed : .running))
            self._progress = Published(initialValue: existingState.progress)
            self._remainingTime = Published(initialValue: existingState.remainingTime)
            self._isRestoring = Published(initialValue: false)
        } else {
            // No active timer - set idle state from the start
            self._timerState = Published(initialValue: .idle)
            self._progress = Published(initialValue: 1.0)
            self._remainingTime = Published(initialValue: 0)
            self._isRestoring = Published(initialValue: false)
        }

        self.childName = child.name

        loadCategories()

        // If there was an existing timer, restore category selection
        if let existingState = manager.timerState(for: child.id) {
            if let category = categories.first(where: { $0.id == existingState.categoryId }) {
                // Use _selectedCategory to avoid triggering didSet
                self._selectedCategory = Published(initialValue: category)
            }
            timeAdded = max(0, existingState.totalDuration - (selectedCategory?.recommendedDuration ?? existingState.totalDuration))
        }

        setupBindings()
        startUpdateLoop()
    }

    deinit {
        updateTimer?.invalidate()
    }

    func setChildName(_ name: String) {
        childName = name
        UserDefaults.standard.set(name, forKey: "childName_\(currentChild.id.uuidString)")
    }

    // MARK: - Setup

    private func setupBindings() {
        // Sync audio enabled state
        $audioCalloutsEnabled
            .sink { [weak self] enabled in
                self?.audioService.isEnabled = enabled
            }
            .store(in: &cancellables)

        // Listen for timer manager changes
        timerManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncWithManager()
            }
            .store(in: &cancellables)
    }

    private func startUpdateLoop() {
        // Update UI every 1 second - sufficient for timer display, reduces memory usage
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateFromManager()
            }
        }
        RunLoop.current.add(updateTimer!, forMode: .common)
    }

    private func syncWithManager() {
        if let state = timerManager.timerState(for: currentChild.id) {
            if state.isPaused {
                timerState = .paused
            } else if state.isCompleted {
                timerState = .completed
            } else {
                timerState = .running
            }
        }
    }

    private func updateFromManager() {
        guard let state = timerManager.timerState(for: currentChild.id) else {
            // No active timer for this child
            if timerState != .idle && timerState != .completed {
                timerState = .idle
                progress = 1.0
                remainingTime = selectedCategory?.recommendedDuration ?? defaultDuration
            }
            return
        }

        // Update from manager state
        remainingTime = state.remainingTime
        progress = state.progress

        if state.isPaused {
            timerState = .paused
        } else if state.isCompleted {
            // Timer completed
            handleTimerCompletion(state: state)
        } else {
            timerState = .running

            // Check for audio callouts
            audioService.checkForAnnouncements(
                remainingTime: remainingTime,
                totalDuration: state.totalDuration
            )
        }
    }

    private func handleTimerCompletion(state: ChildTimerState) {
        timerState = .completed
        audioService.reset()

        // Remove from manager
        _ = timerManager.completeTimer(for: currentChild.id)

        // Show completion prompt instead of auto-logging
        pendingCompletionState = state
    }

    /// Called when user confirms they completed the activity
    func confirmCompletion() {
        guard let state = pendingCompletionState else { return }
        logCompletedActivity(state: state, isComplete: true)
        pendingCompletionState = nil
        resetForNextSession()
    }

    /// Called when user says they didn't finish
    func markIncomplete() {
        guard let state = pendingCompletionState else { return }
        logCompletedActivity(state: state, isComplete: false)
        pendingCompletionState = nil
        resetForNextSession()
    }

    private func loadCategories() {
        // Load categories from shared storage using CategoryData helper
        categories = CategoryData.loadActive(for: currentChild.id)

        // Select first category and set its duration (only if no active timer)
        if timerManager.timerState(for: currentChild.id) == nil {
            if let firstCategory = categories.first {
                selectedCategory = firstCategory
                defaultDuration = firstCategory.recommendedDuration
                remainingTime = defaultDuration
            }
        }
    }

    /// Reload categories (call when returning from settings)
    func reloadCategories() {
        let currentSelectedId = selectedCategory?.id

        // Reload from shared storage using CategoryData helper
        categories = CategoryData.loadActive(for: currentChild.id)

        // Try to keep the same category selected
        if let id = currentSelectedId,
           let category = categories.first(where: { $0.id == id }) {
            selectedCategory = category
        } else if timerState == .idle, let firstCategory = categories.first {
            selectedCategory = firstCategory
            defaultDuration = firstCategory.recommendedDuration
            remainingTime = defaultDuration
        }
    }

    /// Select a category by ID (used for navigation from Schedule)
    func selectCategory(byId categoryId: UUID) {
        guard timerState == .idle else { return }  // Only allow selection when idle
        if let category = categories.first(where: { $0.id == categoryId }) {
            selectedCategory = category
        }
    }

    // MARK: - Timer Controls

    func startTimer() {
        guard let category = selectedCategory else { return }

        // Handle reward category - deduct points before starting
        if category.categoryType == .reward {
            Task {
                await deductRewardCost(for: category)
                await MainActor.run {
                    performTimerStart(category: category)
                }
            }
        } else {
            // Task category - start immediately
            performTimerStart(category: category)
        }
    }

    private func performTimerStart(category: Category) {
        let duration = category.recommendedDuration
        timeAdded = 0

        // Reset audio announcements
        audioService.reset()

        // Start timer through manager
        timerManager.startTimer(for: currentChild, category: category, duration: duration)
        timerState = .running
        remainingTime = duration
        progress = 1.0
    }

    /// Deducts points for starting a reward activity (allows negative balance for budgeting lesson)
    private func deductRewardCost(for category: Category) async {
        guard let pointsService = pointsService else {
            // No points service - allow activity anyway
            return
        }

        let baseCost = 10
        let cost = Int(Double(baseCost) * category.pointsMultiplier)

        do {
            try await pointsService.deductPoints(
                childId: currentChild.id,
                amount: cost,
                reason: .rewardCost
            )
            print("🎁 Deducted \(cost) points for reward activity: \(category.name)")
        } catch {
            print("⚠️ Failed to deduct points for reward: \(error)")
            // Allow activity on error - don't block child
        }
    }

    func pauseTimer() {
        timerManager.pauseTimer(for: currentChild.id)
        timerState = .paused
    }

    func resumeTimer() {
        timerManager.resumeTimer(for: currentChild.id)
        timerState = .running
    }

    func stopTimer() {
        // Stopping cancels the timer - don't log activity
        timerManager.stopTimer(for: currentChild.id)
        timerState = .idle
        audioService.reset()
        progress = 1.0
        remainingTime = selectedCategory?.recommendedDuration ?? defaultDuration
        timeAdded = 0
        pendingCompletionState = nil
    }

    /// Complete task early (before timer ends)
    func completeEarly() {
        guard timerState == .running || timerState == .paused else { return }

        // Get current state for logging - marked as complete since user said they finished
        if let state = timerManager.timerState(for: currentChild.id) {
            logCompletedActivity(state: state, isComplete: true, checkEarlyBonus: true)
        }

        timerManager.stopTimer(for: currentChild.id)
        audioService.reset()
        timerState = .completed

        resetForNextSession()
    }

    /// Add extra time to the current timer
    func addTime(minutes: Int) {
        guard timerState == .running || timerState == .paused else { return }

        let additionalTime = TimeInterval(minutes * 60)
        timeAdded += additionalTime

        timerManager.addTime(for: currentChild.id, minutes: minutes)
    }

    private func resetForNextSession() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.progress = 1.0
            self.remainingTime = self.selectedCategory?.recommendedDuration ?? self.defaultDuration
            self.timerState = .idle
            self.timeAdded = 0
        }
    }

    func setVisualizationMode(_ mode: TimerVisualizationMode) {
        visualizationMode = mode
    }

    func toggleAudioCallouts() {
        audioCalloutsEnabled.toggle()
    }

    // MARK: - Private Methods

    private func logCompletedActivity(state: ChildTimerState, isComplete: Bool, checkEarlyBonus: Bool = false) {
        let duration = state.elapsedTime

        // Try to find category in current list, or reconstruct from state
        // This fixes the bug where category might not be in current categories array
        // (e.g., if app restarted or categories were modified)
        let category: Category
        if let existingCategory = categories.first(where: { $0.id == state.categoryId }) {
            category = existingCategory
        } else {
            // Reconstruct category from state data - this ensures activity is always logged
            category = Category(
                id: state.categoryId,
                name: state.categoryName,
                iconName: state.categoryIconName,
                colorHex: state.categoryColorHex,
                childId: state.childId,
                recommendedDuration: state.totalDuration
            )
            print("⚠️ Category reconstructed from timer state")
        }

        let actualMinutes = Int(duration / 60)
        let actualSeconds = Int(duration) % 60
        print("📊 LOGGING Activity for \(currentChild.name): \(category.name)")
        print("   Child ID: \(currentChild.id)")
        print("   Category ID: \(category.id)")
        print("   Duration: \(actualMinutes)m \(actualSeconds)s")
        print("   Completed: \(isComplete)")

        Task {
            do {
                let activity = try await activityService.logActivity(
                    category: category,
                    duration: duration,
                    child: currentChild,
                    isComplete: isComplete
                )
                print("✅ Activity logged successfully: \(activity.id)")

                // Handle points if service is available
                await handlePointsForActivity(
                    activityId: activity.id,
                    isComplete: isComplete,
                    elapsedTime: duration,
                    recommendedDuration: category.recommendedDuration,
                    checkEarlyBonus: checkEarlyBonus,
                    category: category
                )

                // Handle achievements if service is available and activity was completed
                if isComplete {
                    await handleAchievementsForActivity(
                        category: category,
                        duration: duration,
                        startTime: state.startTime
                    )
                }

                // Update widget data
                await WidgetDataService.shared.updateWidgetData(
                    for: currentChild,
                    activityService: activityService,
                    pointsService: pointsService ?? PointsService(repository: CoreDataPointsRepository(context: PersistenceController.shared.container.viewContext)),
                    timerManager: timerManager
                )
            } catch {
                print("❌ Failed to log activity: \(error)")
            }
        }
    }

    /// Formatted string for actual elapsed time
    var elapsedTimeFormatted: String {
        guard let state = timerManager.timerState(for: currentChild.id) else { return "0:00" }
        let elapsed = state.elapsedTime
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Formatted string for time added
    var timeAddedFormatted: String {
        guard timeAdded > 0 else { return "" }
        let minutes = Int(timeAdded / 60)
        return "+\(minutes) min"
    }

    // MARK: - Points Management

    /// Handle points awarding/deduction for an activity
    private func handlePointsForActivity(
        activityId: UUID,
        isComplete: Bool,
        elapsedTime: TimeInterval,
        recommendedDuration: TimeInterval,
        checkEarlyBonus: Bool = false,
        category: Category?
    ) async {
        // Skip if points service is not available
        guard let pointsService = pointsService else {
            print("⚠️ Points service not available, skipping points handling")
            return
        }

        // Skip points for reward categories (already deducted on start)
        if category?.categoryType == .reward {
            print("ℹ️ Reward category - no completion points (already deducted on start)")
            return
        }

        var totalPointsEarned = 0
        let multiplier = category?.pointsMultiplier ?? 1.0

        do {
            if isComplete {
                // Award points for completing the activity (with multiplier)
                let earnedPoints = Int(10.0 * multiplier)
                try await pointsService.awardPoints(
                    childId: currentChild.id,
                    amount: earnedPoints,
                    reason: .activityComplete,
                    activityId: activityId
                )
                totalPointsEarned += earnedPoints
                print("✅ Awarded \(earnedPoints) points for activity completion (multiplier: \(multiplier)x)")

                // Reset consecutive incomplete counter on success
                consecutiveIncompleteCount = 0

                // Check for early finish bonus if requested (with multiplier)
                if checkEarlyBonus {
                    let percentageCompleted = elapsedTime / recommendedDuration
                    if percentageCompleted < 0.8 {
                        let bonusPoints = Int(5.0 * multiplier)
                        try await pointsService.awardPoints(
                            childId: currentChild.id,
                            amount: bonusPoints,
                            reason: .earlyFinishBonus,
                            activityId: activityId
                        )
                        totalPointsEarned += bonusPoints
                        print("🎉 Awarded \(bonusPoints) bonus points for early finish!")
                    }
                }
            } else {
                // Deduct points for incomplete activity (with multiplier)
                let deductedPoints = Int(5.0 * multiplier)
                try await pointsService.deductPoints(
                    childId: currentChild.id,
                    amount: deductedPoints,
                    reason: .activityIncomplete
                )
                print("⚠️ Deducted \(deductedPoints) points for incomplete activity")

                // Track consecutive incomplete activities
                consecutiveIncompleteCount += 1

                // Apply three-strike penalty if applicable
                if consecutiveIncompleteCount >= 3 {
                    try await pointsService.deductPoints(
                        childId: currentChild.id,
                        amount: 15,
                        reason: .threeStrikePenalty
                    )
                    print("❌ Applied 15-point three-strike penalty")

                    // Reset counter after applying penalty
                    consecutiveIncompleteCount = 0
                }
            }

            // Update weekly rewards if points were earned
            // This fixes Issue 4: Rewards not being updated
            if totalPointsEarned > 0, let rewardsService = rewardsService {
                do {
                    _ = try await rewardsService.addPoints(totalPointsEarned, for: currentChild.id)
                    print("🏆 Updated weekly rewards with \(totalPointsEarned) points")
                } catch {
                    print("⚠️ Failed to update rewards: \(error)")
                    // Continue gracefully - points are still saved
                }
            }
        } catch {
            print("❌ Failed to handle points: \(error)")
            // Continue gracefully - don't let points errors break the app
        }
    }

    // MARK: - Achievement Management

    /// Handle achievement tracking for a completed activity
    private func handleAchievementsForActivity(
        category: Category,
        duration: TimeInterval,
        startTime: Date
    ) async {
        // Skip if achievement service is not available
        guard let achievementService = achievementService else {
            print("⚠️ Achievement service not available, skipping achievement tracking")
            return
        }

        var newlyUnlocked: [Achievement] = []

        do {
            // Track timer completion achievement
            let timerAchievements = try await achievementService.recordTimerCompletion(for: currentChild)
            newlyUnlocked.append(contentsOf: timerAchievements)

            // Track category-specific achievements
            let minutes = Int(duration / 60)
            let categoryAchievements = try await achievementService.recordCategoryTime(
                minutes: minutes,
                category: category,
                for: currentChild
            )
            newlyUnlocked.append(contentsOf: categoryAchievements)

            // Track time-based achievements (e.g., Early Bird)
            let timeAchievements = try await achievementService.recordActivityTime(
                startTime: startTime,
                for: currentChild
            )
            newlyUnlocked.append(contentsOf: timeAchievements)

            // Display notifications for newly unlocked achievements
            if !newlyUnlocked.isEmpty {
                let notifications = AchievementNotificationHelper.createUnlockNotifications(from: newlyUnlocked)
                await MainActor.run {
                    achievementNotifications.append(contentsOf: notifications)
                }

                // Trigger haptic feedback for achievement unlock
                if #available(iOS 13.0, *) {
                    AchievementNotificationHelper.triggerHapticFeedback()
                }

                print("🏆 Unlocked \(newlyUnlocked.count) achievement(s)!")
                for achievement in newlyUnlocked {
                    if let type = AchievementType(rawValue: achievement.achievementTypeId) {
                        print("   ✨ \(type.name)")
                    }
                }
            }
        } catch {
            print("❌ Failed to handle achievements: \(error)")
            // Continue gracefully - don't let achievement errors break the app
        }
    }

    /// Dismiss an achievement notification
    func dismissAchievementNotification(_ notification: AchievementNotificationHelper.UnlockNotification) {
        achievementNotifications.removeAll { $0.id == notification.id }
    }
}

// Note: CategoryData is now defined in FocusPal/Core/Models/CategoryData.swift
// and shared across the app for UserDefaults persistence and Siri integration.
