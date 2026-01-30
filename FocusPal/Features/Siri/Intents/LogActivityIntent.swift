//
//  LogActivityIntent.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import AppIntents
import Foundation

/// App Intent for logging an activity via Siri.
/// Example: "Hey Siri, log homework for 30 minutes in FocusPal"
@available(iOS 16.0, *)
struct LogActivityIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Activity"
    static var description = IntentDescription("Manually log a focus activity")

    @Parameter(title: "Activity")
    var category: SiriCategoryEntity

    @Parameter(title: "Duration in minutes")
    var durationMinutes: Int?

    @Parameter(title: "Child")
    var child: SiriChildEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$durationMinutes) minutes of \(\.$category) for \(\.$child)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let helper = SiriActivityHelper.shared

        // Resolve child
        let selectedChild: Child
        if let childEntity = child {
            selectedChild = childEntity.toChild()
        } else {
            // Try to get single child
            if let singleChild = try await helper.getSingleChild() {
                selectedChild = singleChild
            } else {
                // Multiple children - need to ask
                throw $child.needsValueError("Which child should I log this for?")
            }
        }

        // Resolve duration - use category's recommended duration if not specified
        let duration: Int
        if let minutes = durationMinutes, minutes > 0 {
            duration = minutes
        } else {
            // Use category's recommended duration or ask
            let recommendedMinutes = Int(category.recommendedDuration / 60)
            if recommendedMinutes > 0 {
                duration = recommendedMinutes
            } else {
                throw $durationMinutes.needsValueError("How many minutes?")
            }
        }

        // Validate duration
        guard duration > 0 && duration <= 480 else {
            return .result(dialog: "Please specify a duration between 1 and 480 minutes.")
        }

        do {
            let activity = try await helper.logActivity(
                childId: selectedChild.id,
                categoryId: category.id,
                durationMinutes: duration
            )

            let _ = activity // Activity created successfully

            return .result(dialog: "Logged \(duration) minutes of \(category.name) for \(selectedChild.name)!")
        } catch {
            return .result(dialog: "Sorry, I couldn't log that activity. Please try again.")
        }
    }
}
