//
//  FocusPalApp.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import CoreData

/// Main entry point for the FocusPal application.
/// Configures the app lifecycle, dependency injection container, and root view.
@main
struct FocusPalApp: App {
    /// Shared persistence controller for Core Data
    let persistenceController = PersistenceController.shared

    /// Service container for dependency injection
    @StateObject private var serviceContainer = ServiceContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(serviceContainer)
                .task {
                    // Check and send weekly email if due on app launch
                    serviceContainer.checkWeeklyEmailOnLaunch()
                }
        }
    }
}
