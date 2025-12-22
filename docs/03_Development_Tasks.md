# Development Tasks - FocusPal

**Owner:** Development Agent  
**Status:** In Progress  
**Last Updated:** [Date]

---

## Sprint Planning

### Sprint 1: Foundation & Setup (Week 1-2)

#### Task 1.1: Project Initialization
**Priority:** P0 (Critical)  
**Story Points:** 3  
**Dependencies:** None

**Acceptance Criteria:**
- [ ] Xcode project created with correct settings
- [ ] Git repository initialized with .gitignore
- [ ] Folder structure matches architecture spec
- [ ] Initial commit pushed to repository

**Implementation Steps:**
1. Create new Xcode project (iOS, SwiftUI)
2. Configure project settings (Bundle ID, Team, Capabilities)
3. Set minimum deployment target to iOS 16.0
4. Create folder structure per architecture doc
5. Add .gitignore for Xcode
6. Create README.md with project overview
7. Initialize git and make initial commit

**Files to Create:**
```
FocusPal.xcodeproj
FocusPal/
├── App/FocusPalApp.swift
├── Core/ (empty folders)
├── Features/ (empty folders)
├── DesignSystem/ (empty folders)
└── Resources/
.gitignore
README.md
```

---

#### Task 1.2: Core Data Stack Setup
**Priority:** P0  
**Story Points:** 5  
**Dependencies:** Task 1.1

**Acceptance Criteria:**
- [ ] Core Data model file created with all entities
- [ ] CoreDataStack class implemented
- [ ] Migration strategy defined
- [ ] Test data seeding capability
- [ ] Unit tests for Core Data operations

**Implementation:**

**File:** `Core/Persistence/CoreDataStack.swift`
```swift
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "FocusPal")
        
        // Configure for local-only or CloudKit
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, 
                              forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, 
                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // File protection
        description?.setOption(FileProtectionType.complete as NSObject,
                              forKey: NSPersistentStoreFileProtectionKey)
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var mainContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    func saveContext() {
        let context = mainContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
```

**File:** `FocusPal.xcdatamodeld`
- Create entities: Child, Activity, Category, TimeGoal, Achievement
- Define relationships and attributes per architecture spec
- Set up indexes on frequently queried fields

---

#### Task 1.3: Repository Pattern Implementation
**Priority:** P0  
**Story Points:** 8  
**Dependencies:** Task 1.2

**Acceptance Criteria:**
- [ ] Repository protocols defined
- [ ] Core Data implementations created
- [ ] Mock implementations for testing
- [ ] CRUD operations working
- [ ] Unit tests with 80%+ coverage

**Repositories to Implement:**
1. ChildRepository
2. ActivityRepository
3. CategoryRepository
4. TimeGoalRepository
5. AchievementRepository

**Example - ChildRepository:**

**File:** `Core/Persistence/Repositories/Protocols/ChildRepositoryProtocol.swift`
```swift
import Foundation

protocol ChildRepositoryProtocol {
    func create(name: String, age: Int, avatarId: String) async throws -> Child
    func fetchAll() async throws -> [Child]
    func fetch(by id: UUID) async throws -> Child?
    func update(_ child: Child) async throws -> Child
    func delete(_ childId: UUID) async throws
    func setActive(_ childId: UUID) async throws
    func fetchActive() async throws -> Child?
}
```

**File:** `Core/Persistence/Repositories/Implementation/CoreDataChildRepository.swift`
```swift
import CoreData

class CoreDataChildRepository: ChildRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func create(name: String, age: Int, avatarId: String) async throws -> Child {
        return try await context.perform {
            let entity = ChildEntity(context: self.context)
            entity.id = UUID()
            entity.name = name
            entity.age = Int16(age)
            entity.avatarId = avatarId
            entity.createdDate = Date()
            entity.isActive = false
            
            try self.context.save()
            return entity.toDomain()
        }
    }
    
    func fetchAll() async throws -> [Child] {
        return try await context.perform {
            let request = ChildEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            let entities = try self.context.fetch(request)
            return entities.map { $0.toDomain() }
        }
    }
    
    // Implement remaining methods...
}
```

