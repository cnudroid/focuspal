//
//  QuickActionButton.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Reusable quick action button for the home screen.
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)

                Text(title)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .cornerRadius(12)
        }
    }
}

#Preview {
    HStack {
        QuickActionButton(
            title: "Start Timer",
            icon: "timer",
            color: .blue
        ) { }

        QuickActionButton(
            title: "Quick Log",
            icon: "plus.circle.fill",
            color: .green
        ) { }
    }
    .padding()
}
