//
//  AuthenticationViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import LocalAuthentication

/// ViewModel for parent authentication.
@MainActor
class AuthenticationViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var biometricType: BiometricType = .none
    @Published var errorMessage: String?

    // MARK: - Properties

    private let context = LAContext()
    private var storedPIN: String = "1234"  // In production, store securely in Keychain

    // MARK: - Initialization

    init() {
        checkBiometricType()
    }

    // MARK: - Biometric Type

    enum BiometricType {
        case none
        case touchID
        case faceID
    }

    private func checkBiometricType() {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricType = .none
            return
        }

        switch context.biometryType {
        case .faceID:
            biometricType = .faceID
        case .touchID:
            biometricType = .touchID
        default:
            biometricType = .none
        }
    }

    // MARK: - Authentication Methods

    func verifyPIN(_ pin: String) -> Bool {
        // In production, compare with securely stored PIN
        return pin == storedPIN
    }

    func authenticateWithBiometrics() async -> Bool {
        guard biometricType != .none else { return false }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Access Parent Controls"
            )
            return success
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updatePIN(_ newPIN: String) {
        // In production, store securely in Keychain
        storedPIN = newPIN
    }
}
