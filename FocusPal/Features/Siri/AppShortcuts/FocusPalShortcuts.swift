//
//  FocusPalShortcuts.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import AppIntents

/// Provides App Shortcuts for Siri integration.
/// These phrases appear in the Shortcuts app and can be invoked via Siri.
@available(iOS 16.0, *)
struct FocusPalShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTimerIntent(),
            phrases: [
                "Start \(\StartTimerIntent.$category) timer in \(.applicationName)",
                "Start \(\StartTimerIntent.$category) in \(.applicationName)",
                "Start a timer in \(.applicationName)",
                "Begin \(\StartTimerIntent.$category) in \(.applicationName)",
                "\(.applicationName) start timer",
                "\(.applicationName) start \(\StartTimerIntent.$category)"
            ],
            shortTitle: "Start Timer",
            systemImageName: "timer"
        )
    }
}
