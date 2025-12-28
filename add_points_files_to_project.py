#!/usr/bin/env python3
"""
Script to add Points Service files to Xcode project.
Run this script to automatically add the new Points-related files to FocusPal.xcodeproj
"""

import uuid
import re
import sys

def gen_id():
    """Generate a unique 24-character hex ID for Xcode"""
    return ''.join([hex(ord(c))[2:].upper() for c in str(uuid.uuid4().hex[:24])])

def main():
    project_file = 'FocusPal.xcodeproj/project.pbxproj'

    print("Adding Points Service files to Xcode project...")

    try:
        # Read project file
        with open(project_file, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Could not find {project_file}")
        print("Make sure you run this script from the FocusPal project root directory")
        return 1

    # Generate unique IDs for main source files
    points_repo_protocol_ref = gen_id()
    points_repo_protocol_build = gen_id()

    coredata_points_repo_ref = gen_id()
    coredata_points_repo_build = gen_id()

    points_service_ref = gen_id()
    points_service_build = gen_id()

    mock_points_service_ref = gen_id()
    mock_points_service_build = gen_id()

    # Generate unique IDs for test files
    points_repo_tests_ref = gen_id()
    points_repo_tests_build = gen_id()

    points_service_tests_ref = gen_id()
    points_service_tests_build = gen_id()

    print(f"Generated IDs for source files:")
    print(f"  PointsRepositoryProtocol: {points_repo_protocol_ref}")
    print(f"  CoreDataPointsRepository: {coredata_points_repo_ref}")
    print(f"  PointsService: {points_service_ref}")
    print(f"  MockPointsService: {mock_points_service_ref}")
    print(f"\nGenerated IDs for test files:")
    print(f"  CoreDataPointsRepositoryTests: {points_repo_tests_ref}")
    print(f"  PointsServiceTests: {points_service_tests_ref}")

    # 1. Add PBXFileReference entries for source files
    file_refs = f'''\t\t{points_repo_protocol_ref} /* PointsRepositoryProtocol.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PointsRepositoryProtocol.swift; sourceTree = "<group>"; }};
\t\t{coredata_points_repo_ref} /* CoreDataPointsRepository.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CoreDataPointsRepository.swift; sourceTree = "<group>"; }};
\t\t{points_service_ref} /* PointsService.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PointsService.swift; sourceTree = "<group>"; }};
\t\t{mock_points_service_ref} /* MockPointsService.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MockPointsService.swift; sourceTree = "<group>"; }};
\t\t{points_repo_tests_ref} /* CoreDataPointsRepositoryTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CoreDataPointsRepositoryTests.swift; sourceTree = "<group>"; }};
\t\t{points_service_tests_ref} /* PointsServiceTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PointsServiceTests.swift; sourceTree = "<group>"; }};
'''
    pattern = r'(/\* End PBXFileReference section \*/)'
    content = re.sub(pattern, file_refs + r'\1', content)
    print("✓ Added PBXFileReference entries")

    # 2. Add PBXBuildFile entries
    build_files = f'''\t\t{points_repo_protocol_build} /* PointsRepositoryProtocol.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {points_repo_protocol_ref} /* PointsRepositoryProtocol.swift */; }};
\t\t{coredata_points_repo_build} /* CoreDataPointsRepository.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {coredata_points_repo_ref} /* CoreDataPointsRepository.swift */; }};
\t\t{points_service_build} /* PointsService.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {points_service_ref} /* PointsService.swift */; }};
\t\t{mock_points_service_build} /* MockPointsService.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {mock_points_service_ref} /* MockPointsService.swift */; }};
\t\t{points_repo_tests_build} /* CoreDataPointsRepositoryTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {points_repo_tests_ref} /* CoreDataPointsRepositoryTests.swift */; }};
\t\t{points_service_tests_build} /* PointsServiceTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {points_service_tests_ref} /* PointsServiceTests.swift */; }};
'''
    pattern = r'(/\* End PBXBuildFile section \*/)'
    content = re.sub(pattern, build_files + r'\1', content)
    print("✓ Added PBXBuildFile entries")

    # 3. Add to Repositories/Protocols group (find and add PointsRepositoryProtocol)
    pattern = r'(2AADEECD6A5E92ED154B12EC /\* Protocols \*/ = \{[\s\S]*?children = \()'
    replacement = r'\g<1>\n\t\t\t\t' + points_repo_protocol_ref + ' /* PointsRepositoryProtocol.swift */,'
    content = re.sub(pattern, replacement, content)
    print("✓ Added PointsRepositoryProtocol to Repositories/Protocols group")

    # 4. Add to Repositories/Implementation group (find and add CoreDataPointsRepository)
    pattern = r'(797D75BAE213A4E083117D2E /\* Implementation \*/ = \{[\s\S]*?children = \()'
    replacement = r'\g<1>\n\t\t\t\t' + coredata_points_repo_ref + ' /* CoreDataPointsRepository.swift */,'
    content = re.sub(pattern, replacement, content)
    print("✓ Added CoreDataPointsRepository to Repositories/Implementation group")

    # 5. Add to Services/Implementation group (find and add PointsService)
    # Find the Services Implementation group
    pattern = r'(C2A9718E819BB5E228149336 /\* Implementation \*/ = \{[\s\S]*?children = \()'
    replacement = r'\g<1>\n\t\t\t\t' + points_service_ref + ' /* PointsService.swift */,'
    content = re.sub(pattern, replacement, content)
    print("✓ Added PointsService to Services/Implementation group")

    # 6. Add to Services/Mock group (find and add MockPointsService)
    pattern = r'(B55E94CF59A5D6577CA4EC54 /\* Mock \*/ = \{[\s\S]*?children = \()'
    replacement = r'\g<1>\n\t\t\t\t' + mock_points_service_ref + ' /* MockPointsService.swift */,'
    content = re.sub(pattern, replacement, content)
    print("✓ Added MockPointsService to Services/Mock group")

    # 7. Add to Repositories test group (find and add test files)
    pattern = r'(3E2EB46A865FAA91970B51B1 /\* Repositories \*/ = \{[\s\S]*?children = \()'
    replacement = r'\g<1>\n\t\t\t\t' + points_repo_tests_ref + ' /* CoreDataPointsRepositoryTests.swift */,'
    content = re.sub(pattern, replacement, content)
    print("✓ Added CoreDataPointsRepositoryTests to Repositories test group")

    # 8. Add to Services test group (find and add PointsServiceTests)
    pattern = r'(1A3BC94E8EB97B04AA7C7E21 /\* Services \*/ = \{[\s\S]*?children = \()'
    replacement = r'\g<1>\n\t\t\t\t' + points_service_tests_ref + ' /* PointsServiceTests.swift */,'
    content = re.sub(pattern, replacement, content)
    print("✓ Added PointsServiceTests to Services test group")

    # 9. Add to main Sources build phase (FocusPal target)
    pattern = r'(18DDFCDA5465C321CD30AD4D /\* Sources \*/ = \{[\s\S]*?files = \()'
    replacement = r'\g<1>\n\t\t\t\t' + points_repo_protocol_build + ' /* PointsRepositoryProtocol.swift in Sources */,'
    replacement += '\n\t\t\t\t' + coredata_points_repo_build + ' /* CoreDataPointsRepository.swift in Sources */,'
    replacement += '\n\t\t\t\t' + points_service_build + ' /* PointsService.swift in Sources */,'
    replacement += '\n\t\t\t\t' + mock_points_service_build + ' /* MockPointsService.swift in Sources */,'
    content = re.sub(pattern, replacement, content)
    print("✓ Added source files to main Sources build phase")

    # 10. Add to test Sources build phase (FocusPalTests target)
    pattern = r'(C56711C67DA9B8D0A7516F34 /\* Sources \*/ = \{[\s\S]*?files = \()'
    replacement = r'\g<1>\n\t\t\t\t' + points_repo_tests_build + ' /* CoreDataPointsRepositoryTests.swift in Sources */,'
    replacement += '\n\t\t\t\t' + points_service_tests_build + ' /* PointsServiceTests.swift in Sources */,'
    content = re.sub(pattern, replacement, content)
    print("✓ Added test files to test Sources build phase")

    # Write back to file
    with open(project_file, 'w') as f:
        f.write(content)

    print("\n✅ Successfully added Points Service files to Xcode project!")
    print("\nFiles added:")
    print("  Source files:")
    print("    - FocusPal/Core/Persistence/Repositories/Protocols/PointsRepositoryProtocol.swift")
    print("    - FocusPal/Core/Persistence/Repositories/Implementation/CoreDataPointsRepository.swift")
    print("    - FocusPal/Core/Services/Implementation/PointsService.swift")
    print("    - FocusPal/Core/Services/Mock/MockPointsService.swift")
    print("  Test files:")
    print("    - FocusPalTests/Repositories/CoreDataPointsRepositoryTests.swift")
    print("    - FocusPalTests/Services/PointsServiceTests.swift")
    print("\nYou can now:")
    print("  1. Open FocusPal.xcodeproj in Xcode")
    print("  2. Build the project: xcodebuild -scheme FocusPal -destination 'platform=iOS Simulator,name=iPhone 17'")
    print("  3. Run tests: xcodebuild test -scheme FocusPal -destination 'platform=iOS Simulator,name=iPhone 17'")
    return 0

if __name__ == '__main__':
    sys.exit(main())
