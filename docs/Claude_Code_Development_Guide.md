# FocusPal Development Guide - Using Claude Code with Agent-Based SDLC

## Overview
This guide outlines how to use Claude Code to build the FocusPal iOS/iPadOS app using specialized agents for different phases of the Software Development Life Cycle (SDLC).

## Table of Contents
1. [Initial Setup](#initial-setup)
2. [Agent Framework](#agent-framework)
3. [SDLC Phases & Agents](#sdlc-phases--agents)
4. [Project Structure](#project-structure)
5. [Development Workflow](#development-workflow)
6. [Agent Prompts & Instructions](#agent-prompts--instructions)

---

## Initial Setup

### Prerequisites
- macOS with Xcode 15+ installed
- Claude Code running on your laptop
- Apple Developer account (for deployment)
- Git installed

### Step 1: Create Project Directory
```bash
mkdir FocusPal
cd FocusPal
git init
```

### Step 2: Initialize Xcode Project
Open Claude Code and use this prompt:

```
I want to create a new iOS/iPadOS app called "FocusPal" using SwiftUI. 
Please create the initial Xcode project structure with:
- Target: iOS 16.0+
- Universal app (iPhone and iPad)
- SwiftUI lifecycle
- Proper folder structure for MVVM architecture
- Core Data stack setup
- Initial project configuration
```

---

## Agent Framework

### Agent Roles and Responsibilities

We'll use 7 specialized agents, each focusing on specific SDLC phases:

| Agent | Phase | Responsibilities |
|-------|-------|------------------|
| **Requirements Agent** | Planning | Clarify features, create user stories, define acceptance criteria |
| **Architecture Agent** | Design | Design system architecture, data models, API contracts |
| **UI/UX Agent** | Design | Create UI components, design system, accessibility |
| **Development Agent** | Implementation | Write code, implement features, follow best practices |
| **Testing Agent** | Testing | Write unit tests, integration tests, UI tests |
| **QA Agent** | Quality Assurance | Code review, performance analysis, security audit |
| **DevOps Agent** | Deployment | CI/CD setup, build configuration, TestFlight deployment |

---

## SDLC Phases & Agents

### Phase 1: Requirements & Planning (Week 1)

#### Requirements Agent Prompt Template:
```
You are the Requirements Agent for FocusPal, a kids productivity app.

Context: [Attach PRD document]

Your tasks:
1. Break down the PRD into user stories with acceptance criteria
2. Prioritize features into MVP, v1.5, and v2.0
3. Create a feature dependency map
4. Define technical requirements for each feature
5. Identify potential risks and edge cases

Please create:
- Epic breakdown with user stories
- Acceptance criteria for MVP features
- Technical specifications document
- Risk assessment matrix

Use the format:
Epic: [Name]
User Story: As a [user], I want [goal] so that [benefit]
Acceptance Criteria: Given [context], when [action], then [outcome]
```

#### Deliverables:
- User stories document (markdown)
- Feature priority matrix
- Technical requirements spec
- Risk assessment

---

### Phase 2: System Architecture (Week 1-2)

#### Architecture Agent Prompt Template:
```
You are the Architecture Agent for FocusPal.

Context: 
- iOS/iPadOS app using SwiftUI
- Core Data for local storage
- CloudKit for sync
- Target: iOS 16.0+
- MVVM architecture pattern

Your tasks:
1. Design the app architecture (MVVM with Coordinator pattern)
2. Define Core Data schema for all entities
3. Design the folder structure
4. Create dependency injection setup
5. Design service layer (TimerService, ActivityService, SyncService)
6. Plan navigation flow

Please create:
- Architecture diagram (describe in detail for PlantUML/Mermaid)
- Core Data model definitions
- Service layer interfaces
- Folder structure
- Dependency graph
```

#### Deliverables:
- Architecture documentation
- Core Data schema (.xcdatamodeld description)
- Service layer protocols
- Navigation coordinator structure
- Dependency injection setup

---

### Phase 3: UI/UX Development (Week 2-3)

#### UI/UX Agent Prompt Template:
```
You are the UI/UX Agent for FocusPal.

Context:
- Target audience: Kids 5-16 years old
- Need to be ADHD-friendly with clear visual hierarchy
- SwiftUI-based
- Support iPhone and iPad layouts
- Accessibility is critical

Your tasks:
1. Create a comprehensive design system
2. Implement reusable UI components
3. Design adaptive layouts for iPhone/iPad
4. Ensure WCAG accessibility compliance
5. Create animation specifications
6. Implement color scheme and typography

Please create:
- Design system documentation
- SwiftUI view components (buttons, cards, charts)
- Color palette with accessibility contrast ratios
- Typography scale
- Animation/transition specifications
- Accessibility guidelines

Start with: Design tokens (colors, spacing, typography) as Swift enums/structs
```

#### Deliverables:
- DesignSystem.swift (tokens and utilities)
- Reusable component library
- Accessibility documentation
- Animation specifications

---

### Phase 4: Core Feature Development (Week 3-8)

#### Development Agent Prompt Template:
```
You are the Development Agent for FocusPal.

Current Feature: [Feature Name from User Story]

Context:
- Architecture: MVVM
- Using Combine for reactive programming
- Core Data for persistence
- Following Swift best practices and SOLID principles

Your tasks:
1. Implement the feature according to the user story and acceptance criteria
2. Follow the established architecture patterns
3. Write clean, documented code
4. Implement proper error handling
5. Add logging for debugging
6. Consider performance and memory management

User Story:
[Paste specific user story]

Acceptance Criteria:
[Paste acceptance criteria]

Technical Requirements:
[Paste technical specs]

Please implement:
- View layer (SwiftUI views)
- ViewModel layer (business logic)
- Model layer (data models)
- Service integration
- Proper error handling
- Code comments and documentation

Follow the existing code structure in: [path to relevant files]
```

#### Feature Development Order (MVP):

**Sprint 1 (Week 3-4): Core Infrastructure**
1. User profile management (multi-child support)
2. Core Data stack with models
3. Navigation coordinator
4. Onboarding flow

**Sprint 2 (Week 4-5): Visual Timer**
1. Timer service with notifications
2. Visual timer component (circular/bar/clock views)
3. Timer presets
4. Background timer functionality
5. Sound and haptic feedback

**Sprint 3 (Week 5-6): Activity Tracking**
1. Category management system
2. Activity logging interface
3. Quick log functionality
4. Activity history storage
5. Time calculation and aggregation

**Sprint 4 (Week 6-7): Data Visualization**
1. Chart components (pie, bar, line)
2. Daily activity view
3. Weekly summary view
4. Progress indicators
5. Balance meter

**Sprint 5 (Week 7-8): Parent Controls**
1. Parent authentication
2. Settings and preferences
3. Category configuration
4. Goal setting interface
5. Report generation

---

### Phase 5: Testing (Ongoing, Week 3-8)

#### Testing Agent Prompt Template:
```
You are the Testing Agent for FocusPal.

Context:
- XCTest framework for unit and integration tests
- XCUITest for UI testing
- Aim for 80%+ code coverage
- Focus on critical paths and edge cases

Feature to Test: [Feature Name]

Your tasks:
1. Write comprehensive unit tests for ViewModels
2. Write integration tests for service layers
3. Create UI tests for critical user flows
4. Test edge cases and error scenarios
5. Verify accessibility features
6. Test on different device sizes

Please create:
- Unit test suite for [Component]
- Integration tests for [Service]
- UI test scenarios for [User Flow]
- Edge case test coverage
- Mock objects and test fixtures

Test Coverage Goals:
- ViewModels: 90%+
- Services: 85%+
- Models: 80%+
- Critical user flows: 100%

Current code to test:
[Paste relevant code]
```

#### Testing Checklist:
- [ ] Unit tests for all ViewModels
- [ ] Service layer integration tests
- [ ] Core Data CRUD operation tests
- [ ] Timer accuracy tests
- [ ] Activity calculation tests
- [ ] UI automation tests for main flows
- [ ] Accessibility audit tests
- [ ] Performance tests (launch time, memory)
- [ ] Device compatibility tests (iPhone SE to iPad Pro)

---

### Phase 6: Quality Assurance (Week 8-9)

#### QA Agent Prompt Template:
```
You are the QA Agent for FocusPal.

Your tasks:
1. Perform comprehensive code review
2. Check for code smells and anti-patterns
3. Verify architectural consistency
4. Audit security and privacy
5. Performance analysis
6. Memory leak detection
7. Accessibility compliance verification

Please review:
- Code quality and maintainability
- Swift best practices adherence
- Memory management (reference cycles, leaks)
- Performance bottlenecks
- Security vulnerabilities (data encryption, authentication)
- Privacy compliance (COPPA requirements)
- Accessibility (VoiceOver, Dynamic Type, contrast ratios)

Review this code:
[Paste code for review]

Provide:
- Issues found (categorized by severity: Critical/High/Medium/Low)
- Recommendations for improvement
- Refactoring suggestions
- Performance optimization opportunities
```

#### QA Deliverables:
- Code review reports
- Security audit findings
- Performance analysis report
- Accessibility compliance checklist
- Refactoring recommendations

---

### Phase 7: Deployment & DevOps (Week 9-10)

#### DevOps Agent Prompt Template:
```
You are the DevOps Agent for FocusPal.

Context:
- Xcode Cloud for CI/CD
- TestFlight for beta distribution
- App Store deployment
- Semantic versioning

Your tasks:
1. Set up Xcode Cloud workflows
2. Configure build settings for different environments (Dev/Staging/Prod)
3. Create TestFlight distribution setup
4. Prepare App Store submission materials
5. Set up crash reporting (Firebase Crashlytics)
6. Configure analytics (Firebase/Mixpanel)

Please create:
- Xcode Cloud workflow configuration
- Build configuration setup (schemes, targets)
- Fastlane scripts for automation
- TestFlight deployment guide
- App Store submission checklist
- Release notes template
```

#### Deployment Checklist:
- [ ] Build configurations (Debug, Release)
- [ ] Code signing and provisioning profiles
- [ ] Xcode Cloud CI/CD pipeline
- [ ] Automated testing in CI
- [ ] TestFlight beta distribution
- [ ] App Store screenshots and metadata
- [ ] Privacy policy and terms of service
- [ ] App Store submission

---

## Project Structure

```
FocusPal/
├── FocusPal/
│   ├── App/
│   │   ├── FocusPalApp.swift
│   │   ├── AppCoordinator.swift
│   │   └── AppDelegate.swift
│   │
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── Child.swift
│   │   │   ├── Activity.swift
│   │   │   ├── Category.swift
│   │   │   └── Achievement.swift
│   │   │
│   │   ├── Services/
│   │   │   ├── TimerService.swift
│   │   │   ├── ActivityService.swift
│   │   │   ├── CategoryService.swift
│   │   │   ├── SyncService.swift
│   │   │   ├── NotificationService.swift
│   │   │   └── AnalyticsService.swift
│   │   │
│   │   ├── Persistence/
│   │   │   ├── CoreDataStack.swift
│   │   │   ├── FocusPal.xcdatamodeld
│   │   │   └── Repositories/
│   │   │       ├── ChildRepository.swift
│   │   │       ├── ActivityRepository.swift
│   │   │       └── CategoryRepository.swift
│   │   │
│   │   └── Utilities/
│   │       ├── Constants.swift
│   │       ├── Extensions/
│   │       └── Helpers/
│   │
│   ├── Features/
│   │   ├── Home/
│   │   │   ├── Views/
│   │   │   │   ├── HomeView.swift
│   │   │   │   └── Components/
│   │   │   └── ViewModels/
│   │   │       └── HomeViewModel.swift
│   │   │
│   │   ├── Timer/
│   │   │   ├── Views/
│   │   │   │   ├── TimerView.swift
│   │   │   │   ├── CircularTimerView.swift
│   │   │   │   └── TimerControlsView.swift
│   │   │   └── ViewModels/
│   │   │       └── TimerViewModel.swift
│   │   │
│   │   ├── ActivityLog/
│   │   │   ├── Views/
│   │   │   └── ViewModels/
│   │   │
│   │   ├── Statistics/
│   │   │   ├── Views/
│   │   │   └── ViewModels/
│   │   │
│   │   ├── ParentControls/
│   │   │   ├── Views/
│   │   │   └── ViewModels/
│   │   │
│   │   └── Onboarding/
│   │       ├── Views/
│   │       └── ViewModels/
│   │
│   ├── DesignSystem/
│   │   ├── Tokens/
│   │   │   ├── Colors.swift
│   │   │   ├── Typography.swift
│   │   │   ├── Spacing.swift
│   │   │   └── Animations.swift
│   │   │
│   │   └── Components/
│   │       ├── Buttons/
│   │       ├── Cards/
│   │       ├── Charts/
│   │       └── Inputs/
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   ├── Localizable.strings
│   │   └── Sounds/
│   │
│   └── Supporting Files/
│       ├── Info.plist
│       └── FocusPal.entitlements
│
├── FocusPalTests/
│   ├── UnitTests/
│   │   ├── ViewModelTests/
│   │   ├── ServiceTests/
│   │   └── ModelTests/
│   │
│   └── IntegrationTests/
│       └── CoreDataTests/
│
├── FocusPalUITests/
│   ├── Flows/
│   └── Helpers/
│
├── fastlane/
│   ├── Fastfile
│   └── Appfile
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── docs/
│   ├── architecture/
│   ├── requirements/
│   └── testing/
│
└── README.md
```

---

## Development Workflow

### Daily Workflow with Claude Code

#### 1. Morning Planning Session
```
Prompt: "Acting as the Requirements Agent, review today's sprint tasks 
and provide a detailed breakdown of what needs to be implemented. 
Current sprint: [Sprint Name]. Focus on: [Feature]."
```

#### 2. Architecture Review
```
Prompt: "Acting as the Architecture Agent, review the proposed 
implementation approach for [Feature]. Ensure it aligns with our 
MVVM architecture and suggest any improvements."
```

#### 3. Implementation
```
Prompt: "Acting as the Development Agent, implement [specific feature] 
according to the user story and acceptance criteria. Follow the 
established patterns in [existing similar feature]."
```

#### 4. Testing
```
Prompt: "Acting as the Testing Agent, create comprehensive tests 
for the just-implemented [Feature]. Include unit tests, integration 
tests, and UI tests."
```

#### 5. Code Review
```
Prompt: "Acting as the QA Agent, review the implementation of [Feature]. 
Check for code quality, performance issues, and security concerns."
```

### Weekly Workflow

**Monday**: Sprint planning with Requirements Agent
**Tuesday-Thursday**: Development iterations
**Friday**: QA review, testing, and sprint retrospective

---

## Agent Prompts & Instructions

### Master Context Prompt (Use at start of each session)

```
You are working on FocusPal, a kids productivity and ADHD timer app for iOS/iPadOS.

PROJECT CONTEXT:
- Technology: Swift, SwiftUI, Core Data, CloudKit, Combine
- Architecture: MVVM with Coordinator pattern
- Target: iOS 16.0+, Universal (iPhone & iPad)
- Current Phase: [Planning/Design/Development/Testing/QA/Deployment]
- Current Sprint: [Sprint number and name]

KEY PRINCIPLES:
1. Child-friendly: Large touch targets, simple language, playful design
2. ADHD-focused: Visual time representation, minimal distractions
3. Privacy-first: COPPA compliant, local-first with optional sync
4. Accessible: Full VoiceOver support, Dynamic Type, high contrast
5. Performance: Smooth 60fps animations, <2s launch time

ARCHITECTURE PATTERNS:
- MVVM for feature modules
- Repository pattern for data access
- Service layer for business logic
- Coordinator pattern for navigation
- Dependency injection via SwiftUI Environment

You are currently acting as the [AGENT ROLE].
```

### Specialized Agent Instructions

#### Requirements Agent - Detailed Instructions
```
As the Requirements Agent, your focus is on clarity and completeness.

When breaking down features:
1. Start with the user's goal, not the technical solution
2. Define clear, measurable acceptance criteria
3. Identify edge cases and error scenarios
4. Consider accessibility requirements
5. Note performance expectations
6. Flag dependencies on other features

User Story Template:
Title: [Concise feature name]
As a [child user/parent user/system]
I want [goal]
So that [benefit]

Acceptance Criteria:
- Given [initial state]
  When [action]
  Then [expected result]
- [Additional criteria...]

Technical Notes:
- Dependencies: [List]
- Performance: [Requirements]
- Accessibility: [Considerations]
- Edge Cases: [List]

Definition of Done:
- [ ] Code implemented and peer reviewed
- [ ] Unit tests written (80%+ coverage)
- [ ] UI tests for critical paths
- [ ] Accessibility verified
- [ ] Documentation updated
```

#### Architecture Agent - Detailed Instructions
```
As the Architecture Agent, focus on scalability, maintainability, and patterns.

When designing solutions:
1. Follow SOLID principles
2. Prefer composition over inheritance
3. Keep ViewModels testable (no UIKit dependencies)
4. Use protocols for service abstractions
5. Consider future feature additions
6. Document architectural decisions (ADRs)

Architecture Decision Record Template:
Title: [Decision name]
Status: [Proposed/Accepted/Deprecated]
Context: [What is the issue we're addressing?]
Decision: [What is the change we're making?]
Consequences: [What becomes easier/harder?]

Code Organization:
- Features are self-contained modules
- Shared code goes in Core/
- Design system is separate from features
- Each feature has Views, ViewModels, and Models
- Services are injected, never singletons (except where truly needed)
```

#### Development Agent - Detailed Instructions
```
As the Development Agent, write production-quality code.

Code Quality Standards:
1. SwiftLint compliant
2. Meaningful variable names (no abbreviations)
3. Functions < 50 lines
4. View files < 300 lines (split into components)
5. Comprehensive error handling
6. Logging for debugging
7. Comments for complex logic only

SwiftUI Best Practices:
- Use @StateObject for ViewModels
- Use @EnvironmentObject for shared dependencies
- Prefer composition with small, reusable views
- Extract computed properties for readability
- Use ViewBuilder for conditional views
- Implement PreviewProvider for every view

Combine Best Practices:
- Cancel subscriptions properly
- Use Publishers.CombineLatest for multiple inputs
- Handle errors with catch or replaceError
- Use @Published for ViewModel state
- Keep pipelines readable with one operator per line
```

#### Testing Agent - Detailed Instructions
```
As the Testing Agent, ensure comprehensive test coverage.

Testing Philosophy:
- Test behavior, not implementation
- Aim for fast, independent, repeatable tests
- Mock external dependencies
- Test edge cases and error paths
- Write tests that document expected behavior

Unit Test Template (ViewModel):
```swift
import XCTest
@testable import FocusPal

final class [Feature]ViewModelTests: XCTestCase {
    var sut: [Feature]ViewModel!
    var mockService: Mock[Service]!
    
    override func setUp() {
        super.setUp()
        mockService = Mock[Service]()
        sut = [Feature]ViewModel(service: mockService)
    }
    
    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }
    
    func test_[scenario]_[expectedBehavior]() {
        // Given
        
        // When
        
        // Then
        XCTAssertEqual(...)
    }
}
```

UI Test Scenarios:
- Happy path for each user flow
- Error handling (network failure, invalid input)
- Accessibility (VoiceOver navigation)
- Different device sizes
- Dark mode vs light mode
```

---

## Getting Started Checklist

### Week 1: Setup and Planning
- [ ] Create Xcode project with Claude Code
- [ ] Set up Git repository and initial commit
- [ ] Have Requirements Agent create user stories
- [ ] Have Architecture Agent design system architecture
- [ ] Review and approve architecture
- [ ] Set up Core Data schema
- [ ] Create project folder structure
- [ ] Set up design system tokens

### Week 2: Foundation
- [ ] Implement navigation coordinator
- [ ] Set up dependency injection
- [ ] Create Core Data stack
- [ ] Implement basic repository pattern
- [ ] Create design system components
- [ ] Implement onboarding flow
- [ ] Set up user profile management

### Week 3-4: MVP Core Features
- [ ] Implement visual timer (all visualization modes)
- [ ] Add timer presets and customization
- [ ] Implement background timer functionality
- [ ] Add notifications and sounds
- [ ] Create category management
- [ ] Implement activity logging

### Week 5-6: Data & Analytics
- [ ] Implement data aggregation logic
- [ ] Create chart components
- [ ] Build statistics views
- [ ] Add achievement system
- [ ] Implement progress tracking

### Week 7-8: Parent Controls & Polish
- [ ] Implement parent authentication
- [ ] Create settings and preferences
- [ ] Add category configuration
- [ ] Implement CloudKit sync
- [ ] Polish UI/UX
- [ ] Optimize performance

### Week 9: Testing & QA
- [ ] Complete test coverage
- [ ] Perform QA review
- [ ] Fix critical bugs
- [ ] Accessibility audit
- [ ] Performance optimization

### Week 10: Launch Preparation
- [ ] Set up TestFlight
- [ ] Beta testing
- [ ] App Store assets
- [ ] Submit for review

---

## Sample Agent Interaction Flow

### Example: Implementing Visual Timer Feature

#### Step 1: Requirements
```
You: "Acting as Requirements Agent, break down the Visual Timer feature 
from the PRD into detailed user stories."

Claude Code: [Provides detailed user stories with acceptance criteria]
```

#### Step 2: Architecture
```
You: "Acting as Architecture Agent, design the timer system. Include:
- Timer service architecture
- State management approach
- Background execution strategy
- Notification integration"

Claude Code: [Provides architecture design with protocols and class structure]
```

#### Step 3: UI/UX
```
You: "Acting as UI/UX Agent, create the circular timer view component 
that shows time visually like a Time Timer device."

Claude Code: [Provides SwiftUI view with custom drawing]
```

#### Step 4: Implementation
```
You: "Acting as Development Agent, implement the TimerService according 
to the architecture design. Include all timer modes (countdown, pomodoro, etc.)"

Claude Code: [Provides complete service implementation]
```

#### Step 5: Testing
```
You: "Acting as Testing Agent, create comprehensive tests for TimerService 
and TimerViewModel."

Claude Code: [Provides unit tests]
```

#### Step 6: Review
```
You: "Acting as QA Agent, review the timer implementation for performance, 
accuracy, and edge cases."

Claude Code: [Provides code review with recommendations]
```

---

## Tips for Success with Claude Code

### 1. Be Specific with Context
Always provide:
- Which agent role you want
- Which feature/component you're working on
- Relevant existing code
- Specific requirements or constraints

### 2. Iterative Development
Don't try to build everything at once:
- Start with core functionality
- Add features incrementally
- Test as you go
- Refactor regularly

### 3. Maintain Continuity
Create a "session log" document:
- Track what was implemented each day
- Note important architectural decisions
- Keep a running list of TODOs
- Document any deviations from plan

### 4. Use Version Control Effectively
- Commit after each feature completion
- Use meaningful commit messages
- Create branches for experimental features
- Tag releases (v1.0-mvp, v1.5, etc.)

### 5. Regular Architecture Reviews
Every sprint:
- Review code organization
- Check for architectural drift
- Refactor if needed
- Update documentation

---

## Next Steps

1. **Right Now**: Use Requirements Agent to create detailed user stories
2. **Today**: Use Architecture Agent to design the core system
3. **This Week**: Set up the project structure with Development Agent
4. **Ongoing**: Use appropriate agents for each development task

---

## Support Resources

### When You Get Stuck
```
Prompt: "I'm stuck on [problem]. As the [relevant agent], help me:
1. Understand what's going wrong
2. Identify potential solutions
3. Recommend the best approach
4. Provide implementation guidance"
```

### Code Review Sessions
```
Prompt: "As the QA Agent, perform a comprehensive review of [file/feature].
Focus on:
- Code quality and maintainability
- Performance implications  
- Security concerns
- Accessibility compliance
- Test coverage gaps"
```

### Debugging Help
```
Prompt: "I'm getting [error/unexpected behavior] in [component].
Help me debug by:
1. Analyzing the error
2. Identifying likely causes
3. Suggesting debugging steps
4. Providing a fix"
```

---

## Success Metrics

Track these throughout development:

**Code Quality**
- [ ] SwiftLint violations < 10
- [ ] Test coverage > 80%
- [ ] No force unwraps in production code
- [ ] All public APIs documented

**Performance**
- [ ] App launch < 2 seconds
- [ ] Timer accuracy within 0.1s
- [ ] 60 FPS animations
- [ ] Memory usage < 100MB

**User Experience**
- [ ] All touch targets > 44pt
- [ ] VoiceOver fully functional
- [ ] Supports Dynamic Type
- [ ] Works on all device sizes

---

Ready to start? Begin with the Requirements Agent to create your user stories!
