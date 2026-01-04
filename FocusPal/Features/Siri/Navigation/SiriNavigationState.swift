//
//  SiriNavigationState.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// Represents a pending timer start from Siri
struct PendingTimerStart: Codable {
    let childId: UUID
    let categoryId: UUID
    let timestamp: Date

    init(childId: UUID, categoryId: UUID) {
        self.childId = childId
        self.categoryId = categoryId
        self.timestamp = Date()
    }
}

/// Singleton that manages navigation state from Siri intents
@MainActor
final class SiriNavigationState: ObservableObject {
    static let shared = SiriNavigationState()

    private static let storageKey = "pendingTimerStart"
    private static let expirationInterval: TimeInterval = 30 // seconds

    @Published var pendingTimerStart: PendingTimerStart? {
        didSet {
            persistPendingState()
        }
    }

    private init() {
        loadPendingState()
    }

    // MARK: - Public Methods

    /// Consume and return the pending timer start (one-time use)
    func consumePendingTimerStart() -> PendingTimerStart? {
        let pending = pendingTimerStart
        pendingTimerStart = nil
        return pending
    }

    // MARK: - Private Methods

    private func persistPendingState() {
        if let pending = pendingTimerStart {
            if let data = try? JSONEncoder().encode(pending) {
                UserDefaults.standard.set(data, forKey: Self.storageKey)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: Self.storageKey)
        }
    }

    private func loadPendingState() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let pending = try? JSONDecoder().decode(PendingTimerStart.self, from: data) else {
            return
        }

        // Only use if recent (within expiration interval)
        if Date().timeIntervalSince(pending.timestamp) < Self.expirationInterval {
            pendingTimerStart = pending
        } else {
            // Expired - clean up
            UserDefaults.standard.removeObject(forKey: Self.storageKey)
        }
    }
}
