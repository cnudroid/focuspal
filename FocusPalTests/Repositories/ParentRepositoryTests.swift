//
//  ParentRepositoryTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
import CoreData
@testable import FocusPal

/// Comprehensive tests for ParentRepository
/// Tests all CRUD operations for parent profile persistence
final class ParentRepositoryTests: XCTestCase {

    // MARK: - Properties

    var sut: CoreDataParentRepository!
    var testContext: NSManagedObjectContext!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Setup test CoreData stack
        let testStack = TestCoreDataStack.shared
        testStack.clearAllData()
        testContext = testStack.newTestContext()

        // Initialize repository with test context
        sut = CoreDataParentRepository(context: testContext)
    }

    override func tearDownWithError() throws {
        sut = nil
        testContext = nil
        TestCoreDataStack.shared.clearAllData()
        try super.tearDownWithError()
    }

    // MARK: - Create Tests

    func testCreate_WithValidParent_SavesSuccessfully() async throws {
        // Arrange
        let parent = Parent(
            name: "Jane Doe",
            email: "jane@example.com"
        )

        // Act
        let created = try await sut.create(parent)

        // Assert
        XCTAssertEqual(created.id, parent.id, "Created parent should have same ID")
        XCTAssertEqual(created.name, "Jane Doe")
        XCTAssertEqual(created.email, "jane@example.com")
        XCTAssertNotNil(created.createdDate)
        XCTAssertNil(created.lastLoginDate)
    }

    func testCreate_WithNotificationPreferences_SavesCorrectly() async throws {
        // Arrange
        let preferences = ParentNotificationPreferences(
            weeklyEmailEnabled: true,
            weeklyEmailDay: 2,
            weeklyEmailTime: 10,
            achievementAlertsEnabled: false
        )
        let parent = Parent(
            name: "John Smith",
            email: "john@example.com",
            notificationPreferences: preferences
        )

        // Act
        let created = try await sut.create(parent)

        // Assert
        XCTAssertEqual(created.notificationPreferences.weeklyEmailEnabled, true)
        XCTAssertEqual(created.notificationPreferences.weeklyEmailDay, 2)
        XCTAssertEqual(created.notificationPreferences.weeklyEmailTime, 10)
        XCTAssertEqual(created.notificationPreferences.achievementAlertsEnabled, false)
    }

    func testCreate_WithCustomDates_PreservesValues() async throws {
        // Arrange
        let customDate = Date().addingTimeInterval(-86400) // Yesterday
        let parent = Parent(
            name: "Test Parent",
            email: "test@example.com",
            createdDate: customDate,
            lastLoginDate: customDate
        )

        // Act
        let created = try await sut.create(parent)

        // Assert
        XCTAssertEqual(created.createdDate.timeIntervalSince1970,
                       customDate.timeIntervalSince1970,
                       accuracy: 1.0)
        XCTAssertNotNil(created.lastLoginDate)
    }

    // MARK: - Fetch Tests

    func testFetch_WithNoParent_ReturnsNil() async throws {
        // Act
        let parent = try await sut.fetch()

        // Assert
        XCTAssertNil(parent, "Should return nil when no parent exists")
    }

    func testFetch_WithExistingParent_ReturnsParent() async throws {
        // Arrange
        let parent = Parent(
            name: "Jane Doe",
            email: "jane@example.com"
        )
        _ = try await sut.create(parent)

        // Act
        let fetched = try await sut.fetch()

        // Assert
        XCTAssertNotNil(fetched, "Should return parent when one exists")
        XCTAssertEqual(fetched?.id, parent.id)
        XCTAssertEqual(fetched?.name, "Jane Doe")
        XCTAssertEqual(fetched?.email, "jane@example.com")
    }

    func testFetch_ReturnsSingleParent_WhenMultipleExist() async throws {
        // This test verifies the app's single-parent design constraint
        // Even if multiple parent entities exist in DB, fetch should return only one

        // Arrange
        let parent1 = Parent(name: "Parent 1", email: "parent1@example.com")
        let parent2 = Parent(name: "Parent 2", email: "parent2@example.com")

        _ = try await sut.create(parent1)
        _ = try await sut.create(parent2)

        // Act
        let fetched = try await sut.fetch()

        // Assert
        XCTAssertNotNil(fetched, "Should return a parent")
        // Should return the first one created
        XCTAssertEqual(fetched?.id, parent1.id)
    }

    // MARK: - Update Tests

    func testUpdate_WithExistingParent_UpdatesSuccessfully() async throws {
        // Arrange: Create initial parent
        let parent = Parent(
            name: "Original Name",
            email: "original@example.com"
        )
        let created = try await sut.create(parent)

        // Act: Update name and email
        var updated = created
        updated.name = "Updated Name"
        updated.email = "updated@example.com"
        let result = try await sut.update(updated)

        // Assert
        XCTAssertEqual(result.id, created.id)
        XCTAssertEqual(result.name, "Updated Name")
        XCTAssertEqual(result.email, "updated@example.com")

        // Verify persistence
        let fetched = try await sut.fetch()
        XCTAssertEqual(fetched?.name, "Updated Name")
        XCTAssertEqual(fetched?.email, "updated@example.com")
    }

    func testUpdate_NotificationPreferences_SavesCorrectly() async throws {
        // Arrange: Create parent with default preferences
        let parent = Parent(
            name: "Test Parent",
            email: "test@example.com"
        )
        let created = try await sut.create(parent)

        // Act: Update preferences
        var updated = created
        updated.notificationPreferences = ParentNotificationPreferences(
            weeklyEmailEnabled: false,
            weeklyEmailDay: 7,
            weeklyEmailTime: 18,
            achievementAlertsEnabled: true
        )
        let result = try await sut.update(updated)

        // Assert
        XCTAssertEqual(result.notificationPreferences.weeklyEmailEnabled, false)
        XCTAssertEqual(result.notificationPreferences.weeklyEmailDay, 7)
        XCTAssertEqual(result.notificationPreferences.weeklyEmailTime, 18)
        XCTAssertEqual(result.notificationPreferences.achievementAlertsEnabled, true)

        // Verify persistence
        let fetched = try await sut.fetch()
        XCTAssertEqual(fetched?.notificationPreferences.weeklyEmailEnabled, false)
        XCTAssertEqual(fetched?.notificationPreferences.weeklyEmailDay, 7)
        XCTAssertEqual(fetched?.notificationPreferences.weeklyEmailTime, 18)
    }

    func testUpdate_LastLoginDate_UpdatesSuccessfully() async throws {
        // Arrange
        let parent = Parent(
            name: "Test Parent",
            email: "test@example.com"
        )
        let created = try await sut.create(parent)
        XCTAssertNil(created.lastLoginDate)

        // Act: Update last login date
        var updated = created
        let loginDate = Date()
        updated.lastLoginDate = loginDate
        let result = try await sut.update(updated)

        // Assert
        XCTAssertNotNil(result.lastLoginDate)
        if let resultLoginDate = result.lastLoginDate {
            XCTAssertEqual(resultLoginDate.timeIntervalSince1970,
                           loginDate.timeIntervalSince1970,
                           accuracy: 1.0)
        }

        // Verify persistence
        let fetched = try await sut.fetch()
        XCTAssertNotNil(fetched?.lastLoginDate)
    }

    func testUpdate_WithNonExistentParent_ThrowsError() async throws {
        // Arrange: Create parent with ID that doesn't exist
        let parent = Parent(
            id: UUID(),  // Non-existent ID
            name: "Ghost Parent",
            email: "ghost@example.com"
        )

        // Act & Assert
        do {
            _ = try await sut.update(parent)
            XCTFail("Should throw error for non-existent parent")
        } catch let error as RepositoryError {
            XCTAssertEqual(error, RepositoryError.entityNotFound)
        }
    }

    // MARK: - Delete Tests

    func testDelete_WithExistingParent_DeletesSuccessfully() async throws {
        // Arrange
        let parent = Parent(
            name: "Test Parent",
            email: "test@example.com"
        )
        _ = try await sut.create(parent)

        // Verify it exists
        let beforeDelete = try await sut.fetch()
        XCTAssertNotNil(beforeDelete)

        // Act
        try await sut.delete()

        // Assert
        let afterDelete = try await sut.fetch()
        XCTAssertNil(afterDelete, "Parent should be deleted")
    }

    func testDelete_WithNoParent_DoesNotThrowError() async throws {
        // Act & Assert - should not throw even if no parent exists
        try await sut.delete()

        // Verify still no parent
        let fetched = try await sut.fetch()
        XCTAssertNil(fetched)
    }

    // MARK: - Edge Cases & Integration Tests

    func testParentLifecycle_CreateUpdateDelete() async throws {
        // Test complete lifecycle of a parent profile

        // 1. Create parent
        let parent = Parent(
            name: "Initial Name",
            email: "initial@example.com"
        )
        let created = try await sut.create(parent)
        XCTAssertEqual(created.name, "Initial Name")

        // 2. Fetch and verify
        var fetched = try await sut.fetch()
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, created.id)

        // 3. Update profile
        var updated = created
        updated.name = "Updated Name"
        updated.email = "updated@example.com"
        updated.lastLoginDate = Date()
        let result = try await sut.update(updated)
        XCTAssertEqual(result.name, "Updated Name")

        // 4. Verify update persisted
        fetched = try await sut.fetch()
        XCTAssertEqual(fetched?.name, "Updated Name")
        XCTAssertNotNil(fetched?.lastLoginDate)

        // 5. Update preferences
        var withPrefs = result
        withPrefs.notificationPreferences.weeklyEmailEnabled = false
        withPrefs.notificationPreferences.achievementAlertsEnabled = false
        let prefResult = try await sut.update(withPrefs)
        XCTAssertEqual(prefResult.notificationPreferences.weeklyEmailEnabled, false)

        // 6. Verify preferences persisted
        fetched = try await sut.fetch()
        XCTAssertEqual(fetched?.notificationPreferences.weeklyEmailEnabled, false)

        // 7. Delete parent
        try await sut.delete()

        // 8. Verify deletion
        fetched = try await sut.fetch()
        XCTAssertNil(fetched)
    }

    func testNotificationPreferences_EncodingDecoding() async throws {
        // Test that complex nested structures are properly encoded/decoded

        // Arrange: Create parent with all preference variations
        let preferences = ParentNotificationPreferences(
            weeklyEmailEnabled: true,
            weeklyEmailDay: 3,
            weeklyEmailTime: 15,
            achievementAlertsEnabled: true
        )
        let parent = Parent(
            name: "Test Parent",
            email: "test@example.com",
            notificationPreferences: preferences
        )

        // Act: Save and retrieve
        _ = try await sut.create(parent)
        let fetched = try await sut.fetch()

        // Assert: All fields preserved
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.notificationPreferences.weeklyEmailEnabled, true)
        XCTAssertEqual(fetched?.notificationPreferences.weeklyEmailDay, 3)
        XCTAssertEqual(fetched?.notificationPreferences.weeklyEmailTime, 15)
        XCTAssertEqual(fetched?.notificationPreferences.achievementAlertsEnabled, true)
    }

    func testMultipleUpdates_MaintainDataIntegrity() async throws {
        // Test that multiple rapid updates don't corrupt data

        // Arrange
        let parent = Parent(
            name: "Test Parent",
            email: "test@example.com"
        )
        let created = try await sut.create(parent)

        // Act: Perform multiple updates
        var current = created
        for i in 1...5 {
            current.name = "Name \(i)"
            current.email = "email\(i)@example.com"
            current.notificationPreferences.weeklyEmailDay = i
            current = try await sut.update(current)
        }

        // Assert
        XCTAssertEqual(current.name, "Name 5")
        XCTAssertEqual(current.email, "email5@example.com")
        XCTAssertEqual(current.notificationPreferences.weeklyEmailDay, 5)

        // Verify final state persisted
        let fetched = try await sut.fetch()
        XCTAssertEqual(fetched?.name, "Name 5")
        XCTAssertEqual(fetched?.email, "email5@example.com")
        XCTAssertEqual(fetched?.notificationPreferences.weeklyEmailDay, 5)
    }

    func testCreatedDate_IsImmutable() async throws {
        // Verify that createdDate doesn't change on updates

        // Arrange
        let originalDate = Date().addingTimeInterval(-86400) // Yesterday
        let parent = Parent(
            name: "Test Parent",
            email: "test@example.com",
            createdDate: originalDate
        )
        let created = try await sut.create(parent)

        // Act: Update parent
        var updated = created
        updated.name = "Updated Name"
        let result = try await sut.update(updated)

        // Assert: Created date unchanged
        XCTAssertEqual(result.createdDate.timeIntervalSince1970,
                       originalDate.timeIntervalSince1970,
                       accuracy: 1.0)
    }
}
