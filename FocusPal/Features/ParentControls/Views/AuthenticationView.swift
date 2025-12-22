//
//  AuthenticationView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import LocalAuthentication

/// Parent authentication view with PIN and biometric options.
struct AuthenticationView: View {
    let onAuthenticated: (Bool) -> Void

    @StateObject private var viewModel = AuthenticationViewModel()
    @State private var pin = ""
    @State private var showError = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Lock icon
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text("Parent Controls")
                .font(.title2)
                .fontWeight(.bold)

            Text("Enter PIN or use biometrics to access")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // PIN dots
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < pin.count ? Color.accentColor : Color(.systemGray4))
                        .frame(width: 16, height: 16)
                }
            }
            .padding()

            // Number pad
            VStack(spacing: 16) {
                ForEach(0..<3) { row in
                    HStack(spacing: 24) {
                        ForEach(1...3, id: \.self) { col in
                            let number = row * 3 + col
                            NumberButton(number: number) {
                                addDigit(number)
                            }
                        }
                    }
                }

                HStack(spacing: 24) {
                    // Biometric button
                    Button {
                        Task {
                            await authenticateWithBiometrics()
                        }
                    } label: {
                        Image(systemName: viewModel.biometricType == .faceID ? "faceid" : "touchid")
                            .font(.title)
                            .frame(width: 70, height: 70)
                    }

                    NumberButton(number: 0) {
                        addDigit(0)
                    }

                    // Delete button
                    Button {
                        if !pin.isEmpty {
                            pin.removeLast()
                        }
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
        .alert("Incorrect PIN", isPresented: $showError) {
            Button("Try Again") {
                pin = ""
            }
        }
        .task {
            // Try biometrics on appear
            await authenticateWithBiometrics()
        }
    }

    private func addDigit(_ digit: Int) {
        guard pin.count < 4 else { return }
        pin += "\(digit)"

        if pin.count == 4 {
            verifyPIN()
        }
    }

    private func verifyPIN() {
        if viewModel.verifyPIN(pin) {
            onAuthenticated(true)
        } else {
            showError = true
        }
    }

    private func authenticateWithBiometrics() async {
        let success = await viewModel.authenticateWithBiometrics()
        if success {
            onAuthenticated(true)
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
    AuthenticationView { _ in }
}
