# FocusPal - Master Project Brief

## Project Overview

**Project Name:** FocusPal  
**Type:** iOS/iPadOS Native Application  
**Target Audience:** Children ages 5-16 (primary), Parents (secondary)  
**Primary Purpose:** ADHD-friendly productivity timer and activity tracking app  
**Timeline:** 10 weeks to MVP  
**Technology Stack:** Swift, SwiftUI, Core Data, CloudKit, Combine

---

## Vision Statement

FocusPal helps children develop time awareness, self-regulation, and healthy digital habits through visual timers, activity tracking, and data-driven insights. It replaces expensive physical ADHD timers while providing comprehensive activity management in one app.

---

## Core Value Propositions

1. **Makes Time Visible** - Visual timer representations help children with time blindness see time passing
2. **Builds Self-Awareness** - Activity tracking reveals patterns and promotes balanced habits
3. **Empowers Independence** - Child-friendly interface promotes autonomous time management
4. **Supports Parents** - Oversight tools without being intrusive
5. **Evidence-Based Design** - Built on ADHD research and executive function development principles

---

## Target Users

### Primary Users (Children)
- **Ages 5-7:** Simple interface, picture-based, minimal text, 3 main categories
- **Ages 8-11:** Icon + text, gamification, simple charts, full category access
- **Ages 12-16:** Advanced analytics, goal-setting autonomy, privacy controls

### Secondary Users (Parents/Guardians)
- Manage multiple children (up to 8 profiles)
- Configure categories and set time goals
- View reports and analytics
- Customize app behavior per child

### Tertiary Users (Educators/Therapists)
- Future consideration for classroom/clinical use
- Group management capabilities (v2.0)

---

## Key Differentiators

1. **ADHD-Specific Design** - Not a generic timer app
2. **Visual Time Representation** - Multiple modes including Time Timer style
3. **Integrated Solution** - Timer + tracking + analytics in one app
4. **Multi-Child Support** - Rare in kids productivity apps
5. **Privacy-First** - COPPA compliant, local-first architecture
6. **Cost-Effective** - Physical Time Timer costs $25-40, digital solution offers more

---

## Core Features (MVP)

### 1. Visual ADHD Timer
- Multiple visualization modes (circular disk, progress bar, analog, digital)
- Customizable durations (1 min to 24 hours)
- Pomodoro Technique support
- Multi-sensory alerts (visual, audio, haptic)
- Background execution
- Timer presets for common activities

### 2. Activity Tracking
- Quick-log interface with large category buttons
- 9 main categories with customizable subcategories
- Manual time entry for retroactive logging
- Voice logging capability
- Activity history and notes

### 3. Multi-Child Support
- Up to 8 child profiles per family
- Individual avatars, themes, preferences
- Age-appropriate UI complexity
- Profile switching with optional authentication
- Separate data per child

### 4. Data Visualization
- Daily pie charts showing time distribution
- Weekly bar charts for trend analysis
- Balance meters comparing actual vs recommended time
- Achievement badges and streaks
- Historical comparisons

### 5. Parent Controls
- Secure PIN/biometric authentication
- Category and subcategory management
- Time goal recommendations per category
- Comprehensive activity reports
- Export to PDF/CSV
- Notification preferences

### 6. Onboarding & Setup
- First-time user tutorial
- Profile creation wizard
- Privacy and permissions setup
- Feature introduction

---

## Technical Architecture

### Platform Requirements
- **Minimum iOS:** 16.0 (for latest Screen Time APIs)
- **Devices:** Universal (iPhone and iPad)
- **Orientations:** Portrait and Landscape
- **Themes:** Light and Dark mode support

### Architecture Pattern
- **MVVM** (Model-View-ViewModel)
- **Coordinator Pattern** for navigation
- **Repository Pattern** for data access
- **Service Layer** for business logic
- **Dependency Injection** via SwiftUI Environment

### Core Technologies
- **UI Framework:** SwiftUI
- **Reactive Programming:** Combine
- **Local Storage:** Core Data with encryption
- **Cloud Sync:** CloudKit (optional)
- **Charts:** Swift Charts framework
- **Notifications:** UserNotifications framework
- **Authentication:** LocalAuthentication (Face ID/Touch ID)
- **Background Tasks:** Background Tasks framework

### Data Models (Core Data)

**Child**
- id: UUID
- name: String
- age: Int16
- avatarId: String
- preferences: JSON
- createdDate: Date

**Activity**
- id: UUID
- categoryId: UUID
- childId: UUID
- startTime: Date
- endTime: Date
- duration: Int32 (seconds)
- notes: String?
- mood: Int16? (1-5 scale)
- isManualEntry: Bool

