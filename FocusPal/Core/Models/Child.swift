//
//  Child.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Domain model representing a child profile in the app.
/// Each child has their own activities, categories, time goals, and achievements.
struct Child: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var age: Int
    var avatarId: String
    var themeColor: String
    var preferences: ChildPreferences
    let createdDate: Date
    var lastActiveDate: Date?
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        avatarId: String = "avatar_default",
        themeColor: String = "blue",
        preferences: ChildPreferences = ChildPreferences(),
        createdDate: Date = Date(),
        lastActiveDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.avatarId = avatarId
        self.themeColor = themeColor
        self.preferences = preferences
        self.createdDate = createdDate
        self.lastActiveDate = lastActiveDate
        self.isActive = isActive
    }
}

/// Preferences specific to a child profile
struct ChildPreferences: Equatable, Hashable, Codable {
    var timerVisualization: TimerVisualizationMode = .circular
    var soundsEnabled: Bool = true
    var hapticsEnabled: Bool = true

    // Background preferences
    var animatedBackgroundsEnabled: Bool = true
    var backgroundStyle: BackgroundStylePreference = .automatic

    enum TimerVisualizationMode: String, Codable {
        case circular
        case bar
        case analog
        case space
        case ocean
    }

    /// Available background style preferences
    enum BackgroundStylePreference: String, Codable, CaseIterable {
        case automatic       // Uses different style per screen
        case gradient        // Simple animated gradient
        case floatingShapes  // Stars, hearts, circles floating
        case bubbles         // Rising bubbles
        case waves           // Organic wave shapes
        case sparkles        // Twinkling night sky
        case clouds          // Floating clouds
        case combined        // Shapes + waves combo
        case solid           // No animation, just solid color

        var displayName: String {
            switch self {
            case .automatic: return "Automatic"
            case .gradient: return "Gradient"
            case .floatingShapes: return "Floating Shapes"
            case .bubbles: return "Bubbles"
            case .waves: return "Waves"
            case .sparkles: return "Night Sky"
            case .clouds: return "Clouds"
            case .combined: return "Magic Mix"
            case .solid: return "Simple"
            }
        }

        var description: String {
            switch self {
            case .automatic: return "Different style for each screen"
            case .gradient: return "Smooth color shifts"
            case .floatingShapes: return "Stars and hearts float around"
            case .bubbles: return "Bubbles rise up the screen"
            case .waves: return "Gentle waves at the bottom"
            case .sparkles: return "Twinkling stars like night sky"
            case .clouds: return "Fluffy clouds drift by"
            case .combined: return "Shapes and waves together"
            case .solid: return "Plain background, saves battery"
            }
        }

        var iconName: String {
            switch self {
            case .automatic: return "sparkles.rectangle.stack"
            case .gradient: return "circle.lefthalf.filled"
            case .floatingShapes: return "star.fill"
            case .bubbles: return "bubble.left.and.bubble.right.fill"
            case .waves: return "water.waves"
            case .sparkles: return "sparkles"
            case .clouds: return "cloud.fill"
            case .combined: return "wand.and.stars"
            case .solid: return "square.fill"
            }
        }
    }
}
