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
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        // Start Timer
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

        // Get Today's Time
        AppShortcut(
            intent: GetTodayTimeIntent(),
            phrases: [
                "How much time today in \(.applicationName)",
                "What's my focus time today in \(.applicationName)",
                "How long have I focused today in \(.applicationName)",
                "\(.applicationName) today's time",
                "\(.applicationName) how much time"
            ],
            shortTitle: "Today's Time",
            systemImageName: "clock"
        )

        // Get Streak
        AppShortcut(
            intent: GetStreakIntent(),
            phrases: [
                "What's my streak in \(.applicationName)",
                "How long is my streak in \(.applicationName)",
                "Check my streak in \(.applicationName)",
                "\(.applicationName) my streak",
                "\(.applicationName) streak"
            ],
            shortTitle: "Focus Streak",
            systemImageName: "flame"
        )

        // Log Activity
        AppShortcut(
            intent: LogActivityIntent(),
            phrases: [
                "Log \(\LogActivityIntent.$category) in \(.applicationName)",
                "Log activity in \(.applicationName)",
                "Record \(\LogActivityIntent.$category) in \(.applicationName)",
                "\(.applicationName) log \(\LogActivityIntent.$category)",
                "\(.applicationName) log activity"
            ],
            shortTitle: "Log Activity",
            systemImageName: "plus.circle"
        )
    }
}
