# FocusPal - Comprehensive Test Plan & Strategy

**Version:** 1.0
**Last Updated:** 2025-12-30
**Owner:** QA Team
**Status:** Active

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Test Strategy Overview](#test-strategy-overview)
3. [Test Scope & Objectives](#test-scope--objectives)
4. [Test Levels & Distribution](#test-levels--distribution)
5. [Test Case Inventory](#test-case-inventory)
6. [Test Environment](#test-environment)
7. [Tools & Framework](#tools--framework)
8. [CI/CD Integration](#cicd-integration)
9. [Quality Metrics](#quality-metrics)
10. [Risk Assessment](#risk-assessment)

---

## Executive Summary

FocusPal is an iOS app designed for children with ADHD and their families, providing visual timers, activity tracking, gamification, and parent controls. This test plan ensures comprehensive quality assurance coverage across all features while maintaining development velocity.

### Key Objectives
- Achieve 85%+ overall code coverage with meaningful tests
- Ensure 100% test coverage on critical paths (timer accuracy, data persistence, parent authentication)
- Create maintainable, deterministic UI tests for user flows
- Enable fast feedback loop (unit tests < 5s, full suite < 3 minutes)
- Support both simulator and real device testing

### Testing Pyramid Distribution
- **70% Unit Tests** (fast, isolated, comprehensive coverage)
- **20% Integration Tests** (Core Data, service interactions, data flow)
- **10% UI Tests** (critical user journeys, end-to-end flows)

---

## Test Strategy Overview

### Approach
FocusPal testing follows a **risk-based, layered testing approach**:

1. **Unit Testing First**: All ViewModels, Services, and business logic tested in isolation
2. **Integration Testing**: Validate Core Data persistence, CloudKit sync, and service composition
3. **UI Testing Last**: Focus on critical user journeys and flows that provide unique value
4. **Accessibility Baked In**: Every UI component tested with VoiceOver labels and Dynamic Type
5. **Performance Gates**: Timer accuracy, chart rendering, and data loading benchmarks

### Key Principles
- Tests must be **deterministic** (no flaky tests tolerated)
- Tests must be **fast** (unit tests < 50ms each)
- Tests must be **maintainable** (DRY principle, shared test utilities)
- Tests must provide **meaningful coverage** (not just line coverage, but behavior coverage)
- Tests must **fail fast** (catch regressions immediately)

---

## Test Scope & Objectives

### In Scope

#### Epic 1: User Profile Management
- Child profile creation, editing, deletion (up to 8 profiles)
- Profile switching with data isolation
- Active profile persistence
- Age-based UI complexity adjustments
- Avatar and theme selection

#### Epic 2: Visual ADHD Timer
- Timer start, pause, resume, stop operations
- Timer accuracy (±0.1 seconds over 30 minutes)
- Background execution and notifications
- All visualization modes (Circular, Bar, Analog, Digital)
- Color zone transitions (Green > Yellow > Red)
- Pomodoro mode with work/break cycles
- Timer state persistence across app restarts

#### Epic 3: Activity Tracking
- Quick log activity (one-tap logging)
- Manual time entry with validation
- Activity editing (duration, notes, mood, completion)
- Activity deletion
- Duration calculation accuracy
- Overlapping activity detection
- Activity history filtering

#### Epic 4: Data Visualization & Statistics
- Daily pie chart with category breakdown
- Weekly bar chart with trends
- Monthly aggregation
- Chart rendering performance (< 500ms)
- Empty state handling
- Data drill-down interactions

#### Epic 5: Gamification System
- Points calculation (category-based multipliers)
- Streak tracking (daily consistency)
- Achievement unlocking (8 achievement types)
- Reward tier progression (Bronze, Silver, Gold, Platinum)
- Weekly email report generation
- Achievement notification delivery

#### Epic 6: Parent Controls
- PIN creation and verification
- Biometric authentication (Face ID, Touch ID)
- Category management (create, edit, hide, reorder)
- Time goal setting per category
- Parent profile management
- Email configuration for reports

#### Epic 7: Onboarding
- Welcome flow (3-step process)
- PIN setup during onboarding
- Permission requests (Notifications)
- First-time user experience
- Skip/back navigation

### Out of Scope (Future Versions)
- CloudKit sync reliability testing (v1.5+)
- Apple Watch app testing (v1.5+)
- Emotional check-ins (v2.0+)
- Localization testing (v2.0+)
- Screen Time API integration (v2.0+)

### Critical Paths Requiring 100% Coverage
1. **Timer Accuracy**: Timer must be accurate within ±0.1 seconds
2. **Data Persistence**: No data loss on Core Data operations
3. **Parent Authentication**: PIN/biometric auth cannot be bypassed
4. **Multi-Child Isolation**: Each child's data must be completely isolated
5. **Points Calculation**: Points must be calculated correctly per activity

---

## Test Levels & Distribution

### Unit Tests (70% of test suite)

**Target Coverage:** 90%+ for ViewModels, 85%+ for Services

#### ViewModels to Test
- `OnboardingViewModel` - Onboarding flow logic
- `TimerViewModel` - Timer state management
- `ActivityLogViewModel` - Activity logging and editing
- `StatisticsViewModel` - Data aggregation and chart data
- `ParentAuthViewModel` - Authentication logic
- `ProfileSelectionViewModel` - Profile switching
- `ParentDashboardViewModel` - Parent controls
- `CategoryManagementViewModel` - Category CRUD
- `AchievementViewModel` - Achievement tracking
- `PointsViewModel` - Points and rewards logic

#### Services to Test
- `TimerService` - Timer execution and accuracy
- `ActivityService` - Activity CRUD operations
- `CategoryService` - Category management
- `AchievementService` - Achievement unlock logic
- `PointsService` - Points calculation
- `RewardsService` - Reward tier progression
- `TimeGoalService` - Goal tracking and notifications
- `NotificationService` - Local notification delivery
- `PINService` - PIN hashing and verification
- `EmailService` - Weekly report generation

#### Repositories to Test
- `CoreDataChildRepository` - Child profile persistence
- `CoreDataActivityRepository` - Activity persistence
- `CoreDataCategoryRepository` - Category persistence
- `CoreDataAchievementRepository` - Achievement persistence
- `CoreDataTimeGoalRepository` - Time goal persistence
- `CoreDataPointsRepository` - Points persistence

#### Utilities to Test
- `DateFormatter` extensions
- `TimeInterval` extensions
- `Color` extensions
- Validation helpers
- Calculation utilities

### Integration Tests (20% of test suite)

**Target Coverage:** 80%+ for critical integrations

#### Core Data Integration
- Child profile CRUD with Core Data
- Activity logging with relationships
- Category management with subcategories
- Achievement unlocking with triggers
- Points accumulation and persistence
- Data migration between versions

#### Service Integration
- `TimerService` + `ActivityService` (timer completion logs activity)
- `ActivityService` + `PointsService` (activity awards points)
- `ActivityService` + `AchievementService` (activity unlocks achievements)
- `AchievementService` + `NotificationService` (unlock triggers notification)
- `TimeGoalService` + `NotificationService` (goal exceeded sends reminder)
- `ActivityService` + `EmailService` (weekly report generation)

#### Multi-Child Isolation
- Profile switching clears previous child's data from memory
- Activities are filtered by child ID
- Points and achievements are child-specific
- Categories can be child-specific or shared

#### Background Execution
- Timer continues in background
- Notifications fire when app backgrounded
- Core Data saves on app termination

### UI Tests (10% of test suite)

**Target Coverage:** Critical user journeys only

#### Flow 1: Onboarding (P0)
```
Test ID: UI-001
Priority: P0 (Critical)
Description: Complete first-time onboarding flow
Preconditions: Fresh app install, no data
Steps:
  1. Launch app
  2. Verify welcome screen appears
  3. Tap "Get Started"
  4. Create 4-digit PIN
  5. Confirm PIN
  6. Grant notification permission
  7. Verify landing screen appears
Expected: User completes onboarding and lands on landing screen
```

#### Flow 2: Parent PIN Setup & Child Profile Creation (P0)
```
Test ID: UI-002
Priority: P0 (Critical)
Description: Parent creates first child profile
Preconditions: Onboarding completed, no children
Steps:
  1. Tap "Add Child" from landing screen
  2. Authenticate with PIN
  3. Enter child name "Emma"
  4. Select age: 8
  5. Choose avatar
  6. Choose theme color
  7. Tap "Save"
  8. Verify profile appears in selection list
Expected: Child profile created successfully
```

#### Flow 3: Start Timer and Complete Activity (P0)
```
Test ID: UI-003
Priority: P0 (Critical)
Description: Start timer, let it complete, log activity
Preconditions: Child profile exists and selected
Steps:
  1. Tap "Start Timer" from home
  2. Select "Homework" category
  3. Select 25 minutes duration
  4. Tap play button
  5. Verify timer starts counting down
  6. Fast-forward time to completion
  7. Verify completion notification
  8. Tap "Mark as Complete"
  9. Verify activity logged
Expected: Timer completes and activity is logged
```

#### Flow 4: Quick Log Activity (P0)
```
Test ID: UI-004
Priority: P0 (Critical)
Description: One-tap activity logging
Preconditions: Child profile exists and selected
Steps:
  1. Navigate to Quick Log screen
  2. Tap "Reading" category
  3. Wait 2 seconds
  4. Tap "Physical Activity" category
  5. Navigate to "Today's Activities"
  6. Verify both activities appear
Expected: Activities logged instantly with correct duration
```

#### Flow 5: Manual Activity Entry (P1)
```
Test ID: UI-005
Priority: P1 (High)
Description: Manually enter past activity
Preconditions: Child profile exists and selected
Steps:
  1. Navigate to Activity Log
  2. Tap "Add Activity" (manual entry)
  3. Select "Creative Play" category
  4. Set start time: 2 hours ago
  5. Set end time: 1 hour ago
  6. Add note: "Built LEGO castle"
  7. Select mood: Happy
  8. Tap "Save"
  9. Verify activity appears in history
Expected: Manual activity saved with all details
```

#### Flow 6: Parent Authentication & Category Management (P1)
```
Test ID: UI-006
Priority: P1 (High)
Description: Access parent controls and manage categories
Preconditions: Child profile exists, PIN set
Steps:
  1. Tap settings icon
  2. Verify PIN entry screen appears
  3. Enter correct PIN
  4. Tap "Category Management"
  5. Tap "Add Category"
  6. Enter name: "Music Practice"
  7. Select icon and color
  8. Tap "Save"
  9. Verify category appears in list
  10. Toggle category to inactive
  11. Return to child view
  12. Verify category hidden in quick log
Expected: Parent can manage categories via PIN-protected area
```

#### Flow 7: Profile Switching (P1)
```
Test ID: UI-007
Priority: P1 (High)
Description: Switch between child profiles
Preconditions: Multiple child profiles exist
Steps:
  1. On home screen, tap profile avatar
  2. Verify profile selection screen appears
  3. Tap on different child profile
  4. Verify home screen updates with new child's data
  5. Verify previous child's activities not visible
Expected: Profile switching works with data isolation
```

#### Flow 8: View Statistics & Charts (P2)
```
Test ID: UI-008
Priority: P2 (Medium)
Description: View daily and weekly statistics
Preconditions: Child has logged activities
Steps:
  1. Navigate to Statistics tab
  2. Verify daily pie chart displays
  3. Tap on category slice
  4. Verify drill-down shows details
  5. Switch to weekly view
  6. Verify bar chart shows 7 days
  7. Swipe to previous week
  8. Verify data updates
Expected: Charts display data correctly and interactions work
```

#### Flow 9: Achievement Unlock (P2)
```
Test ID: UI-009
Priority: P2 (Medium)
Description: Unlock achievement and view details
Preconditions: Child is one activity away from unlocking "First Timer"
Steps:
  1. Complete an activity
  2. Verify achievement unlock notification appears
  3. Tap notification
  4. Verify achievement detail screen shows
  5. Verify badge is displayed in color
  6. Navigate to achievements screen
  7. Verify badge appears in unlocked section
Expected: Achievement unlocks and displays correctly
```

#### Flow 10: Pomodoro Timer Cycle (P2)
```
Test ID: UI-010
Priority: P2 (Medium)
Description: Complete full Pomodoro work/break cycle
Preconditions: Child profile exists
Steps:
  1. Tap "Start Timer"
  2. Select "Pomodoro Mode"
  3. Configure: 25min work, 5min break
  4. Start timer
  5. Fast-forward to work completion
  6. Verify break prompt appears
  7. Start break timer
  8. Fast-forward to break completion
  9. Verify session counter shows 1/4
Expected: Pomodoro cycle completes correctly
```

---

## Test Case Inventory

### Unit Test Cases by Module

#### TimerViewModel Tests (18 test cases)
| Test ID | Description | Priority |
|---------|-------------|----------|
| UT-TVM-001 | Start timer sets state to running | P0 |
| UT-TVM-002 | Pause timer sets state to paused | P0 |
| UT-TVM-003 | Resume timer from pause resumes countdown | P0 |
| UT-TVM-004 | Stop timer resets state to idle | P0 |
| UT-TVM-005 | Timer completion triggers notification | P0 |
| UT-TVM-006 | Timer accuracy within 0.1s over 30 minutes | P0 |
| UT-TVM-007 | Background timer continues execution | P0 |
| UT-TVM-008 | Timer state persists across app restart | P1 |
| UT-TVM-009 | Visualization mode changes update UI | P1 |
| UT-TVM-010 | Color zones transition at correct thresholds | P1 |
| UT-TVM-011 | Extend time adds duration correctly | P2 |
| UT-TVM-012 | Multiple timer prevention (only one active) | P1 |
| UT-TVM-013 | Timer with no category selected shows error | P2 |
| UT-TVM-014 | Timer awards points on completion | P1 |
| UT-TVM-015 | Completed activity marked as complete by default | P1 |
| UT-TVM-016 | Timer completion logs activity | P0 |
| UT-TVM-017 | Timer cancellation does not log activity | P1 |
| UT-TVM-018 | Timer during phone call pauses correctly | P2 |

#### ActivityLogViewModel Tests (15 test cases)
| Test ID | Description | Priority |
|---------|-------------|----------|
| UT-ALV-001 | Quick log creates activity with current timestamp | P0 |
| UT-ALV-002 | Quick log calculates duration from previous log | P0 |
| UT-ALV-003 | Manual entry validates end time > start time | P1 |
| UT-ALV-004 | Manual entry detects overlapping activities | P1 |
| UT-ALV-005 | Edit activity updates all fields correctly | P1 |
| UT-ALV-006 | Delete activity removes from database | P0 |
| UT-ALV-007 | Activity duration calculation is accurate | P0 |
| UT-ALV-008 | Activities filtered by child ID | P0 |
| UT-ALV-009 | Activities filtered by date range | P1 |
| UT-ALV-010 | Mood selection saves correctly | P2 |
| UT-ALV-011 | Notes field validates max length (200 chars) | P2 |
| UT-ALV-012 | Rapid successive quick logs handled gracefully | P2 |
| UT-ALV-013 | Activity marked incomplete shows in UI | P1 |
| UT-ALV-014 | Completing activity awards points | P1 |
| UT-ALV-015 | Manual entry marked with indicator | P2 |

#### ParentAuthViewModel Tests (12 test cases)
| Test ID | Description | Priority |
|---------|-------------|----------|
| UT-PAV-001 | Valid 4-digit PIN saves successfully | P0 |
| UT-PAV-002 | PIN verification returns true for correct PIN | P0 |
| UT-PAV-003 | PIN verification returns false for incorrect PIN | P0 |
| UT-PAV-004 | PIN with < 4 digits rejected | P0 |
| UT-PAV-005 | PIN with > 4 digits rejected | P0 |
| UT-PAV-006 | PIN with non-numeric characters rejected | P0 |
| UT-PAV-007 | Biometric authentication falls back to PIN | P1 |
| UT-PAV-008 | Failed authentication increments attempt counter | P1 |
| UT-PAV-009 | 3 failed attempts triggers 30s timeout | P1 |
| UT-PAV-010 | Session timeout after 5 minutes inactivity | P1 |
| UT-PAV-011 | PIN stored in Keychain, not UserDefaults | P0 |
| UT-PAV-012 | PIN reset clears Keychain entry | P1 |

#### PointsService Tests (10 test cases)
| Test ID | Description | Priority |
|---------|-------------|----------|
| UT-PS-001 | Base points awarded for activity completion | P0 |
| UT-PS-002 | Category multiplier applied correctly | P0 |
| UT-PS-003 | Streak bonus added when active | P1 |
| UT-PS-004 | Points accumulate correctly over time | P0 |
| UT-PS-005 | Reward tier upgrade at correct thresholds | P1 |
| UT-PS-006 | Weekly points reset on new week | P1 |
| UT-PS-007 | Incomplete activities award no points | P0 |
| UT-PS-008 | Manually entered activities award points | P1 |
| UT-PS-009 | Points calculation for activities < 5 min | P2 |
| UT-PS-010 | Points leaderboard sorts correctly | P2 |

#### AchievementService Tests (12 test cases)
| Test ID | Description | Priority |
|---------|-------------|----------|
| UT-AS-001 | First timer achievement unlocks on first completion | P1 |
| UT-AS-002 | 3-day streak unlocks after 3 consecutive days | P1 |
| UT-AS-003 | 7-day streak unlocks after 7 consecutive days | P1 |
| UT-AS-004 | Streak breaks when day missed | P1 |
| UT-AS-005 | Homework Hero unlocks at 20 hours | P2 |
| UT-AS-006 | Active Kid unlocks at 30 hours physical | P2 |
| UT-AS-007 | Balanced Week checks no category > 40% | P2 |
| UT-AS-008 | Early Bird unlocks with 5 activities before 10am | P2 |
| UT-AS-009 | Achievement progress tracked incrementally | P1 |
| UT-AS-010 | Achievement unlock triggers notification | P1 |
| UT-AS-011 | Already unlocked achievements don't re-unlock | P1 |
| UT-AS-012 | Achievement data persists across app restarts | P1 |

#### ProfileSelectionViewModel Tests (10 test cases)
| Test ID | Description | Priority |
|---------|-------------|----------|
| UT-PSV-001 | Fetch all profiles returns up to 8 profiles | P0 |
| UT-PSV-002 | Select profile sets active child | P0 |
| UT-PSV-003 | Active profile persists across app restarts | P0 |
| UT-PSV-004 | Profile switching clears previous child's data | P0 |
| UT-PSV-005 | Create profile validates unique name | P2 |
| UT-PSV-006 | Delete profile removes from database | P1 |
| UT-PSV-007 | Cannot delete profile with existing activities | P1 |
| UT-PSV-008 | Edit profile updates all fields | P1 |
| UT-PSV-009 | Age update adjusts UI complexity | P2 |
| UT-PSV-010 | Avatar and theme selection saves correctly | P2 |

#### CategoryService Tests (11 test cases)
| Test ID | Description | Priority |
|---------|-------------|----------|
| UT-CS-001 | Create category with valid data succeeds | P0 |
| UT-CS-002 | Create subcategory with parent ID succeeds | P1 |
| UT-CS-003 | Update category name and color succeeds | P1 |
| UT-CS-004 | Delete category removes from database | P1 |
| UT-CS-005 | Hide category sets isActive to false | P1 |
| UT-CS-006 | Inactive categories hidden in child view | P1 |
| UT-CS-007 | System categories cannot be deleted | P1 |
| UT-CS-008 | Category sort order persists | P2 |
| UT-CS-009 | Fetch active categories filters correctly | P0 |
| UT-CS-010 | Default categories created on first launch | P0 |
| UT-CS-011 | Category color validation (hex format) | P2 |

#### TimeGoalService Tests (8 test cases)
| Test ID | Description | Priority |
|---------|-------------|----------|
| UT-TGS-001 | Set time goal for category succeeds | P1 |
| UT-TGS-002 | Goal exceeded triggers notification | P1 |
| UT-TGS-003 | Goal status calculates correctly (Green/Yellow/Red) | P1 |
| UT-TGS-004 | Age-based default goals applied | P1 |
| UT-TGS-005 | Update goal threshold updates status | P2 |
| UT-TGS-006 | Delete goal removes from database | P2 |
| UT-TGS-007 | Goal progress calculated from today's activities | P1 |
| UT-TGS-008 | Goals reset daily at midnight | P1 |

#### EmailService Tests (6 test cases)
| Test ID | Description | Priority |
|---------|-------------|----------|
| UT-ES-001 | Generate weekly report with activity summary | P1 |
| UT-ES-002 | Email includes points and achievements | P1 |
| UT-ES-003 | Email includes charts (base64 encoded) | P2 |
| UT-ES-004 | Email sent to configured parent email | P1 |
| UT-ES-005 | Email generation fails gracefully if no data | P2 |
| UT-ES-006 | Weekly email scheduled for Sunday 6pm | P1 |

### Integration Test Cases

#### Core Data Integration (8 test cases)
| Test ID | Description | Priority |
|---------|-------------|----------|
| IT-CD-001 | Child profile CRUD operations persist correctly | P0 |
| IT-CD-002 | Activity with category relationship saves | P0 |
| IT-CD-003 | Deleting category cascades to activities | P1 |
| IT-CD-004 | Achievement unlock persists with unlock date | P1 |
| IT-CD-005 | Points accumulation persists across sessions | P0 |
| IT-CD-006 | Fetch activities with predicates filters correctly | P1 |
| IT-CD-007 | Core Data migration from v1 to v2 succeeds | P1 |
| IT-CD-008 | Concurrent writes handled without corruption | P1 |

#### Service Integration (12 test cases)
| Test ID | Description | Priority |
|---------|-------------|----------|
| IT-SI-001 | Timer completion logs activity | P0 |
| IT-SI-002 | Activity completion awards points | P0 |
| IT-SI-003 | Activity triggers achievement unlock | P1 |
| IT-SI-004 | Achievement unlock triggers notification | P1 |
| IT-SI-005 | Goal exceeded sends notification | P1 |
| IT-SI-006 | Weekly report generation includes all data | P1 |
| IT-SI-007 | Profile switch loads correct child's data | P0 |
| IT-SI-008 | Category hide/show updates quick log UI | P1 |
| IT-SI-009 | Points calculation includes streak bonus | P1 |
| IT-SI-010 | Reward tier upgrade updates profile | P1 |
| IT-SI-011 | Background timer completion sends notification | P0 |
| IT-SI-012 | App termination saves all pending changes | P0 |

#### Multi-Child Isolation (6 test cases)
| Test ID | Description | Priority |
|---------|-------------|----------|
| IT-MC-001 | Activities filtered by active child ID | P0 |
| IT-MC-002 | Points isolated per child | P0 |
| IT-MC-003 | Achievements isolated per child | P0 |
| IT-MC-004 | Profile switch clears previous data from memory | P0 |
| IT-MC-005 | Statistics show only active child's data | P0 |
| IT-MC-006 | Email reports per-child summaries | P1 |

---

## Test Environment

### Simulators (CI/CD)
- **iPhone SE (3rd gen)** - Smallest screen, iOS 16.0 (minimum supported)
- **iPhone 14** - Standard size, iOS 17.x (current)
- **iPhone 15 Pro Max** - Largest screen, iOS 17.x (current)
- **iPad (9th gen)** - Tablet, iPadOS 16.0
- **iPad Pro 12.9"** - Large tablet, iPadOS 17.x

### Real Devices (Manual Testing)
- iPhone 12 - iOS 17.x
- iPhone 14 Pro - iOS 17.x
- iPad Air (5th gen) - iPadOS 17.x

### Test Data
- **Fresh Install**: No data, first-time onboarding
- **Single Child**: 1 profile, 50 activities, 2 achievements
- **Multi-Child**: 3 profiles, 200+ activities total, various achievements
- **Max Capacity**: 8 profiles, 1000+ activities, all achievements unlocked
- **Edge Cases**: Overlapping activities, very long durations, DST changes

### Network Conditions (for CloudKit testing - v1.5+)
- Online (fast Wi-Fi)
- Online (slow 3G)
- Offline
- Intermittent connectivity

---

## Tools & Framework

### Primary Framework: XCUITest
**Rationale:**
- Native iOS testing framework from Apple
- Best integration with Xcode and Xcode Cloud
- No third-party dependencies
- Fast execution on simulators
- Excellent support for accessibility testing
- Built-in support for UI element queries

**Alternatives Considered:**
- **Appium**: More flexible but adds complexity and overhead
- **Detox**: React Native focused, not ideal for native Swift
- **EarlGrey**: Google's framework, less community support than XCUITest

### Unit Testing: XCTest
- Standard Swift testing framework
- Async/await support for modern Swift
- Performance measurement with `measure` blocks
- Test data builders pattern for maintainability

### Mocking: Protocol-Based Dependency Injection
- Custom mock implementations for repositories and services
- Shared mocks in `FocusPalTests/Helpers/SharedMocks.swift`
- Test data factories in `FocusPalTests/Helpers/TestData.swift`

### Code Coverage: Xcode Code Coverage
- Integrated in Xcode
- Per-file and per-function coverage reports
- Minimum threshold enforcement in CI

### Performance Testing: XCTest Performance
- `measure` blocks for timing tests
- Baseline comparison for regression detection
- Instruments for deep profiling

### Accessibility Testing: XCTest Accessibility APIs
- `accessibilityLabel` verification
- VoiceOver navigation testing
- Dynamic Type scaling tests
- Contrast ratio validation

### CI/CD: GitHub Actions + Fastlane
- Automated test execution on pull requests
- Parallel test execution across simulators
- Test result reporting and trending
- Coverage reporting with Codecov

---

## CI/CD Integration

### GitHub Actions Workflow

#### On Pull Request
1. Run unit tests on iPhone 14 simulator (< 1 minute)
2. Run integration tests on iPhone 14 simulator (< 1 minute)
3. Check code coverage (must be >= 80%)
4. Run SwiftLint (0 errors)
5. Build app for simulator (< 2 minutes)

#### On Merge to Main
1. Run full test suite on all simulators (< 5 minutes)
   - iPhone SE (3rd gen) - iOS 16.0
   - iPhone 14 - iOS 17.x
   - iPad (9th gen) - iPadOS 16.0
2. Run UI tests on critical paths (< 3 minutes)
3. Generate code coverage report
4. Upload coverage to Codecov
5. Build release candidate
6. Upload to TestFlight (internal)

#### Nightly
1. Run all tests including edge cases
2. Run performance benchmarks
3. Run accessibility audit
4. Generate test report dashboard
5. Run security scans (SAST)

### Test Execution Time Budgets
- **Unit Tests**: < 5 seconds (target: 2 seconds)
- **Integration Tests**: < 30 seconds (target: 15 seconds)
- **UI Tests**: < 3 minutes (target: 2 minutes)
- **Full Suite**: < 5 minutes (target: 3 minutes)

### Failure Handling
- **Flaky Test Policy**: Zero tolerance - investigate and fix immediately
- **Build Breakers**: P0 and P1 test failures block merge
- **P2/P3 Failures**: Create issues but don't block (fix within 2 sprints)
- **Coverage Drops**: Any PR reducing coverage below threshold is blocked

### Test Result Reporting
- **JUnit XML** format for GitHub Actions
- **HTML Reports** generated with XCResultFormatter
- **Slack Notifications** for test failures on main branch
- **Trending Dashboard** showing coverage and pass rate over time

---

## Quality Metrics

### Code Coverage Targets
| Component | Minimum | Target |
|-----------|---------|--------|
| ViewModels | 85% | 90% |
| Services | 80% | 85% |
| Repositories | 75% | 80% |
| Utilities | 75% | 80% |
| Overall | 80% | 85% |

### Test Health Metrics
- **Pass Rate**: >= 99% (on main branch)
- **Flaky Test Rate**: 0% (target: 0%, max: 0%)
- **Test Execution Time**: Trending down (< 5 min full suite)
- **Code Coverage**: Trending up (target: 85%+)
- **Bug Escape Rate**: < 5% (bugs found in production vs. found in testing)

### Performance Benchmarks
| Operation | Baseline | Target | Max |
|-----------|----------|--------|-----|
| Timer Accuracy (30 min) | ±0.05s | ±0.1s | ±0.2s |
| Daily Chart Render | 200ms | 300ms | 500ms |
| Activity Log (100 items) | 50ms | 100ms | 200ms |
| Profile Switch | 100ms | 200ms | 500ms |
| Core Data Save | 20ms | 50ms | 100ms |
| App Cold Launch | 1.5s | 2.0s | 3.0s |

### Accessibility Compliance
- **VoiceOver Coverage**: 100% of screens
- **Dynamic Type**: Tested at 5 sizes (XS, S, M, L, XXXL)
- **Color Contrast**: All text meets WCAG AA (4.5:1)
- **Touch Targets**: 100% meet 44x44pt minimum

---

## Risk Assessment

### High Risk Areas (Require Extra Testing)

#### 1. Timer Accuracy (Risk: HIGH, Impact: CRITICAL)
**Risk:** Timer drift over long durations could frustrate users and lose trust.
**Mitigation:**
- Unit tests verify accuracy within ±0.1s over 30 minutes
- Performance tests measure drift over 1 hour, 2 hours
- Background timer tests ensure accuracy when app backgrounded
- Real device testing to catch simulator vs. device differences

#### 2. Data Persistence (Risk: MEDIUM, Impact: CRITICAL)
**Risk:** Core Data corruption or data loss would destroy user trust.
**Mitigation:**
- Integration tests cover all CRUD operations
- Concurrent write tests prevent race conditions
- App termination tests ensure saves complete
- Core Data lightweight migration tests for version upgrades
- Daily backups to iCloud (future)

#### 3. Parent Authentication Bypass (Risk: MEDIUM, Impact: HIGH)
**Risk:** Children could access parent controls or modify settings.
**Mitigation:**
- Unit tests verify PIN validation logic
- UI tests attempt to access parent area without PIN
- Security tests attempt common bypass techniques (back button, task switcher)
- Keychain storage verified (never UserDefaults)
- Session timeout enforced

#### 4. Multi-Child Data Isolation (Risk: MEDIUM, Impact: HIGH)
**Risk:** One child could see another child's data (privacy violation).
**Mitigation:**
- Integration tests verify data filtering by child ID
- Profile switch tests clear previous child's data from memory
- Statistics tests verify only active child's data shown
- Edge case tests for rapid profile switching

#### 5. Points Calculation Accuracy (Risk: LOW, Impact: MEDIUM)
**Risk:** Incorrect points could demotivate or frustrate children.
**Mitigation:**
- Unit tests for all point calculation scenarios
- Integration tests verify points persist correctly
- Edge case tests (very short activities, very long activities)
- Manual spot checks during exploratory testing

#### 6. Achievement Unlock Logic (Risk: LOW, Impact: MEDIUM)
**Risk:** Achievements not unlocking could reduce engagement.
**Mitigation:**
- Unit tests for each achievement unlock condition
- Integration tests verify achievement persistence
- Notification tests ensure unlock alerts appear
- Edge case tests (unlock during profile switch, app backgrounded)

### Medium Risk Areas (Standard Testing)
- Category management (CRUD operations well-tested)
- Activity editing (validation catches most issues)
- Statistics rendering (visual bugs caught in manual testing)
- Onboarding flow (UI tests cover happy path)

### Low Risk Areas (Basic Testing)
- Profile avatar selection (simple UI, low complexity)
- Theme color selection (visual preference, no logic)
- Settings persistence (standard UserDefaults usage)

---

## Test Maintenance Strategy

### Test Code Quality Standards
- Tests follow same code quality standards as production code
- Tests are reviewed in pull requests
- Tests use descriptive names following Given-When-Then pattern
- Tests are DRY (shared test utilities, data builders)
- Tests are independent and can run in any order
- Tests clean up after themselves (no state leakage)

### Test Data Management
- Use in-memory Core Data stack for tests
- Test data builders for creating mock objects
- Shared fixtures for common scenarios
- No hardcoded test data (use factories)

### Flaky Test Prevention
- No sleeps or arbitrary waits (use XCTest expectations)
- No dependencies on external services in unit tests
- Mock all network requests
- Mock all time-dependent behavior
- Deterministic random number generation when needed

### Test Documentation
- Each test has a clear description
- Complex test logic includes comments
- Test plan document updated with new features
- Test coverage gaps documented and prioritized

---

## Acceptance Criteria for Release

### Must Pass Before Release
- [ ] All P0 tests passing (100%)
- [ ] All P1 tests passing (>= 99%)
- [ ] Code coverage >= 80% overall
- [ ] ViewModels coverage >= 85%
- [ ] Services coverage >= 80%
- [ ] No SwiftLint errors
- [ ] No compiler warnings
- [ ] All critical user flows tested manually
- [ ] Accessibility audit completed
- [ ] Performance benchmarks met

### Nice to Have Before Release
- [ ] All P2 tests passing (>= 95%)
- [ ] All P3 tests passing (>= 90%)
- [ ] Code coverage >= 85% overall
- [ ] UI tests for all edge cases
- [ ] Localization testing (future)
- [ ] Real device testing on all models

---

## Appendix

### Test Naming Convention
```
test_<methodName>_<condition>_<expectedResult>

Examples:
- test_startTimer_whenCalled_startsTimerService
- test_validatePIN_withInvalidLength_returnsFalse
- test_saveActivity_whenRepositoryThrows_handlesError
```

### Test Structure (Given-When-Then)
```swift
func test_example() async {
    // Given: Set up preconditions
    let sut = SystemUnderTest(dependency: mockDependency)

    // When: Execute the action
    let result = await sut.performAction()

    // Then: Verify the outcome
    XCTAssertEqual(result, expectedValue)
}
```

### Mock Object Guidelines
- Mocks track method calls and parameters
- Mocks provide configurable return values
- Mocks can simulate errors
- Mocks reset between tests
- Shared mocks live in `SharedMocks.swift`

### Page Object Pattern for UI Tests
```swift
class TimerScreen {
    let app: XCUIApplication

    var playButton: XCUIElement { app.buttons["Play"] }
    var pauseButton: XCUIElement { app.buttons["Pause"] }
    var timerDisplay: XCUIElement { app.staticTexts["TimerDisplay"] }

    func startTimer() {
        playButton.tap()
    }

    func waitForTimerToStart() -> Bool {
        timerDisplay.waitForExistence(timeout: 2)
    }
}
```

---

**End of Test Plan**
