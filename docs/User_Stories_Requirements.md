# FocusPal - User Stories & Requirements

## Epic 1: User Profile Management

### US-1.1: Create Child Profile
**As a** parent  
**I want** to create profiles for each of my children  
**So that** each child has their own personalized experience and data

**Acceptance Criteria:**
- Given I'm in the parent settings section
  When I tap "Add Child"
  Then I can enter child's name, age, and select an avatar
- Given I've entered valid child information
  When I tap "Save"
  Then the profile is created and appears in the profile list
- Given I'm creating a profile
  When I select an age
  Then the app interface adjusts complexity appropriately

**Technical Notes:**
- Store in Core Data: Child entity with name, age, avatarId, createdDate
- Support up to 8 child profiles
- Age determines UI complexity level (5-7, 8-11, 12-16)

**Definition of Done:**
- ✅ UI implemented with form validation
- ✅ Core Data model created and tested
- ✅ Unit tests for ViewModel (>80% coverage)
- ✅ UI tests for create profile flow
- ✅ Accessibility: VoiceOver labels, Dynamic Type support

---

### US-1.2: Switch Between Profiles
**As a** child user  
**I want** to easily switch to my profile  
**So that** I can see my own activities and timer

**Acceptance Criteria:**
- Given multiple profiles exist
  When I'm on the profile selection screen
  Then I see all child profiles with their avatars and names
- Given I tap on my profile
  When authentication completes (if enabled)
  Then the app loads my personal dashboard
- Given I'm using the app
  When I want to switch profiles
  Then I can access profile switcher from settings

**Technical Notes:**
- Store current active profile in UserDefaults
- Load profile-specific data on switch
- Optional: PIN/pattern lock for older children
- Smooth transition animation

**Definition of Done:**
- ✅ Profile switcher UI implemented
- ✅ Data loading on profile switch tested
- ✅ Memory management verified (no leaks)
- ✅ Accessibility tested with VoiceOver

---

## Epic 2: Visual ADHD Timer

### US-2.1: Start Basic Timer
**As a** child user  
**I want** to start a visual countdown timer  
**So that** I can see how much time I have left for an activity

**Acceptance Criteria:**
- Given I'm on the timer screen
  When I select a duration (5, 10, 15, 20, 25, 30 minutes)
  Then the timer displays the selected time
- Given I tap the start button
  When the timer begins
  Then I see a visual representation of time decreasing
- Given the timer is running
  When time expires
  Then I receive visual, audio, and haptic feedback

**Technical Notes:**
- Use Timer.publish for accurate timing
- Support background execution with background tasks
- Local notifications when app is backgrounded
- Timer precision: ±0.1 seconds over 30 minutes

**Edge Cases:**
- App backgrounded during timer
- Device locked during timer
- Timer interrupted by phone call
- Multiple timers requested

**Definition of Done:**
- ✅ TimerService implemented with Combine
- ✅ Visual timer view with animations
- ✅ Background execution working
- ✅ Notifications configured
- ✅ Unit tests for timing accuracy
- ✅ UI tests for timer flow

---

### US-2.2: Visual Timer Modes
**As a** child user with ADHD  
**I want** different visual representations of time  
**So that** I can choose what helps me focus best

**Acceptance Criteria:**
- Given I'm setting up a timer
  When I select visualization mode
  Then I can choose: Circular (Time Timer style), Progress Bar, Analog Clock, or Digital
- Given I've selected Circular mode
  When the timer runs
  Then I see a colored disk that disappears as time passes
- Given the timer has <5 minutes remaining
  When time continues to decrease
  Then the color changes to indicate warning (yellow then red)

**Technical Notes:**
- Custom SwiftUI drawing with Canvas/Shape
- Smooth 60fps animations
- Color zones: Green (>10min), Yellow (5-10min), Red (<5min)
- Save preferred mode per child profile

**Definition of Done:**
- ✅ All 4 timer visualizations implemented
- ✅ Color transitions smooth
- ✅ Performance: 60fps on iPhone SE
- ✅ Preference saving/loading tested
- ✅ Accessibility: Alternative representations for visually impaired

