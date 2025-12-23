//
//  PINSetupViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// ViewModel for managing PIN setup flow
@MainActor
class PINSetupViewModel: ObservableObject {

    // MARK: - Types

    enum SetupStep {
        case enterPin
        case confirmPin
    }

    // MARK: - Published Properties

    @Published var step: SetupStep = .enterPin
    @Published var enteredPin: String = ""
    @Published var confirmedPin: String = ""
    @Published var errorMessage: String?
    @Published var isComplete: Bool = false

    // MARK: - Properties

    private let pinService: PINServiceProtocol

    // MARK: - Computed Properties

    var currentPin: String {
        switch step {
        case .enterPin:
            return enteredPin
        case .confirmPin:
            return confirmedPin
        }
    }

    var instructionText: String {
        switch step {
        case .enterPin:
            return "Create a 4-digit PIN"
        case .confirmPin:
            return "Confirm your PIN"
        }
    }

    // MARK: - Initialization

    init(pinService: PINServiceProtocol = PINService()) {
        self.pinService = pinService
    }

    // MARK: - PIN Entry Methods

    func addDigit(_ digit: Int) {
        switch step {
        case .enterPin:
            guard enteredPin.count < 4 else { return }
            enteredPin += "\(digit)"

            if enteredPin.count == 4 {
                step = .confirmPin
            }

        case .confirmPin:
            guard confirmedPin.count < 4 else { return }
            confirmedPin += "\(digit)"

            if confirmedPin.count == 4 {
                Task {
                    await verifyAndSavePin()
                }
            }
        }
    }

    func deleteDigit() {
        switch step {
        case .enterPin:
            guard !enteredPin.isEmpty else { return }
            enteredPin.removeLast()

        case .confirmPin:
            guard !confirmedPin.isEmpty else { return }
            confirmedPin.removeLast()
        }
    }

    func goBack() {
        guard step == .confirmPin else { return }
        step = .enterPin
        confirmedPin = ""
        errorMessage = nil
    }

    // MARK: - PIN Setup Methods

    func verifyAndSavePin() async {
        guard enteredPin == confirmedPin else {
            errorMessage = "PINs do not match. Please try again."
            confirmedPin = ""
            return
        }

        do {
            try pinService.savePin(pin: enteredPin)
            isComplete = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save PIN. Please try again."
            confirmedPin = ""
        }
    }
}
