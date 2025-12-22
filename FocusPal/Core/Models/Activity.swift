//
//  Activity.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Domain model representing a logged activity session.
/// Activities track time spent in different categories.
struct Activity: Identifiable, Equatable, Hashable {
    let id: UUID
    let categoryId: UUID
    let childId: UUID
    let startTime: Date
    let endTime: Date
    var notes: String?
    var mood: Mood
    var isManualEntry: Bool
    let createdDate: Date
    var syncStatus: SyncStatus

    /// Calculated duration in seconds
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    /// Duration formatted as minutes
    var durationMinutes: Int {
        Int(duration / 60)
    }

    init(
        id: UUID = UUID(),
        categoryId: UUID,
        childId: UUID,
        startTime: Date,
        endTime: Date,
        notes: String? = nil,
        mood: Mood = .none,
        isManualEntry: Bool = false,
        createdDate: Date = Date(),
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.categoryId = categoryId
        self.childId = childId
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
        self.mood = mood
        self.isManualEntry = isManualEntry
        self.createdDate = createdDate
        self.syncStatus = syncStatus
    }
}

/// Mood rating for an activity
enum Mood: Int, Codable, CaseIterable {
    case none = 0
    case verySad = 1
    case sad = 2
    case neutral = 3
    case happy = 4
    case veryHappy = 5

    var emoji: String {
        switch self {
        case .none: return ""
        case .verySad: return "😢"
        case .sad: return "😕"
        case .neutral: return "😐"
        case .happy: return "😊"
        case .veryHappy: return "😄"
        }
    }
}

/// Sync status for CloudKit synchronization
enum SyncStatus: String, Codable {
    case synced
    case pending
    case conflict
}
