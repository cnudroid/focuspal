//
//  GetStreakIntent.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import AppIntents
import Foundation

/// App Intent for getting the current focus streak via Siri.
/// Example: "Hey Siri, what's my streak in FocusPal"
@available(iOS 16.0, *)
struct GetStreakIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Focus Streak"
    static var description = IntentDescription("Reports your current focus streak")

    @Parameter(title: "Child")
    var child: SiriChildEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Get focus streak for \(\.$child)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let helper = SiriActivityHelper.shared

        // Resolve child - if not specified, get combined streak
        let childId: UUID?
        let childName: String?

        if let childEntity = child {
            childId = childEntity.id
            childName = childEntity.name
        } else {
            // Check if there's a single child - auto-select
            if let singleChild = try await helper.getSingleChild() {
                childId = singleChild.id
                childName = singleChild.name
            } else {
                // Multiple children - get combined streak
                childId = nil
                childName = nil
            }
        }

        do {
            let streak = try await helper.getCurrentStreak(for: childId)
            let formattedStreak = SiriActivityHelper.formatStreak(streak)

            if streak == 0 {
                if let name = childName {
                    return .result(dialog: "\(name) doesn't have a streak yet. Log an activity today to start one!")
                } else {
                    return .result(dialog: "No streak yet. Log an activity today to start one!")
                }
            }

            if let name = childName {
                if streak >= 7 {
                    return .result(dialog: "Amazing! \(name)'s current streak is \(formattedStreak)! Keep up the great work!")
                } else if streak >= 3 {
                    return .result(dialog: "Nice! \(name)'s current streak is \(formattedStreak). Keep going!")
                } else {
                    return .result(dialog: "\(name)'s current streak is \(formattedStreak). Great start!")
                }
            } else {
                if streak >= 7 {
                    return .result(dialog: "Amazing! Your current streak is \(formattedStreak)! Keep up the great work!")
                } else if streak >= 3 {
                    return .result(dialog: "Nice! Your current streak is \(formattedStreak). Keep going!")
                } else {
                    return .result(dialog: "Your current streak is \(formattedStreak). Great start!")
                }
            }
        } catch {
            return .result(dialog: "Sorry, I couldn't get your streak. Please try again.")
        }
    }
}
