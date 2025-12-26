//
//  CreatePINView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// PIN creation screen in onboarding flow.
struct CreatePINView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var isConfirming = false
    @State private var showError = false
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            VStack(spacing: 8) {
                Text(isConfirming ? "Confirm Your PIN" : "Create a Parent PIN")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("This PIN protects parent controls and settings.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // PIN dots
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < currentPin.count ? Color.accentColor : Color(.systemGray4))
                        .frame(width: 16, height: 16)
                }
            }
            .padding()

            if showError || viewModel.errorMessage != nil {
                Text(viewModel.errorMessage ?? "PINs don't match. Please try again.")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if isProcessing {
                ProgressView()
                    .padding(.top, 8)
            }

            Spacer()

            // Number pad
            VStack(spacing: 16) {
                ForEach(0..<3) { row in
                    HStack(spacing: 24) {
                        ForEach(1...3, id: \.self) { col in
                            let number = row * 3 + col
                            NumberPadButton(number: number) {
                                addDigit(number)
                            }
                        }
                    }
                }

                HStack(spacing: 24) {
                    Color.clear.frame(width: 70, height: 70)

                    NumberPadButton(number: 0) {
                        addDigit(0)
                    }

                    Button {
                        deleteDigit()
                    } label: {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .frame(width: 70, height: 70)
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .padding()
    }

    private var currentPin: String {
        isConfirming ? confirmPin : pin
    }

    private func addDigit(_ digit: Int) {
        if isConfirming {
            guard confirmPin.count < 4 else { return }
            confirmPin += "\(digit)"

            if confirmPin.count == 4 {
                validatePINs()
            }
        } else {
            guard pin.count < 4 else { return }
            pin += "\(digit)"

            if pin.count == 4 {
                isConfirming = true
            }
        }
    }

    private func deleteDigit() {
        if isConfirming {
            if !confirmPin.isEmpty {
                confirmPin.removeLast()
            }
        } else {
            if !pin.isEmpty {
                pin.removeLast()
            }
        }
    }

    private func validatePINs() {
        guard viewModel.confirmPIN(pin, confirmedPIN: confirmPin) else {
            showError = true
            pin = ""
            confirmPin = ""
            isConfirming = false
            return
        }

        // Save PIN using view model
        isProcessing = true
        Task {
            let success = await viewModel.savePIN(pin)
            isProcessing = false

            if success {
                onComplete()
            } else {
                showError = true
                pin = ""
                confirmPin = ""
                isConfirming = false
            }
        }
    }
}

struct NumberPadButton: View {
    let number: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(.title)
                .fontWeight(.medium)
                .frame(width: 70, height: 70)
                .background(Color(.systemGray6))
                .cornerRadius(35)
        }
    }
}

#Preview {
    CreatePINView(
        viewModel: OnboardingViewModel(childRepository: MockChildRepository()),
        onComplete: { }
    )
}
