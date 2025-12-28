# Weekly Email Notification Service

## Overview

The Weekly Email Notification Service provides automated weekly activity summaries for parents about their children's progress in FocusPal. The service generates beautifully formatted HTML emails containing detailed statistics, achievements, and insights.

## Architecture

### Components

#### 1. **WeeklySummary** (Model)
**Location:** `/Users/srinivasgurana/self/claude/focuspal/FocusPal/Core/Models/WeeklySummary.swift`

A data model representing aggregated weekly activity data for a child.

**Properties:**
- `childName: String` - Name of the child
- `weekStartDate: Date` - Start of the week
- `weekEndDate: Date` - End of the week
- `totalActivities: Int` - Total number of activities
- `completedActivities: Int` - Number of completed activities
- `incompleteActivities: Int` - Number of incomplete activities
- `totalMinutes: Int` - Total minutes spent on activities
- `pointsEarned: Int` - Points earned this week
- `pointsDeducted: Int` - Points deducted this week
- `netPoints: Int` - Net points (earned + bonus - deducted)
- `currentTier: RewardTier?` - Current reward tier
- `topCategories: [(categoryName: String, minutes: Int)]` - Top 3 categories by time
- `achievementsUnlocked: Int` - Number of achievements unlocked this week
- `streak: Int` - Current consecutive weeks streak

**Computed Properties:**
- `completionRate: Double` - Percentage of completed activities (0-100)
- `totalHours: Double` - Total time in hours
- `averageMinutesPerActivity: Int` - Average duration per activity
- `hasEarnedTier: Bool` - Whether any tier was earned

#### 2. **WeeklySummaryService**
**Location:** `/Users/srinivasgurana/self/claude/focuspal/FocusPal/Core/Services/Implementation/WeeklySummaryService.swift`

Generates weekly summary data by aggregating information from multiple repositories.

**Methods:**
```swift
func generateSummary(for childId: UUID, weekStartDate: Date) async throws -> WeeklySummary
func generateSummariesForAllChildren() async throws -> [WeeklySummary]
```

**Dependencies:**
- `ActivityRepositoryProtocol` - Fetches activity data
- `ChildRepositoryProtocol` - Fetches child information
- `CategoryRepositoryProtocol` - Fetches category data
- `PointsRepositoryProtocol` - Fetches points data
- `RewardsRepositoryProtocol` - Fetches tier/reward data
- `AchievementRepositoryProtocol` - Fetches achievement data

**Logic:**
1. Fetches all activities for the specified week
2. Calculates total/completed/incomplete counts
3. Sums up total minutes and points
4. Determines current tier from weekly reward
5. Identifies top 3 categories by time spent
6. Counts achievements unlocked during the week
7. Calculates consecutive week streak

#### 3. **EmailContentBuilder**
**Location:** `/Users/srinivasgurana/self/claude/focuspal/FocusPal/Core/Services/Implementation/EmailContentBuilder.swift`

Builds beautifully formatted HTML email content from weekly summaries.

**Methods:**
```swift
func buildEmailSubject(childName: String, weekEndDate: Date) -> String
func buildEmailBody(summaries: [WeeklySummary]) -> String
```

**Email Features:**
- Responsive HTML design that works on mobile
- Kid-friendly colors and styling
- Summary cards for each child
- Stats grid showing key metrics
- Tier badges with emoji
- Top categories ranking with medals
- Completion rate progress bar
- Highlights section for streaks and achievements
- Professional gradient header

