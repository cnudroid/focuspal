//
//  PINChangeView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// View for changing the parent PIN - requires verification of old PIN first
struct PINChangeView: View {
    @StateObject private var viewModel: PINChangeViewModel
    @Environment(\.dismiss) private var dismiss

    init(pinService: PINServiceProtocol = PINService()) {
        _viewModel = StateObject(wrappedValue: PINChangeViewModel(pinService: pinService))
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Lock icon
            Image(systemName: "lock.rotation")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text(viewModel.instructionText)
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // PIN dots with shake animation
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < viewModel.currentPin.count ? Color.accentColor : Color(.systemGray4))
                        .frame(width: 16, height: 16)
                }
            }
            .padding()
            .modifier(ShakeEffect(shakes: viewModel.shouldShake ? 3 : 0))

            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Success message
            if viewModel.isComplete {
                Text("PIN changed successfully!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Number pad
            VStack(spacing: 16) {
                ForEach(0..<3) { row in
                    HStack(spacing: 24) {
                        ForEach(1...3, id: \.self) { col in
                            let number = row * 3 + col
                            NumberButton(number: number) {
                                viewModel.addDigit(number)
                            }
                        }
                    }
                }

                HStack(spacing: 24) {
                    // Back button (when in new/confirm steps)
                    if viewModel.step != .verifyOld {
                        Button {
                            viewModel.goBack()
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.title2)
                                .frame(width: 70, height: 70)
                        }
                    } else {
                        Spacer()
                            .frame(width: 70, height: 70)
                    }

                    NumberButton(number: 0) {
                        viewModel.addDigit(0)
                    }

                    // Delete button
                    Button {
                        viewModel.deleteDigit()
                    } label: {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .frame(width: 70, height: 70)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Change PIN")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.isComplete) { isComplete in
            if isComplete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - PIN Change ViewModel

@MainActor
class PINChangeViewModel: ObservableObject {

    // MARK: - Types

    enum ChangeStep {
        case verifyOld
        case enterNew
        case confirmNew
    }

    // MARK: - Published Properties

    @Published var step: ChangeStep = .verifyOld
    @Published var oldPin: String = ""
    @Published var newPin: String = ""
    @Published var confirmedPin: String = ""
    @Published var errorMessage: String?
    @Published var isComplete: Bool = false
    @Published var shouldShake: Bool = false

    // MARK: - Properties

    private let pinService: PINServiceProtocol

    // MARK: - Computed Properties

    var currentPin: String {
        switch step {
        case .verifyOld:
            return oldPin
        case .enterNew:
            return newPin
        case .confirmNew:
            return confirmedPin
        }
    }

    var instructionText: String {
        switch step {
        case .verifyOld:
            return "Enter your current PIN"
        case .enterNew:
            return "Enter your new PIN"
        case .confirmNew:
            return "Confirm your new PIN"
        }
    }

    // MARK: - Initialization

    init(pinService: PINServiceProtocol = PINService()) {
        self.pinService = pinService
    }

    // MARK: - PIN Entry Methods

    func addDigit(_ digit: Int) {
        switch step {
        case .verifyOld:
            guard oldPin.count < 4 else { return }
            oldPin += "\(digit)"
            if oldPin.count == 4 {
                Task { await verifyOldPin() }
            }

        case .enterNew:
            guard newPin.count < 4 else { return }
            newPin += "\(digit)"
            if newPin.count == 4 {
                step = .confirmNew
            }

        case .confirmNew:
            guard confirmedPin.count < 4 else { return }
            confirmedPin += "\(digit)"
            if confirmedPin.count == 4 {
                Task { await saveNewPin() }
            }
        }
    }

    func deleteDigit() {
        switch step {
        case .verifyOld:
            guard !oldPin.isEmpty else { return }
            oldPin.removeLast()

        case .enterNew:
            guard !newPin.isEmpty else { return }
            newPin.removeLast()

        case .confirmNew:
            guard !confirmedPin.isEmpty else { return }
            confirmedPin.removeLast()
        }
    }

    func goBack() {
        switch step {
        case .verifyOld:
            break
        case .enterNew:
            step = .verifyOld
            newPin = ""
            errorMessage = nil
        case .confirmNew:
            step = .enterNew
            confirmedPin = ""
            errorMessage = nil
        }
    }

    // MARK: - Verification Methods

    private func verifyOldPin() async {
        guard pinService.verifyPin(pin: oldPin) else {
            errorMessage = "Incorrect PIN. Please try again."
            oldPin = ""
            shouldShake = true
            await resetShake()
            return
        }

        step = .enterNew
        errorMessage = nil
    }

    private func saveNewPin() async {
        guard newPin == confirmedPin else {
            errorMessage = "PINs do not match. Please try again."
            confirmedPin = ""
            shouldShake = true
            await resetShake()
            return
        }

        guard newPin != oldPin else {
            errorMessage = "New PIN must be different from old PIN."
            confirmedPin = ""
            shouldShake = true
            await resetShake()
            return
        }

        do {
            try pinService.savePin(pin: newPin)
            isComplete = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save PIN. Please try again."
            confirmedPin = ""
            shouldShake = true
            await resetShake()
        }
    }

    private func resetShake() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        shouldShake = false
    }
}

#Preview {
    PINChangeView()
}
