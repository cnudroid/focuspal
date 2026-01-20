//
//  ContentView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import CoreData

/// Root content view that handles navigation between onboarding and main app flow.
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var serviceContainer: ServiceContainer

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentChild: Child?
    @State private var completedTimerAlert: ChildTimerState?
    @State private var showingCompletedAlert = false
    @State private var showingRecoveryAlert = false

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                // Show onboarding flow for first-time users
                OnboardingContainerView()
            } else if let child = currentChild {
                // Child is logged in - show main app
                MainTabView(currentChild: child)
                    .overlay(alignment: .topTrailing) {
                        // Exit button to return to landing
                        Button {
                            currentChild = nil
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .padding(12)
                                .background(Color(.systemBackground).opacity(0.8))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                    }
            } else {
                // Show landing page with profile selection
                LandingView(
                    childRepository: serviceContainer.childRepository,
                    onChildSelected: { child in
                        currentChild = child
                    }
                )
            }
        }
        .onReceive(serviceContainer.multiChildTimerManager.$completedTimers) { timers in
            // Show alert for any completed timer (only if we don't already have one showing)
            if completedTimerAlert == nil, let completed = timers.first {
                completedTimerAlert = completed
            }
        }
        .alert("Timer Completed!", isPresented: $showingCompletedAlert) {
            Button("OK") {
                dismissCompletedAlert()
            }
        } message: {
            if let state = completedTimerAlert {
                Text("\(state.childName) completed \(state.categoryName)!")
            } else {
                Text("Great job!")
            }
        }
        .onChange(of: completedTimerAlert) { newValue in
            showingCompletedAlert = newValue != nil
        }
        // Show recovery alert when timers are restored
        .onReceive(serviceContainer.multiChildTimerManager.$hasRestoredTimers) { hasRestored in
            if hasRestored {
                showingRecoveryAlert = true
            }
        }
        .alert("Timer Restored", isPresented: $showingRecoveryAlert) {
            Button("Continue") {
                serviceContainer.multiChildTimerManager.acknowledgeTimerRestoration()
            }
        } message: {
            Text("Your timer has been restored from your last session. It's still running!")
        }
        // Handle Siri navigation
        .task {
            await handleSiriNavigation()
        }
        .onReceive(SiriNavigationState.shared.$pendingTimerStart) { pending in
            if pending != nil {
                Task { await handleSiriNavigation() }
            }
        }
    }

    @MainActor
    private func handleSiriNavigation() async {
        guard hasCompletedOnboarding else { return }

        if let pending = SiriNavigationState.shared.consumePendingTimerStart() {
            // Fetch the child for this timer
            do {
                if let child = try await serviceContainer.childRepository.fetch(by: pending.childId) {
                    // Set the current child
                    currentChild = child

                    // Set the pending category for timer view
                    serviceContainer.pendingTimerCategoryId = pending.categoryId

                    // Signal to navigate to timer tab and auto-start
                    serviceContainer.pendingSiriTimerNavigation = true
                    serviceContainer.shouldAutoStartTimer = true
                }
            } catch {
                print("Failed to load child for Siri timer: \(error)")
            }
        }
    }

    private func dismissCompletedAlert() {
        if let state = completedTimerAlert {
            serviceContainer.multiChildTimerManager.dismissCompletedTimer(state)
        }
        completedTimerAlert = nil
        showingCompletedAlert = false
    }
}

/// Tab identifiers for programmatic navigation
/// Restructured to 3 kid-friendly tabs: Today, Rewards, Me
enum AppTab: Hashable {
    case today
    case rewards
    case me
}

