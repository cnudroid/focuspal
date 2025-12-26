//
//  OnboardingContainerView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Container view managing the onboarding flow.
struct OnboardingContainerView: View {
    @StateObject private var viewModel: OnboardingViewModel

    init(childRepository: ChildRepositoryProtocol = MockChildRepository()) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(childRepository: childRepository))
    }

    var body: some View {
        TabView(selection: $viewModel.currentStep) {
            WelcomeView(onContinue: viewModel.nextStep)
                .tag(OnboardingStep.welcome)

            CreatePINView(
                viewModel: viewModel,
                onComplete: viewModel.nextStep
            )
            .tag(OnboardingStep.createPIN)

            CreateProfileView(
                viewModel: viewModel,
                onComplete: viewModel.nextStep
            )
            .tag(OnboardingStep.createProfile)

            PermissionsView(onComplete: {
                Task {
                    await viewModel.completeOnboarding()
                }
            })
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