**Styling:**
- CSS Grid layout for responsive stats
- Linear gradient header (#667eea to #764ba2)
- Color-coded tier badges (Bronze, Silver, Gold, Platinum)
- Medal emoji for top categories (🥇 🥈 🥉)
- Mobile-responsive design with media queries

#### 4. **EmailService**
**Location:** `/Users/srinivasgurana/self/claude/focuspal/FocusPal/Core/Services/Implementation/EmailService.swift`

Handles email preparation and sending via iOS mailto: URL scheme.

**Protocol:**
```swift
protocol EmailServiceProtocol {
    func prepareEmail(to: String, subject: String, body: String) throws -> URL
    func canSendEmail() -> Bool
    func sendEmail(to: String, subject: String, body: String) async throws
}
```

**Implementation Details:**
- Uses `mailto:` URL scheme to open system mail app
- Validates email addresses with regex
- Supports multiple recipients (comma-separated)
- Properly encodes subject and body in URL
- Opens mail app via `UIApplication.shared.open()`

**Limitations:**
- Requires user interaction to actually send (iOS restriction)
- Email body is pre-filled but user can edit before sending
- Cannot send emails silently in background

#### 5. **WeeklyEmailScheduler**
**Location:** `/Users/srinivasgurana/self/claude/focuspal/FocusPal/Core/Services/Implementation/WeeklyEmailScheduler.swift`

Manages scheduling and triggering of weekly email notifications.

**Methods:**
```swift
func scheduleWeeklyEmail() async throws
func sendWeeklyEmailNow() async throws
func checkAndSendIfDue() async
func shouldSendEmail(preferences: ParentNotificationPreferences) -> Bool
func getLastSentDate() -> Date?
func setLastSentDate(_ date: Date)
```

**Scheduling Logic:**
1. Reads parent notification preferences
2. Creates `UNCalendarNotificationTrigger` for specified day/time
3. Schedules local notification to remind user
4. Tracks last sent date in UserDefaults
5. Prevents duplicate sends on same day

**Configuration (from Parent model):**
- `weeklyEmailEnabled: Bool` - Enable/disable weekly emails
- `weeklyEmailDay: Int` - Day of week (1=Sunday, 2=Monday, ..., 7=Saturday)
- `weeklyEmailTime: Int` - Hour of day (0-23 in 24-hour format)

## Test Coverage

All components have comprehensive test coverage following TDD principles:

### WeeklySummaryServiceTests
**Location:** `/Users/srinivasgurana/self/claude/focuspal/FocusPalTests/Services/WeeklySummaryServiceTests.swift`

**Test Cases:**
- ✓ Generates empty summary when no activities exist
- ✓ Calculates activity totals correctly
- ✓ Sums points (earned, deducted, bonus) accurately
- ✓ Includes current reward tier
- ✓ Returns top 3 categories sorted by minutes
- ✓ Counts achievements unlocked within the week
- ✓ Calculates consecutive week streaks
- ✓ Generates summaries for all children
- ✓ Handles edge cases (incomplete activities, multiple categories)
- ✓ Throws error when child not found

### EmailContentBuilderTests
**Location:** `/Users/srinivasgurana/self/claude/focuspal/FocusPalTests/Services/EmailContentBuilderTests.swift`

**Test Cases:**
- ✓ Builds subject line with child name and date
- ✓ Generates valid HTML structure
- ✓ Includes all child data in email body
- ✓ Displays multiple children's summaries
- ✓ Shows zero stats when no activities
- ✓ Highlights high tier achievements
- ✓ Lists top categories in order
- ✓ Displays streak information
- ✓ Handles empty summary array gracefully

### EmailServiceTests
**Location:** `/Users/srinivasgurana/self/claude/focuspal/FocusPalTests/Services/EmailServiceTests.swift`

**Test Cases:**
- ✓ Returns true for canSendEmail()
- ✓ Creates valid mailto: URL
- ✓ Encodes special characters correctly
- ✓ Throws error for empty/invalid email
- ✓ Handles HTML email bodies
- ✓ Supports long email content
- ✓ Accepts comma-separated recipients

### WeeklyEmailSchedulerTests
**Location:** `/Users/srinivasgurana/self/claude/focuspal/FocusPalTests/Services/WeeklyEmailSchedulerTests.swift`

**Test Cases:**
- ✓ Sends email when enabled
- ✓ Skips sending when disabled
- ✓ Includes all children in one email
- ✓ Handles empty summaries gracefully
- ✓ Persists last sent date
- ✓ Prevents duplicate sends

## Usage

### Basic Setup

```swift
// Initialize dependencies
let summaryService = WeeklySummaryService(
    activityRepository: activityRepository,
    childRepository: childRepository,
    categoryRepository: categoryRepository,
    pointsRepository: pointsRepository,
    rewardsRepository: rewardsRepository,
    achievementRepository: achievementRepository
)

let contentBuilder = EmailContentBuilder()
let emailService = EmailService()

let scheduler = WeeklyEmailScheduler(
    summaryService: summaryService,
    contentBuilder: contentBuilder,
    emailService: emailService,
    parentRepository: parentRepository
)
```

### Send Email Immediately

```swift
Task {
    try await scheduler.sendWeeklyEmailNow()
}
```

### Schedule Weekly Notifications

```swift
Task {
    try await scheduler.scheduleWeeklyEmail()
}
```

### Check and Send on App Launch

```swift
// In AppDelegate or App initialization
Task {
    await scheduler.checkAndSendIfDue()
}
```

### Generate Summary for Specific Child

```swift
let weekStart = Calendar.current.startOfDay(for: Date())
let summary = try await summaryService.generateSummary(
    for: childId,
    weekStartDate: weekStart
)

print("\\(summary.childName) completed \\(summary.completedActivities) activities this week!")
```

## Integration with ServiceContainer

Add to `ServiceContainer.swift`:

```swift
class ServiceContainer {
    // ... existing properties ...

    private var weeklySummaryService: WeeklySummaryService!
    private var emailContentBuilder: EmailContentBuilder!
    private var emailService: EmailService!
    private var weeklyEmailScheduler: WeeklyEmailScheduler!

    func setupServices() {
        // ... existing setup ...

        // Weekly Email Services
        weeklySummaryService = WeeklySummaryService(
            activityRepository: activityRepository,
            childRepository: childRepository,
            categoryRepository: categoryRepository,
            pointsRepository: pointsRepository,
            rewardsRepository: rewardsRepository,
            achievementRepository: achievementRepository
        )

        emailContentBuilder = EmailContentBuilder()
        emailService = EmailService()

        weeklyEmailScheduler = WeeklyEmailScheduler(
            summaryService: weeklySummaryService,
            contentBuilder: emailContentBuilder,
            emailService: emailService,
            parentRepository: parentRepository
        )
    }

    func onAppLaunch() async {
        // ... existing code ...

        // Check and send weekly email if due
        await weeklyEmailScheduler.checkAndSendIfDue()
    }
}
```

## Email Sample Output

The generated HTML email includes:

```
┌─────────────────────────────────────────┐
│     📊 FocusPal Weekly Summary          │
│   (Beautiful gradient header)           │
└─────────────────────────────────────────┘

Hello! Here's your weekly activity summary for your amazing kids.

┌─────────────────────────────────────────┐
│ Emma                                    │
│ Dec 20, 2024 - Dec 27, 2024            │
│                                         │
│ 🥈 Silver Tier Achieved!                │
│                                         │
│ Total Activities: 15  Completed: 12     │
│ Total Time: 7.5 hr    Points: 105       │
│                                         │
│ 🎉 Highlights:                          │
│ 🔥 3 week streak!                       │
│ 🏆 2 new achievements unlocked!         │
│                                         │
│ 📚 Top Categories:                      │
│ 🥇 Homework - 3.0 hr                    │
│ 🥈 Reading - 2.5 hr                     │
│ 🥉 Sports - 2.0 hr                      │
│                                         │
│ Completion Rate: 80% [████████░░]       │
└─────────────────────────────────────────┘

Keep up the great work! 🌟
```

## Parent Notification Preferences

Parents can configure weekly emails through the Parent model:

```swift
var parent = Parent(
    name: "Jane Doe",
    email: "jane@example.com"
)

// Configure weekly email
parent.notificationPreferences.weeklyEmailEnabled = true
parent.notificationPreferences.weeklyEmailDay = 1  // Sunday
parent.notificationPreferences.weeklyEmailTime = 9 // 9 AM
```

## Future Enhancements

Potential improvements:

1. **Email Templates** - Multiple email design templates
2. **PDF Attachment** - Generate PDF report attachment
3. **Charts/Graphs** - Visual charts for trends
4. **Comparison View** - Week-over-week comparisons
5. **Customization** - Parent-configurable email sections
6. **Email History** - Archive of sent emails
7. **Silent Sending** - Server-side email delivery (requires backend)
8. **Multi-Language** - Localized email content

## Dependencies

- Foundation
- UIKit (for mailto: URL handling)
- UserNotifications (for scheduling)
- All FocusPal core models and repositories

## Error Handling

The service handles various error conditions:

- `WeeklySummaryServiceError.childNotFound` - Child ID doesn't exist
- `EmailServiceError.invalidEmail` - Invalid email address format
- `EmailServiceError.cannotCreateMailtoURL` - URL creation failed
- `EmailServiceError.cannotOpenMailApp` - Cannot open mail application

## Performance Considerations

- Summaries are generated on-demand, not cached
- All database queries are async/await
- HTML email body is built in memory
- No network calls (uses local mailto: scheme)

## Privacy & Security

- No email data is transmitted to external servers
- Uses system mail app for actual sending
- Parent can review/edit email before sending
- Last sent date stored locally in UserDefaults

## Testing

Run tests:

```bash
# Run all Weekly Email Service tests
xcodebuild test -scheme FocusPal -destination 'platform=iOS Simulator,name=iPhone 15'

# Or in Xcode: Cmd+U
```

All tests follow the Red-Green-Refactor TDD cycle.

## License

Part of the FocusPal application.

---

**Created with Test-Driven Development (TDD)**
All components have comprehensive test coverage following best practices.
