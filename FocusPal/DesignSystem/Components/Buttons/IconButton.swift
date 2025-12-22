//
//  IconButton.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Icon-only button with customizable size and style.
struct IconButton: View {
    let icon: String
    let size: IconButtonSize
    let style: IconButtonStyle
    let action: () -> Void

    init(
        icon: String,
        size: IconButtonSize = .medium,
        style: IconButtonStyle = .default,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(style.foregroundColor)
                .frame(width: size.buttonSize, height: size.buttonSize)
                .background(style.backgroundColor)
                .cornerRadius(size.buttonSize / 2)
        }
    }
}

// MARK: - Size

enum IconButtonSize {
    case small
    case medium
    case large

    var buttonSize: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 44
        case .large: return 56
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 18
        case .large: return 24
        }
    }
}

// MARK: - Style

enum IconButtonStyle {
    case `default`
    case filled
    case tinted
    case plain

    var foregroundColor: Color {
        switch self {
        case .default: return .primary
        case .filled: return .white
        case .tinted: return .accentColor
        case .plain: return .secondary
        }
    }

    var backgroundColor: Color {
        switch self {
        case .default: return Color(.systemGray5)
        case .filled: return .accentColor
        case .tinted: return .accentColor.opacity(0.15)
        case .plain: return .clear
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        IconButton(icon: "play.fill", size: .small, style: .default) { }
        IconButton(icon: "pause.fill", size: .medium, style: .filled) { }
        IconButton(icon: "stop.fill", size: .large, style: .tinted) { }
        IconButton(icon: "gear", size: .medium, style: .plain) { }
    }
    .padding()
}
