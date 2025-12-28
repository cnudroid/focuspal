#!/usr/bin/env python3
"""
Script to add TimerViewModelPointsTests.swift to the Xcode project.
"""

import sys
import uuid

def main():
    project_file = '/Users/srinivasgurana/self/claude/focuspal/FocusPal.xcodeproj/project.pbxproj'
    test_file_path = 'FocusPalTests/ViewModels/TimerViewModelPointsTests.swift'

    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()

    # Generate UUIDs for the file reference and build file
    file_ref_uuid = str(uuid.uuid4()).replace('-', '')[:24].upper()
    build_file_uuid = str(uuid.uuid4()).replace('-', '')[:24].upper()

    # Find the PBXFileReference section
    file_ref_marker = '/* Begin PBXFileReference section */'
    file_ref_idx = content.find(file_ref_marker)
    if file_ref_idx == -1:
        print("Error: Could not find PBXFileReference section")
        return 1

    # Insert the file reference
    file_ref_entry = f'\t\t{file_ref_uuid} /* TimerViewModelPointsTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TimerViewModelPointsTests.swift; sourceTree = "<group>"; }};\n'

    # Find a good insertion point (after other test files)
    insert_idx = content.find('/* OnboardingViewModelTests.swift */', file_ref_idx)
    if insert_idx != -1:
        # Find the end of that line
        insert_idx = content.find('\n', insert_idx) + 1
        content = content[:insert_idx] + file_ref_entry + content[insert_idx:]

    # Find the PBXBuildFile section
    build_file_marker = '/* Begin PBXBuildFile section */'
    build_file_idx = content.find(build_file_marker)
    if build_file_idx == -1:
        print("Error: Could not find PBXBuildFile section")
        return 1

    # Insert the build file
    build_file_entry = f'\t\t{build_file_uuid} /* TimerViewModelPointsTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* TimerViewModelPointsTests.swift */; }};\n'

    # Find a good insertion point
    insert_idx = content.find('/* OnboardingViewModelTests.swift in Sources */', build_file_idx)
    if insert_idx != -1:
        insert_idx = content.find('\n', insert_idx) + 1
        content = content[:insert_idx] + build_file_entry + content[insert_idx:]

    # Find the ViewModels group in PBXGroup section
    viewmodels_marker = '/* ViewModels */ = {'
    viewmodels_idx = content.find(viewmodels_marker)
    if viewmodels_idx != -1:
        # Find the children array
        children_idx = content.find('children = (', viewmodels_idx)
        if children_idx != -1:
            # Find the end of the first child reference
            first_child_idx = content.find('/* OnboardingViewModelTests.swift */', children_idx)
            if first_child_idx != -1:
                insert_idx = content.find(',\n', first_child_idx) + 2
                group_entry = f'\t\t\t\t{file_ref_uuid} /* TimerViewModelPointsTests.swift */,\n'
                content = content[:insert_idx] + group_entry + content[insert_idx:]

    # Find the PBXSourcesBuildPhase for FocusPalTests
    sources_phase_marker = 'FocusPalTests /* Sources */,'
    sources_idx = content.find(sources_phase_marker)
    if sources_idx != -1:
        # Find the files array
        files_idx = content.find('files = (', sources_idx)
        if files_idx != -1:
            # Find a good insertion point
            first_file_idx = content.find('/* OnboardingViewModelTests.swift in Sources */', files_idx)
            if first_file_idx != -1:
                insert_idx = content.find(',\n', first_file_idx) + 2
                sources_entry = f'\t\t\t\t{build_file_uuid} /* TimerViewModelPointsTests.swift in Sources */,\n'
                content = content[:insert_idx] + sources_entry + content[insert_idx:]

    # Write the modified content back
    with open(project_file, 'w') as f:
        f.write(content)

    print(f"Successfully added TimerViewModelPointsTests.swift to project")
    print(f"File reference UUID: {file_ref_uuid}")
    print(f"Build file UUID: {build_file_uuid}")
    return 0

if __name__ == '__main__':
    sys.exit(main())
