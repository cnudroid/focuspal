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

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                // Show main app with tab navigation
                MainTabView()
            } else {
                // Show onboarding flow
                OnboardingContainerView()
            }
        }
    }
}

/// Main tab view for the primary app navigation
struct MainTabView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            TimerView(
                timerService: serviceContainer.timerService,
                activityService: serviceContainer.activityService
            )
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            ActivityLogView()
                .tabItem {
                    Label("Log", systemImage: "list.bullet.clipboard")
                }

            StatisticsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