---

### US-2.3: Pomodoro Timer
**As a** child user  
**I want** to use work/break cycles  
**So that** I can maintain focus for longer periods

**Acceptance Criteria:**
- Given I select Pomodoro mode
  When I configure it
  Then I can set work duration (default 25min) and break duration (default 5min)
- Given I start Pomodoro
  When work session completes
  Then I'm prompted to take a break with automatic break timer
- Given I complete 4 work sessions
  When the 4th session ends
  Then I get a longer break (default 15min)

**Technical Notes:**
- Store Pomodoro state (session count, current phase)
- Handle interruptions gracefully
- Show session progress (1/4, 2/4, etc.)
- Customizable durations via parent controls

**Definition of Done:**
- ✅ Pomodoro logic implemented in TimerService
- ✅ Session counter UI
- ✅ Auto-transition between work/break
- ✅ Unit tests for session counting
- ✅ UI tests for full Pomodoro cycle

---

## Epic 3: Activity Tracking

### US-3.1: Quick Log Activity
**As a** child user  
**I want** to quickly log what I just did  
**So that** I can track my activities without disruption

**Acceptance Criteria:**
- Given I'm on the activity log screen
  When I see the category buttons
  Then they are large, colorful, and clearly labeled with icons
- Given I tap a category
  When the tap registers
  Then activity is logged with current timestamp
- Given activity is logged
  When I view my today summary
  Then I see the logged activity with duration

**Technical Notes:**
- One-tap logging (no additional forms for quick log)
- Store: Activity entity with category, startTime, endTime, childId
- Calculate duration from consecutive logs of same category
- Haptic feedback on log

**Edge Cases:**
- Rapid successive taps
- Category change without explicit end
- Logging while timer is running

**Definition of Done:**
- ✅ Quick log UI with large touch targets (>60pt)
- ✅ Activity creation and storage
- ✅ Duration calculation logic
- ✅ Unit tests for edge cases
- ✅ Performance: <100ms to log

---

### US-3.2: Manual Time Entry
**As a** child user  
**I want** to add activities I forgot to log  
**So that** my tracking is complete and accurate

**Acceptance Criteria:**
- Given I want to log a past activity
  When I access manual entry
  Then I can select category, start time, end time, and add optional notes
- Given I enter a time range
  When I save
  Then the activity appears in my history with "manually entered" indicator
- Given I enter overlapping times
  When I try to save
  Then I see a warning and can adjust

**Technical Notes:**
- Date/time picker UI
- Validate: end time > start time, total duration reasonable
- Check for conflicts with existing activities
- Optional notes field (max 200 chars)

**Definition of Done:**
- ✅ Manual entry form implemented
- ✅ Validation logic with clear error messages
- ✅ Conflict detection
- ✅ Unit tests for validation
- ✅ UI tests for manual entry flow

---

### US-3.3: Category Management
**As a** parent  
**I want** to customize activity categories  
**So that** tracking matches my child's routine

**Acceptance Criteria:**
- Given I'm in parent settings
  When I access category management
  Then I see all categories with subcategories
- Given I want to add a subcategory
  When I tap "Add" under a category
  Then I can enter name and optionally assign a color/icon
- Given I want to hide a category
  When I toggle it off
  Then it doesn't appear in child's logging interface

**Technical Notes:**
- Category entity: name, icon, color, isActive, parentId (for subcategories)
- Pre-populated with default categories
- Parent-only access via PIN authentication
- Sync across devices if CloudKit enabled

**Definition of Done:**
- ✅ Category CRUD operations
- ✅ Parent authentication flow
- ✅ UI for category management
- ✅ Persistence with Core Data
- ✅ Unit tests for category operations

---

## Epic 4: Data Visualization

### US-4.1: Daily Activity Summary
**As a** child user  
**I want** to see what I did today in a visual chart  
**So that** I can understand how I spent my time

**Acceptance Criteria:**
- Given I navigate to stats screen
  When I view today's summary
  Then I see a pie chart showing time distribution across categories
