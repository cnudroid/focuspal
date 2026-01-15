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
enum AppTab: Hashable {
    case home
    case schedule
    case timer
    case log
    case stats
    case rewards
}

/// Main tab view for the primary app navigation
struct MainTabView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @State private var selectedTab: AppTab = .home
    let currentChild: Child

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                selectedTab: $selectedTab,
                currentChild: currentChild,
                activityService: serviceContainer.activityService,
                categoryService: serviceContainer.categoryService,
                pointsService: serviceContainer.pointsService
            )
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)

            ScheduledTasksView(child: currentChild, selectedTab: $selectedTab)
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(AppTab.schedule)

            TimerView(
                timerManager: serviceContainer.multiChildTimerManager,
                activityService: serviceContainer.activityService,
                pointsService: serviceContainer.pointsService,
                rewardsService: serviceContainer.rewardsService,
                currentChild: currentChild
            )
                .id(currentChild.id)  // Force recreation when child changes
                .transition(.identity)  // Prevent default transition animation
                .animation(nil, value: currentChild.id)  // Disable animation on child switch
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
                .tag(AppTab.timer)

            RewardsView(
                rewardsService: serviceContainer.rewardsService,
                achievementService: serviceContainer.achievementService,
                currentChild: currentChild
            )
                .tabItem {
                    Label("Rewards", systemImage: "trophy.fill")
                }
                .tag(AppTab.rewards)

            StatisticsView(currentChild: currentChild)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(AppTab.stats)

            ActivityLogView(currentChild: currentChild)
                .tabItem {
                    Label("Log", systemImage: "list.bullet.clipboard")
                }
                .tag(AppTab.log)
        }
        // Handle Siri navigation to timer tab
        .onReceive(serviceContainer.$pendingSiriTimerNavigation) { shouldNavigate in
            if shouldNavigate {
                selectedTab = .timer
                serviceContainer.pendingSiriTimerNavigation = false
            }
        }
        // Handle deep link navigation from widgets
        .onReceive(serviceContainer.$pendingDeepLinkTab) { tab in
            if let tab = tab {
                selectedTab = tab
                serviceContainer.pendingDeepLinkTab = nil
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(ServiceContainer())
}
