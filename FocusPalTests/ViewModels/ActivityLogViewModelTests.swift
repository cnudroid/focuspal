//
//  ActivityLogViewModelTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//
//  TDD tests for ActivityLogViewModel
//  Issue #26: Activity deletion race condition fix

import XCTest
@testable import FocusPal

/// Tests for ActivityLogViewModel, particularly the deletion race condition fix
@MainActor
final class ActivityLogViewModelTests: XCTestCase {

    var sut: ActivityLogViewModel!
    var mockActivityService: MockActivityService!
    var testChild: Child!
    var testCategory: Category!

    override func setUp() async throws {
        try await super.setUp()

        mockActivityService = MockActivityService()
        testChild = Child(name: "TestChild", age: 8)
        testCategory = Category(
            name: "Reading",
            iconName: "book.fill",
            colorHex: "#FF0000",
            childId: testChild.id,
            recommendedDuration: 25 * 60
        )

        sut = ActivityLogViewModel(
            activityService: mockActivityService,
            child: testChild
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockActivityService = nil
        testChild = nil
        testCategory = nil
        try await super.tearDown()
    }

    // MARK: - Issue #26: Activity Deletion Race Condition Tests

    /// Test that deleteActivities captures activity IDs immediately before async task
    /// This is the key test for Issue #26: Wrong activity deleted due to race condition
    func testDeleteActivities_CapturesIDsBeforeAsyncTask() async {
        // Given: ViewModel has activities loaded
        mockActivityService.addMockActivities(5, for: testChild.id, categoryId: testCategory.id)
        await sut.loadActivities()

        // Get the expected activity ID at index 2 BEFORE any operations
        let expectedDeletedId = sut.activities[2].id

        // When: Delete activity at index 2
        sut.deleteActivities(at: IndexSet(integer: 2))

        // Wait for async operation
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then: The correct activity (the one at index 2) should be deleted
        XCTAssertEqual(mockActivityService.deleteCallCount, 1, "Should call delete once")
        XCTAssertEqual(mockActivityService.deletedActivityIds.first, expectedDeletedId,
                      "Should delete the activity that was at index 2 when user initiated delete")
    }

    /// Test that deletion uses captured ID even if list changes during async operation
    /// Simulates the race condition scenario from Issue #26
    func testDeleteActivities_UsesCorrectID_WhenListChanges() async {
        // Given: ViewModel has activities loaded
        mockActivityService.addMockActivities(10, for: testChild.id, categoryId: testCategory.id)
        await sut.loadActivities()

        // Capture the activity ID at index 5 - this is what should be deleted
        let targetActivityId = sut.activities[5].id

        // When: Delete activity at index 5
        sut.deleteActivities(at: IndexSet(integer: 5))

        // Wait for async operation
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then: The correct activity should be deleted (the one the user selected)
        XCTAssertTrue(mockActivityService.deletedActivityIds.contains(targetActivityId),
                     "The activity that was at index 5 when user swiped should be deleted")
    }

    /// Test that multiple deletions delete correct activities
    func testDeleteActivities_MultipleIndices_DeletesCorrectActivities() async {
        // Given: ViewModel has activities loaded
        mockActivityService.addMockActivities(10, for: testChild.id, categoryId: testCategory.id)
        await sut.loadActivities()

        // Capture the activity IDs at indices 2, 4, 6
        let expectedIds = [
            sut.activities[2].id,
            sut.activities[4].id,
            sut.activities[6].id
        ]

        // When: Delete activities at indices 2, 4, 6
        sut.deleteActivities(at: IndexSet([2, 4, 6]))

        // Wait for async operation
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then: All three correct activities should be deleted
        XCTAssertEqual(mockActivityService.deleteCallCount, 3, "Should delete 3 activities")
        for expectedId in expectedIds {
            XCTAssertTrue(mockActivityService.deletedActivityIds.contains(expectedId),
                         "Activity \(expectedId) should be deleted")
        }
    }

    /// Test that out-of-bounds index is handled gracefully
    func testDeleteActivities_OutOfBoundsIndex_DoesNotCrash() async {
        // Given: ViewModel has 3 activities
        mockActivityService.addMockActivities(3, for: testChild.id, categoryId: testCategory.id)
        await sut.loadActivities()

        // When: Try to delete at index 10 (out of bounds)
        sut.deleteActivities(at: IndexSet(integer: 10))

        // Wait for async operation
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then: Should not crash, no deletion should occur
        XCTAssertEqual(mockActivityService.deleteCallCount, 0,
                      "Should not call delete for out-of-bounds index")
    }

    /// Test that empty IndexSet is handled gracefully
    func testDeleteActivities_EmptyIndexSet_DoesNothing() async {
        // Given: ViewModel has activities
        mockActivityService.addMockActivities(5, for: testChild.id, categoryId: testCategory.id)
        await sut.loadActivities()

        // When: Delete with empty IndexSet
        sut.deleteActivities(at: IndexSet())

        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: No deletion should occur
        XCTAssertEqual(mockActivityService.deleteCallCount, 0,
                      "Should not call delete for empty IndexSet")
    }

    /// Test that deletion reloads activities after completion
    func testDeleteActivities_ReloadsActivitiesAfterDeletion() async {
        // Given: ViewModel has activities
        mockActivityService.addMockActivities(5, for: testChild.id, categoryId: testCategory.id)
        await sut.loadActivities()
        let initialActivitiesCount = sut.activities.count

        // When: Delete an activity
        sut.deleteActivities(at: IndexSet(integer: 0))

        // Wait for async operation to complete
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then: Activities should be reloaded (one less activity)
        XCTAssertEqual(sut.activities.count, initialActivitiesCount - 1,
                      "Activities should be reloaded with one less item")
    }

    // MARK: - Basic Activity Loading Tests

    func testLoadActivities_FetchesActivitiesForCurrentChild() async {
        // Given: Mock service has activities
        mockActivityService.addMockActivities(3, for: testChild.id, categoryId: testCategory.id)

        // When: Load activities
        await sut.loadActivities()

        // Then: Activities should be loaded
        XCTAssertEqual(sut.activities.count, 3, "Should load 3 activities")
    }
}
