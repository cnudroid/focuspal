# Test Framework Setup Guide - FocusPal

**Version:** 1.0
**Last Updated:** 2025-12-30
**Owner:** QA Team

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [XCTest Setup](#xctest-setup)
3. [XCUITest Setup](#xcuitest-setup)
4. [Test Utilities & Helpers](#test-utilities--helpers)
5. [Mock Objects](#mock-objects)
6. [Test Data Management](#test-data-management)
7. [Running Tests](#running-tests)
8. [Writing Your First Test](#writing-your-first-test)
9. [Best Practices](#best-practices)

---

## Getting Started

### Prerequisites

**Required:**
- Xcode 15.2 or later
- macOS 14.0 or later
- iOS 16.0+ simulators installed

**Recommended:**
- SwiftLint for code quality
- xcpretty for readable test output
- Homebrew for dependency management

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourorg/focuspal.git
   cd focuspal
   ```

2. **Install dependencies**
   ```bash
   # Install SwiftLint
   brew install swiftlint

   # Install xcpretty
   gem install xcpretty

   # Optional: Install xchtmlreport for HTML reports
   brew install xchtmlreport
   ```

3. **Open project in Xcode**
   ```bash
   open FocusPal.xcodeproj
   ```

4. **Verify test targets exist**
   - FocusPalTests (Unit & Integration)
   - FocusPalUITests (UI Tests)

### Project Structure

```
FocusPal/
├── FocusPal/                          # Main app code
│   ├── Core/                          # Core business logic
│   ├── Features/                      # Feature modules
│   └── DesignSystem/                  # Reusable UI components
├── FocusPalTests/                     # Unit & Integration tests
│   ├── Models/                        # Model tests
│   ├── ViewModels/                    # ViewModel tests
│   ├── Services/                      # Service tests
│   ├── Repositories/                  # Repository tests
│   ├── Integration/                   # Integration tests
│   └── Helpers/                       # Test utilities
│       ├── TestData.swift             # Test data builders
│       ├── SharedMocks.swift          # Shared mock objects
│       └── TestCoreDataStack.swift    # In-memory Core Data
├── FocusPalUITests/                   # UI tests
│   ├── Tests/                         # Test files
│   ├── PageObjects/                   # Page Object pattern
│   └── BaseUITest.swift               # Base class for UI tests
└── docs/                              # Documentation
    ├── 06_Comprehensive_Test_Plan.md
    └── 07_CICD_Testing_Guide.md
```

---

## XCTest Setup

### Creating a Unit Test File

1. **In Xcode:**
   - Right-click on `FocusPalTests` folder
   - Select `New File...`
   - Choose `Unit Test Case Class`
   - Name: `[ClassName]Tests.swift`
   - Target: `FocusPalTests`

2. **Template:**

```swift
//
//  ExampleViewModelTests.swift
//  FocusPalTests
//
//  Tests for ExampleViewModel
//

import XCTest
@testable import FocusPal

@MainActor
final class ExampleViewModelTests: XCTestCase {

    var sut: ExampleViewModel!  // System Under Test
    var mockDependency: MockDependency!

    override func setUp() async throws {
        try await super.setUp()

        // Initialize mocks
        mockDependency = MockDependency()

        // Initialize system under test
        sut = ExampleViewModel(dependency: mockDependency)
    }

    override func tearDown() async throws {
        sut = nil
        mockDependency = nil
        try await super.tearDown()
    }

    // MARK: - Test Methods

    func test_methodName_condition_expectedResult() async {
        // Given: Set up preconditions
        let expectedValue = "test"

        // When: Execute the action
        let result = await sut.performAction(input: expectedValue)

        // Then: Verify the outcome
        XCTAssertEqual(result, expectedValue)
        XCTAssertTrue(mockDependency.methodCalled)
    }
}
```

### Test Naming Convention

**Pattern:** `test_<methodName>_<condition>_<expectedResult>`

**Examples:**
- `test_startTimer_whenCalled_startsTimerService`
- `test_validatePIN_withInvalidLength_returnsFalse`
- `test_saveActivity_whenRepositoryThrows_handlesError`

### Given-When-Then Structure

All tests should follow the Given-When-Then pattern:

```swift
func test_example() async {
    // Given: Describe the initial state
    // Set up preconditions, create test data, configure mocks

    // When: Describe the action
    // Execute the method being tested

    // Then: Describe the expected outcome
    // Assert results, verify method calls, check state changes
}
```

---

## XCUITest Setup

### Creating a UI Test File

1. **In Xcode:**
   - Right-click on `FocusPalUITests/Tests` folder
   - Select `New File...`
   - Choose `UI Test Case Class`
   - Name: `[Feature]UITests.swift`
   - Target: `FocusPalUITests`

2. **Template:**

```swift
//
//  ExampleFlowUITests.swift
//  FocusPalUITests
//
//  UI tests for Example feature
//  Test ID: UI-XXX
//  Priority: P0 (Critical)
//

import XCTest

final class ExampleFlowUITests: BaseUITest {

    var examplePage: ExamplePage!

    override func setUp() {
        super.setUp()
        examplePage = ExamplePage(app: app)
    }

    override func tearDown() {
        examplePage = nil
        super.tearDown()
    }

    // MARK: - UI-XXX-001: Test Name

    func test_feature_scenario_expectedResult() {
        // Given: User is on X screen
        launchWithSingleChild()
        examplePage.verifyScreenDisplayed()

        // When: User performs action
        examplePage.tapButton()

        // Then: Expected result occurs
        examplePage.verifyResultDisplayed()
        takeScreenshot(named: "Example_Result")
    }
}
```

### Page Object Pattern

Create page objects for screens:

```swift
//
//  ExamplePage.swift
//  FocusPalUITests
//
//  Page Object for Example screen
//

import XCTest

class ExamplePage {

    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Elements

    var screenTitle: XCUIElement {
        app.staticTexts["Example Screen"]
    }

    var actionButton: XCUIElement {
        app.buttons["Action Button"]
    }

    var resultLabel: XCUIElement {
        app.staticTexts["ResultLabel"]
    }

    // MARK: - Actions

    func tapActionButton() {
        actionButton.tap()
    }

    // MARK: - Verification

    func verifyScreenDisplayed() {
        XCTAssertTrue(
            screenTitle.waitForExistence(timeout: 2),
            "Screen title should be visible"
        )
    }

    func verifyResultDisplayed() {
        XCTAssertTrue(
            resultLabel.exists,
            "Result label should be displayed"
        )
    }
}
```

### BaseUITest Features

FocusPal provides a `BaseUITest` class with utilities:

```swift
class MyUITest: BaseUITest {
    func test_example() {
        // Launch helpers
        launchFreshApp()                    // Fresh install
        launchWithOnboardingComplete()      // Onboarding done
        launchWithSingleChild()             // One child profile
        launchWithMultipleChildren(count: 3) // Multiple profiles
        launchWithSampleData()              // Pre-populated data

        // Wait helpers
        wait(for: element, timeout: 5)
        waitForDisappearance(of: element, timeout: 5)
        waitUntilHittable(element, timeout: 5)

        // Interaction helpers
        tapWhenHittable(element)
        clearAndType(text: "New text", into: textField)
        scrollTo(element, in: scrollView)

        // Assertion helpers
        assertExists(element)
        assertNotExists(element)
        assertContainsText(element, text: "Expected")

        // Screenshot helpers
        takeScreenshot(named: "MyScreen")

        // Navigation helpers
        navigateBack()
        navigateToTab("Activities")

        // PIN entry helper
        enterPIN("1234", using: app)
    }
}
```

---

## Test Utilities & Helpers

### TestData Builder

Location: `FocusPalTests/Helpers/TestData.swift`

**Purpose:** Create test objects with sensible defaults

**Usage:**

```swift
// Create child with defaults
let child = TestData.makeChild()
// name: "Test Child", age: 8

// Create child with custom values
let customChild = TestData.makeChild(
    name: "Emma",
    age: 10,
    avatarId: "avatar_girl_1",
    themeColor: "pink"
)

// Create category
let category = TestData.makeCategory(
    name: "Homework",
    iconName: "book.fill",
    colorHex: "#FF6B6B"
)

// Create activity
let activity = TestData.makeActivity(
    categoryId: category.id,
    childId: child.id,
    startTime: Date().addingTimeInterval(-3600),
    endTime: Date()
)

// Create achievement
let achievement = TestData.makeAchievement(
    achievementTypeId: "first_timer",
    childId: child.id,
    unlockedDate: Date()
)
```

### TestCoreDataStack

Location: `FocusPalTests/Helpers/TestCoreDataStack.swift`

**Purpose:** In-memory Core Data stack for fast tests

**Usage:**

```swift
class MyRepositoryTests: XCTestCase {
    var coreDataStack: CoreDataStack!
    var repository: CoreDataChildRepository!

    override func setUp() {
        // Create in-memory stack (not persisted to disk)
        coreDataStack = CoreDataStack.inMemory()
        repository = CoreDataChildRepository(
            context: coreDataStack.viewContext
        )
    }

    override func tearDown() {
        coreDataStack = nil
        repository = nil
    }

    func test_createChild_persists() async throws {
        let child = TestData.makeChild()
        let created = try await repository.create(child)

        XCTAssertNotNil(created.id)
    }
}
```

---

## Mock Objects

### Shared Mocks

Location: `FocusPalTests/Helpers/SharedMocks.swift`

**Available Mocks:**
- `SharedMockPINService`
- `TestMockChildRepository`
- `TestMockActivityService`
- `TestMockAchievementRepository`

**Usage:**

```swift
class MyViewModelTests: XCTestCase {
    var sut: MyViewModel!
    var mockPINService: SharedMockPINService!

    override func setUp() {
        mockPINService = SharedMockPINService()
        sut = MyViewModel(pinService: mockPINService)
    }

    func test_validatePIN_callsService() async {
        // Configure mock
        mockPINService.isPinSetValue = true
        mockPINService.verifyPinReturnValue = true

        // Execute
        let result = await sut.validatePIN("1234")

        // Verify
        XCTAssertTrue(result)
        XCTAssertTrue(mockPINService.verifyPinCalled)
    }
}
```

### Creating Custom Mocks

**Protocol-based mocking:**

```swift
// 1. Define protocol
protocol MyServiceProtocol {
    func performAction() async throws -> String
}

// 2. Create mock
class MockMyService: MyServiceProtocol {
    var performActionCalled = false
    var performActionReturnValue: String = "default"
    var shouldThrowError = false

    func performAction() async throws -> String {
        performActionCalled = true

        if shouldThrowError {
            throw TestError.failed
        }

        return performActionReturnValue
    }

    func reset() {
        performActionCalled = false
        performActionReturnValue = "default"
        shouldThrowError = false
    }

    enum TestError: Error {
        case failed
    }
}

// 3. Use in tests
class MyTests: XCTestCase {
    var mockService: MockMyService!

    func test_example() async throws {
        mockService = MockMyService()
        mockService.performActionReturnValue = "success"

        let result = try await mockService.performAction()

        XCTAssertEqual(result, "success")
        XCTAssertTrue(mockService.performActionCalled)
    }
}
```

---

## Test Data Management

### Fixtures

Create reusable test data:

```swift
enum TestFixtures {
    static let sampleChildren = [
        TestData.makeChild(name: "Emma", age: 8),
        TestData.makeChild(name: "Lucas", age: 10),
        TestData.makeChild(name: "Sophia", age: 12)
    ]

    static let defaultCategories = [
        TestData.makeCategory(name: "Homework"),
        TestData.makeCategory(name: "Reading"),
        TestData.makeCategory(name: "Physical Activity")
    ]

    static func sampleActivities(for child: Child) -> [Activity] {
        let category = defaultCategories[0]
        return [
            TestData.makeActivity(
                categoryId: category.id,
                childId: child.id,
                startTime: Date().addingTimeInterval(-7200),
                endTime: Date().addingTimeInterval(-5400)
            ),
            TestData.makeActivity(
                categoryId: category.id,
                childId: child.id,
                startTime: Date().addingTimeInterval(-3600),
                endTime: Date()
            )
        ]
    }
}
```

### Random Data Generation

For property-based testing:

```swift
extension TestData {
    static func randomChild() -> Child {
        let names = ["Emma", "Lucas", "Sophia", "Oliver", "Ava"]
        let ages = [5, 6, 7, 8, 9, 10, 11, 12]
        let avatars = ["avatar_boy_1", "avatar_girl_1", "avatar_default"]
        let themes = ["blue", "pink", "green", "purple"]

        return makeChild(
            name: names.randomElement()!,
            age: ages.randomElement()!,
            avatarId: avatars.randomElement()!,
            themeColor: themes.randomElement()!
        )
    }
}
```

**⚠️ Warning:** Use seeded random for reproducibility:

```swift
var randomGenerator = SystemRandomNumberGenerator()

// Use seeded generator for reproducible tests
let seededValue = (0..<10).randomElement(using: &randomGenerator)
```

---

## Running Tests

### From Xcode

**Run all tests:**
- Keyboard: `⌘ + U`
- Menu: Product > Test

**Run specific test:**
- Click diamond icon next to test method
- Click diamond icon next to test class

**Run test repeatedly:**
- Edit Scheme > Test
- Options > Repeat: Until Failure / 100 times

**Run tests on specific device:**
- Select device/simulator
- Run tests as normal

### From Command Line

**All tests:**
```bash
xcodebuild test \
  -scheme FocusPal \
  -destination 'platform=iOS Simulator,name=iPhone 14'
```

**Unit tests only:**
```bash
xcodebuild test \
  -scheme FocusPal \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -only-testing:FocusPalTests
```

**Specific test class:**
```bash
xcodebuild test \
  -scheme FocusPal \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -only-testing:FocusPalTests/TimerViewModelTests
```

**With pretty output:**
```bash
xcodebuild test \
  -scheme FocusPal \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  | xcpretty
```

**With code coverage:**
```bash
xcodebuild test \
  -scheme FocusPal \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -enableCodeCoverage YES
```

### Viewing Test Results

**In Xcode:**
- Test Navigator (⌘ + 6)
- Report Navigator (⌘ + 9)

**Command line:**
```bash
# View latest test results
open $(find ~/Library/Developer/Xcode/DerivedData -name "*.xcresult" | head -1)

# View specific result bundle
xcrun xcresulttool get --path TestResults.xcresult

# Export as JSON
xcrun xcresulttool get --path TestResults.xcresult --format json > results.json
```

---

## Writing Your First Test

### Example: Test a ViewModel

**Scenario:** Test `TimerViewModel.startTimer()`

1. **Create test file:**
   ```swift
   // FocusPalTests/ViewModels/TimerViewModelTests.swift

   import XCTest
   @testable import FocusPal

   @MainActor
   final class TimerViewModelTests: XCTestCase {
       var sut: TimerViewModel!
       var mockTimerService: MockTimerService!

       override func setUp() async throws {
           try await super.setUp()
           mockTimerService = MockTimerService()
           sut = TimerViewModel(timerService: mockTimerService)
       }

       override func tearDown() async throws {
           sut = nil
           mockTimerService = nil
           try await super.tearDown()
       }
   }
   ```

2. **Write test:**
   ```swift
   func test_startTimer_whenCalled_startsTimerService() async {
       // Given: Timer is idle
       XCTAssertEqual(sut.state, .idle)

       let duration: TimeInterval = 1500 // 25 minutes
       let category = TestData.makeCategory(name: "Homework")

       // When: Start timer is called
       await sut.startTimer(duration: duration, category: category)

       // Then: Timer service is started
       XCTAssertTrue(mockTimerService.startTimerCalled)
       XCTAssertEqual(mockTimerService.startTimerDuration, duration)
       XCTAssertEqual(sut.state, .running)
   }
   ```

3. **Create mock:**
   ```swift
   class MockTimerService: TimerServiceProtocol {
       var startTimerCalled = false
       var startTimerDuration: TimeInterval?

       func startTimer(duration: TimeInterval, category: Category?) {
           startTimerCalled = true
           startTimerDuration = duration
       }
   }
   ```

4. **Run test:**
   - Press ⌘ + U
   - Verify test passes ✅

### Example: Test a UI Flow

**Scenario:** Test onboarding completion

1. **Create test file:**
   ```swift
   // FocusPalUITests/Tests/OnboardingFlowUITests.swift

   import XCTest

   final class OnboardingFlowUITests: BaseUITest {
       var onboardingPage: OnboardingPage!

       override func setUp() {
           super.setUp()
           onboardingPage = OnboardingPage(app: app)
       }

       override func tearDown() {
           onboardingPage = nil
           super.tearDown()
       }
   }
   ```

2. **Write test:**
   ```swift
   func test_completeOnboarding_happyPath_landsOnHomeScreen() {
       // Given: Fresh app install
       launchFreshApp()

       // When: User completes onboarding
       onboardingPage.verifyWelcomeScreen()
       onboardingPage.tapGetStarted()

       onboardingPage.enterPIN("1234")
       onboardingPage.enterPIN("1234") // Confirm

       onboardingPage.tapFinish()

       // Then: User lands on home screen
       let homeTitle = app.staticTexts["Welcome!"]
       XCTAssertTrue(homeTitle.waitForExistence(timeout: 2))
       takeScreenshot(named: "OnboardingComplete")
   }
   ```

3. **Run test:**
   - Select simulator
   - Run test
   - Observe automation

---

## Best Practices

### 1. Test Independence

❌ **BAD:**
```swift
class BadTests: XCTestCase {
    static var sharedData: [String] = []

    func test_first() {
        BadTests.sharedData.append("test1")
        XCTAssertEqual(BadTests.sharedData.count, 1)
    }

    func test_second() {
        // Depends on test_first running first!
        XCTAssertEqual(BadTests.sharedData.count, 1)
    }
}
```

✅ **GOOD:**
```swift
class GoodTests: XCTestCase {
    var testData: [String] = []

    override func setUp() {
        testData = []
    }

    func test_first() {
        testData.append("test1")
        XCTAssertEqual(testData.count, 1)
    }

    func test_second() {
        testData.append("test2")
        XCTAssertEqual(testData.count, 1)
    }
}
```

### 2. Fast Tests

❌ **BAD:**
```swift
func test_slow() {
    sleep(5) // Avoid arbitrary waits
    XCTAssertTrue(element.exists)
}
```

✅ **GOOD:**
```swift
func test_fast() {
    XCTAssertTrue(element.waitForExistence(timeout: 5))
}
```

### 3. Descriptive Failures

❌ **BAD:**
```swift
XCTAssertTrue(result)
```

✅ **GOOD:**
```swift
XCTAssertTrue(result, "PIN validation should return true for valid 4-digit PIN")
```

### 4. Test One Thing

❌ **BAD:**
```swift
func test_everythingAtOnce() {
    // Tests 5 different things
    XCTAssertTrue(sut.validatePIN("1234"))
    XCTAssertFalse(sut.validatePIN("abc"))
    XCTAssertEqual(sut.state, .valid)
    // ... more assertions
}
```

✅ **GOOD:**
```swift
func test_validatePIN_withValidPIN_returnsTrue() {
    XCTAssertTrue(sut.validatePIN("1234"))
}

func test_validatePIN_withInvalidPIN_returnsFalse() {
    XCTAssertFalse(sut.validatePIN("abc"))
}

func test_validatePIN_withValidPIN_updatesState() {
    sut.validatePIN("1234")
    XCTAssertEqual(sut.state, .valid)
}
```

### 5. Mock External Dependencies

✅ Always mock:
- Network requests
- File system
- Current date/time
- Random number generation
- External APIs

❌ Never mock:
- The system under test
- Simple data models
- Value types

---

## Troubleshooting

### Tests Not Running

**Check:**
1. Test target is selected
2. Test file is in test target membership
3. Test class inherits from XCTestCase
4. Test methods start with `test`
5. Test target is included in scheme

### Tests Failing Randomly

**Common causes:**
- Timing issues (use proper waits)
- Shared state between tests
- Asynchronous operations
- Animation timing

**Solutions:**
- Use `waitForExpectation`
- Reset state in `setUp`/`tearDown`
- Use async/await properly
- Disable animations in tests

### Coverage Not Updating

**Check:**
1. Code coverage enabled in scheme
2. Test targets configured
3. Derived data cleared
4. Xcode restarted

---

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [WWDC: Testing in Xcode](https://developer.apple.com/videos/play/wwdc2019/413/)
- [Test Plan Document](./06_Comprehensive_Test_Plan.md)
- [CI/CD Guide](./07_CICD_Testing_Guide.md)

---

**You're now ready to write tests for FocusPal!**
