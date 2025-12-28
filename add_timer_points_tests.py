#!/usr/bin/env python3
"""
Script to add TimerViewModelPointsTests.swift to Xcode project.
"""

import uuid
import re
import sys

def gen_id():
    """Generate a unique 24-character hex ID for Xcode"""
    return ''.join([hex(ord(c))[2:].upper() for c in str(uuid.uuid4().hex[:24])])

def main():
    project_file = 'FocusPal.xcodeproj/project.pbxproj'

    print("Adding TimerViewModelPointsTests to Xcode project...")

    try:
        # Read project file
        with open(project_file, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Could not find {project_file}")
        print("Make sure you run this script from the FocusPal project root directory")
        return 1

    # Generate unique IDs
    tests_ref_id = gen_id()
    tests_build_id = gen_id()

    print(f"Generated IDs:")
    print(f"  Timer Points tests ref: {tests_ref_id}")
    print(f"  Timer Points tests build: {tests_build_id}")

    # 1. Add PBXFileReference entry
    file_ref = f'''\t\t{tests_ref_id} /* TimerViewModelPointsTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TimerViewModelPointsTests.swift; sourceTree = "<group>"; }};
'''
    pattern = r'(/\* End PBXFileReference section \*/)'
    content = re.sub(pattern, file_ref + r'\1', content)
    print("✓ Added PBXFileReference entry")

    # 2. Add PBXBuildFile entry
    build_file = f'''\t\t{tests_build_id} /* TimerViewModelPointsTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {tests_ref_id} /* TimerViewModelPointsTests.swift */; }};
'''
    pattern = r'(/\* End PBXBuildFile section \*/)'
    content = re.sub(pattern, build_file + r'\1', content)
    print("✓ Added PBXBuildFile entry")

    # 3. Add to ViewModels group children (find the ViewModels group in FocusPalTests)
    # Look for the ViewModels group and add our file to its children
    pattern = r'(/\* ViewModels \*/ = \{[\s\S]*?children = \(\n)'
    replacement = r'\g<1>\t\t\t\t' + tests_ref_id + ' /* TimerViewModelPointsTests.swift */,\n'
    content = re.sub(pattern, replacement, content)
    print("✓ Added to ViewModels group children")

    # 4. Add to Sources build phase
    pattern = r'(C56711C67DA9B8D0A7516F34 /\* Sources \*/ = \{[\s\S]*?files = \(\n)'
    replacement = r'\g<1>\t\t\t\t' + tests_build_id + ' /* TimerViewModelPointsTests.swift in Sources */,\n'
    content = re.sub(pattern, replacement, content)
    print("✓ Added to Sources build phase")

    # Write back to file
    with open(project_file, 'w') as f:
        f.write(content)

    print("\n✅ Successfully added TimerViewModelPointsTests.swift to Xcode project!")
    print("\nYou can now:")
    print("  1. Open FocusPal.xcodeproj in Xcode")
    print("  2. Build and run tests with: xcodebuild test -scheme FocusPal -destination 'platform=iOS Simulator,name=iPhone 17'")
    return 0

if __name__ == '__main__':
    sys.exit(main())
