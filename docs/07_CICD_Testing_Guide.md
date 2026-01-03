# CI/CD Testing Integration Guide - FocusPal

**Version:** 1.0
**Last Updated:** 2025-12-30
**Owner:** DevOps & QA Team

---

## Table of Contents

1. [Overview](#overview)
2. [GitHub Actions Workflows](#github-actions-workflows)
3. [Local Testing](#local-testing)
4. [Test Execution Strategy](#test-execution-strategy)
5. [Device Farm Integration](#device-farm-integration)
6. [Performance Monitoring](#performance-monitoring)
7. [Test Reporting](#test-reporting)
8. [Troubleshooting](#troubleshooting)

---

## Overview

FocusPal uses GitHub Actions for continuous integration and automated testing. The CI/CD pipeline ensures code quality, catches regressions early, and provides fast feedback to developers.

### Pipeline Goals
- **Fast Feedback**: Unit tests complete in < 1 minute
- **Comprehensive Coverage**: All test levels automated
- **Quality Gates**: Block merges on test failures or coverage drops
- **Visibility**: Clear test reports and notifications

### Pipeline Stages

```
┌─────────────┐
│ Pull Request│
└──────┬──────┘
       │
       ├──────┐
       │      │
       ▼      ▼
   ┌────┐  ┌────┐
   │Lint│  │Build│
   └──┬─┘  └──┬─┘
      │       │
      ▼       ▼
  ┌────────────┐
  │ Unit Tests │
  └─────┬──────┘
        │
        ▼
  ┌──────────────────┐
  │Integration Tests │
  └────────┬─────────┘
           │
           ▼
      ┌─────────┐
      │UI Tests │
      └────┬────┘
           │
           ▼
    ┌────────────┐
    │Coverage    │
    │Check (80%) │
    └─────┬──────┘
          │
          ▼
     ┌─────────┐
     │ ✅ Merge │
     └─────────┘
```

---

## GitHub Actions Workflows

### 1. Pull Request Workflow (`test.yml`)

**Trigger:** On pull request to `main` or `develop`

**Jobs:**

#### SwiftLint
```yaml
- Runs SwiftLint with strict mode
- Reports: 0 errors, 0 warnings
- Duration: ~30 seconds
- Blocks merge: Yes (on errors)
```

#### Unit Tests
```yaml
- Runs all unit tests in FocusPalTests
- Device: iPhone 14 Simulator, iOS 17.2
- Code coverage: Enabled
- Duration: ~45 seconds
- Blocks merge: Yes
```

#### Integration Tests
```yaml
- Runs integration test suite
- Device: iPhone 14 Simulator, iOS 17.2
- Tests: Core Data, Service Integration, Multi-Child
- Duration: ~30 seconds
- Blocks merge: Yes
```

#### UI Tests
```yaml
- Runs on 3 devices in parallel:
  - iPhone SE (3rd gen) - Small screen
  - iPhone 14 - Standard
  - iPad (10th gen) - Tablet
- Tests: Critical user journeys
- Duration: ~2 minutes per device
- Blocks merge: Yes
```

#### Code Coverage
```yaml
- Aggregates coverage from all test runs
- Threshold: 80% overall
- Checks per-module thresholds:
  - ViewModels: 85%
  - Services: 80%
  - Repositories: 75%
- Uploads to Codecov
- Blocks merge: Yes (if below threshold)
```

#### Build
```yaml
- Builds for simulator (Debug)
- Builds for device (Release) on main branch
- Duration: ~1-2 minutes
- Blocks merge: Yes
```

**Total Duration:** ~4-5 minutes

**Success Criteria:**
- All tests passing
- Code coverage >= 80%
- SwiftLint clean
- Build successful

### 2. Nightly Workflow (`nightly.yml`)

**Trigger:** Daily at 2 AM UTC (or manual dispatch)

**Jobs:**

#### Full Test Suite
```yaml
- Runs ALL tests across:
  - 5 device types (iPhone SE, 14, 15 Pro Max, iPad, iPad Pro)
  - 2 iOS versions (16.4, 17.2)
  - Total: 10 configurations
- Duration: ~20-25 minutes
- Matrix strategy for parallelization
```

#### Accessibility Audit
```yaml
- Runs accessibility-specific tests
- Checks:
  - VoiceOver labels on all elements
  - Dynamic Type support (5 sizes)
  - Color contrast (WCAG AA)
  - Touch target sizes (44x44pt min)
- Duration: ~3 minutes
```

#### Memory Leak Detection
```yaml
- Runs tests with Address Sanitizer
- Detects:
  - Memory leaks
  - Use-after-free
  - Double-free
  - Buffer overflows
- Duration: ~5 minutes (slower due to sanitizer)
```

#### Performance Benchmarks
```yaml
- Measures:
  - Timer accuracy (±0.1s target)
  - Chart rendering (< 500ms target)
  - App launch time (< 2s target)
  - Core Data operations (< 100ms)
- Compares against baseline
- Duration: ~3 minutes
```

#### Security Scan
```yaml
- Checks for:
  - Hardcoded API keys
  - Sensitive data in code
  - SwiftLint security rules
- Duration: ~1 minute
```

#### Test Report Generation
```yaml
- Aggregates all test results
- Generates HTML report with xchtmlreport
- Creates summary in GitHub Actions
- Sends Slack notification
- Duration: ~2 minutes
```

**Total Duration:** ~30-40 minutes

**Notification:** Slack message with summary

### 3. Release Workflow (Future)

**Trigger:** Tag push (e.g., `v1.0.0`)

**Steps:**
1. Run full test suite
2. Build release candidate
3. Upload to TestFlight (internal)
4. Create GitHub release with notes
5. Notify team on Slack

---

## Local Testing

### Prerequisites

```bash
# Install dependencies
brew install swiftlint xcpretty

# Verify Xcode version
xcodebuild -version
# Should be: Xcode 15.2 or later
```

### Run All Tests Locally

```bash
# Full test suite
xcodebuild test \
  -scheme FocusPal \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -enableCodeCoverage YES \
  | xcpretty
```

### Run Specific Test Suites

```bash
# Unit tests only
xcodebuild test \
  -scheme FocusPal \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -only-testing:FocusPalTests

# Integration tests only
xcodebuild test \
  -scheme FocusPal \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -only-testing:FocusPalTests/Integration

# UI tests only
xcodebuild test \
  -scheme FocusPal \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -only-testing:FocusPalUITests

# Specific test class
xcodebuild test \
  -scheme FocusPal \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -only-testing:FocusPalTests/TimerViewModelTests

# Specific test method
xcodebuild test \
  -scheme FocusPal \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -only-testing:FocusPalTests/TimerViewModelTests/test_startTimer_whenCalled_startsTimerService
```

### Run Tests from Xcode

1. Open `FocusPal.xcodeproj`
2. Select test scheme (⌘+<)
3. Select device/simulator
4. Run tests:
   - All tests: ⌘+U
   - Specific test: Click diamond next to test
   - Test class: Click diamond next to class

### Generate Coverage Report Locally

```bash
# Run tests with coverage
xcodebuild test \
  -scheme FocusPal \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# View coverage
xccov view --report TestResults.xcresult

# Generate HTML report
xcrun xccov view --report --json TestResults.xcresult > coverage.json
```

---

## Test Execution Strategy

### Test Levels & Frequency

| Test Level | Frequency | Duration | Devices | Coverage |
|------------|-----------|----------|---------|----------|
| Unit | Every PR | ~45s | 1 (iPhone 14) | 70% of suite |
| Integration | Every PR | ~30s | 1 (iPhone 14) | 20% of suite |
| UI (Critical) | Every PR | ~2min | 3 devices | 10% of suite |
| UI (Full) | Nightly | ~10min | 5 devices, 2 OS | All UI tests |
| Accessibility | Nightly | ~3min | 1 device | Accessibility only |
| Performance | Nightly | ~3min | 1 device | Benchmarks |
| Memory | Nightly | ~5min | 1 device | Leak detection |

### Parallel Execution

**Pull Request (Parallel):**
```
┌──────────┐  ┌──────────┐  ┌──────────┐
│  Lint    │  │  Unit    │  │  Build   │
│  30s     │  │  Tests   │  │  90s     │
│          │  │  45s     │  │          │
└──────────┘  └──────────┘  └──────────┘
      │             │             │
      └─────────────┴─────────────┘
                    │
          ┌─────────▼─────────┐
          │ Integration Tests │
          │       30s         │
          └─────────┬─────────┘
                    │
       ┌────────────┼────────────┐
       │            │            │
   ┌───▼───┐   ┌───▼───┐   ┌───▼───┐
   │iPhone │   │iPhone │   │ iPad  │
   │  SE   │   │  14   │   │       │
   │UI Tests│   │UI Tests│   │UI Tests│
   │ 2min  │   │ 2min  │   │ 2min  │
   └───┬───┘   └───┬───┘   └───┬───┘
       └───────────┼───────────┘
                   │
            ┌──────▼──────┐
            │  Coverage   │
            │   Check     │
            │    10s      │
            └─────────────┘

Total Wall Time: ~3-4 minutes (with parallelization)
```

### Test Prioritization

**Critical Path Tests (Must Pass on Every PR):**
1. Onboarding flow (UI-001)
2. Timer start/stop/complete (UI-003)
3. Activity logging (UI-004, UI-005)
4. Parent authentication (UT-PAV-001 to 012)
5. Multi-child data isolation (IT-MC-001 to 006)

**Extended Tests (Nightly Only):**
1. All device/OS combinations
2. Accessibility audit
3. Performance benchmarks
4. Memory leak detection
5. Edge case scenarios

---

## Device Farm Integration

### AWS Device Farm Setup (Future)

For real device testing beyond simulators:

```yaml
# .github/workflows/device-farm.yml
name: Device Farm Tests

on:
  schedule:
    - cron: '0 6 * * 1' # Weekly on Monday

jobs:
  device-farm:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Build for device
        run: |
          xcodebuild build-for-testing \
            -scheme FocusPal \
            -sdk iphoneos \
            -configuration Release

      - name: Upload to Device Farm
        run: |
          aws devicefarm create-upload \
            --project-arn ${{ secrets.DEVICE_FARM_PROJECT_ARN }} \
            --name FocusPal.ipa \
            --type IOS_APP

      - name: Run tests on real devices
        run: |
          aws devicefarm schedule-run \
            --project-arn ${{ secrets.DEVICE_FARM_PROJECT_ARN }} \
            --device-pool-arn ${{ secrets.DEVICE_FARM_POOL_ARN }} \
            --test ios-xctest
```

**Recommended Device Pool:**
- iPhone 12 (iOS 16.5)
- iPhone 13 Pro (iOS 17.0)
- iPhone 14 (iOS 17.2)
- iPad Air 5th gen (iPadOS 16.5)
- iPad Pro 12.9" (iPadOS 17.2)

**Test Frequency:** Weekly
**Cost Estimate:** ~$250/month (Device Farm pricing)

---

## Performance Monitoring

### Metrics Tracked

#### Timer Accuracy
```swift
func test_timerAccuracy_over30Minutes_withinTolerance() {
    measure(metrics: [XCTClockMetric()]) {
        // Start 30-minute timer
        // Verify actual duration: 1800s ± 0.1s
    }

    // Baseline: 1800.00s
    // Current: 1800.08s
    // Status: ✅ PASS (within ±0.1s)
}
```

#### Chart Rendering
```swift
func test_chartRendering_1000Activities_under500ms() {
    measure(metrics: [XCTClockMetric()]) {
        // Render daily chart with 1000 activities
    }

    // Baseline: 300ms
    // Current: 285ms
    // Status: ✅ PASS (< 500ms target)
}
```

#### App Launch Time
```swift
func test_appLaunch_coldStart_under2Seconds() {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
        XCUIApplication().launch()
    }

    // Baseline: 1.8s
    // Current: 1.75s
    // Status: ✅ PASS (< 2s target)
}
```

### Performance Regression Detection

If a test exceeds baseline by > 10%:
1. GitHub Action fails
2. Slack notification sent
3. Performance issue created automatically
4. Developer must investigate before merge

---

## Test Reporting

### Coverage Report (Codecov)

**Access:** https://codecov.io/gh/yourorg/focuspal

**Badges:**
```markdown
[![codecov](https://codecov.io/gh/yourorg/focuspal/branch/main/graph/badge.svg)](https://codecov.io/gh/yourorg/focuspal)
```

**Features:**
- Per-file coverage visualization
- Coverage diff on PRs
- Coverage trends over time
- Sunburst graphs for module coverage

### HTML Test Report

**Generated by:** xchtmlreport
**Location:** GitHub Actions artifacts
**Contents:**
- Test pass/fail summary
- Execution time per test
- Screenshots on failure
- Device/OS breakdown

### Slack Notifications

**Channels:**
- `#focuspal-ci` - All build notifications
- `#focuspal-alerts` - Failures on main branch only

**Message Format:**
```
✅ FocusPal Build Passed
Branch: main
Commit: abc1234 - "Add timer pause feature"
Author: @johndoe
Tests: 342 passed, 0 failed
Coverage: 83.2% (+0.5%)
Duration: 3m 42s
[View Report]
```

---

## Troubleshooting

### Common Issues

#### Issue: Tests Fail Only in CI

**Symptoms:**
- Tests pass locally but fail in GitHub Actions
- Intermittent failures
- Timeout errors

**Causes & Solutions:**

1. **Timing Issues**
   ```swift
   // ❌ BAD: Hardcoded sleep
   sleep(1)

   // ✅ GOOD: Wait with expectation
   wait(for: element, timeout: 5)
   ```

2. **Simulator Differences**
   - CI uses default simulator state
   - Local may have cached data
   - **Solution:** Reset simulator between runs

3. **Environment Variables**
   ```swift
   // Check for CI environment
   let isCI = ProcessInfo.processInfo.environment["CI"] == "true"

   if isCI {
       // Use longer timeouts
   }
   ```

#### Issue: Flaky UI Tests

**Symptoms:**
- Test passes sometimes, fails other times
- "Element not found" errors
- Animation timing issues

**Solutions:**

1. **Disable Animations in Tests**
   ```swift
   app.launchEnvironment["UITEST_DISABLE_ANIMATIONS"] = "1"
   ```

2. **Wait for Hittability**
   ```swift
   XCTAssertTrue(button.waitForExistence(timeout: 5))
   XCTAssertTrue(button.isHittable)
   button.tap()
   ```

3. **Increase Timeouts in CI**
   ```swift
   let timeout: TimeInterval = isCI ? 10 : 5
   wait(for: element, timeout: timeout)
   ```

#### Issue: Code Coverage Drops Unexpectedly

**Symptoms:**
- Coverage below 80% threshold
- PR blocked
- No obvious code changes

**Solutions:**

1. **Check Coverage Report**
   - Download coverage.json from artifacts
   - Identify uncovered lines
   - Add missing tests

2. **Exclude Generated Code**
   ```swift
   // swiftlint:disable:next coverage_exclusion
   func generatedMethod() {
       // This code won't count against coverage
   }
   ```

3. **Verify Test Execution**
   - Check test logs for skipped tests
   - Ensure all test targets included

#### Issue: Build Takes Too Long

**Symptoms:**
- CI exceeds 10 minutes
- Timeout errors
- Developers frustrated with slow feedback

**Solutions:**

1. **Optimize Test Execution**
   ```yaml
   # Run tests in parallel
   -parallel-testing-enabled YES
   -maximum-concurrent-test-simulator-destinations 3
   ```

2. **Cache Dependencies**
   ```yaml
   - name: Cache Swift packages
     uses: actions/cache@v3
     with:
       path: .build
       key: ${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}
   ```

3. **Split Test Suites**
   - Run unit tests first (fast feedback)
   - Run UI tests only if unit tests pass

#### Issue: Memory Leak Detected

**Symptoms:**
- Address Sanitizer reports leaks
- Nightly build fails
- Memory usage grows during tests

**Solutions:**

1. **Identify Leak Source**
   ```
   ==12345==ERROR: LeakSanitizer: detected memory leaks
   Direct leak of 32 byte(s) in 1 object(s) allocated from:
       #0 TimerViewModel.startTimer()
       #1 TimerView.playButtonTapped()
   ```

2. **Common Causes**
   ```swift
   // ❌ Retain cycle
   timer.publisher.sink { [self] in
       self.updateUI()
   }

   // ✅ Weak self
   timer.publisher.sink { [weak self] in
       self?.updateUI()
   }
   ```

3. **Verify Fix**
   ```bash
   xcodebuild test \
     -enableAddressSanitizer YES \
     -only-testing:FocusPalTests/TimerViewModelTests
   ```

---

## Best Practices

### 1. Keep Tests Fast
- Unit tests should be < 50ms each
- Use in-memory Core Data for tests
- Mock network requests
- Disable animations in UI tests

### 2. Make Tests Deterministic
- No random data (use seeded generators)
- No current date (inject Date dependencies)
- No network calls (use mocks)
- No file system dependencies

### 3. Maintain Test Isolation
- Each test should be independent
- Clean up after tests (tearDown)
- Don't rely on test execution order
- Reset singletons between tests

### 4. Write Meaningful Tests
- Test behavior, not implementation
- Use descriptive test names
- Add comments for complex scenarios
- Keep tests simple and focused

### 5. Monitor Test Health
- Fix flaky tests immediately
- Keep coverage above 80%
- Review failed tests before merge
- Update tests with code changes

---

## Appendix

### Useful Commands

```bash
# List all simulators
xcrun simctl list devices

# Boot simulator
xcrun simctl boot "iPhone 14"

# Install app on simulator
xcrun simctl install booted path/to/app.app

# Reset simulator
xcrun simctl erase "iPhone 14"

# View test results
xcrun xcresulttool get --path TestResults.xcresult

# Convert xcresult to JSON
xcrun xcresulttool get --path TestResults.xcresult --format json

# Generate coverage report
xcrun xccov view --report TestResults.xcresult
```

### Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [XCUITest Guide](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/09-ui_testing.html)
- [GitHub Actions for iOS](https://docs.github.com/en/actions/guides/building-and-testing-ios)
- [Fastlane](https://fastlane.tools/) - Alternative CI/CD tool
- [Codecov Docs](https://docs.codecov.com/)

---

**End of CI/CD Testing Guide**
