//
//  PINEntryView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// View for entering parent PIN with lockout protection
struct PINEntryView: View {
    @StateObject private var viewModel: ParentAuthViewModel
    let onAuthenticated: () -> Void

    init(pinService: PINServiceProtocol = PINService(), onAuthenticated: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ParentAuthViewModel(pinService: pinService))
        self.onAuthenticated = onAuthenticated
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Lock icon
            Image(systemName: viewModel.isLockedOut ? "lock.fill" : "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(viewModel.isLockedOut ? .red : .accentColor)

            Text("Parent Controls")
                .font(.title2)
                .fontWeight(.bold)

            if viewModel.isLockedOut {
                lockoutMessage
            } else {
                normalMessage
            }

            // PIN dots with shake animation
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < viewModel.enteredPin.count ? Color.accentColor : Color(.systemGray4))
                        .frame(width: 16, height: 16)
                }
            }
            .padding()
            .modifier(ShakeEffect(shakes: viewModel.shouldShake ? 3 : 0))

            // Failed attempts indicator
            if viewModel.failedAttempts > 0 && !viewModel.isLockedOut {
                Text("Incorrect PIN (\(viewModel.failedAttempts)/3 attempts)")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Number pad
            numberPad
                .opacity(viewModel.isLockedOut ? 0.3 : 1.0)
                .disabled(viewModel.isLockedOut)

            Spacer()
        }
        .padding()
        .onChange(of: viewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                onAuthenticated()
            }
        }
    }

    // MARK: - Subviews

    private var normalMessage: some View {
        Text("Enter PIN to access")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }

    private var lockoutMessage: some View {
        VStack(spacing: 8) {
            Text("Too many failed attempts")
                .font(.subheadline)
                .foregroundColor(.red)
                .fontWeight(.semibold)

            Text("Try again in \(Int(viewModel.remainingLockoutTime)) seconds")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .multilineTextAlignment(.center)
    }

    private var numberPad: some View {
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
                // Empty space for alignment
                Spacer()
                    .frame(width: 70, height: 70)

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
    }
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = 10 * sin(shakes * .pi * 2)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

#Preview {
    PINEntryView { }
}
