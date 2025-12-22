//
//  Colors.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Design system color palette.
extension Color {

    // MARK: - Primary Colors

    static let fpPrimary = Color("Primary", bundle: nil)
    static let fpSecondary = Color("Secondary", bundle: nil)
    static let fpAccent = Color.accentColor

    // MARK: - Semantic Colors

    static let fpSuccess = Color(hex: "#4CAF50")
    static let fpWarning = Color(hex: "#FFC107")
    static let fpError = Color(hex: "#FF5252")
    static let fpInfo = Color(hex: "#2196F3")

    // MARK: - Category Colors

    static let categoryHomework = Color(hex: "#4A90D9")
    static let categoryReading = Color(hex: "#7B68EE")
    static let categoryScreenTime = Color(hex: "#FF6B6B")
    static let categoryPlaying = Color(hex: "#4ECDC4")
    static let categorySports = Color(hex: "#45B7D1")
    static let categoryMusic = Color(hex: "#F7DC6F")

    // MARK: - Background Colors

    static let fpBackground = Color(.systemBackground)
    static let fpSecondaryBackground = Color(.secondarySystemBackground)
    static let fpGroupedBackground = Color(.systemGroupedBackground)

    // MARK: - Text Colors

    static let fpTextPrimary = Color(.label)
    static let fpTextSecondary = Color(.secondaryLabel)
    static let fpTextTertiary = Color(.tertiaryLabel)

    // MARK: - Hex Initializer

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Colors

struct ThemeColors {
    let primary: Color
    let secondary: Color
    let background: Color

    static let blue = ThemeColors(
        primary: Color(hex: "#4A90D9"),
        secondary: Color(hex: "#A8D0F0"),
        background: Color(hex: "#E8F4FD")
    )

    static let pink = ThemeColors(
        primary: Color(hex: "#FF69B4"),
        secondary: Color(hex: "#FFB6D9"),
        background: Color(hex: "#FFF0F5")
    )

    static let green = ThemeColors(
        primary: Color(hex: "#4CAF50"),
        secondary: Color(hex: "#A5D6A7"),
        background: Color(hex: "#E8F5E9")
    )

    static let purple = ThemeColors(
        primary: Color(hex: "#9C27B0"),
        secondary: Color(hex: "#CE93D8"),
        background: Color(hex: "#F3E5F5")
    )
}
