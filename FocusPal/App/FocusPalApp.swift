//
//  FocusPalApp.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import CoreData
import AppIntents

/// Main entry point for the FocusPal application.
/// Configures the app lifecycle, dependency injection container, and root view.
@main
struct FocusPalApp: App {
    /// Shared persistence controller for Core Data
    let persistenceController = PersistenceController.shared

    /// Service container for dependency injection
    @StateObject private var serviceContainer = ServiceContainer()

    /// Track scene phase for lifecycle management
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(serviceContainer)
                .task {
                    // Check and send weekly email if due on app launch
                    serviceContainer.checkWeeklyEmailOnLaunch()

                    // Register App Shortcuts with the system for Siri integration
                    if #available(iOS 16.0, *) {
                        FocusPalShortcuts.updateAppShortcutParameters()
                    }
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    /// Handle deep links from widgets and other sources
    private func handleDeepLink(_ url: URL) {
        print("📱 Deep link received: \(url)")

        guard url.scheme == "focuspal" else { return }

        switch url.host {
        case "timer":
            // Check for category parameter
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let categoryId = components.queryItems?.first(where: { $0.name == "category" })?.value,
               let uuid = UUID(uuidString: categoryId) {
                // Navigate to timer with specific category
                serviceContainer.pendingTimerCategoryId = uuid
            }
            serviceContainer.pendingDeepLinkTab = .timer

        case "stats":
            serviceContainer.pendingDeepLinkTab = .stats

        case "rewards":
            serviceContainer.pendingDeepLinkTab = .rewards

        case "log":
            serviceContainer.pendingDeepLinkTab = .log

        default:
            break
        }
    }

    /// Handle scene phase changes to save timer state
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // App is in background - save timer state
            Task { @MainActor in
                await serviceContainer.multiChildTimerManager.persistStatesOnBackground()
            }
        case .inactive:
            // App is becoming inactive - save timer state
            Task { @MainActor in
                await serviceContainer.multiChildTimerManager.persistStatesOnBackground()
            }
        case .active:
            // App is active - update widget data
            serviceContainer.updateWidgetData()
        @unknown default:
            break
        }
    }
}
