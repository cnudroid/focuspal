# Agent Coordination Guide - FocusPal

**Purpose:** Enable all agents to work in parallel while maintaining integration

---

## Daily Standup Template

**Time:** 9:00 AM (Virtual/Async)

Each agent reports:
1. What I completed yesterday
2. What I'm working on today
3. Any blockers

**Example:**
```
Development Agent:
- Completed: Core Data stack setup (Task 1.2)
- Today: Implementing ChildRepository (Task 1.3)
- Blockers: None

UI/UX Agent:
- Completed: Color palette and typography system
- Today: Building button components
- Blockers: Waiting for Fredoka font license confirmation

Testing Agent:
- Completed: Test infrastructure setup
- Today: Writing ViewModel test templates
- Blockers: Need mock services from Development Agent
```

---

## Parallel Work Streams

### Week 1-2: Foundation

**Requirements Agent:**
- ✅ DONE: User stories created
- Work on: Edge case documentation
- Output: Update acceptance criteria

**Architecture Agent:**
- Create Core Data model file
- Design service protocols
- Document architecture decisions
- Output: Complete architecture spec

**UI/UX Agent:**
- Implement design system (colors, typography)
- Create component library
- Design mockups for all screens
- Output: Figma designs + Swift components

**Development Agent:**
- Set up Xcode project
- Implement Core Data stack
- Create repository layer
- Output: Working foundation code

**Testing Agent:**
- Set up test targets
- Create mock object templates
- Write test infrastructure
- Output: Test templates ready

**QA Agent:**
- Review architecture decisions
- Set up SwiftLint
- Create code review template
- Output: Quality guidelines

**DevOps Agent:**
- Set up Git repository
- Configure Xcode Cloud
- Create Fastlane scripts
- Output: CI/CD pipeline

---

## Integration Points

### Daily Integration
**Time:** 5:00 PM

**Process:**
1. Development Agent pushes code
2. CI/CD runs (DevOps)
3. Tests run (Testing Agent verifies)
4. QA reviews code
5. Issues logged and assigned

### Weekly Integration
**Time:** Friday 3:00 PM

**Process:**
1. Demo completed features
2. Review progress vs plan
3. Adjust next week's tasks
4. Update documentation

---

## Communication Protocols

### Urgent Issues (P0/P1 bugs)
**Channel:** #urgent-focuspal
**Response Time:** 1 hour
**Notify:** All agents

### Questions/Clarifications
**Channel:** #focuspal-questions
**Response Time:** 4 hours

### Code Reviews
**Channel:** GitHub Pull Requests
**Response Time:** 24 hours
**Required Reviewers:** QA Agent + 1 other

### Design Reviews
**Channel:** #focuspal-design
**Response Time:** 24 hours
**Required Reviewers:** UI/UX + Product Owner

---

## Dependency Management

### Agent Dependencies

**Development Agent depends on:**
- Architecture Agent: Service protocols, data models
- UI/UX Agent: Design system components
- Requirements Agent: User stories, acceptance criteria

**Testing Agent depends on:**
- Development Agent: Code to test, mock interfaces
- Requirements Agent: Acceptance criteria

**QA Agent depends on:**
- All agents: Code/designs to review

**DevOps Agent depends on:**
- Development Agent: Buildable code
- Testing Agent: Test suite

### Breaking Changes Protocol

**If you need to make a breaking change:**

1. Announce in #focuspal-breaking-changes
2. Wait 24 hours for objections
3. Create migration guide
4. Update affected code
5. Notify dependent agents

---

## File Ownership

### Core Data Models
**Owner:** Architecture Agent  
**Reviewers:** Development Agent, QA Agent  
**Location:** `Core/Persistence/FocusPal.xcdatamodeld`

### Service Protocols
**Owner:** Architecture Agent  
**Implementer:** Development Agent  
**Location:** `Core/Services/Protocols/`

### UI Components
**Owner:** UI/UX Agent  
**Implementer:** Development Agent  
**Location:** `DesignSystem/Components/`

### Tests
**Owner:** Testing Agent  
**Reviewers:** Development Agent  
**Location:** `FocusPalTests/`

### Documentation
**Owners:** All agents (respective areas)  
**Location:** `docs/`

---

## Code Review Process

### Pull Request Template
```markdown
## Description
[What does this PR do?]

## Related User Story
US-X.X: [Story title]

## Type of Change
- [ ] New feature
- [ ] Bug fix
- [ ] Refactor
- [ ] Documentation

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Screenshots (if UI change)
[Add screenshots]

## Checklist
- [ ] Code follows style guide
- [ ] No SwiftLint warnings
- [ ] Tests pass
- [ ] Documentation updated
- [ ] No force unwraps

## Agent Sign-off
- [ ] Development Agent
- [ ] QA Agent
- [ ] [Additional reviewer if needed]
```

