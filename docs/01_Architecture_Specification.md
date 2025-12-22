# Architecture Specification - FocusPal

**Owner:** Architecture Agent  
**Status:** In Progress  
**Last Updated:** [Date]

---

## Table of Contents
1. [System Architecture Overview](#system-architecture-overview)
2. [Architecture Patterns](#architecture-patterns)
3. [Module Structure](#module-structure)
4. [Data Architecture](#data-architecture)
5. [Service Layer Design](#service-layer-design)
6. [Navigation Architecture](#navigation-architecture)
7. [Dependency Management](#dependency-management)
8. [Architecture Decision Records](#architecture-decision-records)

---

## System Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Presentation Layer                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Home    │  │  Timer   │  │  Stats   │  │ Settings │   │
│  │  View    │  │  View    │  │  View    │  │  View    │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │             │              │              │          │
│  ┌────▼─────────────▼──────────────▼──────────────▼─────┐  │
│  │              ViewModel Layer                          │  │
│  │  (Business Logic, State Management, Combine)          │  │
│  └────────────────────┬───────────────────────────────────┘  │
└───────────────────────┼──────────────────────────────────────┘
                        │
┌───────────────────────▼──────────────────────────────────────┐
│                     Service Layer                            │
│  ┌─────────┐  ┌─────────┐  ┌──────────┐  ┌─────────────┐  │
│  │ Timer   │  │Activity │  │ Category │  │Notification │  │
│  │ Service │  │ Service │  │ Service  │  │  Service    │  │
│  └────┬────┘  └────┬────┘  └────┬─────┘  └──────┬──────┘  │
│       └────────────┼─────────────┴────────────────┘          │
└────────────────────┼──────────────────────────────────────────┘
                     │
┌────────────────────▼──────────────────────────────────────────┐
│                 Repository Layer                              │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │   Child     │  │   Activity   │  │   Category   │        │
│  │ Repository  │  │  Repository  │  │  Repository  │        │
│  └──────┬──────┘  └──────┬───────┘  └──────┬───────┘        │
│         └─────────────────┼──────────────────┘                │
└───────────────────────────┼───────────────────────────────────┘
                            │
┌───────────────────────────▼───────────────────────────────────┐
│                   Persistence Layer                           │
│  ┌────────────────┐           ┌─────────────────┐           │
│  │  Core Data     │◄─────────►│   CloudKit      │           │
│  │  (Local DB)    │           │  (Cloud Sync)   │           │
│  └────────────────┘           └─────────────────┘           │
└───────────────────────────────────────────────────────────────┘
```

### Architecture Layers

**Presentation Layer (SwiftUI Views)**
- Responsible for UI rendering and user interaction
- Observes ViewModels for state changes
- No business logic, only presentation logic
- Reusable components in DesignSystem module

**ViewModel Layer**
- Manages view state using @Published properties
- Handles user actions and coordinates with services
- Uses Combine for reactive data flows
- Testable without UI dependencies

**Service Layer**
- Implements business logic
- Coordinates between repositories
- Manages background tasks and notifications
- Protocol-based for testability and flexibility

**Repository Layer**
- Abstracts data access from services
- Handles Core Data operations
- Manages sync with CloudKit
- Provides clean API for CRUD operations

**Persistence Layer**
- Core Data for local storage
- CloudKit for optional cloud sync
- Encrypted storage for sensitive data
- Background context for heavy operations

---

## Architecture Patterns

### 1. MVVM (Model-View-ViewModel)

**Rationale:** SwiftUI works naturally with MVVM pattern. Clear separation of concerns, testable business logic.

```swift
// Model
struct Activity {
    let id: UUID
    let categoryId: UUID
    let startTime: Date
    let endTime: Date
    var duration: TimeInterval { endTime.timeIntervalSince(startTime) }
}

// View
struct ActivityLogView: View {
    @StateObject private var viewModel = ActivityLogViewModel()
    
    var body: some View {
        // UI code
    }
}

// ViewModel
@MainActor
class ActivityLogViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var isLoading = false
    
    private let activityService: ActivityServiceProtocol
    
    init(activityService: ActivityServiceProtocol = ActivityService.shared) {
        self.activityService = activityService
    }
    
    func loadActivities() async {
        isLoading = true
        activities = await activityService.fetchTodayActivities()
        isLoading = false
    }
}
```

### 2. Coordinator Pattern (Navigation)

**Rationale:** Centralized navigation logic, ViewModels don't know about routing.

```swift
protocol Coordinator {
    var navigationController: UINavigationController { get }
    func start()
}

class AppCoordinator: Coordinator {
    let navigationController: UINavigationController
    private var childCoordinators: [Coordinator] = []
    
    func start() {
        let homeView = HomeView(coordinator: self)
        // Setup navigation
    }
    
    func showTimer() {
        let timerCoordinator = TimerCoordinator(navigationController: navigationController)
        childCoordinators.append(timerCoordinator)
        timerCoordinator.start()
    }
}
```

### 3. Repository Pattern

**Rationale:** Abstract data access, easier to swap implementations, better testability.

```swift
protocol ChildRepositoryProtocol {
    func create(_ child: Child) async throws -> Child
    func fetchAll() async throws -> [Child]
    func update(_ child: Child) async throws -> Child
    func delete(_ childId: UUID) async throws
}

class CoreDataChildRepository: ChildRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    func create(_ child: Child) async throws -> Child {
        // Core Data implementation
    }
}

class MockChildRepository: ChildRepositoryProtocol {
    var mockChildren: [Child] = []
    
    func create(_ child: Child) async throws -> Child {
        mockChildren.append(child)
        return child
    }
}
```

### 4. Dependency Injection

**Rationale:** Loose coupling, easier testing, flexible architecture.

```swift
// Using SwiftUI Environment
struct ServicesEnvironmentKey: EnvironmentKey {
    static let defaultValue: ServiceContainer = ServiceContainer()
}

extension EnvironmentValues {
    var services: ServiceContainer {
        get { self[ServicesEnvironmentKey.self] }
        set { self[ServicesEnvironmentKey.self] = newValue }
    }
}

// Usage in View
struct HomeView: View {
    @Environment(\.services) var services
    
    var body: some View {
        // Use services.timerService, services.activityService, etc.
    }
}
```

---

## Module Structure

### Folder Organization

```
FocusPal/
├── App/
│   ├── FocusPalApp.swift              # App entry point
│   ├── AppCoordinator.swift           # Root coordinator
│   └── ServiceContainer.swift         # DI container
│
├── Core/
│   ├── Models/                        # Domain models
│   │   ├── Child.swift
│   │   ├── Activity.swift
│   │   ├── Category.swift
│   │   ├── TimeGoal.swift
│   │   └── Achievement.swift
│   │
│   ├── Services/                      # Business logic
│   │   ├── Protocols/
│   │   │   ├── TimerServiceProtocol.swift
│   │   │   ├── ActivityServiceProtocol.swift
│   │   │   └── CategoryServiceProtocol.swift
│   │   ├── Implementation/
│   │   │   ├── TimerService.swift
│   │   │   ├── ActivityService.swift
│   │   │   ├── CategoryService.swift
│   │   │   ├── SyncService.swift
│   │   │   ├── NotificationService.swift
│   │   │   └── AnalyticsService.swift
│   │   └── Mock/
│   │       ├── MockTimerService.swift
│   │       └── MockActivityService.swift
│   │
│   ├── Persistence/                   # Data layer
│   │   ├── CoreDataStack.swift
│   │   ├── FocusPal.xcdatamodeld
│   │   ├── Repositories/
│   │   │   ├── Protocols/
│   │   │   │   ├── ChildRepositoryProtocol.swift
│   │   │   │   ├── ActivityRepositoryProtocol.swift
│   │   │   │   └── CategoryRepositoryProtocol.swift
│   │   │   ├── Implementation/
│   │   │   │   ├── CoreDataChildRepository.swift
│   │   │   │   ├── CoreDataActivityRepository.swift
│   │   │   │   └── CoreDataCategoryRepository.swift
│   │   │   └── Mock/
│   │   │       ├── MockChildRepository.swift
│   │   │       └── MockActivityRepository.swift
│   │   └── CloudKit/
│   │       ├── CloudKitManager.swift
│   │       └── SyncCoordinator.swift
│   │
│   └── Utilities/
│       ├── Constants.swift
│       ├── Logger.swift
│       ├── DateHelper.swift
│       ├── Extensions/
│       │   ├── Date+Extensions.swift
│       │   ├── Color+Extensions.swift
│       │   └── View+Extensions.swift
│       └── Helpers/
│           ├── HapticManager.swift
│           └── SoundManager.swift
│
├── Features/
│   ├── Home/
│   │   ├── Views/
│   │   │   ├── HomeView.swift
│   │   │   └── Components/
│   │   │       ├── QuickStatsCard.swift
│   │   │       ├── QuickActionButton.swift
│   │   │       └── TodayActivityList.swift
│   │   ├── ViewModels/
│   │   │   └── HomeViewModel.swift
│   │   └── Coordinator/
│   │       └── HomeCoordinator.swift
│   │
│   ├── Timer/
│   │   ├── Views/
│   │   │   ├── TimerView.swift
│   │   │   ├── CircularTimerView.swift
│   │   │   ├── BarTimerView.swift
│   │   │   ├── AnalogTimerView.swift
│   │   │   └── TimerControlsView.swift
│   │   ├── ViewModels/
│   │   │   └── TimerViewModel.swift
│   │   └── Models/
│   │       ├── TimerMode.swift
│   │       └── TimerState.swift
│   │
│   ├── ActivityLog/
│   │   ├── Views/
│   │   │   ├── ActivityLogView.swift
│   │   │   ├── QuickLogView.swift
│   │   │   └── ManualEntryView.swift
│   │   └── ViewModels/
│   │       └── ActivityLogViewModel.swift
│   │
│   ├── Statistics/
│   │   ├── Views/
│   │   │   ├── StatisticsView.swift
│   │   │   ├── DailyChartView.swift
│   │   │   ├── WeeklyChartView.swift
│   │   │   └── AchievementsView.swift
│   │   ├── ViewModels/
│   │   │   └── StatisticsViewModel.swift
│   │   └── Components/
│   │       ├── PieChart.swift
│   │       ├── BarChart.swift
│   │       └── BalanceMeter.swift
│   │
│   ├── ParentControls/
│   │   ├── Views/
│   │   │   ├── ParentDashboardView.swift
│   │   │   ├── AuthenticationView.swift
│   │   │   ├── CategoryManagementView.swift
│   │   │   ├── TimeGoalsView.swift
│   │   │   └── ReportsView.swift
│   │   ├── ViewModels/
│   │   │   ├── ParentDashboardViewModel.swift
│   │   │   ├── AuthenticationViewModel.swift
│   │   │   └── CategoryManagementViewModel.swift
│   │   └── Services/
│   │       └── AuthenticationService.swift
│   │
│   ├── Onboarding/
│   │   ├── Views/
│   │   │   ├── OnboardingContainerView.swift
│   │   │   ├── WelcomeView.swift
│   │   │   ├── CreatePINView.swift
│   │   │   ├── CreateProfileView.swift
│   │   │   └── PermissionsView.swift
│   │   └── ViewModels/
│   │       └── OnboardingViewModel.swift
│   │
│   └── ProfileSelection/
│       ├── Views/
│       │   └── ProfileSelectionView.swift
│       └── ViewModels/
│           └── ProfileSelectionViewModel.swift
│
├── DesignSystem/
│   ├── Tokens/
│   │   ├── Colors.swift              # Color palette
│   │   ├── Typography.swift          # Font styles
│   │   ├── Spacing.swift             # Spacing scale
│   │   ├── Shadows.swift             # Shadow styles
│   │   └── Animations.swift          # Animation presets
│   │
│   └── Components/
│       ├── Buttons/
│       │   ├── PrimaryButton.swift
│       │   ├── SecondaryButton.swift
│       │   └── IconButton.swift
│       ├── Cards/
│       │   ├── ActivityCard.swift
│       │   ├── StatCard.swift
│       │   └── AchievementCard.swift
│       ├── Inputs/
│       │   ├── TextField.swift
│       │   ├── SecureField.swift
│       │   └── Picker.swift
│       └── Common/
│           ├── LoadingView.swift
│           ├── EmptyStateView.swift
│           └── ErrorView.swift
│
├── Resources/
│   ├── Assets.xcassets
│   ├── Sounds/
│   │   ├── timer-complete.wav
│   │   ├── timer-warning.wav
│   │   └── achievement-unlock.wav
│   └── Localizable/
│       ├── en.lproj/
│       │   └── Localizable.strings
│       └── es.lproj/
│           └── Localizable.strings
│
└── Supporting Files/
    ├── Info.plist
    ├── FocusPal.entitlements
    └── Config/
        ├── Development.xcconfig
        ├── Staging.xcconfig
        └── Production.xcconfig
```

---

## Data Architecture

### Core Data Schema

#### Entity: ChildEntity
```swift
@objc(ChildEntity)
public class ChildEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var age: Int16
    @NSManaged public var avatarId: String
    @NSManaged public var themeColor: String
    @NSManaged public var preferencesJSON: Data?
    @NSManaged public var createdDate: Date
    @NSManaged public var lastActiveDate: Date?
    @NSManaged public var isActive: Bool
    
    // Relationships
    @NSManaged public var activities: NSSet?
    @NSManaged public var timeGoals: NSSet?
    @NSManaged public var achievements: NSSet?
}
```

#### Entity: ActivityEntity
```swift
@objc(ActivityEntity)
public class ActivityEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var startTime: Date
    @NSManaged public var endTime: Date
    @NSManaged public var duration: Int32  // in seconds
    @NSManaged public var notes: String?
    @NSManaged public var mood: Int16  // 0=none, 1-5=mood scale
    @NSManaged public var isManualEntry: Bool
    @NSManaged public var createdDate: Date
    @NSManaged public var syncStatus: String  // "synced", "pending", "conflict"
    
    // Relationships
    @NSManaged public var child: ChildEntity
    @NSManaged public var category: CategoryEntity
}
```

#### Entity: CategoryEntity
```swift
@objc(CategoryEntity)
public class CategoryEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var iconName: String
    @NSManaged public var colorHex: String
    @NSManaged public var isActive: Bool
    @NSManaged public var sortOrder: Int16
    @NSManaged public var isSystem: Bool  // true for default categories
    
    // Relationships
    @NSManaged public var parentCategory: CategoryEntity?
    @NSManaged public var subcategories: NSSet?
    @NSManaged public var child: ChildEntity
    @NSManaged public var activities: NSSet?
    @NSManaged public var timeGoals: NSSet?
}
```

#### Entity: TimeGoalEntity
```swift
@objc(TimeGoalEntity)
public class TimeGoalEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var recommendedMinutes: Int32
    @NSManaged public var warningThreshold: Int16  // percentage (e.g., 80 = 80%)
    @NSManaged public var isActive: Bool
    @NSManaged public var createdDate: Date
    
    // Relationships
    @NSManaged public var category: CategoryEntity
    @NSManaged public var child: ChildEntity
}
```

#### Entity: AchievementEntity
```swift
@objc(AchievementEntity)
public class AchievementEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var achievementTypeId: String  // "streak_3day", "homework_hero", etc.
    @NSManaged public var unlockedDate: Date?
    @NSManaged public var progress: Int32  // current progress value
    @NSManaged public var targetValue: Int32  // value needed to unlock
    
    // Relationships
    @NSManaged public var child: ChildEntity
}
```

### Indexes and Performance Optimization

```swift
// Fetch requests with predicates and sorting
extension ActivityEntity {
    @nonobjc public class func fetchTodayActivities(for childId: UUID) -> NSFetchRequest<ActivityEntity> {
        let request = NSFetchRequest<ActivityEntity>(entityName: "ActivityEntity")
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        request.predicate = NSPredicate(
            format: "child.id == %@ AND startTime >= %@",
            childId as CVarArg,
            startOfDay as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        request.fetchBatchSize = 20
        
        return request
    }
}

// Core Data Model Configuration
// - Add indexes on frequently queried fields: child.id, startTime, category.id
// - Set deleteRule: cascade for parent relationships
// - Enable cloudKit sync for relevant entities
```

---

## Service Layer Design

### Timer Service

```swift
protocol TimerServiceProtocol {
    var timerState: Published<TimerState>.Publisher { get }
    var remainingTime: Published<TimeInterval>.Publisher { get }
    
    func startTimer(duration: TimeInterval, mode: TimerMode, category: Category?)
    func pauseTimer()
    func resumeTimer()
    func stopTimer()
    func setVisualizationMode(_ mode: TimerVisualizationMode)
}

class TimerService: TimerServiceProtocol {
    @Published private(set) var timerState: TimerState = .idle
    @Published private(set) var remainingTime: TimeInterval = 0
    
    private var timer: Timer?
    private var startTime: Date?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    // Implementation details...
}
```

### Activity Service

```swift
protocol ActivityServiceProtocol {
    func logActivity(category: Category, duration: TimeInterval, child: Child) async throws -> Activity
    func fetchTodayActivities(for child: Child) async throws -> [Activity]
    func fetchActivities(for child: Child, dateRange: DateInterval) async throws -> [Activity]
    func updateActivity(_ activity: Activity) async throws -> Activity
    func deleteActivity(_ activityId: UUID) async throws
    func calculateDailyAggregates(for child: Child, date: Date) async throws -> [CategoryAggregate]
}
```

### Notification Service

```swift
protocol NotificationServiceProtocol {
    func requestAuthorization() async throws -> Bool
    func scheduleTimerCompletion(in duration: TimeInterval, categoryName: String)
    func scheduleTimeGoalWarning(category: String, timeUsed: Int, goalTime: Int)
    func scheduleAchievementUnlock(achievement: Achievement)
    func cancelAllNotifications()
    func cancelNotifications(withIdentifier identifier: String)
}
```

---

## Navigation Architecture

### Coordinator Protocol

```swift
protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    func start()
    func coordinate(to coordinator: Coordinator)
}

extension Coordinator {
    func coordinate(to coordinator: Coordinator) {
        coordinator.start()
        childCoordinators.append(coordinator)
    }
    
    func removeChild(_ coordinator: Coordinator?) {
        childCoordinators = childCoordinators.filter { $0 !== coordinator }
    }
}
```

### App Coordinator Flow

```
AppCoordinator
├── OnboardingCoordinator (first launch)
│   └── ProfileSetupCoordinator
│
└── MainCoordinator (authenticated)
    ├── HomeCoordinator
    ├── TimerCoordinator
    ├── ActivityLogCoordinator
    ├── StatisticsCoordinator
    └── ParentControlsCoordinator
        ├── AuthenticationCoordinator
        └── SettingsCoordinator
```

---

## Dependency Management

### Service Container

```swift
class ServiceContainer {
    // Singletons
    lazy var coreDataStack: CoreDataStack = {
        CoreDataStack(modelName: "FocusPal")
    }()
    
    // Repositories
    lazy var childRepository: ChildRepositoryProtocol = {
        CoreDataChildRepository(context: coreDataStack.mainContext)
    }()
    
    lazy var activityRepository: ActivityRepositoryProtocol = {
        CoreDataActivityRepository(context: coreDataStack.mainContext)
    }()
    
    lazy var categoryRepository: CategoryRepositoryProtocol = {
        CoreDataCategoryRepository(context: coreDataStack.mainContext)
    }()
    
    // Services
    lazy var timerService: TimerServiceProtocol = {
        TimerService(notificationService: notificationService)
    }()
    
    lazy var activityService: ActivityServiceProtocol = {
        ActivityService(repository: activityRepository)
    }()
    
    lazy var categoryService: CategoryServiceProtocol = {
        CategoryService(repository: categoryRepository)
    }()
    
    lazy var notificationService: NotificationServiceProtocol = {
        NotificationService()
    }()
    
    lazy var syncService: SyncServiceProtocol = {
        SyncService(cloudKitManager: CloudKitManager())
    }()
}

// SwiftUI Environment
extension EnvironmentValues {
    var services: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}

private struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer()
}
```

---

## Architecture Decision Records

### ADR-001: SwiftUI Over UIKit

**Status:** Accepted  
**Date:** [Date]

**Context:**  
Need to choose between SwiftUI and UIKit for the UI framework.

**Decision:**  
Use SwiftUI exclusively for all UI code.

**Consequences:**
- ✅ Faster development with declarative syntax
- ✅ Better animation support
- ✅ Native support for MVVM pattern
- ✅ Built-in accessibility features
- ❌ Minimum iOS 16.0 requirement (acceptable for our target)
- ❌ Some advanced customizations require workarounds

---

### ADR-002: Core Data Over Realm

**Status:** Accepted  
**Date:** [Date]

**Context:**  
Need to choose a local persistence solution.

**Decision:**  
Use Core Data with CloudKit integration.

**Consequences:**
- ✅ Native Apple framework, well-supported
- ✅ CloudKit sync built-in
- ✅ NSPersistentCloudKitContainer handles sync complexity
- ✅ Better Xcode tooling
- ❌ More boilerplate than Realm
- ❌ Steeper learning curve

---

### ADR-003: Coordinator Pattern for Navigation

**Status:** Accepted  
**Date:** [Date]

**Context:**  
SwiftUI doesn't have a built-in navigation coordinator pattern.

**Decision:**  
Implement custom Coordinator pattern for navigation management.

**Consequences:**
- ✅ Centralized navigation logic
- ✅ ViewModels remain navigation-agnostic
- ✅ Easier to test navigation flows
- ✅ Better deep linking support
- ❌ Additional code complexity
- ❌ Need to maintain coordinator hierarchy

---

### ADR-004: Protocol-Based Services

**Status:** Accepted  
**Date:** [Date]

**Context:**  
Services need to be testable and swappable.

**Decision:**  
All services defined as protocols with concrete implementations.

**Consequences:**
- ✅ Easy to mock for testing
- ✅ Dependency injection friendly
- ✅ Can swap implementations (e.g., mock vs real)
- ✅ Clear contracts for each service
- ❌ More code (protocol + implementation)
- ❌ Need to maintain both

---

### ADR-005: Repository Pattern for Data Access

**Status:** Accepted  
**Date:** [Date]

**Context:**  
Need to abstract Core Data details from business logic.

**Decision:**  
Use Repository pattern with protocol-based repositories.

**Consequences:**
- ✅ Business logic independent of persistence mechanism
- ✅ Easy to test with mock repositories
- ✅ Can add caching layer transparently
- ✅ Easier to migrate persistence if needed
- ❌ Additional abstraction layer
- ❌ More code to maintain

---

## Performance Considerations

### Optimization Strategies

1. **Lazy Loading**
   - Use `@FetchRequest` with proper predicates
   - Implement pagination for large datasets
   - Lazy load images and heavy resources

2. **Background Processing**
   - Use background context for write operations
   - Schedule heavy computations off main thread
   - Use OperationQueue for complex tasks

3. **Caching**
   - Cache calculated values (daily aggregates)
   - Use NSCache for temporary in-memory cache
   - Invalidate cache on data changes

4. **Batch Operations**
   - Batch fetch requests (fetchBatchSize = 20)
   - Batch save operations
   - Use batch delete for bulk deletions

5. **Memory Management**
   - Use weak references in closures
   - Release resources in deinit
   - Monitor memory usage with Instruments
   - Properly configure fetch request result types

---

## Security Architecture

### Data Protection

```swift
// Core Data Encryption
let description = NSPersistentStoreDescription()
description.setOption(
    FileProtectionType.complete as NSObject,
    forKey: NSPersistentStoreFileProtectionKey
)

