//
//  ParentProfilePromptViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// ViewModel for the parent profile prompt shown to existing users
/// who haven't set up their parent profile yet.
@MainActor
class ParentProfilePromptViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var parentName = ""
    @Published var parentEmail = ""
    @Published var weeklyEmailEnabled = true
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSaved = false

    // MARK: - Dependencies

    private let parentRepository: ParentRepositoryProtocol

    // MARK: - Initialization

    init(parentRepository: ParentRepositoryProtocol? = nil) {
        self.parentRepository = parentRepository ?? CoreDataParentRepository(
            context: PersistenceController.shared.container.viewContext
        )
    }

    // MARK: - Validation

    /// Validates if the email format is valid
    func isEmailValid() -> Bool {
        let trimmedEmail = parentEmail.trimmingCharacters(in: .whitespaces)

        // Basic email validation
        let emailRegex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return emailPredicate.evaluate(with: trimmedEmail)
    }

    /// Checks if the form is valid and can be saved
    var canSave: Bool {
        let trimmedName = parentName.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = parentEmail.trimmingCharacters(in: .whitespaces)

        return !trimmedName.isEmpty && !trimmedEmail.isEmpty && isEmailValid()
    }

    // MARK: - Actions

    /// Saves the parent profile with the entered information
    func saveProfile() async {
        guard canSave else {
            errorMessage = "Please provide valid name and email"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Check if parent profile already exists
            let existingParent = try await parentRepository.fetch()

            let notificationPreferences = ParentNotificationPreferences(
                weeklyEmailEnabled: weeklyEmailEnabled,
                weeklyEmailDay: 1, // Sunday
                weeklyEmailTime: 9, // 9 AM
                achievementAlertsEnabled: true
            )

            if let existing = existingParent {
                // Update existing profile
                var updatedParent = existing
                updatedParent.name = parentName.trimmingCharacters(in: .whitespaces)
                updatedParent.email = parentEmail.trimmingCharacters(in: .whitespaces)
                updatedParent.notificationPreferences = notificationPreferences
                updatedParent.lastLoginDate = Date()

                _ = try await parentRepository.update(updatedParent)
            } else {
                // Create new profile
                let parent = Parent(
                    name: parentName.trimmingCharacters(in: .whitespaces),
                    email: parentEmail.trimmingCharacters(in: .whitespaces),
                    createdDate: Date(),
                    lastLoginDate: Date(),
                    notificationPreferences: notificationPreferences
                )

                _ = try await parentRepository.create(parent)
            }

            isSaved = true
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Skips the profile setup for now
    func skipForNow() {
        // Mark that we've shown the prompt
        UserDefaults.standard.set(true, forKey: "hasShownParentProfilePrompt")
        isSaved = true // Treat skip as completion to dismiss the sheet
    }
}
