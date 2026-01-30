//
//  GetTodayTimeIntent.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import AppIntents
import Foundation

/// App Intent for getting today's total focus time via Siri.
/// Example: "Hey Siri, how much time today in FocusPal"
@available(iOS 16.0, *)
struct GetTodayTimeIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Today's Focus Time"
    static var description = IntentDescription("Reports your total focus time for today")

    @Parameter(title: "Child")
    var child: SiriChildEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Get today's focus time for \(\.$child)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let helper = SiriActivityHelper.shared

        // Resolve child - if not specified, get all children's time
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
                // Multiple children - get total for all
                childId = nil
                childName = nil
            }
        }

        do {
            let totalSeconds = try await helper.getTodayTotalTime(for: childId)
            let formattedTime = SiriActivityHelper.formatDuration(totalSeconds)

            if totalSeconds == 0 {
                if let name = childName {
                    return .result(dialog: "\(name) hasn't logged any focus time today. Start a timer to begin!")
                } else {
                    return .result(dialog: "No focus time logged today. Start a timer to begin!")
                }
            }

            if let name = childName {
                return .result(dialog: "\(name) has focused for \(formattedTime) today. Great job!")
            } else {
                return .result(dialog: "Total focus time today is \(formattedTime). Keep it up!")
            }
        } catch {
            return .result(dialog: "Sorry, I couldn't get today's focus time. Please try again.")
        }
    }
}
