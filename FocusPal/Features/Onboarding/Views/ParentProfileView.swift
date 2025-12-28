//
//  ParentProfileView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Parent profile setup screen in onboarding flow.
struct ParentProfileView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var isProcessing = false
    @FocusState private var focusedField: Field?

    enum Field {
        case name
        case email
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            // Header
            VStack(spacing: 8) {
                Text("Parent Profile")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Let's set up your profile for weekly reports and account management.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Form fields
            VStack(spacing: 20) {
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    TextField("Enter your name", text: $viewModel.parentName)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .email
                        }
                }

                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Address")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    TextField("your.email@example.com", text: $viewModel.parentEmail)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                            handleContinue()
                        }
                }

                // Weekly email toggle
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $viewModel.weeklyEmailEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weekly Email Reports")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Get a summary of your child's activities every Sunday")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.accentColor)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)

            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            if isProcessing {
                ProgressView()
                    .padding(.top, 8)
            }

            Spacer()

            // Continue button
            Button(action: handleContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canContinue ? Color.accentColor : Color.gray)
                    .cornerRadius(14)
            }
            .disabled(!canContinue || isProcessing)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            // Auto-focus on name field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .name
            }
        }
    }

    private var canContinue: Bool {
        !viewModel.parentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.parentEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func handleContinue() {
        guard canContinue else { return }

        focusedField = nil
        isProcessing = true

        Task {
            let success = await viewModel.saveParentProfile()
            isProcessing = false

            if success {
                onComplete()
            }
        }
    }
}

#Preview {
    ParentProfileView(
        viewModel: OnboardingViewModel(
            childRepository: MockChildRepository(),
            parentRepository: MockParentRepository()
        ),
        onComplete: { }
    )
}
