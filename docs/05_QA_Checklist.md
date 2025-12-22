# QA Checklist - FocusPal

**Owner:** QA Agent

## Code Review Checklist

### Architecture & Design
- [ ] Follows MVVM pattern correctly
- [ ] No business logic in Views
- [ ] ViewModels use @Published for state
- [ ] Services are protocol-based
- [ ] Dependency injection used properly
- [ ] No singleton abuse (only where appropriate)

### Code Quality
- [ ] No force unwraps in production code
- [ ] Proper error handling (try/catch or Result)
- [ ] No retain cycles (weak self in closures)
- [ ] Functions < 50 lines
- [ ] Files < 400 lines
- [ ] Meaningful variable names
- [ ] No commented-out code
- [ ] SwiftLint violations: 0

### Performance
- [ ] No blocking operations on main thread
- [ ] Async/await used for async operations
- [ ] Images optimized and properly sized
- [ ] Core Data fetch requests have predicates
- [ ] No memory leaks (checked with Instruments)
- [ ] App launches in < 2 seconds

### Security
- [ ] No sensitive data in UserDefaults
- [ ] Keychain used for credentials
- [ ] Core Data encryption enabled
- [ ] No API keys in code
- [ ] Parent authentication required for settings

### Testing
- [ ] Unit tests written and passing
- [ ] Test coverage meets thresholds
- [ ] UI tests for critical paths
- [ ] No failing tests
- [ ] Mock objects used properly

## Functional Testing

### Timer Functionality
- [ ] Timer starts correctly
- [ ] Timer counts down accurately (±0.1s)
- [ ] Timer continues in background
- [ ] Timer notification fires on completion
- [ ] Timer can be paused and resumed
- [ ] Timer can be stopped
- [ ] All visualization modes work
- [ ] Color changes at correct thresholds
- [ ] Pomodoro mode cycles correctly
- [ ] Timer state persists across app restarts

### Activity Tracking
- [ ] Quick log creates activity
- [ ] Manual entry validates time ranges
- [ ] Activities appear in history
- [ ] Duration calculated correctly
- [ ] Categories display properly
- [ ] Activities can be edited
- [ ] Activities can be deleted
- [ ] Notes save correctly

### Data & Analytics
- [ ] Daily chart shows correct data
- [ ] Weekly chart aggregates properly
- [ ] Monthly trends accurate
- [ ] Charts render in < 500ms
- [ ] Empty states display
- [ ] Achievement unlocks trigger
- [ ] Badges display correctly
- [ ] Export works (PDF/CSV)

### Multi-Child
- [ ] Can create multiple profiles
- [ ] Can switch between profiles
- [ ] Data isolated per child
- [ ] Profile deletion works
- [ ] Age-based UI adapts
- [ ] Max 8 profiles enforced

### Parent Controls
- [ ] Authentication required
- [ ] PIN creation works
- [ ] Biometric auth works
- [ ] Category management functions
- [ ] Time goals save
- [ ] Reports generate correctly
- [ ] Settings persist

## Accessibility Testing

### VoiceOver
- [ ] All screens navigable with VoiceOver
- [ ] All buttons have labels
- [ ] All images have descriptions
- [ ] State changes announced
- [ ] Charts have alternative text
- [ ] Forms have proper labels

### Dynamic Type
- [ ] Text scales at all sizes
- [ ] Layout doesn't break at XXXL
- [ ] Touch targets remain accessible
- [ ] No text truncation

### Color & Contrast
- [ ] All text meets 4.5:1 ratio
- [ ] Color not sole indicator
- [ ] Icons paired with labels
- [ ] Works in high contrast mode

### Motor & Cognitive
- [ ] Touch targets ≥ 44x44pt
- [ ] No time-critical interactions
- [ ] Reduce motion supported
- [ ] Clear visual hierarchy

## Device Testing

### iPhone Models
- [ ] iPhone SE (3rd gen) - Small screen
- [ ] iPhone 14 - Standard
- [ ] iPhone 15 Pro Max - Large
- [ ] Portrait orientation
- [ ] Landscape orientation (where supported)

