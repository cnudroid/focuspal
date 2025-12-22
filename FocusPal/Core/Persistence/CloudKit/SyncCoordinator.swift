//
//  SyncCoordinator.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import CoreData
import Combine

/// Coordinates sync between Core Data and CloudKit.
/// Monitors for changes and triggers sync operations.
class SyncCoordinator {

    // MARK: - Properties

    private let cloudKitManager: CloudKitManager
    private let persistenceController: PersistenceController
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        cloudKitManager: CloudKitManager,
        persistenceController: PersistenceController = .shared
    ) {
        self.cloudKitManager = cloudKitManager
        self.persistenceController = persistenceController

        setupChangeObservers()
    }

    // MARK: - Setup

    private func setupChangeObservers() {
        // Observe Core Data save notifications
        NotificationCenter.default.publisher(
            for: .NSManagedObjectContextDidSave,
            object: persistenceController.container.viewContext
        )
        .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            Task {
                try? await self?.cloudKitManager.performSync()
            }
        }
        .store(in: &cancellables)

        // Observe remote change notifications
        NotificationCenter.default.publisher(
            for: .NSPersistentStoreRemoteChange,
            object: persistenceController.container.persistentStoreCoordinator
        )
        .sink { [weak self] _ in
            Task {
                try? await self?.cloudKitManager.processRemoteChanges()
            }
        }
        .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Manually trigger a sync operation
    func triggerManualSync() async throws {
        try await cloudKitManager.performSync()
    }
}