**Category**
- id: UUID
- name: String
- iconName: String
- colorHex: String
- parentCategoryId: UUID? (for subcategories)
- isActive: Bool
- sortOrder: Int16
- childId: UUID

**TimeGoal**
- id: UUID
- categoryId: UUID
- childId: UUID
- recommendedMinutes: Int32
- warningThreshold: Int16 (percentage)
- isActive: Bool

**Achievement**
- id: UUID
- achievementType: String
- name: String
- description: String
- unlockedDate: Date?
- childId: UUID

---

## Design System

### Color Palette
**Primary Colors:**
- Indigo: #6366F1
- Purple: #A855F7
- Pink: #EC4899
- Orange: #F97316
- Cyan: #06B6D4

**Category Colors:**
- Homework: #FF6B6B (Red)
- Creative Play: #4ECDC4 (Turquoise)
- Physical Activity: #FFD93D (Yellow)
- Screen Time: #A78BFA (Purple)
- Reading: #F472B6 (Pink)
- Social Time: #34D399 (Green)
- Life Skills: #FB923C (Orange)
- Rest & Self-Care: #818CF8 (Indigo)

**Semantic Colors:**
- Success: #10B981
- Warning: #F59E0B
- Error: #EF4444
- Info: #3B82F6

### Typography
**Font Family:** Fredoka (Primary), SF Pro (System fallback)

**Scale:**
- Display: 56pt, Bold
- Heading 1: 36pt, Bold
- Heading 2: 30pt, Bold
- Heading 3: 26pt, Bold
- Body Large: 22pt, Regular
- Body: 17pt, Regular
- Caption: 14pt, Regular
- Small: 12pt, Regular

### Spacing Scale
- XXS: 4pt
- XS: 8pt
- SM: 12pt
- MD: 16pt
- LG: 24pt
- XL: 32pt
- 2XL: 48pt
- 3XL: 64pt

### Border Radius
- Small: 8pt
- Medium: 12pt
- Large: 20pt
- XLarge: 24pt
- Round: 999pt (fully rounded)

### Shadows
- Small: 0px 1px 2px rgba(0,0,0,0.05)
- Medium: 0px 4px 6px rgba(0,0,0,0.1)
- Large: 0px 10px 15px rgba(0,0,0,0.1)
- XLarge: 0px 20px 25px rgba(0,0,0,0.15)

---

## Non-Functional Requirements

### Performance
- **App Launch:** <2 seconds (cold start)
- **Timer Accuracy:** ±0.1 seconds over 30 minutes
- **Chart Rendering:** <500ms for 30 days of data
- **Memory Usage:** <100MB typical, <150MB peak
- **Battery Drain:** <5% per hour with active timer
- **Animation:** 60 FPS minimum

### Accessibility
- Full VoiceOver support on all screens
- Dynamic Type support (XS to XXXL)
- Minimum contrast ratio: 4.5:1 (WCAG AA)
- Touch targets: minimum 44x44 points
- Support for Reduce Motion preference
- Closed captions for audio alerts
- Alternative text for all images

