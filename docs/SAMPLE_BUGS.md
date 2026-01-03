# Sample Bug Reports - FocusPal

**These are example bug reports demonstrating proper bug documentation**

---

## Bug #1: Timer Continues Running After App Force Quit

**Bug ID:** #47
**Title:** Timer state not restored after app force quit
**Priority:** P1 (High)
**Severity:** High
**Status:** New

### Environment
- **Device:** iPhone 14 Pro
- **iOS Version:** 17.2
- **App Version:** 1.0.0 (105)
- **Build Type:** TestFlight

### Description

**Summary:**
When a timer is running and the app is force quit from the app switcher, the timer state is not properly restored on next launch. The user loses track of their current activity.

**Expected Behavior:**
After force quitting the app with a running timer:
1. Timer should be saved to persistent storage
2. On relaunch, timer should be restored (paused or running)
3. Elapsed time should be calculated correctly
4. User should see option to continue or cancel

**Actual Behavior:**
After force quitting the app:
1. Timer state is lost
2. On relaunch, timer screen shows idle state
3. No indication that a timer was previously running
4. Activity is not logged

**Impact:**
- Affects all users who force quit the app while timer running
- Results in lost activity tracking
- Reproducibility: Always
- Estimated 20% of users force quit apps regularly

### Steps to Reproduce

1. Launch FocusPal and select child profile "Emma"
2. Navigate to Timer tab
3. Select "Homework" category
4. Start 25-minute timer
5. Wait 5 minutes
6. Double-tap home button to open app switcher
7. Swipe up to force quit FocusPal
8. Relaunch FocusPal from home screen

**Expected:** Timer should show 20 minutes remaining (paused state) with option to resume
**Actual:** Timer screen shows idle state (00:00)

### Screenshots

![Timer Running Before Force Quit](screenshots/bug47_before.png)
![Timer Idle After Relaunch](screenshots/bug47_after.png)

### Console Logs

```
2025-12-30 14:32:18.234 [INFO] TimerService: Timer started - Duration: 1500s, Category: Homework
2025-12-30 14:32:18.256 [INFO] TimerService: Timer state saved to UserDefaults
[App force quit - no logs]
2025-12-30 14:38:12.123 [INFO] App launched
2025-12-30 14:38:12.156 [WARNING] TimerService: No saved timer state found
2025-12-30 14:38:12.178 [INFO] TimerService: Initialized in idle state
```

### Related Issues
- Related to #32 (Background timer persistence)
- May be related to #18 (Activity not logged on app crash)

### Test Case Failed
- Test ID: UT-TVM-008 (Timer state persists across app restart)
- Test ID: UI-003-010 (Timer persists across app restart)

### For QA Team

**Automated Test:** Yes - test is passing, but doesn't cover force quit scenario
**Regression:** No - this never worked correctly
**Workaround:** Users should use pause button before leaving app

**Root Cause Analysis:**
TimerService saves state to UserDefaults in `applicationWillResignActive` but this delegate method is not called during force quit. Need to save state on timer tick or use more aggressive persistence strategy.

**Proposed Fix:**
1. Save timer state on every significant event (start, pause, extend)
2. Add timer state checkpointing every 10 seconds
3. On app launch, check for stale timer (started > 2 hours ago = expired)
4. Show recovery dialog with "Resume" or "Discard" options

---

## Bug #2: Achievement Unlock Notification Not Appearing

**Bug ID:** #52
**Title:** Achievement unlock notification doesn't appear after earning badge
**Priority:** P2 (Medium)
**Severity:** Medium
**Status:** New

### Environment
- **Device:** iPad Air 5th gen
- **iOS Version:** 17.1
- **App Version:** 1.0.0 (108)
- **Build Type:** Debug

### Description

**Summary:**
When a child earns their first achievement (First Timer), the unlock notification/celebration animation does not appear. The badge is unlocked in the achievements screen but no feedback is given to the user.

**Expected Behavior:**
1. Child completes first timer activity
2. Achievement "First Timer" unlocks
3. Notification banner appears: "Achievement Unlocked! First Timer"
4. Confetti animation plays
5. User can tap notification to view achievement details

**Actual Behavior:**
1. Child completes first timer activity
2. Achievement unlocks silently
3. No notification or animation
4. Badge appears in achievements screen only if user navigates there

