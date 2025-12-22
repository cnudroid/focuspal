//
//  ErrorView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Error state view with retry option.
struct ErrorView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?

    init(
        title: String = "Something went wrong",
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: FPSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            VStack(spacing: FPSpacing.xs) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(FPSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Inline error banner
struct ErrorBanner: View {
    let message: String
    let onDismiss: (() -> Void)?

    init(message: String, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(spacing: FPSpacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.white)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(FPSpacing.md)
        .background(Color.red)
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 40) {
        ErrorView(
            message: "Unable to load activities. Please check your connection."
        ) { }

        ErrorBanner(message: "Failed to save activity") { }
            .padding()
    }
}
