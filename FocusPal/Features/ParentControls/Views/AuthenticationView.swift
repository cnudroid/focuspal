//
//  AuthenticationView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import LocalAuthentication

/// Parent authentication view with PIN setup and entry, plus biometric options.
struct AuthenticationView: View {
    let onAuthenticated: () -> Void

    @StateObject private var biometricViewModel = BiometricAuthViewModel()
    // TODO: Implement ParentAuthViewModel
    // @StateObject private var authViewModel = ParentAuthViewModel()
    @State private var showSetup = false

    // TODO: Implement PINService
    // private let pinService = PINService()

    var body: some View {
        Group {
            // Temporary stub - show authentication button
            VStack {
                Text("Parent Authentication")
                    .font(.title)
                Button("Authenticate") {
                    onAuthenticated()
                }
                .padding()
            }

            // TODO: Uncomment when PINService is implemented
            /*
            if !pinService.isPinSet() {
                PINSetupView(pinService: pinService) {
                    onAuthenticated()
                }
            } else {
                pinEntryWithBiometrics
            }
            */
        }
        .task {
            await tryBiometrics()
        }
    }

    private var pinEntryWithBiometrics: some View {
        VStack {
            Text("PIN Entry")
            // TODO: Implement PINEntryView
            /*
            ZStack(alignment: .topTrailing) {
                PINEntryView(pinService: pinService) {
                    onAuthenticated()
                }

                // Biometric button overlay
                if biometricViewModel.biometricType != .none {
                    Button {
                        Task {
                            await tryBiometrics()
                        }
                    } label: {
                        Image(systemName: biometricViewModel.biometricType == .faceID ? "faceid" : "touchid")
                            .font(.title)
                            .foregroundColor(.accentColor)
                            .padding()
                    }
                    .padding(.top, 50)
                }
            }
            */
        }
    }

    private func tryBiometrics() async {
        let success = await biometricViewModel.authenticate()
        if success {
            onAuthenticated()
        }
    }
}

// MARK: - Biometric Authentication ViewModel

@MainActor
class BiometricAuthViewModel: ObservableObject {
    @Published var biometricType: BiometricType = .none

    enum BiometricType {
        case none
        case touchID
        case faceID
    }

    private let context = LAContext()

    init() {
        checkBiometricType()
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

    func authenticate() async -> Bool {
        guard biometricType != .none else { return false }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Access Parent Controls"
            )
        } catch {
            return false
        }
    }
}

struct NumberButton: View {
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
    AuthenticationView { }
}