### Security & Privacy
- COPPA compliant (Children's Online Privacy Protection Act)
- All data encrypted at rest (Core Data encryption)
- Optional end-to-end encryption for CloudKit
- No third-party analytics or tracking
- Local authentication (PIN/biometric) for parent controls
- Secure Keychain storage for credentials
- Parents can export and delete all data

### Reliability
- Graceful offline mode
- Auto-save all changes
- Conflict resolution for sync
- Error recovery without data loss
- Background timer continues reliably

---

## Success Metrics

### Engagement Metrics
- Daily Active Users (DAU): 70% of registered children
- Activities logged per day: 5-8 average
- Timer sessions per active day: 3+ minimum
- 30-day retention rate: 60%+
- Weekly active users: 80%+

### Behavioral Outcomes
- Reduction in parental time prompting (parent survey)
- Improved task completion rates (activity data)
- More balanced activity distribution (reduced variance)
- Increased homework time consistency week-over-week

### Parent Satisfaction
- Net Promoter Score (NPS): 50+
- Parent dashboard usage: 80% check weekly
- Perceived value: 75% rate as "very helpful" or higher
- Subscription renewal rate: 70%+ for premium

### Technical Metrics
- Crash-free rate: 99.5%+
- App Store rating: 4.5+ stars
- Bug escape rate: <2% to production
- Code coverage: 80%+

---

## Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Low child engagement | High | Medium | Extensive user testing, gamification, reward systems |
| Privacy/data breach | Critical | Low | E2E encryption, security audits, minimal data collection |
| Over-reliance on technology | Medium | Medium | Educational content, promotes offline activities, usage limits |
| Competitive market | Medium | High | ADHD-specific focus, superior UX, clinical partnerships |
| iOS API changes | Medium | Low | Use stable APIs, modular architecture, regular updates |
| Core Data performance | Medium | Medium | Optimize queries, implement caching, background processing |
| Timer accuracy issues | High | Low | Thorough testing, use system Timer API, background tasks |

---

## Constraints

### Technical Constraints
- Must support iOS 16.0+ (excludes older devices)
- No web version for MVP
- Limited to Apple ecosystem
- CloudKit requires iCloud account

### Business Constraints
- Single developer team
- 10-week MVP timeline
- Limited initial budget
- App Store guidelines compliance required

### Design Constraints
- Must be kid-friendly (ages 5+)
- Must work on small screens (iPhone SE)
- Must support accessibility features
- Must follow Apple HIG

---

## Development Phases

### Phase 1: Planning & Architecture (Week 1)
- Requirements finalization
- Architecture design
- Core Data schema design
- Design system creation
- Project setup

### Phase 2: Foundation (Week 2)
- Navigation framework
- Design system components
- Core Data stack
- User profile management
- Onboarding flow

### Phase 3: Core Features (Weeks 3-6)
- Visual timer implementation
- Activity tracking system
- Category management
- Data visualization
- Basic parent controls

### Phase 4: Advanced Features (Week 7-8)
- Achievement system
- Export functionality
- CloudKit sync
- Advanced analytics
- Polish and refinement

### Phase 5: Testing & QA (Week 9)
- Comprehensive testing
- Bug fixing
- Performance optimization
- Accessibility audit
- Security review

### Phase 6: Launch Prep (Week 10)
- TestFlight distribution
- Beta testing
- App Store submission
- Marketing materials
- Support documentation

---

## Monetization Strategy

### Free Tier
- 1 child profile
- Basic timer (2 visualization modes)
- 6 main categories
- 7-day historical data
- Basic charts

### Premium Tier ($4.99/month or $39.99/year)
- Up to 8 child profiles
- All timer modes
- Unlimited categories
- Unlimited historical data
- CloudKit sync
- Advanced analytics
- PDF/CSV export
- Gamification features
- Priority support

### Educational/Clinical Tier ($9.99/month)
- Up to 30 profiles
- Class management tools
- Aggregated analytics
- Progress reports
- FERPA compliance

---

## Compliance & Legal

### Required Compliance
- **COPPA** (Children's Online Privacy Protection Act)
- **Apple App Store Guidelines**
- **GDPR** (for EU users)
- **CCPA** (for California users)
- **FERPA** (for educational tier)

### Privacy Policy Requirements
- Clear data collection disclosure
- Parental consent mechanisms
- Data retention policies
- Right to deletion
- Contact information

### Terms of Service
- Age restrictions
- Acceptable use policy
- Liability limitations
- Intellectual property rights
- Subscription terms

---

## Support & Documentation

### User Documentation
- In-app help system
- Video tutorials
- FAQ section
- Troubleshooting guide
- Parent guide

### Technical Documentation
- API documentation
- Architecture diagrams
- Database schema
- Code style guide
- Contributing guidelines

---

## Future Roadmap (Post-MVP)

### Version 1.5 (3 months post-launch)
- Apple Watch companion app
- Advanced gamification (virtual pet)
- Emotional regulation tools
- Focus enhancement features
- Improved parent dashboard

### Version 2.0 (6 months post-launch)
- Routine and habit builder
- Family challenges (social features)
- AI-powered insights
- Integration with Screen Time API
- Educational content library

### Version 3.0 (12 months post-launch)
- Android version
- Web dashboard for parents
- API for third-party integrations
- Advanced reporting and analytics
- Multi-language support

---

## Contact & Stakeholders

**Project Owner:** [Your Name]  
**Development Team:** Claude Code Agent Team  
**Timeline:** [Start Date] to [Target Launch Date]  
**Repository:** [Git Repository URL]  
**Project Board:** [Project Management Tool URL]

---

## Document Control

**Version:** 1.0  
**Last Updated:** [Current Date]  
**Next Review:** Weekly during development  
**Owner:** Requirements Agent  
**Approvers:** All agent teams

---

**This document serves as the single source of truth for all development agents. All agents must reference this document and keep it updated with any architectural decisions or requirement changes.**
