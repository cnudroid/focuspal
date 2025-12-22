//
//  Persistence.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import CoreData

/// Controller managing the Core Data stack for the FocusPal application.
/// Provides access to the persistent container and managed object contexts.
struct PersistenceController {
    /// Shared singleton instance for production use
    static let shared = PersistenceController()

    /// Preview instance with in-memory store for SwiftUI previews
    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create sample data for previews
        // Add preview data here as needed

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    /// The Core Data persistent container
    let container: NSPersistentContainer

    /// Main view context for UI operations
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// Background context for heavy operations
    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }

    /// Initializes the persistence controller
    /// - Parameter inMemory: If true, uses an in-memory store (for testing/previews)
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FocusPal")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        // Configure for CloudKit sync if available
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        // Enable file protection
        description.setOption(
            FileProtectionType.complete as NSObject,
            forKey: NSPersistentStoreFileProtectionKey
        )

        // Enable persistent history tracking for CloudKit
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Replace with proper error handling in production
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Saves changes in the view context if there are any
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