### Review Criteria

**Development Agent reviews for:**
- Code correctness
- Architecture compliance
- Best practices

**QA Agent reviews for:**
- Code quality
- Test coverage
- Performance
- Security

**UI/UX Agent reviews for:**
- Design system compliance
- Accessibility
- User experience

---

## Sprint Ceremonies

### Sprint Planning (Week Start)
**Duration:** 2 hours  
**Attendees:** All agents  
**Output:**
- Sprint backlog
- Task assignments
- Definition of done

### Sprint Review (Week End)
**Duration:** 1 hour  
**Attendees:** All agents + stakeholders  
**Output:**
- Demo of completed work
- Feedback collection
- Product backlog updates

### Sprint Retrospective (Week End)
**Duration:** 30 minutes  
**Attendees:** All agents  
**Output:**
- What went well
- What to improve
- Action items

---

## Conflict Resolution

### Technical Disagreements

1. **Discussion:** Agents discuss in #focuspal-tech
2. **Architecture Agent:** Makes recommendation
3. **Vote:** If still unclear, majority vote
4. **Document:** Decision recorded in ADR
5. **Move Forward:** Implement agreed solution

### Priority Conflicts

1. **Requirements Agent:** Reviews priorities
2. **Product Owner:** Makes final call
3. **Update:** Sprint backlog adjusted

---

## Knowledge Sharing

### Documentation
**Location:** `/docs` folder in repository

**Structure:**
```
docs/
├── architecture/
│   ├── decisions/      # ADRs
│   ├── diagrams/       # Architecture diagrams
│   └── patterns/       # Code patterns
├── design/
│   ├── components/     # Component specs
│   ├── mockups/        # Figma exports
│   └── guidelines/     # Design guidelines
├── development/
│   ├── setup/          # Getting started
│   ├── workflows/      # Development workflows
│   └── troubleshooting/
├── testing/
│   ├── strategies/     # Test strategies
│   └── data/           # Test data
└── deployment/
    ├── processes/      # Release processes
    └── runbooks/       # Operational guides
```

### Weekly Knowledge Share
**Time:** Friday 2:00 PM  
**Duration:** 30 minutes  
**Format:** One agent presents something learned this week

---

## Tools & Access

### Required Tools
- **Xcode:** Latest stable version
- **Git:** Version control
- **Fastlane:** Deployment automation
- **SwiftLint:** Code quality
- **Claude Code:** AI development assistant

### Access Required
- **GitHub:** Repository access
- **Xcode Cloud:** CI/CD access
- **App Store Connect:** Deployment access
- **Figma:** Design files (UI/UX Agent)
- **Slack:** Team communication

---

## Emergency Procedures

### Production Incident

**P0 Incident (App Down/Data Loss):**
1. DevOps Agent: Assess severity
2. All Agents: Stop current work
3. Development Agent: Investigate & fix
4. Testing Agent: Verify fix
5. DevOps Agent: Deploy hotfix
6. Post-mortem: Document learnings

**P1 Incident (Major Bug):**
1. QA Agent: Triage and assign
2. Development Agent: Fix in 24 hours
3. Testing Agent: Verify
4. DevOps Agent: Schedule deployment

---

## Success Metrics

### Agent Performance

**Development Agent:**
- Tasks completed per sprint
- Code review turnaround time
- Test coverage of submitted code

**Testing Agent:**
- Test coverage maintained
- Bugs caught before production
- Test suite execution time

**QA Agent:**
- Code review thoroughness
- Bugs found in review
- Quality gate enforcement

**DevOps Agent:**
- Deployment success rate
- CI/CD pipeline uptime
- Deployment frequency

---

## Weekly Schedule

**Monday:**
- 9:00 AM: Sprint Planning
- All Day: Deep work on assigned tasks

**Tuesday-Thursday:**
- 9:00 AM: Daily standup (async)
- All Day: Development & testing
- 5:00 PM: Daily integration

**Friday:**
- 9:00 AM: Daily standup (async)
- 2:00 PM: Knowledge share
- 3:00 PM: Sprint review
- 3:30 PM: Sprint retrospective
- 4:00 PM: Next sprint planning (if needed)

---

## Getting Started Checklist

### For Each Agent

- [ ] Read master project brief
- [ ] Read your specific agent documentation
- [ ] Set up development environment
- [ ] Join communication channels
- [ ] Access all necessary tools
- [ ] Review current sprint backlog
- [ ] Identify your first task
- [ ] Introduce yourself to team
- [ ] Set up daily standup routine
- [ ] Bookmark important documents

---

**Remember:** We succeed together. Communicate early and often. Ask questions. Help each other. Ship quality software. 🚀
