# DevOps & Deployment - FocusPal

**Owner:** DevOps Agent

## Build Configuration

### Xcode Schemes

**Development**
- Bundle ID: com.focuspal.dev
- CloudKit container: Development
- Debug symbols: Yes
- Optimizations: Off
- API endpoints: Dev/staging

**Staging**
- Bundle ID: com.focuspal.staging
- CloudKit container: Development
- Debug symbols: Yes
- Optimizations: On
- API endpoints: Staging

**Production**
- Bundle ID: com.focuspal.app
- CloudKit container: Production
- Debug symbols: No
- Optimizations: On
- API endpoints: Production

### Build Settings (.xcconfig files)

**Development.xcconfig**
```
PRODUCT_BUNDLE_IDENTIFIER = com.focuspal.dev
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG
ENABLE_TESTABILITY = YES
```

**Production.xcconfig**
```
PRODUCT_BUNDLE_IDENTIFIER = com.focuspal.app
SWIFT_ACTIVE_COMPILATION_CONDITIONS = RELEASE
ENABLE_TESTABILITY = NO
```

## CI/CD Pipeline (Xcode Cloud)

### Workflow: Pull Request
**Trigger:** On PR to main  
**Actions:**
1. Run SwiftLint
2. Build project
3. Run unit tests
4. Run integration tests
5. Generate coverage report
6. Report status to GitHub

### Workflow: Merge to Main
**Trigger:** On merge to main  
**Actions:**
1. Run full test suite
2. Build debug version
3. Create TestFlight build
4. Upload to TestFlight (Internal)
5. Notify team

### Workflow: Release
**Trigger:** On tag (v*)  
**Actions:**
1. Run full test suite
2. Build release version
3. Archive app
4. Upload to App Store Connect
5. Submit for review (manual approval)

## Fastlane Configuration

### Fastfile
```ruby
default_platform(:ios)

platform :ios do
  desc "Run tests"
  lane :test do
    run_tests(
      workspace: "FocusPal.xcworkspace",
      scheme: "FocusPal",
      devices: ["iPhone 15 Pro"],
      code_coverage: true
    )
  end

  desc "Build for TestFlight"
  lane :beta do
    increment_build_number(xcodeproj: "FocusPal.xcodeproj")
    build_app(
      workspace: "FocusPal.xcworkspace",
      scheme: "FocusPal",
      export_method: "app-store"
    )
    upload_to_testflight(skip_waiting_for_build_processing: true)
    slack(message: "New TestFlight build available!")
  end

  desc "Deploy to App Store"
  lane :release do
    build_app(
      workspace: "FocusPal.xcworkspace",
      scheme: "FocusPal-Production",
      export_method: "app-store"
    )
    upload_to_app_store(
      skip_metadata: false,
      skip_screenshots: false,
      submit_for_review: true,
      automatic_release: false
    )
  end

  desc "Capture screenshots"
  lane :screenshots do
    capture_screenshots(
      workspace: "FocusPal.xcworkspace",
      scheme: "FocusPal-UITests"
    )
  end
end
```

## Code Signing

### Certificates
- Development: Apple Development
- Distribution: Apple Distribution

### Provisioning Profiles
- Development: Automatic
- App Store: Manual (managed in Apple Developer Portal)

### Keychain Setup
```bash
# Create keychain
security create-keychain -p "" build.keychain
security default-keychain -s build.keychain
security unlock-keychain -p "" build.keychain

# Import certificates
security import cert.p12 -k build.keychain -P $CERT_PASSWORD -T /usr/bin/codesign
```

## Version Management

### Semantic Versioning
Format: MAJOR.MINOR.PATCH (e.g., 1.2.3)

- MAJOR: Breaking changes, major features
- MINOR: New features, non-breaking
- PATCH: Bug fixes

### Build Number
Auto-incremented on each TestFlight build

### Version Tracking
```bash
# Get current version
agvtool what-marketing-version

# Bump version
agvtool new-marketing-version 1.1.0

# Bump build number
agvtool next-version -all
```

## TestFlight Distribution

### Internal Testing
- Target: Development team
- Frequency: Daily (on merge to main)
- Duration: 1-2 days
- Feedback: Via Slack/GitHub issues

### External Testing
- Target: Beta testers (50-100 users)
- Frequency: Weekly
- Duration: 1-2 weeks
- Feedback: Via TestFlight feedback + support email

### Beta Tester Groups
1. **Family & Friends** - 10 users
2. **ADHD Community** - 30 users
3. **Educators** - 10 users

## App Store Submission

### Pre-Submission Checklist
- [ ] All features tested
- [ ] No critical bugs
- [ ] Test coverage > 80%
- [ ] Performance benchmarks met
- [ ] Privacy policy updated
- [ ] Screenshots captured (all device sizes)
- [ ] App preview video created
- [ ] Metadata localized
- [ ] Keywords optimized
- [ ] Support URL functional
- [ ] Age rating determined

