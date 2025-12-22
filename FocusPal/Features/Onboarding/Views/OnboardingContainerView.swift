//
//  OnboardingContainerView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Container view managing the onboarding flow.
struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        TabView(selection: $viewModel.currentStep) {
            WelcomeView(onContinue: viewModel.nextStep)
                .tag(OnboardingStep.welcome)

            CreatePINView(onComplete: viewModel.nextStep)
                .tag(OnboardingStep.createPIN)

            CreateProfileView(onComplete: viewModel.nextStep)
                .tag(OnboardingStep.createProfile)

            PermissionsView(onComplete: viewModel.completeOnboarding)
                .tag(OnboardingStep.permissions)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: viewModel.currentStep)
    }
}

/// Onboarding steps
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case createPIN = 1
    case createProfile = 2
    case permissions = 3
}

#Preview {
    OnboardingContainerView()
}
