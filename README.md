# FocusPal

A family-focused iOS app designed to help children develop healthy time management habits through engaging timer experiences and visual progress tracking.

## Overview

FocusPal is an ADHD-friendly screen time and activity tracker built specifically for families with multiple children. It features intuitive timer visualizations inspired by the Time Timer concept, making abstract time concepts tangible for children of all ages.

Parents can set up profiles for each child, configure activity categories with time goals, and monitor progress through detailed statistics—all protected by a simple PIN system.

## Features

### Multi-Child Support
- Create profiles for each family member with custom avatars and theme colors
- Independent activity tracking per child
- Concurrent timers—each child can have their own running timer
- Switch between profiles seamlessly from the landing page

### Timer Visualizations
- **Circular Timer**: ADHD-friendly Time Timer style with disappearing color wedge
- **Bar Timer**: Simple horizontal progress bar
- **Analog Timer**: Traditional clock-style display
- Audio callouts at key intervals (10 minutes, 1 minute remaining)
- Pause, resume, and add time functionality

### Activity Tracking
- Automatic activity logging when timers complete
- Manual entry option with time picker
- Mood tracking with emoji scale
- Notes support for context
- Category-based organization

### Time Goals
- Set recommended daily time per category
- Warning notifications at 80% threshold
- Visual progress indicators
- Balance scoring to encourage variety

### Achievements System
Eight unlockable achievements to motivate consistency:
- **First Timer**: Complete your first activity
- **3-Day Streak**: Activity 3 days in a row
- **Week Warrior**: 7-day streak
- **Monthly Master**: 30-day streak
- **Homework Hero**: 10 hours of homework
- **Reading Champion**: 20 hours of reading
- **Balance Master**: 7 balanced days
- **Early Bird**: Activity before 8 AM

### Statistics & Analytics
- Weekly summaries with total time and active days
- Category breakdown with pie charts
- Daily activity timeline
- Balance meter visualization
- Historical comparisons

### Parent Controls
- PIN-protected access to settings
- Category management (create, edit, toggle)
- Time goal configuration
- Progress reports per child
- PIN change functionality

### Smart Notifications
- Timer completion alerts
- 5-minute and 1-minute warnings
- Time goal threshold notifications
- Streak celebrations and reminders
- Daily goal reminders

## Benefits

### For Children
- **Visual Time Understanding**: See time pass with intuitive circular display
- **Achievement Motivation**: Unlock badges for consistent behavior
- **Independence**: Start and manage their own activity timers
- **Positive Reinforcement**: Celebrate streaks and milestones

### For Parents
- **Multi-Child Management**: One app for the whole family
- **Insight & Reports**: Understand how children spend their time
- **Goal Setting**: Encourage balance across activities
- **Low Friction**: Quick setup, minimal ongoing maintenance

### For Families with ADHD
- **Time Timer Style**: Research-backed visual countdown
- **Audio Callouts**: Gentle time warnings
- **Category Colors**: Visual organization
- **Simple Interface**: Reduced cognitive load

## Architecture

FocusPal follows clean architecture principles with clear separation of concerns.

### Pattern Overview

```
┌─────────────────────────────────────────────────────────┐
│                        Views                            │
│              (SwiftUI Declarative UI)                   │
└─────────────────────────┬───────────────────────────────┘
                          │ @StateObject / @ObservedObject
┌─────────────────────────▼───────────────────────────────┐
│                    ViewModels                           │
│         (Business Logic, @Published State)              │
└─────────────────────────┬───────────────────────────────┘
                          │ Protocol-based injection
┌─────────────────────────▼───────────────────────────────┐
│                     Services                            │
│    (TimerService, ActivityService, Analytics, etc.)     │
└─────────────────────────┬───────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│                   Repositories                          │
│         (CoreData implementations + Mappers)            │
└─────────────────────────┬───────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│                     Core Data                           │
│              (Entities, Persistence)                    │
└─────────────────────────────────────────────────────────┘
```

### Key Patterns

| Pattern | Implementation |
|---------|----------------|
| **MVVM** | ViewModels with @Published properties observed by SwiftUI Views |
| **Dependency Injection** | ServiceContainer provides all services via lazy singletons |
| **Repository** | Protocol-based data access with CoreData implementations |
| **Coordinator** | AppCoordinator manages navigation between onboarding and main app |

### Core Services

| Service | Responsibility |
|---------|----------------|
| `MultiChildTimerManager` | Concurrent timers per child with persistence |
| `ActivityService` | Log and fetch activities |
| `CategoryService` | Manage activity categories |
| `AchievementService` | Track progress and unlock achievements |
| `TimeGoalService` | Monitor daily time usage against goals |
| `AnalyticsService` | Generate statistics and balance scores |
| `NotificationService` | Schedule all local notifications |

