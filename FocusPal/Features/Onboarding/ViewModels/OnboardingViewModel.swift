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
    @Published var selectedAvatar = "avatar_default"
    @Published var selectedTheme = "blue"

    // MARK: - App Storage

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

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

    func completeOnboarding() {
        // Save all data
        saveChildProfile()
        hasCompletedOnboarding = true
    }

    // MARK: - Private Methods

    private func saveChildProfile() {
        let child = Child(
            name: childName,
            age: childAge,
            avatarId: selectedAvatar,
            themeColor: selectedTheme
        )

        // Save to repository
        // In production, use ChildRepository
        print("Saving child profile: \(child.name)")
    }
}
