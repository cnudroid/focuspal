//
//  OnboardingViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import SwiftUI

/// ViewModel for the onboarding flow.
@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentStep: OnboardingStep = .welcome
    @Published var childName = ""
    @Published var childAge = 8
    @Published var selectedAvatar = "person.circle.fill"
    @Published var selectedTheme = "blue"
    @Published var errorMessage: String?

    // Parent profile properties
    @Published var parentName = ""
    @Published var parentEmail = ""
    @Published var weeklyEmailEnabled = true

    // MARK: - Dependencies

    private let pinService: PINServiceProtocol
    private let childRepository: ChildRepositoryProtocol
    private let parentRepository: ParentRepositoryProtocol

    // MARK: - App Storage

    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false

    // MARK: - Validation Constants

    private let minAge = 4
    private let maxAge = 16
    private let pinLength = 4

    // MARK: - Initialization

    init(
        pinService: PINServiceProtocol = PINService(),
        childRepository: ChildRepositoryProtocol,
        parentRepository: ParentRepositoryProtocol
    ) {
        self.pinService = pinService
        self.childRepository = childRepository
        self.parentRepository = parentRepository
    }

    // MARK: - Navigation

    func nextStep() {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            return
        }
        currentStep = nextStep
    }

    func previousStep() {
        guard let prevStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else {
            return
        }
        currentStep = prevStep
    }

    // MARK: - PIN Management

    /// Validate PIN format and length
    /// - Parameter pin: The PIN to validate
    /// - Returns: true if PIN is valid, false otherwise
    func validatePIN(_ pin: String) -> Bool {
        clearError()

        // Check length
        guard pin.count == pinLength else {
            errorMessage = "PIN must be exactly 4 digits"
            return false
        }

        // Check numeric format
        guard pin.allSatisfy({ $0.isNumber }) else {
            errorMessage = "PIN must contain only numbers"
            return false
        }

        return true
    }

    /// Save PIN to secure storage
    /// - Parameter pin: The PIN to save
    /// - Returns: true if save succeeded, false otherwise
    func savePIN(_ pin: String) async -> Bool {
        // Validate first
        guard validatePIN(pin) else {
            return false
        }

        do {
            try pinService.savePin(pin: pin)
            clearError()
            return true
        } catch {
            errorMessage = "Failed to save PIN: \(error.localizedDescription)"
            return false
        }
    }

    /// Confirm PIN matches the original
    /// - Parameters:
    ///   - pin: Original PIN
    ///   - confirmedPIN: Confirmation PIN
    /// - Returns: true if PINs match, false otherwise
    func confirmPIN(_ pin: String, confirmedPIN: String) -> Bool {
        clearError()

        guard pin == confirmedPIN else {
            errorMessage = "PINs do not match. Please try again."
            return false
        }

        return true
    }

    // MARK: - Profile Management

    /// Validate parent profile data
    /// - Returns: true if profile data is valid, false otherwise
    func validateParentProfile() -> Bool {
        clearError()

        // Validate name
        let trimmedName = parentName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter your name"
            return false
        }

        // Validate email
        let trimmedEmail = parentEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email"
            return false
        }

        guard isValidEmail(trimmedEmail) else {
            errorMessage = "Please enter a valid email address"
            return false
        }

        return true
    }

    /// Validate email format using regex
    /// - Parameter email: The email to validate
    /// - Returns: true if email format is valid, false otherwise
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// Save parent profile to repository
    /// - Returns: true if save succeeded, false otherwise
    func saveParentProfile() async -> Bool {
        // Validate first
        guard validateParentProfile() else {
            return false
        }

        let preferences = ParentNotificationPreferences(
            weeklyEmailEnabled: weeklyEmailEnabled,
            weeklyEmailDay: 1,
            weeklyEmailTime: 9,
            achievementAlertsEnabled: true
        )

        let parent = Parent(
            name: parentName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: parentEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            notificationPreferences: preferences
        )

        do {
            _ = try await parentRepository.create(parent)
            clearError()
            return true
        } catch {
            errorMessage = "Failed to save parent profile: \(error.localizedDescription)"
            return false
        }
    }

    /// Validate child profile data
    /// - Returns: true if profile data is valid, false otherwise
    func validateProfile() -> Bool {
        clearError()

        // Validate name
        let trimmedName = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a name for your child"
            return false
        }

        // Validate age range
        guard childAge >= minAge && childAge <= maxAge else {
            errorMessage = "Age must be between \(minAge) and \(maxAge)"
            return false
        }

        return true
    }

    /// Save child profile to repository
    /// - Returns: true if save succeeded, false otherwise
    func saveChildProfile() async -> Bool {
        // Validate first
        guard validateProfile() else {
            return false
        }

        let child = Child(
            name: childName.trimmingCharacters(in: .whitespacesAndNewlines),
            age: childAge,
            avatarId: selectedAvatar,
            themeColor: selectedTheme,
            isActive: true
        )

        do {
            _ = try await childRepository.create(child)
            clearError()
            return true
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Onboarding Completion

    func completeOnboarding() {
        // Just mark onboarding as complete
        // Child profiles are added via Parent Controls after onboarding
        hasCompletedOnboarding = true
    }

    // MARK: - Error Handling

    func clearError() {
        errorMessage = nil
    }
}
