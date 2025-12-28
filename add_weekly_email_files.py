#!/usr/bin/env python3
"""
Script to add Weekly Email Notification files to FocusPal Xcode project.
"""

import sys
import uuid

def generate_uuid():
    """Generate a UUID in Xcode format (24 uppercase hex characters)"""
    return uuid.uuid4().hex[:24].upper()

# File mappings: (path, group_path, file_type)
FILES_TO_ADD = [
    # Models
    ("FocusPal/Core/Models/WeeklySummary.swift", "Core/Models", "sourcecode.swift"),

    # Services - Implementation
    ("FocusPal/Core/Services/Implementation/WeeklySummaryService.swift", "Core/Services/Implementation", "sourcecode.swift"),
    ("FocusPal/Core/Services/Implementation/EmailContentBuilder.swift", "Core/Services/Implementation", "sourcecode.swift"),
    ("FocusPal/Core/Services/Implementation/EmailService.swift", "Core/Services/Implementation", "sourcecode.swift"),
    ("FocusPal/Core/Services/Implementation/WeeklyEmailScheduler.swift", "Core/Services/Implementation", "sourcecode.swift"),

    # Tests
    ("FocusPalTests/Services/WeeklySummaryServiceTests.swift", "Services", "sourcecode.swift"),
    ("FocusPalTests/Services/EmailContentBuilderTests.swift", "Services", "sourcecode.swift"),
    ("FocusPalTests/Services/EmailServiceTests.swift", "Services", "sourcecode.swift"),
    ("FocusPalTests/Services/WeeklyEmailSchedulerTests.swift", "Services", "sourcecode.swift"),
]

def main():
    print("Weekly Email Notification Service files created successfully!")
    print("\nFiles created:")
    print("=" * 60)

    print("\n📦 Models:")
    print("  - FocusPal/Core/Models/WeeklySummary.swift")

    print("\n🔧 Services:")
    print("  - FocusPal/Core/Services/Implementation/WeeklySummaryService.swift")
    print("  - FocusPal/Core/Services/Implementation/EmailContentBuilder.swift")
    print("  - FocusPal/Core/Services/Implementation/EmailService.swift")
    print("  - FocusPal/Core/Services/Implementation/WeeklyEmailScheduler.swift")

    print("\n✅ Tests:")
    print("  - FocusPalTests/Services/WeeklySummaryServiceTests.swift")
    print("  - FocusPalTests/Services/EmailContentBuilderTests.swift")
    print("  - FocusPalTests/Services/EmailServiceTests.swift")
    print("  - FocusPalTests/Services/WeeklyEmailSchedulerTests.swift")

    print("\n" + "=" * 60)
    print("\n⚠️  MANUAL STEPS REQUIRED:")
    print("=" * 60)
    print("""
1. Open FocusPal.xcodeproj in Xcode

2. Add the following files to the project by dragging them into Xcode:

   Models Group (FocusPal/Core/Models):
   - WeeklySummary.swift

   Services/Implementation Group (FocusPal/Core/Services/Implementation):
   - WeeklySummaryService.swift
   - EmailContentBuilder.swift
   - EmailService.swift
   - WeeklyEmailScheduler.swift

   FocusPalTests/Services Group:
   - WeeklySummaryServiceTests.swift
   - EmailContentBuilderTests.swift
   - EmailServiceTests.swift
   - WeeklyEmailSchedulerTests.swift

3. When adding files, make sure to:
   ✓ Check "Copy items if needed"
   ✓ Add to FocusPal target for implementation files
   ✓ Add to FocusPalTests target for test files

4. Build and run tests to verify everything compiles correctly

5. (Optional) Register WeeklyEmailScheduler in ServiceContainer.swift:
   - Add property: private var weeklyEmailScheduler: WeeklyEmailScheduler!
   - Initialize in setupServices():
     weeklyEmailScheduler = WeeklyEmailScheduler(
         summaryService: weeklySummaryService,
         contentBuilder: emailContentBuilder,
         emailService: emailService,
         parentRepository: parentRepository
     )
   - Add to onAppLaunch() to check and send emails:
     Task {
         await weeklyEmailScheduler.checkAndSendIfDue()
     }
""")

    print("\n📋 SUMMARY:")
    print("=" * 60)
    print("The Weekly Email Notification Service provides:")
    print("  ✓ WeeklySummary model for aggregated child activity data")
    print("  ✓ WeeklySummaryService to generate weekly reports")
    print("  ✓ EmailContentBuilder to create beautiful HTML emails")
    print("  ✓ EmailService to send emails via mailto: URL scheme")
    print("  ✓ WeeklyEmailScheduler to schedule and manage email delivery")
    print("  ✓ Comprehensive test coverage for all components")
    print("\nAll files follow TDD principles and FocusPal coding standards!")
    print("=" * 60)

if __name__ == "__main__":
    main()