---

#### Task 1.4: Service Layer Foundation
**Priority:** P0  
**Story Points:** 8  
**Dependencies:** Task 1.3

**Acceptance Criteria:**
- [ ] Service protocols defined
- [ ] Basic implementations created
- [ ] Dependency injection configured
- [ ] Service container implemented
- [ ] Unit tests for core services

**Services to Implement (Foundation):**
1. ChildService - Profile management
2. CategoryService - Category CRUD
3. NotificationService - Basic notifications

**File:** `App/ServiceContainer.swift`
```swift
import Foundation

class ServiceContainer {
    // MARK: - Singleton
    static let shared = ServiceContainer()
    
    // MARK: - Core Data
    lazy var coreDataStack: CoreDataStack = {
        CoreDataStack.shared
    }()
    
    // MARK: - Repositories
    lazy var childRepository: ChildRepositoryProtocol = {
        CoreDataChildRepository(context: coreDataStack.mainContext)
    }()
    
    lazy var activityRepository: ActivityRepositoryProtocol = {
        CoreDataActivityRepository(context: coreDataStack.mainContext)
    }()
    
    lazy var categoryRepository: CategoryRepositoryProtocol = {
        CoreDataCategoryRepository(context: coreDataStack.mainContext)
    }()
    
    // MARK: - Services
    lazy var childService: ChildServiceProtocol = {
        ChildService(repository: childRepository)
    }()
    
    lazy var categoryService: CategoryServiceProtocol = {
        CategoryService(repository: categoryRepository)
    }()
    
    lazy var notificationService: NotificationServiceProtocol = {
        NotificationService()
    }()
    
    private init() {}
}

// SwiftUI Environment
import SwiftUI

private struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

extension EnvironmentValues {
    var services: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
```

---

#### Task 1.5: Design System Implementation
**Priority:** P0  
**Story Points:** 8  
**Dependencies:** None (can run parallel)

**Acceptance Criteria:**
- [ ] Color palette implemented
- [ ] Typography system created
- [ ] Spacing constants defined
- [ ] Basic components created (buttons, cards)
- [ ] Preview providers for all components

**Files to Create:**

**File:** `DesignSystem/Tokens/Colors.swift`
```swift
import SwiftUI

enum AppColors {
    // Brand Colors
    static let primaryIndigo = Color(hex: "6366F1")
    static let primaryPurple = Color(hex: "A855F7")
    static let primaryPink = Color(hex: "EC4899")
    
    // Category Colors
    static let homework = Color(hex: "FF6B6B")
    static let creativePlay = Color(hex: "4ECDC4")
    static let physical = Color(hex: "FFD93D")
    static let screenTime = Color(hex: "A78BFA")
    static let reading = Color(hex: "F472B6")
    static let social = Color(hex: "34D399")
    static let lifeSkills = Color(hex: "FB923C")
    static let selfCare = Color(hex: "818CF8")
    
    // Semantic
    static let success = Color(hex: "10B981")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")
    static let info = Color(hex: "3B82F6")
    
    // Neutrals
    static let gray50 = Color(hex: "F9FAFB")
    static let gray100 = Color(hex: "F3F4F6")
    static let gray200 = Color(hex: "E5E7EB")
    static let gray300 = Color(hex: "D1D5DB")
    static let gray400 = Color(hex: "9CA3AF")
    static let gray500 = Color(hex: "6B7280")
    static let gray600 = Color(hex: "4B5563")
    static let gray700 = Color(hex: "374151")
    static let gray800 = Color(hex: "1F2937")
    static let gray900 = Color(hex: "111827")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

**File:** `DesignSystem/Components/Buttons/PrimaryButton.swift`
```swift
import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Fredoka", size: 18).weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [AppColors.primaryIndigo, AppColors.primaryPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: AppColors.primaryIndigo.opacity(0.3), radius: 8, y: 4)
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Start Timer") {}
        PrimaryButton(title: "Save") {}
            .disabled(true)
    }
    .padding()
}
```

---

### Sprint 2: Profile & Onboarding (Week 2-3)

#### Task 2.1: Child Profile Management
**Priority:** P0  
**Story Points:** 8  
**User Story:** US-1.1, US-1.2

**Implementation:**

**Files:**
- `Features/ProfileSelection/Views/ProfileSelectionView.swift`
- `Features/ProfileSelection/Views/CreateProfileView.swift`
- `Features/ProfileSelection/ViewModels/ProfileSelectionViewModel.swift`

**ViewModel Example:**
```swift
@MainActor
class ProfileSelectionViewModel: ObservableObject {
    @Published var children: [Child] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showCreateProfile = false
    
