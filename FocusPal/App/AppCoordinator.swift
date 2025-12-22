//
//  AppCoordinator.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Protocol defining the base coordinator interface.
/// Coordinators manage navigation flow and child coordinator lifecycle.
protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    func start()
    func coordinate(to coordinator: Coordinator)
}

extension Coordinator {
    func coordinate(to coordinator: Coordinator) {
        coordinator.start()
        childCoordinators.append(coordinator)
    }

    func removeChild(_ coordinator: Coordinator?) {
        childCoordinators = childCoordinators.filter { $0 !== coordinator }
    }
}

/// Root coordinator for the application.
/// Manages the top-level navigation flow including onboarding and main app.
class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []

    private let window: UIWindow?

    init(window: UIWindow?) {
        self.window = window
    }

    func start() {
        // Determine initial flow based on onboarding status
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        if hasCompletedOnboarding {
            showMainApp()
        } else {
            showOnboarding()
        }
    }

    private func showOnboarding() {
        // Start onboarding coordinator
    }

    private func showMainApp() {
        // Start main app coordinator
    }
}
