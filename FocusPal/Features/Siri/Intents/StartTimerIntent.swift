//
//  StartTimerIntent.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import AppIntents
import Foundation

/// App Intent for starting a focus timer via Siri.
/// Example: "Hey Siri, start homework timer in FocusPal"
@available(iOS 16.0, *)
struct StartTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Timer"
    static var description = IntentDescription("Start a focus timer for an activity")

    // Open the app when this intent runs
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Activity")
    var category: SiriCategoryEntity?

    @Parameter(title: "Child")
    var child: SiriChildEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Start \(\.$category) timer for \(\.$child)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Step 1: Resolve the child
        let selectedChild: Child
        do {
            selectedChild = try await resolveChild()
        } catch let error as ChildResolutionError {
            switch error {
            case .noChildren:
                return .result(dialog: "Please create a child profile first in FocusPal.")
            case .needsSelection:
                throw $child.needsValueError("Which child should I start the timer for?")
            }
        }

        // Step 2: Resolve the category
        let selectedCategory: Category
        if let categoryEntity = category {
            selectedCategory = categoryEntity.toCategory(childId: selectedChild.id)
        } else {
            // Use first available task category as default
            let categories = CategoryData.loadActiveTasks(for: selectedChild.id)
            if let first = categories.first {
                selectedCategory = first
            } else {
                return .result(dialog: "No activity categories found. Please set up categories in FocusPal.")
            }
        }

        // Step 3: Set up navigation state for the app
        SiriNavigationState.shared.pendingTimerStart = PendingTimerStart(
            childId: selectedChild.id,
            categoryId: selectedCategory.id
        )

        let durationMinutes = Int(selectedCategory.recommendedDuration / 60)
        return .result(dialog: "Starting \(selectedCategory.name) timer for \(selectedChild.name)! \(durationMinutes) minutes.")
    }

    // MARK: - Private Helpers

    private enum ChildResolutionError: Error {
        case noChildren
        case needsSelection
    }

    @MainActor
    private func resolveChild() async throws -> Child {
        // If child was explicitly provided, use it
        if let childEntity = child {
            return childEntity.toChild()
        }

        // Otherwise, fetch all children and decide
        let repository = CoreDataChildRepository(
            context: PersistenceController.shared.container.viewContext
        )
        let children = try await repository.fetchAll()

        switch children.count {
        case 0:
            throw ChildResolutionError.noChildren
        case 1:
            // Single child - auto-select
            return children[0]
        default:
            // Multiple children - need to ask
            throw ChildResolutionError.needsSelection
        }
    }
}