// Keychain for Sensitive Data
class KeychainManager {
    static func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }
}
```

### Authentication Flow

```swift
class AuthenticationService {
    func authenticateParent() async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric auth available
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // Fall back to PIN
            return try await authenticateWithPIN()
        }
        
        // Use biometrics
        return try await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Access parent controls"
        )
    }
}
```

---

## Testing Architecture

### Test Structure

```
FocusPalTests/
├── UnitTests/
│   ├── Services/
│   │   ├── TimerServiceTests.swift
│   │   └── ActivityServiceTests.swift
│   ├── ViewModels/
│   │   ├── HomeViewModelTests.swift
│   │   └── TimerViewModelTests.swift
│   ├── Repositories/
│   │   └── ActivityRepositoryTests.swift
│   └── Utilities/
│       └── DateHelperTests.swift
│
├── IntegrationTests/
│   ├── CoreDataIntegrationTests.swift
│   └── SyncIntegrationTests.swift
│
└── Mocks/
    ├── MockTimerService.swift
    ├── MockActivityRepository.swift
    └── MockNotificationService.swift
```

---

**Next Steps for Architecture Agent:**
1. Create Core Data model file (.xcdatamodeld)
2. Implement CoreDataStack
3. Create repository protocols and implementations
4. Define service protocols
5. Set up dependency injection container
6. Create coordinator base classes