- Given a category has >0 minutes
  When I tap on that pie slice
  Then I see detailed breakdown with subcategories
- Given I have no activities today
  When I view the chart
  Then I see an encouraging message to start logging

**Technical Notes:**
- Use Swift Charts framework
- Color-code by category color
- Show percentages and actual time
- Smooth animations on data load
- Handle empty state gracefully

**Definition of Done:**
- ✅ Pie chart component implemented
- ✅ Data aggregation logic tested
- ✅ Tap interaction for drill-down
- ✅ Empty state designed
- ✅ Accessibility: Chart data in table format for VoiceOver

---

### US-4.2: Weekly Trends
**As a** child user  
**I want** to see my week at a glance  
**So that** I can notice patterns in my activities

**Acceptance Criteria:**
- Given I'm viewing statistics
  When I switch to weekly view
  Then I see a bar chart with 7 days showing category breakdown
- Given I tap a specific day
  When the interaction occurs
  Then I see that day's detailed breakdown
- Given it's a new week
  When I view the chart
  Then the previous week's data is still accessible

**Technical Notes:**
- Stacked bar chart with category colors
- Date range selector (this week, last week, custom)
- Store aggregated data for performance
- Swipe gestures for week navigation

**Definition of Done:**
- ✅ Weekly bar chart implemented
- ✅ Data aggregation optimized
- ✅ Week navigation working
- ✅ Performance: <500ms to render
- ✅ UI tests for weekly view

---

### US-4.3: Achievement Badges
**As a** child user  
**I want** to earn badges for accomplishments  
**So that** I feel motivated to maintain good habits

**Acceptance Criteria:**
- Given I complete an achievement goal
  When the system detects it
  Then I receive a notification and see unlocked badge with animation
- Given I view my achievements
  When I'm on the achievements screen
  Then I see earned badges in color and locked badges in grayscale
- Given I tap an achievement
  When the detail view opens
  Then I see description, unlock date, and progress toward next tier

**Technical Notes:**
- Achievement types: Streak (3/7/30 days), Category (hours in category), Balance (even distribution)
- Badge images in Assets catalog
- Local notifications on unlock
- Achievement entity: id, name, description, unlockedDate, childId

**Achievements List:**
1. 🔥 3-Day Streak
2. 🔥 7-Day Streak  
3. 🔥 30-Day Streak
4. 📚 Homework Hero (20 hours homework)
5. ⚡ Active Kid (30 hours physical activity)
6. 🎨 Creative Mind (15 hours creative play)
7. ⚖️ Balanced Week (no category >40% of time)
8. 🌅 Early Bird (5 activities logged before 10am)

**Definition of Done:**
- ✅ Achievement tracking logic
- ✅ Unlock notifications
- ✅ Badge UI with animations
- ✅ Unit tests for unlock conditions
- ✅ Celebration animation on unlock

---

## Epic 5: Parent Controls

### US-5.1: Parent Authentication
**As a** parent  
**I want** secure access to parent settings  
**So that** my child cannot modify important configurations

**Acceptance Criteria:**
- Given I try to access parent settings
  When I tap the settings icon
  Then I'm prompted for authentication (PIN, Face ID, or Touch ID)
- Given I enter correct credentials
  When authentication succeeds
  Then I access the parent dashboard
- Given authentication fails 3 times
  When the 3rd failure occurs
  Then I must wait 30 seconds before trying again

**Technical Notes:**
- Use LocalAuthentication framework
- Fallback to PIN if biometrics unavailable
- Store PIN hash (never plaintext) in Keychain
- Session timeout after 5 minutes of inactivity

**Edge Cases:**
- Device doesn't support biometrics
- Biometric data changes (new fingerprint)
- User forgot PIN (reset flow required)

**Definition of Done:**
- ✅ LocalAuthentication integration
- ✅ PIN creation and verification
- ✅ Keychain storage
- ✅ Session management
- ✅ UI tests for auth flows

---

### US-5.2: Time Goals Setting
**As a** parent  
**I want** to set recommended time limits for categories  
**So that** my child has guidance on balanced time allocation

