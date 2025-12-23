//
//  ParentAuthViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// ViewModel for managing parent authentication state, PIN entry, and lockout logic
@MainActor
class ParentAuthViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var enteredPin: String = ""
    @Published var failedAttempts: Int = 0
    @Published var isAuthenticated: Bool = false
    @Published var shouldShake: Bool = false
    @Published var lockoutEndTime: Date?

    // MARK: - Properties

    private let pinService: PINServiceProtocol
    private let maxAttempts = 3
    private let lockoutDuration: TimeInterval = 30

    // MARK: - Computed Properties

    var isPinSetup: Bool {
        pinService.isPinSet()
    }

    var isLockedOut: Bool {
        guard let endTime = lockoutEndTime else { return false }
        return Date() < endTime
    }

    var remainingLockoutTime: TimeInterval {
        guard let endTime = lockoutEndTime else { return 0 }
        let remaining = endTime.timeIntervalSince(Date())
        return max(0, remaining)
    }

    // MARK: - Initialization

    init(pinService: PINServiceProtocol = PINService()) {
        self.pinService = pinService
    }

    // MARK: - PIN Entry Methods

    func addDigit(_ digit: Int) {
        guard !isLockedOut else { return }
        guard enteredPin.count < 4 else { return }

        enteredPin += "\(digit)"

        if enteredPin.count == 4 {
            Task {
                await verifyPin()
            }
        }
    }

    func deleteDigit() {
        guard !enteredPin.isEmpty else { return }
        enteredPin.removeLast()
    }

    // MARK: - Authentication Methods

    func verifyPin() async {
        guard !isLockedOut else { return }
        guard enteredPin.count == 4 else { return }

        let pin = enteredPin
        enteredPin = ""

        let isValid = pinService.verifyPin(pin: pin)

        if isValid {
            isAuthenticated = true
            failedAttempts = 0
            lockoutEndTime = nil
        } else {
            failedAttempts += 1
            shouldShake = true

            if failedAttempts >= maxAttempts {
                lockoutEndTime = Date().addingTimeInterval(lockoutDuration)
            }

            await resetShake()
        }
    }

    func resetShake() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        shouldShake = false
    }

    // MARK: - State Management

    func reset() {
        enteredPin = ""
        failedAttempts = 0
        isAuthenticated = false
        shouldShake = false
    }
}