### iPad Models
- [ ] iPad (9th gen)
- [ ] iPad Air
- [ ] iPad Pro 12.9"
- [ ] Portrait and landscape
- [ ] Split view compatibility

### iOS Versions
- [ ] iOS 16.0 (minimum)
- [ ] iOS 17.x (current)
- [ ] iOS 18 beta (if available)

## Compatibility Testing

### Light/Dark Mode
- [ ] All screens in light mode
- [ ] All screens in dark mode
- [ ] Mode switching works
- [ ] Colors adapt correctly
- [ ] Readability maintained

### Localization (Future)
- [ ] English (US) - Primary
- [ ] Spanish - Secondary
- [ ] Date formats correct
- [ ] Number formats correct

## Performance Testing

### App Performance
- [ ] Cold launch < 2s
- [ ] Warm launch < 1s
- [ ] Timer accuracy verified
- [ ] No dropped frames (60 FPS)
- [ ] Memory usage < 100MB typical
- [ ] Battery drain < 5%/hour
- [ ] No crashes in 30-min session

### Data Performance
- [ ] 1000 activities load in < 1s
- [ ] Charts render in < 500ms
- [ ] Core Data operations < 100ms
- [ ] Sync completes in background
- [ ] No data loss

## Edge Cases

### Timer Edge Cases
- [ ] Timer during phone call
- [ ] Timer during low battery
- [ ] Timer when device locked
- [ ] Timer across midnight
- [ ] Multiple timers (should prevent)
- [ ] Very long durations (24 hours)
- [ ] Very short durations (1 minute)

### Data Edge Cases
- [ ] No activities logged
- [ ] Maximum activities (10,000+)
- [ ] All categories disabled
- [ ] Overlapping activities
- [ ] Future dated activities
- [ ] Activities on DST change

### Network Edge Cases
- [ ] Offline mode works
- [ ] Sync when back online
- [ ] Conflict resolution
- [ ] Poor network conditions
- [ ] No iCloud account

## Security Testing

### Authentication
- [ ] PIN cannot be bypassed
- [ ] Biometric auth fallback works
- [ ] Session timeout enforces
- [ ] Failed attempts limit
- [ ] PIN reset requires verification

### Data Protection
- [ ] Core Data encrypted at rest
- [ ] Keychain secure
- [ ] No data in logs
- [ ] Screen recording protection
- [ ] Screenshot protection (if needed)

## Privacy Compliance

### COPPA
- [ ] No data collection without consent
- [ ] Parental controls present
- [ ] No third-party tracking
- [ ] Privacy policy accessible
- [ ] Data export available

## Bug Severity Classification

**P0 - Critical (Fix immediately)**
- App crashes
- Data loss
- Security vulnerabilities
- Core feature completely broken

**P1 - High (Fix before release)**
- Major feature doesn't work
- Performance severely degraded
- Accessibility issues
- Incorrect data calculations

**P2 - Medium (Fix if time allows)**
- Minor feature issues
- UI glitches
- Non-critical errors
- Minor performance issues

**P3 - Low (Future release)**
- Cosmetic issues
- Nice-to-have features
- Documentation issues

## Release Checklist

### Pre-Release
- [ ] All P0/P1 bugs fixed
- [ ] Test coverage > 80%
- [ ] No SwiftLint errors
- [ ] No compiler warnings
- [ ] App Store assets ready
- [ ] Privacy policy updated
- [ ] App Store description ready

### TestFlight
- [ ] Internal testing complete
- [ ] External beta started
- [ ] Feedback collected
- [ ] Critical bugs fixed

### App Store Submission
- [ ] Final build uploaded
- [ ] Screenshots uploaded
- [ ] Description finalized
- [ ] Keywords optimized
- [ ] Support URL active
- [ ] Privacy policy URL active

## QA Agent Responsibilities

1. Review all pull requests for quality
2. Run full test suite regularly
3. Perform exploratory testing
4. Document bugs with reproduction steps
5. Verify bug fixes
6. Maintain QA checklist
7. Report on quality metrics
8. Approve releases