**Acceptance Criteria:**
- Given I'm in parent settings
  When I access time goals
  Then I see sliders for each category with min/max recommendations
- Given I set a screen time limit to 90 minutes
  When my child approaches that limit
  Then they receive a gentle reminder notification
- Given a goal is exceeded
  When viewing stats
  Then the category shows as "over goal" with visual indicator

**Technical Notes:**
- Goals stored per child profile
- Non-blocking reminders (not hard limits for MVP)
- Visual indicators: Green (<75%), Yellow (75-100%), Red (>100%)
- Default goals based on age and research recommendations

**Default Goals by Age:**
- Ages 5-7: Screen 60min, Physical 90min, Creative 60min
- Ages 8-11: Screen 90min, Physical 60min, Homework 60min, Creative 45min
- Ages 12-16: Screen 120min, Physical 60min, Homework 90min

**Definition of Done:**
- ✅ Goal setting UI
- ✅ Notification triggers
- ✅ Visual indicators in stats
- ✅ Age-based defaults
- ✅ Unit tests for goal logic

---

### US-5.3: Activity Reports
**As a** parent  
**I want** to view comprehensive reports of my child's activities  
**So that** I can understand their time usage patterns

**Acceptance Criteria:**
- Given I access the reports section
  When I select a child and date range
  Then I see detailed breakdown of activities with charts and statistics
- Given I want to share a report
  When I tap export
  Then I can generate PDF or CSV with the data
- Given I want insights
  When viewing the report
  Then I see trends, comparisons, and recommendations

**Technical Notes:**
- Report components: Summary stats, category breakdown, trends, peak times, goal achievement
- PDF generation with PDFKit
- CSV export for external analysis
- Report templates: Daily, Weekly, Monthly

**Definition of Done:**
- ✅ Report generation logic
- ✅ PDF/CSV export working
- ✅ Insights algorithm implemented
- ✅ Email/share functionality
- ✅ Performance: <2s to generate report

---

## Epic 6: Onboarding & Setup

### US-6.1: First-Time Onboarding
**As a** new user  
**I want** clear guidance on setting up the app  
**So that** I can start using it quickly and correctly

**Acceptance Criteria:**
- Given I open the app for the first time
  When the app launches
  Then I see a welcome screen explaining key benefits
- Given I proceed through onboarding
  When I complete each step
  Then I create my first child profile and set up initial categories
- Given onboarding is complete
  When I finish
  Then I land on the home screen ready to use

**Onboarding Flow:**
1. Welcome screen with app benefits
2. Create parent PIN
3. Add first child profile
4. Brief timer tutorial
5. Activity logging introduction
6. Privacy and data notice
7. Optional: Enable notifications

**Definition of Done:**
- ✅ Onboarding screens designed and implemented
- ✅ Flow logic with progress indicator
- ✅ Skip option for experienced users
- ✅ Completion persisted (only show once)
- ✅ Accessibility tested

---

## Epic 7: Advanced Features (v1.5+)

### US-7.1: CloudKit Sync
**As a** parent with multiple devices  
**I want** my data to sync across all devices  
**So that** my children can use any family device

**Technical Notes:**
- Optional feature (can use local-only)
- CKRecord types for all entities
- Conflict resolution: last-write-wins with timestamp
- Background sync with CKQuerySubscription
- Offline queue for changes

---

### US-7.2: Apple Watch Companion
**As a** child user  
**I want** to control timer from my watch  
**So that** I don't need to pull out my phone/iPad

**Features:**
- Quick timer start (preset durations)
- Timer status at a glance
- Activity quick log
- Today's summary complications

---

### US-7.3: Emotional Check-Ins
**As a** child user  
**I want** to record how I feel during activities  
**So that** I can understand what makes me happy/frustrated

**Features:**
- Emoji mood selector (5 levels)
- Before/after activity mood tracking
- Mood trends in statistics
- Parent insights on mood patterns

---

## Feature Priority Matrix

