//
//  SyncServiceProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// Protocol defining the sync service interface.
/// Manages CloudKit synchronization for app data.
protocol SyncServiceProtocol {
    /// Publisher for sync status updates
    var syncStatusPublisher: AnyPublisher<SyncStatus, Never> { get }

    /// Check if CloudKit sync is available
    var isSyncAvailable: Bool { get }

    /// Trigger a manual sync
    func triggerSync() async throws

    /// Handle incoming remote changes
    func handleRemoteChanges() async throws

    /// Resolve sync conflicts
    func resolveConflict(_ conflict: SyncConflict) async throws

    /// Enable or disable sync
    func setSyncEnabled(_ enabled: Bool)
}

/// Sync operation status
enum SyncOperationStatus {
    case idle
    case syncing
    case completed
    case failed(Error)
}

/// Represents a sync conflict that needs resolution
struct SyncConflict: Identifiable {
    let id: UUID
    let entityType: String
    let localVersion: Any
    let remoteVersion: Any
    let conflictDate: Date
}
