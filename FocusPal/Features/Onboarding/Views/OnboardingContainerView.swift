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

    init(childRepository: ChildRepositoryProtocol? = nil, parentRepository: ParentRepositoryProtocol? = nil) {
        // Use real CoreData repositories by default
        let childRepo = childRepository ?? CoreDataChildRepository(
            context: PersistenceController.shared.container.viewContext
        )
        let parentRepo = parentRepository ?? CoreDataParentRepository(
            context: PersistenceController.shared.container.viewContext
        )
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(
            childRepository: childRepo,
            parentRepository: parentRepo
        ))
    }

    var body: some View {
        TabView(selection: $viewModel.currentStep) {
            WelcomeView(onContinue: viewModel.nextStep)
                .tag(OnboardingStep.welcome)

            ParentProfileView(
                viewModel: viewModel,
                onComplete: viewModel.nextStep
            )
            .tag(OnboardingStep.parentProfile)

            CreatePINView(
                viewModel: viewModel,
                onComplete: viewModel.completeOnboarding
            )
            .tag(OnboardingStep.createPIN)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: viewModel.currentStep)
    }
}

/// Onboarding steps
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case parentProfile = 1
    case createPIN = 2
}

#Preview {
    OnboardingContainerView()
}