### Data Models

| Model | Purpose |
|-------|---------|
| `Child` | User profile with preferences |
| `Category` | Activity type (Homework, Reading, etc.) |
| `Activity` | Logged time entries |
| `TimeGoal` | Daily time targets per category |
| `Achievement` | Unlockable badges with progress |
| `ChildTimerState` | Persisted timer state for recovery |

## Project Structure

```
FocusPal/
├── App/
│   ├── FocusPalApp.swift          # Main entry point
│   ├── AppCoordinator.swift       # Navigation coordination
│   ├── ContentView.swift          # Root view with tab navigation
│   ├── ServiceContainer.swift     # Dependency injection container
│   └── Persistence.swift          # CoreData stack setup
│
├── Core/
│   ├── Models/                    # Domain models (Child, Activity, etc.)
│   ├── Services/
│   │   ├── Protocols/             # Service interfaces
│   │   ├── Implementation/        # Production implementations
│   │   └── Mock/                  # Test doubles
│   ├── Persistence/
│   │   ├── Repositories/          # Data access layer
│   │   └── Mappers/               # Entity ↔ Model conversion
│   └── Utilities/                 # Extensions, helpers, constants
│
├── Features/
│   ├── Timer/                     # Timer screen & visualizations
│   ├── Home/                      # Dashboard with quick stats
│   ├── Statistics/                # Charts & achievements
│   ├── ActivityLog/               # Manual logging UI
│   ├── ParentControls/            # Settings & category management
│   ├── Onboarding/                # Setup flow
│   ├── Landing/                   # Profile selection
│   └── ProfileSelection/          # Child switcher
│
├── DesignSystem/
│   ├── Tokens/                    # Colors, typography, spacing
│   └── Components/                # Reusable UI components
│
├── Resources/
│   ├── Assets.xcassets            # Images and colors
│   └── FocusPal.xcdatamodeld      # CoreData model
│
└── FocusPalTests/                 # Unit and integration tests
```

## Getting Started

### Requirements
- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/focuspal.git
   cd focuspal
   ```

2. Open the project in Xcode:
   ```bash
   open FocusPal.xcodeproj
   ```

3. Build and run on simulator or device (⌘R)

### First Launch

1. **Welcome Screen**: Tap "Get Started"
2. **PIN Setup**: Create a 4-digit parent PIN
3. **Permissions**: Allow notifications for timer alerts
4. **Add Child**: Create your first child profile
5. **Start Timer**: Select a category and begin!

## Usage

### Starting a Timer

1. Select a child profile from the landing page
2. Navigate to the Timer tab
3. Choose an activity category (Homework, Reading, etc.)
4. Tap "Start" to begin the countdown
5. Use pause/resume as needed
6. Activity is automatically logged on completion

### Adding Time Goals

1. Tap the lock icon to access Parent Controls
2. Enter your PIN
3. Select "Time Goals"
4. Set recommended minutes per category
5. Save changes

### Viewing Statistics

1. Navigate to the Statistics tab
2. View weekly summary at the top
3. Scroll to see category breakdown
4. Check achievements progress
5. Monitor balance score

### Managing Categories

1. Access Parent Controls with PIN
2. Select "Categories"
3. Toggle categories on/off
4. Create custom categories with icon and color
5. Set recommended duration per category

## Technical Highlights

### Timer Persistence
Timers survive app termination. State is saved to UserDefaults and restored on launch, ensuring children don't lose progress if the app closes unexpectedly.

### Deterministic UUIDs
Categories use hash-based UUIDs derived from `childId + categoryName`, ensuring data consistency across sessions and potential future sync scenarios.

### ADHD-Friendly Design
The circular timer visualization is inspired by research showing that visual time representation helps individuals with ADHD better understand time passage.

### Multi-Child Isolation
Each child's data is strictly isolated. Categories, activities, achievements, and time goals are all filtered by `childId` to prevent any cross-contamination.

## Testing

Run the test suite:
```bash
xcodebuild test -project FocusPal.xcodeproj -scheme FocusPal -destination 'platform=iOS Simulator,name=iPhone 17'
```

The project includes:
- Unit tests for ViewModels
- Repository tests with in-memory CoreData
- Service tests with mock dependencies
- Model tests for business logic

## License

This project is proprietary software. All rights reserved.

## Acknowledgments

- Time Timer concept for visual time management inspiration
- SF Symbols for iconography
- SwiftUI and Combine frameworks
