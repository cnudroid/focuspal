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
    }
}

/// Tab identifiers for programmatic navigation
enum AppTab: Hashable {
    case home
    case timer
    case log
    case stats
}

/// Main tab view for the primary app navigation
struct MainTabView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @State private var selectedTab: AppTab = .home
    let currentChild: Child

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab, currentChild: currentChild)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)

            TimerView(
                timerService: serviceContainer.timerService,
                activityService: serviceContainer.activityService,
                currentChild: currentChild
            )
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
                .tag(AppTab.timer)

            ActivityLogView(currentChild: currentChild)
                .tabItem {
                    Label("Log", systemImage: "list.bullet.clipboard")
                }
                .tag(AppTab.log)

            StatisticsView(currentChild: currentChild)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(AppTab.stats)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(ServiceContainer())
}