**Impact:**
- Reduces engagement and motivation
- Children don't realize they've earned achievements
- Affects all users earning their first achievement
- Reproducibility: Always

### Steps to Reproduce

1. Create fresh child profile "Test User"
2. Verify no achievements unlocked (navigate to Achievements)
3. Go to Timer tab
4. Select "Reading" category and 5 minutes duration
5. Start timer
6. Wait for timer to complete
7. Mark activity as complete
8. Observe for unlock notification

**Expected:** Celebration screen with "Achievement Unlocked: First Timer" and confetti animation
**Actual:** Nothing happens, user returns to timer screen

### Screenshots

![Expected Celebration Screen](screenshots/bug52_expected.png)
![Actual Result - No Notification](screenshots/bug52_actual.png)

### Console Logs

```
2025-12-30 15:10:23.445 [INFO] ActivityService: Activity logged - Category: Reading, Duration: 300s
2025-12-30 15:10:23.467 [INFO] PointsService: Points awarded: 30
2025-12-30 15:10:23.489 [INFO] AchievementService: Checking achievements for activity completion
2025-12-30 15:10:23.502 [INFO] AchievementService: Achievement unlocked - ID: first_timer
2025-12-30 15:10:23.515 [INFO] AchievementService: Saving achievement to database
2025-12-30 15:10:23.534 [INFO] AchievementService: Achievement saved successfully
[No notification logs]
```

### Related Issues
- Similar to #41 (Time goal notification not firing)
- Related to #15 (NotificationService permissions)

### Test Case Failed
- Test ID: UT-AS-010 (Achievement unlock triggers notification)
- Test ID: UI-009 (Achievement unlock notification appears)

### For QA Team

**Automated Test:** Partial - unit test passes (notification called) but integration test fails
**Regression:** No - feature is newly implemented
**Workaround:** Users can manually navigate to Achievements screen to see unlocked badges

**Root Cause Analysis:**
AchievementService calls NotificationService.showAchievementUnlock() but the notification is not displayed. Likely issue:
1. NotificationService.showAchievementUnlock() not implemented correctly
2. Missing notification permission check
3. UI presentation happening on background thread

**Proposed Fix:**
1. Verify NotificationService has notification permissions before attempting to show
2. Ensure notification is dispatched on main thread
3. Add fallback in-app modal if notifications disabled
4. Add integration test covering full flow

---

## Bug #3: Activity Deletion Removes Wrong Activity

**Bug ID:** #61
**Title:** Deleting activity sometimes deletes different activity
**Priority:** P0 (Critical)
**Severity:** Critical
**Status:** In Progress

### Environment
- **Device:** iPhone SE 3rd gen
- **iOS Version:** 16.5
- **App Version:** 1.0.0 (110)
- **Build Type:** TestFlight

### Description

**Summary:**
When deleting an activity via swipe-to-delete gesture on Activity List, occasionally the wrong activity is deleted. This appears to be a race condition where the list updates while the delete operation is in progress.

**Expected Behavior:**
1. User swipes left on "Reading - 2:00 PM - 3:00 PM"
2. Delete button appears
3. User taps Delete
4. Confirmation dialog appears
5. User confirms deletion
6. "Reading - 2:00 PM - 3:00 PM" activity is removed
7. Other activities remain unchanged

**Actual Behavior:**
1-5. Same as expected
6. Different activity is deleted (e.g., "Homework - 1:00 PM - 2:00 PM")
7. The intended activity remains in the list

**Impact:**
- DATA LOSS - users lose wrong activity data
- Affects data integrity and user trust
- Reproducibility: Sometimes (race condition)
- Estimated 5% of delete operations affected
- **This is a critical data integrity bug**

### Steps to Reproduce

1. Create child profile with 10+ activities logged
2. Navigate to Activity Log
3. Scroll to middle of list (around item 5 or 6)
4. Quickly swipe left on an activity
5. Immediately tap Delete button
6. Confirm deletion
7. Check which activity was actually deleted

**Reproducibility:** Sometimes (appears to happen when list is scrolling or updating)

### Screenshots

![Before Delete - Swiping "Reading" Activity](screenshots/bug61_before.png)
![After Delete - "Homework" Activity Removed Instead](screenshots/bug61_after.png)

### Console Logs

