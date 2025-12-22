//
//  Typography.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Design system typography styles.
struct FPTypography {

    // MARK: - Display Styles

    static let displayLarge = Font.system(size: 57, weight: .regular, design: .rounded)
    static let displayMedium = Font.system(size: 45, weight: .regular, design: .rounded)
    static let displaySmall = Font.system(size: 36, weight: .regular, design: .rounded)

    // MARK: - Headline Styles

    static let headlineLarge = Font.system(size: 32, weight: .semibold, design: .rounded)
    static let headlineMedium = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .rounded)

    // MARK: - Title Styles

    static let titleLarge = Font.system(size: 22, weight: .medium, design: .default)
    static let titleMedium = Font.system(size: 16, weight: .medium, design: .default)
    static let titleSmall = Font.system(size: 14, weight: .medium, design: .default)

    // MARK: - Body Styles

    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)

    // MARK: - Label Styles

    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

    // MARK: - Timer Display

    static let timerLarge = Font.system(size: 64, weight: .bold, design: .rounded).monospacedDigit()
    static let timerMedium = Font.system(size: 48, weight: .bold, design: .rounded).monospacedDigit()
    static let timerSmall = Font.system(size: 32, weight: .bold, design: .rounded).monospacedDigit()
}

// MARK: - View Extension

extension View {
    func fpTypography(_ style: FPTextStyle) -> some View {
        self.font(style.font)
    }
}

enum FPTextStyle {
    case displayLarge
    case displayMedium
    case displaySmall
    case headlineLarge
    case headlineMedium
    case headlineSmall
    case titleLarge
    case titleMedium
    case titleSmall
    case bodyLarge
    case bodyMedium
    case bodySmall
    case labelLarge
    case labelMedium
    case labelSmall
    case timerLarge
    case timerMedium
    case timerSmall

    var font: Font {
        switch self {
        case .displayLarge: return FPTypography.displayLarge
        case .displayMedium: return FPTypography.displayMedium
        case .displaySmall: return FPTypography.displaySmall
        case .headlineLarge: return FPTypography.headlineLarge
        case .headlineMedium: return FPTypography.headlineMedium
        case .headlineSmall: return FPTypography.headlineSmall
        case .titleLarge: return FPTypography.titleLarge
        case .titleMedium: return FPTypography.titleMedium
        case .titleSmall: return FPTypography.titleSmall
        case .bodyLarge: return FPTypography.bodyLarge
        case .bodyMedium: return FPTypography.bodyMedium
        case .bodySmall: return FPTypography.bodySmall
        case .labelLarge: return FPTypography.labelLarge
        case .labelMedium: return FPTypography.labelMedium
        case .labelSmall: return FPTypography.labelSmall
        case .timerLarge: return FPTypography.timerLarge
        case .timerMedium: return FPTypography.timerMedium
        case .timerSmall: return FPTypography.timerSmall
        }
    }
}
