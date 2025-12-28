#!/usr/bin/env python3
"""
Script to add ParentRepository files to Xcode project.
Run this script to automatically add the new repository files to FocusPal.xcodeproj
"""

import uuid
import re
import sys

def gen_id():
    """Generate a unique 24-character hex ID for Xcode"""
    return ''.join([hex(ord(c))[2:].upper() for c in str(uuid.uuid4().hex[:24])])

def main():
    project_file = 'FocusPal.xcodeproj/project.pbxproj'

    print("Adding ParentRepository files to Xcode project...")

    try:
        # Read project file
        with open(project_file, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Could not find {project_file}")
        print("Make sure you run this script from the FocusPal project root directory")
        return 1

    # Generate unique IDs for all files
    protocol_ref_id = gen_id()
    protocol_build_id = gen_id()
    coredata_impl_ref_id = gen_id()
    coredata_impl_build_id = gen_id()
    mock_ref_id = gen_id()
    mock_build_id = gen_id()
    tests_ref_id = gen_id()
    tests_build_id = gen_id()

    print(f"Generated IDs:")
    print(f"  Protocol ref: {protocol_ref_id}")
    print(f"  CoreData impl ref: {coredata_impl_ref_id}")
    print(f"  Mock ref: {mock_ref_id}")
    print(f"  Tests ref: {tests_ref_id}")

    # 1. Add PBXFileReference entries
    file_refs = f'''\t\t{protocol_ref_id} /* ParentRepositoryProtocol.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ParentRepositoryProtocol.swift; sourceTree = "<group>"; }};
\t\t{coredata_impl_ref_id} /* CoreDataParentRepository.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CoreDataParentRepository.swift; sourceTree = "<group>"; }};
\t\t{mock_ref_id} /* MockParentRepository.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MockParentRepository.swift; sourceTree = "<group>"; }};
\t\t{tests_ref_id} /* ParentRepositoryTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ParentRepositoryTests.swift; sourceTree = "<group>"; }};
'''
    pattern = r'(/\* End PBXFileReference section \*/)'
    content = re.sub(pattern, file_refs + r'\1', content)
    print("✓ Added PBXFileReference entries")

    # 2. Add PBXBuildFile entries
    build_files = f'''\t\t{protocol_build_id} /* ParentRepositoryProtocol.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {protocol_ref_id} /* ParentRepositoryProtocol.swift */; }};
\t\t{coredata_impl_build_id} /* CoreDataParentRepository.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {coredata_impl_ref_id} /* CoreDataParentRepository.swift */; }};
\t\t{mock_build_id} /* MockParentRepository.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {mock_ref_id} /* MockParentRepository.swift */; }};
\t\t{tests_build_id} /* ParentRepositoryTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {tests_ref_id} /* ParentRepositoryTests.swift */; }};
'''
    pattern = r'(/\* End PBXBuildFile section \*/)'
    content = re.sub(pattern, build_files + r'\1', content)
    print("✓ Added PBXBuildFile entries")

    # 3. Add files to Protocols group
    pattern = r'(/\* ChildRepositoryProtocol\.swift \*/.*?\n\s*)'
    replacement = r'\1' + f'\t\t\t\t{protocol_ref_id} /* ParentRepositoryProtocol.swift */,\n\t\t\t\t'
    content = re.sub(pattern, replacement, content)
    print("✓ Added protocol to Protocols group")

    # 4. Add files to Implementation group
    pattern = r'(/\* CoreDataChildRepository\.swift \*/.*?\n\s*)'
    replacement = r'\1' + f'\t\t\t\t{coredata_impl_ref_id} /* CoreDataParentRepository.swift */,\n\t\t\t\t'
    content = re.sub(pattern, replacement, content)
    print("✓ Added implementation to Implementation group")

    # 5. Add files to Mock group
    pattern = r'(/\* MockChildRepository\.swift \*/.*?\n\s*)'
    replacement = r'\1' + f'\t\t\t\t{mock_ref_id} /* MockParentRepository.swift */,\n\t\t\t\t'
    content = re.sub(pattern, replacement, content)
    print("✓ Added mock to Mock group")

    # 6. Add test file to Repositories group (in tests)
    # Find the Repositories group in tests
    pattern = r'(/\* CoreDataAchievementRepositoryTests\.swift \*/.*?\n\s*)'
    replacement = r'\1' + f'\t\t\t\t{tests_ref_id} /* ParentRepositoryTests.swift */,\n\t\t\t\t'
    content = re.sub(pattern, replacement, content)
    print("✓ Added tests to Repositories test group")

    # 7. Add to main target Sources build phase
    # Find the Sources section for FocusPal target
    pattern = r'(buildActionMask = 2147483647;\s*files = \(\s*(?:.*?\n\s*)*?)(.*?/\* CoreDataChildRepository\.swift in Sources \*/.*?\n)'
    replacement = r'\1' + f'\t\t\t\t{protocol_build_id} /* ParentRepositoryProtocol.swift in Sources */,\n\t\t\t\t{coredata_impl_build_id} /* CoreDataParentRepository.swift in Sources */,\n\t\t\t\t{mock_build_id} /* MockParentRepository.swift in Sources */,\n\t\t\t\t\2'
    content = re.sub(pattern, replacement, content, count=1)
    print("✓ Added files to FocusPal Sources build phase")

    # 8. Add test file to test target Sources build phase
    # Find test sources section
    pattern = r'(buildActionMask = 2147483647;\s*files = \(\s*(?:.*?\n\s*)*?)(.*?/\* CoreDataAchievementRepositoryTests\.swift in Sources \*/.*?\n)'
    replacement = r'\1' + f'\t\t\t\t{tests_build_id} /* ParentRepositoryTests.swift in Sources */,\n\t\t\t\t\2'
    content = re.sub(pattern, replacement, content)
    print("✓ Added test file to FocusPalTests Sources build phase")

    # Write back to file
    try:
        with open(project_file, 'w') as f:
            f.write(content)
        print("\n✅ Successfully added ParentRepository files to Xcode project!")
        print("\nYou can now:")
        print("  1. Open FocusPal.xcodeproj in Xcode")
        print("  2. Build and run tests with: xcodebuild test -scheme FocusPal -destination 'platform=iOS Simulator,name=iPhone 17'")
        return 0
    except Exception as e:
        print(f"\n❌ Error writing to project file: {e}")
        return 1

if __name__ == '__main__':
    sys.exit(main())
