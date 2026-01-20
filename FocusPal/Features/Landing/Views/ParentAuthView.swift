//
//  ParentAuthView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import LocalAuthentication

/// Wrapper view for parent authentication - Face ID first, PIN as fallback.
struct ParentAuthView: View {
    let onAuthenticated: () -> Void
    let onCancel: () -> Void

    @State private var isPinSet: Bool = false
    @State private var hasCheckedPin: Bool = false
    @State private var biometricFailures: Int = 0
    @State private var showPINFallback: Bool = false
    @State private var biometricType: BiometricType = .none
    @State private var isAuthenticating: Bool = false
    @State private var errorMessage: String?

    private let pinService = PINService()
    private let maxBiometricAttempts = 3

    enum BiometricType {
        case none, faceID, touchID
    }

    var body: some View {
        NavigationStack {
            Group {
                if !hasCheckedPin {
                    ProgressView()
                        .onAppear {
                            checkInitialState()
                        }
                } else if !isPinSet {
                    // First time: show PIN setup
                    PINSetupView(pinService: pinService) {
                        isPinSet = true
                        onAuthenticated()
                    }
                } else if showPINFallback || biometricType == .none {
                    // Show PIN entry (fallback or no biometrics available)
                    PINEntryView(pinService: pinService, onAuthenticated: onAuthenticated)
                } else {
                    // Show biometric authentication view
                    biometricAuthView
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
        .task {
            // Auto-attempt biometrics if PIN is set and biometrics available
            if hasCheckedPin && isPinSet && biometricType != .none && !showPINFallback {
                await attemptBiometricAuth()
            }
        }
    }

    // MARK: - Biometric Auth View

    private var biometricAuthView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Biometric icon
            Image(systemName: biometricType == .faceID ? "faceid" : "touchid")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            Text("Parent Controls")
                .font(.title2)
                .fontWeight(.bold)

            if let error = errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text(biometricType == .faceID ? "Use Face ID to access" : "Use Touch ID to access")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Retry button
            if !isAuthenticating {
                Button {
                    Task {
                        await attemptBiometricAuth()
                    }
                } label: {
                    HStack {
                        Image(systemName: biometricType == .faceID ? "faceid" : "touchid")
                        Text("Try Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            } else {
                ProgressView()
                    .padding()
            }

            Spacer()

            // Use PIN instead button
            Button {
                showPINFallback = true
            } label: {
                Text("Use PIN Instead")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
            .padding(.bottom, 40)

            // Attempts remaining indicator
            if biometricFailures > 0 {
                Text("\(maxBiometricAttempts - biometricFailures) attempt\(maxBiometricAttempts - biometricFailures == 1 ? "" : "s") remaining before PIN required")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Helper Methods

    private func checkInitialState() {
        isPinSet = pinService.isPinSet()
        biometricType = detectBiometricType()
        hasCheckedPin = true
    }

    private func detectBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }

    private func attemptBiometricAuth() async {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        errorMessage = nil

        let context = LAContext()
        let reason = "Access Parent Controls"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            if success {
                onAuthenticated()
            } else {
                handleBiometricFailure(message: "Authentication failed")
            }
        } catch let error as LAError {
            switch error.code {
            case .userCancel:
                // User cancelled - don't count as failure
                errorMessage = nil
            case .userFallback:
                // User chose to use PIN
                showPINFallback = true
            case .biometryLockout:
                // Too many failed attempts at system level
                errorMessage = "Biometrics locked. Please use PIN."
                showPINFallback = true
            case .biometryNotAvailable, .biometryNotEnrolled:
                showPINFallback = true
            default:
                handleBiometricFailure(message: "Authentication failed. Try again.")
            }
        } catch {
            handleBiometricFailure(message: "Authentication failed. Try again.")
        }

        isAuthenticating = false
    }

    private func handleBiometricFailure(message: String) {
        biometricFailures += 1
        errorMessage = message

        if biometricFailures >= maxBiometricAttempts {
            errorMessage = "Too many failed attempts. Please use PIN."
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showPINFallback = true
            }
        }
    }
}

#Preview {
    ParentAuthView(onAuthenticated: {}, onCancel: {})
}
