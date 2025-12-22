//
//  Shadows.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Design system shadow styles.
struct FPShadow {

    // MARK: - Shadow Levels

    static let none = ShadowStyle(color: .clear, radius: 0, x: 0, y: 0)

    static let small = ShadowStyle(
        color: Color.black.opacity(0.08),
        radius: 4,
        x: 0,
        y: 2
    )

    static let medium = ShadowStyle(
        color: Color.black.opacity(0.12),
        radius: 8,
        x: 0,
        y: 4
    )

    static let large = ShadowStyle(
        color: Color.black.opacity(0.16),
        radius: 16,
        x: 0,
        y: 8
    )

    static let xlarge = ShadowStyle(
        color: Color.black.opacity(0.20),
        radius: 24,
        x: 0,
        y: 12
    )

    // MARK: - Semantic Shadows

    static let card = medium
    static let button = small
    static let modal = large
    static let floating = xlarge
}

/// Shadow style definition
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extension

extension View {
    func fpShadow(_ style: ShadowStyle) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }

    func cardShadow() -> some View {
        self.fpShadow(FPShadow.card)
    }

    func buttonShadow() -> some View {
        self.fpShadow(FPShadow.button)
    }

    func modalShadow() -> some View {
        self.fpShadow(FPShadow.modal)
    }
}
