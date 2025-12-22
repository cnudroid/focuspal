//
//  SecondaryButton.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Secondary action button with outline style.
struct SecondaryButton: View {
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
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FPSpacing.md)
            .padding(.horizontal, FPSpacing.lg)
            .background(Color(.systemBackground))
            .foregroundColor(isDisabled ? .gray : .accentColor)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isDisabled ? Color.gray : Color.accentColor, lineWidth: 2)
            )
        }
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        SecondaryButton("Cancel", icon: "xmark") { }
        SecondaryButton("Loading...", isLoading: true) { }
        SecondaryButton("Disabled", isDisabled: true) { }
    }
    .padding()
}
