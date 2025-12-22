# Testing Strategy - FocusPal

**Owner:** Testing Agent  
**Status:** In Progress

## Testing Pyramid

```
       /\
      /UI\      10% - UI Tests (Critical flows)
     /----\
    /Integ \    20% - Integration Tests
   /--------\
  /   Unit   \  70% - Unit Tests (ViewModels, Services, Utilities)
 /------------\
```

## Test Coverage Goals

- **ViewModels:** 90%+
- **Services:** 85%+
- **Repositories:** 80%+
- **Utilities:** 80%+
- **Overall:** 80%+

## Unit Testing

### ViewModel Tests

**Example: TimerViewModelTests**
```swift
import XCTest
@testable import FocusPal

@MainActor
final class TimerViewModelTests: XCTestCase {
    var sut: TimerViewModel!
    var mockTimerService: MockTimerService!
    
    override func setUp() async throws {
        mockTimerService = MockTimerService()
        sut = TimerViewModel(timerService: mockTimerService)
    }
    
    override func tearDown() {
        sut = nil
        mockTimerService = nil
    }
    
    func test_startTimer_whenCalled_startsTimerService() async {
        // Given
        let duration: TimeInterval = 1500
        let category = Category.mock(name: "Homework")
        
        // When
        await sut.startTimer(duration: duration, category: category)
        
        // Then
        XCTAssertTrue(mockTimerService.startTimerCalled)
        XCTAssertEqual(mockTimerService.startTimerDuration, duration)
        XCTAssertEqual(sut.state, .running)
    }
    
    func test_timerCompletion_logsActivity() async {
        // Given
        await sut.startTimer(duration: 10, category: .mock())
        
        // When
        await mockTimerService.simulateCompletion()
        
        // Then
        XCTAssertEqual(sut.state, .completed)
        // Verify activity logged
    }
}
```

### Service Tests

**Example: ActivityServiceTests**
```swift
final class ActivityServiceTests: XCTestCase {
    var sut: ActivityService!
    var mockRepository: MockActivityRepository!
    
    func test_logActivity_createsActivity() async throws {
        // Given
        mockRepository = MockActivityRepository()
        sut = ActivityService(repository: mockRepository)
        let category = Category.mock()
        let child = Child.mock()
        
        // When
        let activity = try await sut.logActivity(
            category: category,
            duration: 1800,
            child: child
        )
        
        // Then
        XCTAssertNotNil(activity.id)
        XCTAssertEqual(activity.duration, 1800)
        XCTAssertEqual(mockRepository.createCalled, true)
    }
}
```

## Integration Testing

### Core Data Tests

```swift
final class CoreDataIntegrationTests: XCTestCase {
    var stack: CoreDataStack!
    
    override func setUp() {
        // Use in-memory store for testing
        stack = CoreDataStack.inMemory()
    }
    
    func test_createChild_persistsToDatabase() async throws {
        let repository = CoreDataChildRepository(context: stack.mainContext)
        
        let child = try await repository.create(
            name: "Test Child",
            age: 8,
            avatarId: "fox"
        )
        
        let fetched = try await repository.fetch(by: child.id)
        XCTAssertEqual(fetched?.name, "Test Child")
    }
}
```

## UI Testing

### Critical User Flows

**Flow 1: Create Profile and Start Timer**
```swift
final class OnboardingFlowUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    func test_completeOnboarding_andStartTimer() {
        // Welcome screen
        XCTAssertTrue(app.staticTexts["Welcome to FocusPal"].exists)
        app.buttons["Get Started"].tap()
        
        // Create PIN
        app.buttons["1"].tap()
        app.buttons["2"].tap()
        app.buttons["3"].tap()
        app.buttons["4"].tap()
        
        // Create profile
        let nameField = app.textFields["Child Name"]
        nameField.tap()
        nameField.typeText("Alex")
        
        app.buttons["Age: 8"].tap()
        app.buttons["Next"].tap()
        
        // Home screen
        XCTAssertTrue(app.staticTexts["Hey Alex!"].waitForExistence(timeout: 2))
        
        // Start timer
        app.buttons["Start Timer"].tap()
        app.buttons["25 min"].tap()
        app.buttons["Play"].tap()
        
        XCTAssertTrue(app.staticTexts["24:59"].waitForExistence(timeout: 2))
    }
}
```

## Mock Objects

### MockTimerService
```swift
class MockTimerService: TimerServiceProtocol {
    var startTimerCalled = false
    var startTimerDuration: TimeInterval?
    var pauseTimerCalled = false
    var stopTimerCalled = false
    
    @Published var state: TimerState = .idle
    @Published var remainingTime: TimeInterval = 0
    
    var timerStatePublisher: Published<TimerState>.Publisher { $state }
    var remainingTimePublisher: Published<TimeInterval>.Publisher { $remainingTime }
    
    func startTimer(duration: TimeInterval, mode: TimerMode, category: Category?) {
        startTimerCalled = true
        startTimerDuration = duration
        state = .running(mode: mode, category: category)
        remainingTime = duration
    }
    
    func pauseTimer() {
        pauseTimerCalled = true
        if case .running(let mode, let category) = state {
            state = .paused(mode: mode, category: category)
        }
    }
    
    func stopTimer() {
        stopTimerCalled = true
        state = .idle
        remainingTime = 0
    }
    
    func simulateCompletion() async {
        remainingTime = 0
        state = .completed
    }
}
```

## Test Data Builders

```swift
extension Child {
    static func mock(
        id: UUID = UUID(),
        name: String = "Test Child",
        age: Int = 8,
        avatarId: String = "fox"
    ) -> Child {
        Child(id: id, name: name, age: age, avatarId: avatarId, createdDate: Date())
    }
}

extension Category {
    static func mock(
        id: UUID = UUID(),
        name: String = "Homework",
        color: String = "FF6B6B",
        iconName: String = "book.fill"
    ) -> Category {
        Category(id: id, name: name, colorHex: color, iconName: iconName)
    }
}
```

## Performance Testing

```swift
func test_fetchActivities_performance() {
    // Create 1000 activities
    measure {
        _ = try? await activityService.fetchActivities(for: child, dateRange: lastMonth)
    }
}
```

## Accessibility Testing

```swift
func test_homeView_voiceOverAccessibility() {
    let view = HomeView()
    let hostingController = UIHostingController(rootView: view)
    
    // Verify VoiceOver labels exist
    XCTAssertNotNil(hostingController.view.accessibilityLabel)
}
```

## Testing Responsibilities

1. Write tests BEFORE or ALONGSIDE implementation (TDD)
2. Maintain test coverage above thresholds
3. Update tests when requirements change
4. Fix flaky tests immediately
5. Run full test suite before commits
6. Create UI test recordings for critical flows