/// Main tab view for the primary app navigation
struct MainTabView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @State private var selectedTab: AppTab = .today
    @State private var showingTimerOverlay = false
    @State private var timerOverlayCategoryId: UUID?
    @State private var showingDailyGift = false
    @State private var dailyGiftContent: DailyGiftContent = .empty
    @State private var hasCheckedDailyGift = false
    let currentChild: Child

    var body: some View {
        TabView(selection: $selectedTab) {
            // Today tab - main kid experience with tasks and mascot
            TodayView(
                currentChild: currentChild,
                onStartTimer: { categoryId in
                    timerOverlayCategoryId = categoryId
                    showingTimerOverlay = true
                }
            )
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }
                .tag(AppTab.today)

            // Rewards tab - already kid-friendly
            RewardsView(
                rewardsService: serviceContainer.rewardsService,
                achievementService: serviceContainer.achievementService,
                currentChild: currentChild
            )
                .tabItem {
                    Label("Rewards", systemImage: "trophy.fill")
                }
                .tag(AppTab.rewards)

            // Me tab - avatar, points, simple progress
            MeView(currentChild: currentChild)
                .tabItem {
                    Label("Me", systemImage: "person.fill")
                }
                .tag(AppTab.me)
        }
        // Timer overlay - full screen cover
        .fullScreenCover(isPresented: $showingTimerOverlay) {
            TimerOverlayView(
                currentChild: currentChild,
                initialCategoryId: timerOverlayCategoryId,
                onDismiss: {
                    showingTimerOverlay = false
                    timerOverlayCategoryId = nil
                }
            )
        }
        // Handle Siri navigation - trigger timer overlay instead of tab
        .onReceive(serviceContainer.$pendingSiriTimerNavigation) { shouldNavigate in
            if shouldNavigate {
                if let categoryId = serviceContainer.pendingTimerCategoryId {
                    timerOverlayCategoryId = categoryId
                }
                showingTimerOverlay = true
                serviceContainer.pendingSiriTimerNavigation = false
            }
        }
        // Handle timer overlay from service container
        .onReceive(serviceContainer.$pendingTimerOverlay) { showOverlay in
            if showOverlay {
                if let categoryId = serviceContainer.pendingTimerCategoryId {
                    timerOverlayCategoryId = categoryId
                }
                showingTimerOverlay = true
                serviceContainer.pendingTimerOverlay = false
            }
        }
        // Handle deep link navigation from widgets
        .onReceive(serviceContainer.$pendingDeepLinkTab) { tab in
            if let tab = tab {
                selectedTab = tab
                serviceContainer.pendingDeepLinkTab = nil
            }
        }
        // Check for daily gift on first appearance
        .task {
            guard !hasCheckedDailyGift else { return }
            hasCheckedDailyGift = true
            await checkDailyGift()
        }
        // Daily gift overlay
        .fullScreenCover(isPresented: $showingDailyGift) {
            DailyGiftBoxView(
                childName: currentChild.name,
                giftContent: dailyGiftContent,
                onDismiss: {
                    markGiftShown()
                    showingDailyGift = false
                }
            )
        }
    }

    // MARK: - Daily Gift Methods

    private func checkDailyGift() async {
        let lastShownKey = "DailyGiftLastShown_\(currentChild.id.uuidString)"
        let lastShownDate = UserDefaults.standard.object(forKey: lastShownKey) as? Date
        let today = Calendar.current.startOfDay(for: Date())

        // Check if we've already shown the gift today
        if let lastDate = lastShownDate, Calendar.current.isDate(lastDate, inSameDayAs: today) {
            return
        }

        // Load gift content
        await loadGiftContent()

        // Show the gift
        showingDailyGift = true
    }

    private func loadGiftContent() async {
        var points = 0
        var streak = 0
        var activities = 0
        var newBadges: [String] = []

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            dailyGiftContent = .empty
            return
        }

        // Load yesterday's activities
        do {
            let dateRange = DateInterval(start: yesterday, end: today)
            let yesterdayActivities = try await serviceContainer.activityService.fetchActivities(
                for: currentChild,
                dateRange: dateRange
            )
            activities = yesterdayActivities.filter { $0.isComplete }.count

            // Calculate points from activities
            points = yesterdayActivities.reduce(0) { total, activity in
                total + (activity.isComplete ? activity.durationMinutes : 0)
            }
        } catch {
            print("Error loading yesterday's activities: \(error)")
        }

        // Load recently unlocked achievements (last 24 hours)
        do {
            let recentAchievements = try await serviceContainer.achievementService.fetchUnlockedAchievements(for: currentChild)
            let recentBadges = recentAchievements.filter { achievement in
                guard let unlockedDate = achievement.unlockedDate else { return false }
                return unlockedDate > yesterday
            }

            newBadges = recentBadges.compactMap { achievement in
                AchievementType(rawValue: achievement.achievementTypeId)?.emoji
            }
        } catch {
            print("Error loading achievements: \(error)")
        }

        // Simple streak calculation
        do {
            var currentStreak = 0
            var checkDate = yesterday

            for _ in 0..<14 {
                let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate)!
                let dayRange = DateInterval(start: checkDate, end: nextDay)
                let dayActivities = try await serviceContainer.activityService.fetchActivities(
                    for: currentChild,
                    dateRange: dayRange
                )

                if dayActivities.contains(where: { $0.isComplete }) {
                    currentStreak += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                } else {
                    break
                }
            }
            streak = currentStreak
        } catch {
            print("Error calculating streak: \(error)")
        }

        // Generate encouragement message
        let message = generateEncouragementMessage(points: points, streak: streak, activities: activities, badges: newBadges.count)

        dailyGiftContent = DailyGiftContent(
            pointsYesterday: points,
            currentStreak: streak,
            activitiesCompleted: activities,
            newBadges: newBadges,
            encouragementMessage: message
        )
    }

    private func generateEncouragementMessage(points: Int, streak: Int, activities: Int, badges: Int) -> String? {
        if points == 0 && activities == 0 {
            return "Start a timer today to earn awesome rewards!"
        }
        if badges > 0 {
            return "Amazing! You earned \(badges) new badge\(badges > 1 ? "s" : "")!"
        }
        if streak >= 7 {
            return "Incredible! \(streak) days in a row! You're a superstar!"
        } else if streak >= 3 {
            return "You're on fire! Keep the streak going!"
        }
        if activities > 0 {
            return "You completed \(activities) activit\(activities > 1 ? "ies" : "y")! Keep it up!"
        }
        return "Every day is a chance to learn and grow!"
    }

    private func markGiftShown() {
        let key = "DailyGiftLastShown_\(currentChild.id.uuidString)"
        UserDefaults.standard.set(Date(), forKey: key)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(ServiceContainer())
}
