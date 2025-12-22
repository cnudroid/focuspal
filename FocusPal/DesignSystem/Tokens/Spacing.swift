//
//  Spacing.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Design system spacing scale.
struct FPSpacing {

    // MARK: - Base Scale (4pt)

    static let none: CGFloat = 0
    static let xxxs: CGFloat = 2   // 0.5x
    static let xxs: CGFloat = 4    // 1x
    static let xs: CGFloat = 8     // 2x
    static let sm: CGFloat = 12    // 3x
    static let md: CGFloat = 16    // 4x
    static let lg: CGFloat = 24    // 6x
    static let xl: CGFloat = 32    // 8x
    static let xxl: CGFloat = 48   // 12x
    static let xxxl: CGFloat = 64  // 16x

    // MARK: - Semantic Spacing

    static let cardPadding: CGFloat = md
    static let sectionSpacing: CGFloat = lg
    static let listItemSpacing: CGFloat = sm
    static let buttonPadding: CGFloat = md
    static let iconPadding: CGFloat = xs
    static let screenPadding: CGFloat = md
}

// MARK: - View Extensions

extension View {
    func fpPadding(_ spacing: CGFloat = FPSpacing.md) -> some View {
        self.padding(spacing)
    }

    func fpPadding(_ edges: Edge.Set, _ spacing: CGFloat) -> some View {
        self.padding(edges, spacing)
    }

    func fpHStack(spacing: CGFloat = FPSpacing.sm) -> some View {
        HStack(spacing: spacing) { self }
    }

    func fpVStack(spacing: CGFloat = FPSpacing.sm) -> some View {
        VStack(spacing: spacing) { self }
    }
}

// MARK: - Stack Helpers

struct FPHStack<Content: View>: View {
    let spacing: CGFloat
    let alignment: VerticalAlignment
    let content: () -> Content

    init(
        spacing: CGFloat = FPSpacing.sm,
        alignment: VerticalAlignment = .center,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        HStack(alignment: alignment, spacing: spacing) {
            content()
        }
    }
}

struct FPVStack<Content: View>: View {
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: () -> Content

    init(
        spacing: CGFloat = FPSpacing.sm,
        alignment: HorizontalAlignment = .center,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content()
        }
    }
}
