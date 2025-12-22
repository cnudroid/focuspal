//
//  PrimaryButton.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Primary action button with customizable appearance.
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: FPSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FPSpacing.md)
            .padding(.horizontal, FPSpacing.lg)
            .background(isDisabled ? Color.gray : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(isDisabled || isLoading)
        .buttonShadow()
    }
}

// MARK: - Size Variants

extension PrimaryButton {
    func small() -> some View {
        self
            .scaleEffect(0.85)
    }

    func large() -> some View {
        self
            .scaleEffect(1.1)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton("Get Started", icon: "arrow.right") { }
        PrimaryButton("Loading...", isLoading: true) { }
        PrimaryButton("Disabled", isDisabled: true) { }
    }
    .padding()
}
