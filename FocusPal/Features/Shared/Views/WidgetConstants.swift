//
//  WidgetConstants.swift
//  FocusPal
//
//  Shared constants for widget data sharing between main app and widgets.
//

import Foundation

/// Constants for App Group and shared data keys
enum WidgetConstants {
    /// App Group identifier for sharing data between app and widgets
    static let appGroupIdentifier = "group.com.focuspal.dev"

    /// UserDefaults suite name (same as app group)
    static let suiteName = appGroupIdentifier

    /// Keys for shared UserDefaults
    enum Keys {
        static let widgetData = "widgetData"
        static let lastUpdated = "widgetLastUpdated"
    }

    /// Widget kind identifiers
    enum WidgetKind {
        static let small = "FocusPalSmallWidget"
        static let medium = "FocusPalMediumWidget"
        static let large = "FocusPalLargeWidget"
    }

    /// Deep link URL schemes
    enum DeepLink {
        static let scheme = "focuspal"

        // Primary tabs
        static let today = "focuspal://today"
        static let rewards = "focuspal://rewards"
        static let me = "focuspal://me"

        // Timer overlay
        static let timer = "focuspal://timer"
        static let timerWithCategory = "focuspal://timer?category="

        // Legacy deep links (redirect to Me tab for parent controls access)
        static let stats = "focuspal://stats"
        static let log = "focuspal://log"
    }
}
