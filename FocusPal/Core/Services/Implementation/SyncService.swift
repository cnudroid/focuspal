//
//  SyncService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// Concrete implementation of the sync service.
/// Manages CloudKit synchronization for app data.
class SyncService: SyncServiceProtocol {

    // MARK: - Published Properties

    @Published private(set) var syncStatus: SyncOperationStatus = .idle

    // MARK: - Publishers

    var syncStatusPublisher: AnyPublisher<SyncStatus, Never> {
        // Convert SyncOperationStatus to SyncStatus for external consumers
        $syncStatus
            .map { status -> SyncStatus in
                switch status {
                case .idle, .completed:
                    return .synced
                case .syncing:
                    return .pending
                case .failed:
                    return .pending
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Properties

    private let cloudKitManager: CloudKitManager
    private var isSyncEnabledInternal: Bool = true

    var isSyncAvailable: Bool {
        // Check if iCloud is available and user is signed in
        return FileManager.default.ubiquityIdentityToken != nil
    }

    // MARK: - Initialization

    init(cloudKitManager: CloudKitManager) {
        self.cloudKitManager = cloudKitManager
    }

    // MARK: - SyncServiceProtocol

    func triggerSync() async throws {
        guard isSyncEnabledInternal, isSyncAvailable else { return }

        syncStatus = .syncing

        do {
            try await cloudKitManager.performSync()
            syncStatus = .completed
        } catch {
            syncStatus = .failed(error)
            throw error
        }
    }

    func handleRemoteChanges() async throws {
        guard isSyncAvailable else { return }
        try await cloudKitManager.processRemoteChanges()
    }

    func resolveConflict(_ conflict: SyncConflict) async throws {
        // Default strategy: remote wins
        // In production, this could present UI for user choice
        try await cloudKitManager.resolveConflict(conflict, strategy: .remoteWins)
    }

    func setSyncEnabled(_ enabled: Bool) {
        isSyncEnabledInternal = enabled

        if !enabled {
            syncStatus = .idle
        }
    }
}