    private let childService: ChildServiceProtocol
    
    init(childService: ChildServiceProtocol = ServiceContainer.shared.childService) {
        self.childService = childService
    }
    
    func loadChildren() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            children = try await childService.fetchAll()
        } catch {
            errorMessage = "Failed to load profiles: \(error.localizedDescription)"
        }
    }
    
    func selectChild(_ child: Child) async {
        do {
            try await childService.setActive(child.id)
            // Navigate to home screen
        } catch {
            errorMessage = "Failed to select profile: \(error.localizedDescription)"
        }
    }
    
    func createChild(name: String, age: Int, avatarId: String) async {
        do {
            let child = try await childService.create(name: name, age: age, avatarId: avatarId)
            children.append(child)
            showCreateProfile = false
        } catch {
            errorMessage = "Failed to create profile: \(error.localizedDescription)"
        }
    }
}
```

---

#### Task 2.2: Onboarding Flow
**Priority:** P0  
**Story Points:** 5  
**User Story:** US-6.1

**Screens:**
1. Welcome screen
2. Create parent PIN
3. Create first child profile
4. Permissions request (notifications)
5. Quick tutorial

**Implementation:**
- Use TabView with PageTabViewStyle for step progression
- Store onboarding completion in UserDefaults
- Show only on first launch

---

### Sprint 3: Visual Timer (Week 3-4)

#### Task 3.1: Timer Service Implementation
**Priority:** P0  
**Story Points:** 13  
**User Story:** US-2.1, US-2.2

**Implementation:**

**File:** `Core/Services/Implementation/TimerService.swift`
```swift
import Combine
import UserNotifications

@MainActor
class TimerService: ObservableObject, TimerServiceProtocol {
    @Published private(set) var state: TimerState = .idle
    @Published private(set) var remainingTime: TimeInterval = 0
    @Published private(set) var visualizationMode: TimerVisualizationMode = .circular
    
    private var timer: Timer?
    private var endTime: Date?
    private var totalDuration: TimeInterval = 0
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    private let notificationService: NotificationServiceProtocol
    
    init(notificationService: NotificationServiceProtocol = ServiceContainer.shared.notificationService) {
        self.notificationService = notificationService
        setupNotificationObservers()
    }
    
    func startTimer(duration: TimeInterval, mode: TimerMode, category: Category?) {
        totalDuration = duration
        remainingTime = duration
        endTime = Date().addingTimeInterval(duration)
        state = .running(mode: mode, category: category)
        
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        
        // Schedule notification
        notificationService.scheduleTimerCompletion(in: duration, categoryName: category?.name ?? "Activity")
        
        // Request background task
        startBackgroundTask()
    }
    
    private func tick() {
        guard let endTime = endTime else { return }
        
        remainingTime = max(0, endTime.timeIntervalSinceNow)
        
        if remainingTime <= 0 {
            timerCompleted()
        }
    }
    
    private func timerCompleted() {
        timer?.invalidate()
        timer = nil
        state = .completed
        endBackgroundTask()
        
        // Haptic & sound feedback
        HapticManager.success()
        SoundManager.play(.timerComplete)
    }
    
    func pauseTimer() {
        guard case .running = state else { return }
        
        timer?.invalidate()
        timer = nil
        
        if case .running(let mode, let category) = state {
            state = .paused(mode: mode, category: category)
        }
        
        notificationService.cancelAllNotifications()
    }
    