### App Store Metadata

**Title:** FocusPal - ADHD Timer & Tracker

**Subtitle:** Visual timer and activity tracking for kids

**Description:**
```
Help your child develop time awareness and healthy habits!

FocusPal is designed specifically for children with ADHD and executive function challenges. Our visual timer makes time tangible, helping kids understand how much time remains for homework, play, or any activity.

VISUAL TIMER
• Time Timer-style disappearing disk
• Color-coded time zones (green → yellow → red)
• Pomodoro technique support
• Multiple visualization modes

ACTIVITY TRACKING
• Quick-log activities with one tap
• Track homework, play, screen time, and more
• See patterns over time
• Build healthy habits

FOR PARENTS
• Manage multiple children
• Set time goals
• View comprehensive reports
• Export data to share with therapists

PRIVACY FIRST
• No third-party tracking
• Local-first data storage
• Optional cloud sync via iCloud
• COPPA compliant

FocusPal helps build independence, self-awareness, and executive function skills through evidence-based design.
```

**Keywords:**
ADHD, timer, kids, children, productivity, focus, time management, activities, tracker, executive function, time timer, pomodoro, parental controls

**Screenshots Needed:**
- 6.7" (iPhone 15 Pro Max): 6 screenshots
- 5.5" (iPhone 8 Plus): 6 screenshots
- 12.9" (iPad Pro): 6 screenshots

### Screenshot Plan
1. Timer with circular visualization
2. Activity logging interface
3. Weekly progress chart
4. Achievement badges
5. Parent dashboard
6. Multi-child profiles

## Monitoring & Analytics

### Crash Reporting
**Tool:** Firebase Crashlytics

```swift
// AppDelegate
func application(_ application: UIApplication, 
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure()
    return true
}
```

### Analytics
**Tool:** Firebase Analytics (privacy-compliant)

**Events to Track:**
- app_open
- timer_start
- timer_complete
- activity_logged
- achievement_unlocked
- profile_created
- feature_used (with feature name)

**No PII Collected:**
- No names, ages, or personal data
- Aggregate usage patterns only
- Compliant with COPPA

### Performance Monitoring
- App launch time
- Screen load times
- Network request duration
- Core Data query performance

## Release Process

### 1. Code Freeze
- No new features
- Bug fixes only
- Final testing begins

### 2. Release Branch
```bash
git checkout -b release/1.0.0
git push origin release/1.0.0
```

### 3. Build & Test
- Build release version
- Run full test suite
- Perform manual QA
- Fix any critical bugs

### 4. TestFlight
- Upload to TestFlight
- Internal testing (2 days)
- External testing (1 week)
- Collect feedback

### 5. App Store Submission
```bash
fastlane release
```
- Upload to App Store Connect
- Submit for review
- Response time: 24-48 hours typically

### 6. Release
- Approve for release (manual or auto)
- Monitor crash reports
- Monitor user feedback
- Prepare hotfix if needed

### 7. Post-Release
- Tag release in git
- Update changelog
- Announce on social media
- Monitor reviews

## Hotfix Process

**For critical bugs in production:**

1. Create hotfix branch from production tag
```bash
git checkout -b hotfix/1.0.1 v1.0.0
```

2. Fix bug and test thoroughly

3. Increment patch version
```bash
agvtool new-marketing-version 1.0.1
```

4. Build and submit
```bash
fastlane release
```

5. Request expedited review
6. Merge hotfix to main and develop

## Environment Variables

### Development
```
API_BASE_URL=https://dev.focuspal.com/api
CLOUDKIT_CONTAINER=iCloud.com.focuspal.dev
ANALYTICS_ENABLED=false
```

### Production
```
API_BASE_URL=https://api.focuspal.com
CLOUDKIT_CONTAINER=iCloud.com.focuspal.app
ANALYTICS_ENABLED=true
```

## Backup & Recovery

### Daily Backups
- Automated via Xcode Cloud
- Stored in iCloud
- Retention: 30 days

### Version Control
- Git repository: GitHub
- Branching strategy: Git Flow
- Protected branches: main, develop

## Support Infrastructure

### Support Channels
- Email: support@focuspal.com
- In-app feedback form
- GitHub issues (for bugs)

### Response Times
- Critical (P0): 4 hours
- High (P1): 24 hours
- Medium (P2): 3 days
- Low (P3): 1 week

## DevOps Agent Responsibilities

1. Maintain CI/CD pipelines
2. Manage build configurations
3. Handle code signing
4. Coordinate releases
5. Monitor app health
6. Respond to crashes
7. Maintain infrastructure
8. Document processes
