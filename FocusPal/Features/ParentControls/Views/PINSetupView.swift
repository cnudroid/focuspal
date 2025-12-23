//
//  PINSetupView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// View for setting up a new parent PIN
struct PINSetupView: View {
    @StateObject private var viewModel: PINSetupViewModel
    let onComplete: () -> Void

    init(pinService: PINServiceProtocol = PINService(), onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: PINSetupViewModel(pinService: pinService))
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Lock icon
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text("Set Up Parent PIN")
                .font(.title2)
                .fontWeight(.bold)

            Text(viewModel.instructionText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // PIN dots
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < viewModel.currentPin.count ? Color.accentColor : Color(.systemGray4))
                        .frame(width: 16, height: 16)
                }
            }
            .padding()

            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
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
                    // Back button (only in confirm step)
                    if viewModel.step == .confirmPin {
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
        .onChange(of: viewModel.isComplete) { isComplete in
            if isComplete {
                onComplete()
            }
        }
    }
}

#Preview {
    PINSetupView { }
}
