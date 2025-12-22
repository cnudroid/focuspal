//
//  LoadingView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Full-screen loading indicator view.
struct LoadingView: View {
    let message: String?

    init(_ message: String? = nil) {
        self.message = message
    }

    var body: some View {
        VStack(spacing: FPSpacing.md) {
            ProgressView()
                .scaleEffect(1.5)

            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.9))
    }
}

/// Inline loading indicator
struct InlineLoadingView: View {
    let message: String?

    init(_ message: String? = nil) {
        self.message = message
    }

    var body: some View {
        HStack(spacing: FPSpacing.sm) {
            ProgressView()

            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

/// Skeleton loading placeholder
struct SkeletonView: View {
    let height: CGFloat

    @State private var isAnimating = false

    init(height: CGFloat = 20) {
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    colors: [Color(.systemGray5), Color(.systemGray4), Color(.systemGray5)],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(height: height)
            .animation(
                Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingView("Loading activities...")
            .frame(height: 200)
            .border(Color.gray)

        InlineLoadingView("Syncing...")

        VStack(spacing: 8) {
            SkeletonView(height: 20)
            SkeletonView(height: 16)
            SkeletonView(height: 16)
        }
        .padding()
    }
}
