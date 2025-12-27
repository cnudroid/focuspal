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

    init(childRepository: ChildRepositoryProtocol? = nil) {
        // Use real CoreData repository by default
        let repository = childRepository ?? CoreDataChildRepository(
            context: PersistenceController.shared.container.viewContext
        )
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(childRepository: repository))
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

            PermissionsView(onComplete: {
                viewModel.completeOnboarding()
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
    case permissions = 2
}

#Preview {
    OnboardingContainerView()
}