    func resumeTimer() {
        guard case .paused(let mode, let category) = state else { return }
        
        endTime = Date().addingTimeInterval(remainingTime)
        state = .running(mode: mode, category: category)
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        
        notificationService.scheduleTimerCompletion(in: remainingTime, categoryName: category?.name ?? "Activity")
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        endTime = nil
        remainingTime = 0
        state = .idle
        endBackgroundTask()
        notificationService.cancelAllNotifications()
    }
    
    func setVisualizationMode(_ mode: TimerVisualizationMode) {
        visualizationMode = mode
    }
    
    // MARK: - Background Task
    
    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        // Timer continues via scheduled Timer
        // Notification scheduled for completion
    }
    
    @objc private func appWillEnterForeground() {
        // Recalculate remaining time
        if let endTime = endTime {
            remainingTime = max(0, endTime.timeIntervalSinceNow)
            if remainingTime <= 0 {
                timerCompleted()
            }
        }
    }
}

enum TimerState: Equatable {
    case idle
    case running(mode: TimerMode, category: Category?)
    case paused(mode: TimerMode, category: Category?)
    case completed
}

enum TimerMode: String {
    case countdown
    case pomodoro
}

enum TimerVisualizationMode: String, CaseIterable {
    case circular
    case progressBar
    case analogClock
    case digital
}
```

---

#### Task 3.2: Visual Timer Components
**Priority:** P0  
**Story Points:** 13  
**Dependencies:** Task 3.1

**Components to Build:**
1. CircularTimerView (Time Timer style)
2. BarTimerView (progress bar)
3. AnalogTimerView (clock face)
4. DigitalTimerView (countdown numbers)

**Circular Timer Example:**
```swift
struct CircularTimerView: View {
    let progress: Double // 0.0 to 1.0
    let remainingTime: TimeInterval
    
    private var color: Color {
        let minutes = remainingTime / 60
        if minutes > 10 {
            return AppColors.success
        } else if minutes > 5 {
            return AppColors.warning
        } else {
            return AppColors.error
        }
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(AppColors.gray200, lineWidth: 12)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: 1 - progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
            
            // Time display
            VStack(spacing: 8) {
                Text(formatTime(remainingTime))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.gray800)
                
                Text("remaining")
                    .font(.caption)
                    .foregroundColor(AppColors.gray500)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
```

---

## Code Quality Standards

### Swift Style Guide

1. **Naming Conventions:**
   - Classes/Structs: PascalCase
   - Variables/Functions: camelCase
   - Constants: camelCase
   - Enums: PascalCase with lowercase cases

2. **File Organization:**
   - One type per file
   - Mark extensions with // MARK: -
   - Group related code

3. **Documentation:**
   - Use /// for public API documentation
   - Document complex logic
   - Avoid obvious comments

4. **Error Handling:**
   - Use Result type or async throws
   - Create custom error types
   - Provide meaningful error messages

5. **Code Length:**
   - Functions: < 50 lines
   - Files: < 400 lines
   - Split large files into extensions

### Testing Requirements

**Unit Tests:**
- All ViewModels: 90%+ coverage
- All Services: 85%+ coverage
- All Repositories: 80%+ coverage

**Integration Tests:**
- Core Data operations
- Service interactions
- Sync functionality

**UI Tests:**
- Critical user flows
- Happy paths
- Error scenarios

---

## Task Dependencies Graph

```
1.1 (Project Setup)
  ├─> 1.2 (Core Data)
  │     ├─> 1.3 (Repositories)
  │     │     └─> 1.4 (Services)
  │     │           ├─> 2.1 (Profiles)
  │     │           │     └─> 2.2 (Onboarding)
  │     │           └─> 3.1 (Timer Service)
  │     │                 └─> 3.2 (Timer UI)
  │     └─> [All future data tasks]
  └─> 1.5 (Design System)
        └─> [All UI tasks]
```

---

**Development Agent Responsibilities:**
1. Implement tasks according to specifications
2. Write unit tests for all code (TDD preferred)
3. Follow code quality standards
4. Document complex logic
5. Create pull requests with clear descriptions
6. Respond to code review feedback
7. Update task status in project board
