//
//  TestCoreDataStack.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import CoreData
@testable import FocusPal

/// In-memory Core Data stack for unit testing
final class TestCoreDataStack {
    static let shared = TestCoreDataStack()

    let persistentContainer: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    private init() {
        persistentContainer = NSPersistentContainer(name: "FocusPal")

        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false

        persistentContainer.persistentStoreDescriptions = [description]

        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load test Core Data stack: \(error)")
            }
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    /// Creates a fresh context for each test
    func newTestContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = viewContext
        return context
    }

    /// Clears all entities from the store
    func clearAllData() {
        let entities = persistentContainer.managedObjectModel.entities
        for entity in entities {
            guard let entityName = entity.name else { continue }
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)

            do {
                let objects = try viewContext.fetch(fetchRequest)
                for object in objects {
                    viewContext.delete(object)
                }
            } catch {
                print("Failed to clear \(entityName): \(error)")
            }
        }

        do {
            try viewContext.save()
        } catch {
            print("Failed to save after clearing: \(error)")
        }

        viewContext.reset()
    }
}
