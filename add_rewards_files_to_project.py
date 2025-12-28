#!/usr/bin/env python3
"""
Script to add Rewards-related files to Xcode project.
Run this script to automatically add the new Rewards files to FocusPal.xcodeproj
"""

import uuid
import re
import sys

def gen_id():
    """Generate a unique 24-character hex ID for Xcode"""
    return ''.join([hex(ord(c))[2:].upper() for c in str(uuid.uuid4().hex[:24])])

def main():
    project_file = 'FocusPal.xcodeproj/project.pbxproj'

    print("Adding Rewards files to Xcode project...")

    try:
        # Read project file
        with open(project_file, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Could not find {project_file}")
        print("Make sure you run this script from the FocusPal project root directory")
        return 1

    # Generate unique IDs for main app files
    rewards_repo_protocol_ref_id = gen_id()
    rewards_repo_impl_ref_id = gen_id()
    rewards_service_ref_id = gen_id()
    mock_rewards_service_ref_id = gen_id()

    rewards_repo_protocol_build_id = gen_id()
    rewards_repo_impl_build_id = gen_id()
    rewards_service_build_id = gen_id()
    mock_rewards_service_build_id = gen_id()

    # Generate unique IDs for test files
    rewards_repo_tests_ref_id = gen_id()
    rewards_service_tests_ref_id = gen_id()

    rewards_repo_tests_build_id = gen_id()
    rewards_service_tests_build_id = gen_id()

    print(f"Generated IDs for main app files:")
    print(f"  RewardsRepositoryProtocol ref: {rewards_repo_protocol_ref_id}")
    print(f"  CoreDataRewardsRepository ref: {rewards_repo_impl_ref_id}")
    print(f"  RewardsService ref: {rewards_service_ref_id}")
    print(f"  MockRewardsService ref: {mock_rewards_service_ref_id}")
    print(f"\nGenerated IDs for test files:")
    print(f"  CoreDataRewardsRepositoryTests ref: {rewards_repo_tests_ref_id}")
    print(f"  RewardsServiceTests ref: {rewards_service_tests_ref_id}")

    # 1. Add PBXFileReference entries for main app files
    file_refs = f'''\t\t{rewards_repo_protocol_ref_id} /* RewardsRepositoryProtocol.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = RewardsRepositoryProtocol.swift; sourceTree = "<group>"; }};
\t\t{rewards_repo_impl_ref_id} /* CoreDataRewardsRepository.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CoreDataRewardsRepository.swift; sourceTree = "<group>"; }};
\t\t{rewards_service_ref_id} /* RewardsService.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = RewardsService.swift; sourceTree = "<group>"; }};
\t\t{mock_rewards_service_ref_id} /* MockRewardsService.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MockRewardsService.swift; sourceTree = "<group>"; }};
\t\t{rewards_repo_tests_ref_id} /* CoreDataRewardsRepositoryTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CoreDataRewardsRepositoryTests.swift; sourceTree = "<group>"; }};
\t\t{rewards_service_tests_ref_id} /* RewardsServiceTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = RewardsServiceTests.swift; sourceTree = "<group>"; }};
'''
    pattern = r'(/\* End PBXFileReference section \*/)'
    content = re.sub(pattern, file_refs + r'\1', content)
    print("✓ Added PBXFileReference entries")

    # 2. Add PBXBuildFile entries
    build_files = f'''\t\t{rewards_repo_protocol_build_id} /* RewardsRepositoryProtocol.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {rewards_repo_protocol_ref_id} /* RewardsRepositoryProtocol.swift */; }};
\t\t{rewards_repo_impl_build_id} /* CoreDataRewardsRepository.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {rewards_repo_impl_ref_id} /* CoreDataRewardsRepository.swift */; }};
\t\t{rewards_service_build_id} /* RewardsService.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {rewards_service_ref_id} /* RewardsService.swift */; }};
\t\t{mock_rewards_service_build_id} /* MockRewardsService.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {mock_rewards_service_ref_id} /* MockRewardsService.swift */; }};
\t\t{rewards_repo_tests_build_id} /* CoreDataRewardsRepositoryTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {rewards_repo_tests_ref_id} /* CoreDataRewardsRepositoryTests.swift */; }};
\t\t{rewards_service_tests_build_id} /* RewardsServiceTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {rewards_service_tests_ref_id} /* RewardsServiceTests.swift */; }};
'''
    pattern = r'(/\* End PBXBuildFile section \*/)'
    content = re.sub(pattern, build_files + r'\1', content)
    print("✓ Added PBXBuildFile entries")

    # 3. Add files to Protocols group (find the group that contains TimeGoalRepositoryProtocol)
    pattern = r'(.*TimeGoalRepositoryProtocol\.swift.*\n)'
    replacement = r'\g<1>\t\t\t\t' + rewards_repo_protocol_ref_id + ' /* RewardsRepositoryProtocol.swift */,\n'
    content = re.sub(pattern, replacement, content)
    print("✓ Added RewardsRepositoryProtocol to Protocols group")

    # 4. Add files to Implementation group (find the group that contains CoreDataTimeGoalRepository)
    pattern = r'(.*CoreDataTimeGoalRepository\.swift.*\n)'
    replacement = r'\g<1>\t\t\t\t' + rewards_repo_impl_ref_id + ' /* CoreDataRewardsRepository.swift */,\n'
    content = re.sub(pattern, replacement, content)
    print("✓ Added CoreDataRewardsRepository to Implementation group")

    # 5. Add files to Services Implementation group (find the group that contains TimeGoalService)
    pattern = r'(.*TimeGoalService\.swift.*\n)'
    replacement = r'\g<1>\t\t\t\t' + rewards_service_ref_id + ' /* RewardsService.swift */,\n'
    content = re.sub(pattern, replacement, content)
    print("✓ Added RewardsService to Services Implementation group")

    # 6. Add files to Mock Services group (find the group that contains MockActivityService)
    pattern = r'(.*MockActivityService\.swift.*\n)'
    replacement = r'\g<1>\t\t\t\t' + mock_rewards_service_ref_id + ' /* MockRewardsService.swift */,\n'
    content = re.sub(pattern, replacement, content)
    print("✓ Added MockRewardsService to Mock Services group")

    # 7. Add test files to Repositories group (in tests)
    pattern = r'(.*CoreDataTimeGoalRepositoryTests\.swift.*\n)'
    replacement = r'\g<1>\t\t\t\t' + rewards_repo_tests_ref_id + ' /* CoreDataRewardsRepositoryTests.swift */,\n'
    content = re.sub(pattern, replacement, content)
    print("✓ Added CoreDataRewardsRepositoryTests to Repositories tests group")

    # 8. Add test files to Services group (in tests)
    pattern = r'(.*TimeGoalServiceTests\.swift.*\n)'
    replacement = r'\g<1>\t\t\t\t' + rewards_service_tests_ref_id + ' /* RewardsServiceTests.swift */,\n'
    content = re.sub(pattern, replacement, content)
    print("✓ Added RewardsServiceTests to Services tests group")

    # 9. Add to main app Sources build phase (find FocusPal target sources)
    # Look for the Sources build phase that's NOT the test target
    pattern = r'(7B8FE53C83CA88329E0A0B6E /\* Sources \*/ = \{[\s\S]*?files = \(\n)'
    replacement = r'\g<1>\t\t\t\t' + rewards_repo_protocol_build_id + ' /* RewardsRepositoryProtocol.swift in Sources */,\n'
    replacement += '\t\t\t\t' + rewards_repo_impl_build_id + ' /* CoreDataRewardsRepository.swift in Sources */,\n'
    replacement += '\t\t\t\t' + rewards_service_build_id + ' /* RewardsService.swift in Sources */,\n'
    replacement += '\t\t\t\t' + mock_rewards_service_build_id + ' /* MockRewardsService.swift in Sources */,\n'
    content = re.sub(pattern, replacement, content)
    print("✓ Added main app files to FocusPal Sources build phase")

    # 10. Add to test Sources build phase
    pattern = r'(C56711C67DA9B8D0A7516F34 /\* Sources \*/ = \{[\s\S]*?files = \(\n)'
    replacement = r'\g<1>\t\t\t\t' + rewards_repo_tests_build_id + ' /* CoreDataRewardsRepositoryTests.swift in Sources */,\n'
    replacement += '\t\t\t\t' + rewards_service_tests_build_id + ' /* RewardsServiceTests.swift in Sources */,\n'
    content = re.sub(pattern, replacement, content)
    print("✓ Added test files to FocusPalTests Sources build phase")

    # Write back to file
    with open(project_file, 'w') as f:
        f.write(content)

    print("\n✅ Successfully added Rewards files to Xcode project!")
    print("\nFiles added:")
    print("  Main App:")
    print("    - RewardsRepositoryProtocol.swift")
    print("    - CoreDataRewardsRepository.swift")
    print("    - RewardsService.swift")
    print("    - MockRewardsService.swift")
    print("  Tests:")
    print("    - CoreDataRewardsRepositoryTests.swift")
    print("    - RewardsServiceTests.swift")
    print("\nYou can now:")
    print("  1. Open FocusPal.xcodeproj in Xcode")
    print("  2. Build the project: Cmd+B")
    print("  3. Run tests: Cmd+U")
    return 0

if __name__ == '__main__':
    sys.exit(main())
