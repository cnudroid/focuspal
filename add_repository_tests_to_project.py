#!/usr/bin/env python3
"""
Script to add CoreData Repository test files to Xcode project.
Run this script to automatically add the new test files to FocusPal.xcodeproj
"""

import uuid
import re
import sys

def gen_id():
    """Generate a unique 24-character hex ID for Xcode"""
    return ''.join([hex(ord(c))[2:].upper() for c in str(uuid.uuid4().hex[:24])])

def main():
    project_file = 'FocusPal.xcodeproj/project.pbxproj'

    print("Adding Repository tests to Xcode project...")

    try:
        # Read project file
        with open(project_file, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Could not find {project_file}")
        print("Make sure you run this script from the FocusPal project root directory")
        return 1

    # Generate unique IDs
    repos_group_id = gen_id()
    achievement_tests_ref_id = gen_id()
    timegoal_tests_ref_id = gen_id()
    achievement_tests_build_id = gen_id()
    timegoal_tests_build_id = gen_id()

    print(f"Generated IDs:")
    print(f"  Repositories group: {repos_group_id}")
    print(f"  Achievement tests ref: {achievement_tests_ref_id}")
    print(f"  TimeGoal tests ref: {timegoal_tests_ref_id}")

    # 1. Add PBXFileReference entries
    file_refs = f'''\t\t{achievement_tests_ref_id} /* CoreDataAchievementRepositoryTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CoreDataAchievementRepositoryTests.swift; sourceTree = "<group>"; }};
\t\t{timegoal_tests_ref_id} /* CoreDataTimeGoalRepositoryTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CoreDataTimeGoalRepositoryTests.swift; sourceTree = "<group>"; }};
'''
    pattern = r'(/\* End PBXFileReference section \*/)'
    content = re.sub(pattern, file_refs + r'\1', content)
    print("✓ Added PBXFileReference entries")

    # 2. Add PBXBuildFile entries
    build_files = f'''\t\t{achievement_tests_build_id} /* CoreDataAchievementRepositoryTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {achievement_tests_ref_id} /* CoreDataAchievementRepositoryTests.swift */; }};
\t\t{timegoal_tests_build_id} /* CoreDataTimeGoalRepositoryTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {timegoal_tests_ref_id} /* CoreDataTimeGoalRepositoryTests.swift */; }};
'''
    pattern = r'(/\* End PBXBuildFile section \*/)'
    content = re.sub(pattern, build_files + r'\1', content)
    print("✓ Added PBXBuildFile entries")

    # 3. Add Repositories group definition
    repos_group = f'''\t\t{repos_group_id} /* Repositories */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{achievement_tests_ref_id} /* CoreDataAchievementRepositoryTests.swift */,
\t\t\t\t{timegoal_tests_ref_id} /* CoreDataTimeGoalRepositoryTests.swift */,
\t\t\t);
\t\t\tpath = Repositories;
\t\t\tsourceTree = "<group>";
\t\t}};
'''

    # Add group definition before FocusPalTests group
    pattern = r'(65A35FC57144265C1AC42CF0 /\* FocusPalTests \*/ = \{)'
    content = re.sub(pattern, repos_group + r'\t\t\1', content)
    print("✓ Added Repositories group definition")

    # 4. Add Repositories to FocusPalTests children
    pattern = r'(65A35FC57144265C1AC42CF0 /\* FocusPalTests \*/ = \{[\s\S]*?children = \(\n)'
    replacement = r'\g<1>\t\t\t\t' + repos_group_id + ' /* Repositories */,\n'
    content = re.sub(pattern, replacement, content)
    print("✓ Added Repositories to FocusPalTests children")

    # 5. Add to Sources build phase
    pattern = r'(C56711C67DA9B8D0A7516F34 /\* Sources \*/ = \{[\s\S]*?files = \(\n)'
    replacement = r'\g<1>\t\t\t\t' + achievement_tests_build_id + ' /* CoreDataAchievementRepositoryTests.swift in Sources */,\n'
    replacement += '\t\t\t\t' + timegoal_tests_build_id + ' /* CoreDataTimeGoalRepositoryTests.swift in Sources */,\n'
    content = re.sub(pattern, replacement, content)
    print("✓ Added files to Sources build phase")

    # Write back to file
    with open(project_file, 'w') as f:
        f.write(content)

    print("\n✅ Successfully added Repository test files to Xcode project!")
    print("\nYou can now:")
    print("  1. Open FocusPal.xcodeproj in Xcode")
    print("  2. Build and run tests with: xcodebuild test -scheme FocusPal -destination 'platform=iOS Simulator,name=iPhone 17'")
    return 0

if __name__ == '__main__':
    sys.exit(main())