```
2025-12-30 16:23:12.123 [INFO] ActivityListView: Swipe gesture detected on cell index: 5
2025-12-30 16:23:12.145 [INFO] ActivityListView: Delete button tapped for activity ID: 3F4A2B1C-...
2025-12-30 16:23:12.156 [INFO] ActivityListViewModel: Delete requested for activity ID: 3F4A2B1C-...
2025-12-30 16:23:12.167 [INFO] ActivityListView: Refreshing list
2025-12-30 16:23:12.178 [WARNING] ActivityListView: Cell index mismatch detected during refresh
2025-12-30 16:23:12.189 [INFO] ActivityRepository: Deleting activity ID: 2E5B3A7D-...  [WRONG ID!]
2025-12-30 16:23:12.201 [INFO] ActivityRepository: Activity deleted successfully
2025-12-30 16:23:12.223 [ERROR] ActivityListViewModel: Activity ID mismatch - Expected: 3F4A2B1C, Deleted: 2E5B3A7D
```

### Related Issues
- #58 (List refresh causes flickering)
- #44 (Race condition in activity updates)

### Test Case Failed
- Test ID: UI-005-005 (Delete activity with swipe)
- Test ID: IT-SI-012 (Concurrent operations don't corrupt data)

### For QA Team

**Automated Test:** No - UI test passes (doesn't catch race condition)
**Regression:** Yes - this started in build 108 after list optimization changes
**Workaround:** Delete activities from detail view instead of swipe-to-delete

**Root Cause Analysis:**
SwiftUI List is updating indices while delete operation is in progress. The delete action captures the activity ID from the cell, but by the time the repository deletion occurs, the list has reordered and the index no longer matches the activity.

Flow:
1. User swipes on cell at index 5 (activity A)
2. Delete button tap stores activity ID from index 5
3. List refreshes due to other updates
4. Index 5 now points to activity B
5. Delete operation uses activity B's ID instead of A's ID

**Proposed Fix:**
1. Always use activity ID, never rely on index
2. Pass activity object (not ID) to delete function
3. Add validation check before delete: confirm activity ID matches user's selection
4. Add unit test for concurrent list updates during delete
5. Add integration test that simulates rapid list changes

**Fix Verification:**
- [ ] Reproduced bug in test environment
- [ ] Fix implemented
- [ ] Unit test added for race condition
- [ ] Manual testing: 50+ delete operations with no issues
- [ ] Beta testing: 1 week with no reports
- [ ] Ready for release

---

## Bug Classification Summary

| Priority | Example | Response Time | Fix Timeline |
|----------|---------|---------------|--------------|
| P0 - Critical | Data loss, crashes | Immediately | Same day |
| P1 - High | Major feature broken | 1 business day | 2-3 days |
| P2 - Medium | Minor feature issue | 3 business days | 1 week |
| P3 - Low | Cosmetic, edge case | 1 week | Next sprint |

---

## Common Bug Categories

### Timer Issues
- Timer accuracy drift
- Background execution failures
- State persistence problems
- Notification timing

### Activity Tracking Issues
- Duration calculation errors
- Overlapping activity detection
- Manual entry validation
- Data integrity (wrong data deleted/updated)

### Parent Controls Issues
- PIN bypass vulnerabilities
- Authentication failures
- Category management bugs
- Permission issues

### Multi-Child Issues
- Data isolation failures
- Profile switching bugs
- Cross-child data leakage

### UI/UX Issues
- Layout breaks at different text sizes
- Color contrast failures
- VoiceOver navigation issues
- Touch target size violations

### Performance Issues
- Chart rendering slowness
- Memory leaks
- Battery drain
- App launch time

---

## Bug Triage Process

1. **New Bug Reported**
   - QA validates: Can it be reproduced?
   - If yes: Assign priority/severity
   - If no: Request more info or close

2. **Triaged Bugs**
   - P0: Assign immediately, daily standups
   - P1: Assign within 24 hours
   - P2/P3: Assign in sprint planning

3. **In Progress**
   - Developer investigates root cause
   - Fix implemented with tests
   - PR created with bug reference

4. **Fixed**
   - QA verifies fix
   - Regression tests run
   - Mark as closed or reopen

5. **Won't Fix**
   - Document reason
   - Notify reporter
   - Close with label

---

**End of Sample Bugs**
