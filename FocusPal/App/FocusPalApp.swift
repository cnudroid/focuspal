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
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
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
            // App is active - check for restored timers
            break
        @unknown default:
            break
        }
    }
}