### MVP (v1.0) - Must Have
- ✅ User profile management (US-1.1, US-1.2)
- ✅ Basic visual timer (US-2.1, US-2.2)
- ✅ Activity logging (US-3.1, US-3.2)
- ✅ Category management (US-3.3)
- ✅ Daily/weekly statistics (US-4.1, US-4.2)
- ✅ Parent authentication (US-5.1)
- ✅ Time goals (US-5.2)
- ✅ Onboarding (US-6.1)

### v1.5 - Should Have
- ⏳ Pomodoro timer (US-2.3)
- ⏳ Achievement badges (US-4.3)
- ⏳ Activity reports export (US-5.3)
- ⏳ CloudKit sync (US-7.1)
- ⏳ Apple Watch app (US-7.2)

### v2.0 - Nice to Have
- 🎯 Emotional check-ins (US-7.3)
- 🎯 Focus mode integration
- 🎯 Routine builder
- 🎯 Family challenges
- 🎯 Screen time API integration

---

## User Story Estimation

| Epic | Story Count | Total Points |
|------|-------------|--------------|
| User Profile Management | 2 | 8 |
| Visual ADHD Timer | 3 | 21 |
| Activity Tracking | 3 | 13 |
| Data Visualization | 3 | 21 |
| Parent Controls | 3 | 13 |
| Onboarding | 1 | 5 |
| **MVP Total** | **15** | **81 points** |

**Velocity Estimate:** 10 points/week with 1 developer  
**MVP Timeline:** 8-10 weeks

---

## Non-Functional Requirements

### Performance
- App launch: <2 seconds cold start
- Timer accuracy: ±0.1 seconds over 30 minutes
- Chart rendering: <500ms for 30 days of data
- Memory usage: <100MB typical, <150MB peak
- Battery: <5% drain per hour with active timer

### Accessibility
- Full VoiceOver support on all screens
- Dynamic Type support (XS to XXXL)
- Minimum contrast ratio: 4.5:1 (WCAG AA)
- Touch targets: minimum 44x44 points
- Support for reduced motion

### Privacy & Security
- COPPA compliant (no data collection without consent)
- All data encrypted at rest (Core Data encryption)
- Optional: End-to-end encryption for CloudKit
- No third-party tracking
- Parents can export/delete all data

### Compatibility
- iOS 16.0+ (for latest APIs)
- iPhone SE (3rd gen) to iPhone 15 Pro Max
- iPad (9th gen) to iPad Pro 12.9"
- Supports portrait and landscape
- Light and dark mode

---

## Acceptance Test Scenarios

### Critical Path: Timer Usage
1. User opens app → sees home screen (2s)
2. User taps "Start Timer" → timer screen loads (<500ms)
3. User selects 25 minutes → time displays correctly
4. User selects "Homework" category → category highlights
5. User taps play → timer starts counting down (±0.1s accuracy)
6. User backgrounds app → timer continues in background
7. Timer completes → notification fires (<2s delay)
8. User returns to app → sees completion screen

### Critical Path: Activity Logging
1. User taps "Log Activity" → log screen appears
2. User taps "Reading" → activity logged (<100ms)
3. Activity appears in "Today's Activities" → shows current time
4. User logs multiple activities → durations calculate correctly
5. User views stats → sees activities in pie chart

---

## Definition of Ready (User Story)

A user story is ready for development when:
- [ ] Acceptance criteria are clear and testable
- [ ] UI mockups exist (if applicable)
- [ ] Dependencies identified and resolved
- [ ] Technical approach discussed with Architecture Agent
- [ ] Edge cases documented
- [ ] Performance requirements specified
- [ ] Accessibility requirements noted
- [ ] Estimated in story points

---

## Definition of Done (User Story)

A user story is done when:
- [ ] Code implemented following architecture patterns
- [ ] Unit tests written (>80% coverage)
- [ ] Integration tests passing
- [ ] UI tests for critical paths
- [ ] Code reviewed by QA Agent
- [ ] Accessibility verified (VoiceOver tested)
- [ ] Performance meets requirements
- [ ] Documentation updated
- [ ] No critical or high-severity bugs
- [ ] Merged to main branch

---

**Next Step:** Begin with US-1.1 (Create Child Profile) for first sprint!
