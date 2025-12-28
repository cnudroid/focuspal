#!/usr/bin/env python3
"""
Script to add ParentProfilePrompt files to the Xcode project.
"""

import hashlib
import re


def generate_pbx_id(base_string):
    """Generate a deterministic PBX ID from a string."""
    hash_obj = hashlib.md5(base_string.encode())
    return hash_obj.hexdigest()[:24].upper()


def add_files_to_project():
    """Add ParentProfilePrompt files to Xcode project."""

    project_path = '/Users/srinivasgurana/self/claude/focuspal/FocusPal.xcodeproj/project.pbxproj'

    # Generate IDs
    view_id = generate_pbx_id('ParentProfilePromptView.swift')
    viewmodel_id = generate_pbx_id('ParentProfilePromptViewModel.swift')
    view_build_id = generate_pbx_id('ParentProfilePromptView.swift_build')
    viewmodel_build_id = generate_pbx_id('ParentProfilePromptViewModel.swift_build')

    print("Adding ParentProfilePrompt files to Xcode project...")
    print(f"Generated IDs:")
    print(f"  View file: {view_id}")
    print(f"  ViewModel file: {viewmodel_id}")
    print(f"  View build: {view_build_id}")
    print(f"  ViewModel build: {viewmodel_build_id}")

    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()

    # 1. Add PBXFileReference entries
    file_refs_section = r'(/\* Begin PBXFileReference section \*/)'
    file_refs_addition = f"""\n\t\t{view_id} /* ParentProfilePromptView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ParentProfilePromptView.swift; sourceTree = "<group>"; }};
\t\t{viewmodel_id} /* ParentProfilePromptViewModel.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ParentProfilePromptViewModel.swift; sourceTree = "<group>"; }};"""

    content = re.sub(file_refs_section, r'\1' + file_refs_addition, content)
    print("✓ Added PBXFileReference entries")

    # 2. Add PBXBuildFile entries
    build_file_section = r'(/\* Begin PBXBuildFile section \*/)'
    build_file_addition = f"""\n\t\t{view_build_id} /* ParentProfilePromptView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {view_id} /* ParentProfilePromptView.swift */; }};
\t\t{viewmodel_build_id} /* ParentProfilePromptViewModel.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {viewmodel_id} /* ParentProfilePromptViewModel.swift */; }};"""

    content = re.sub(build_file_section, r'\1' + build_file_addition, content)
    print("✓ Added PBXBuildFile entries")

    # 3. Find ParentControls Views group and add View file (specific group ID)
    views_group_pattern = r'(71E188DE922CC2570ABB382F /\* Views \*/ = \{\s+isa = PBXGroup;\s+children = \(((?:[^)]|\n)*?)\);)'

    views_match = re.search(views_group_pattern, content)
    if views_match:
        children_content = views_match.group(2)
        # Add the new file reference
        new_children = children_content.rstrip() + f"\n\t\t\t\t{view_id} /* ParentProfilePromptView.swift */,"

        # Replace the children list
        old_section = views_match.group(1)
        new_section = old_section.replace(children_content, new_children)
        content = content.replace(old_section, new_section, 1)
        print("✓ Added View file to ParentControls Views group")
    else:
        print("⚠ Could not find ParentControls Views group")

    # 4. Find ParentControls ViewModels group and add ViewModel file (specific group ID)
    viewmodels_group_pattern = r'(DEAACB929E8342F8F6ADD32B /\* ViewModels \*/ = \{\s+isa = PBXGroup;\s+children = \(((?:[^)]|\n)*?)\);)'

    viewmodels_match = re.search(viewmodels_group_pattern, content)
    if viewmodels_match:
        children_content = viewmodels_match.group(2)
        # Add the new file reference
        new_children = children_content.rstrip() + f"\n\t\t\t\t{viewmodel_id} /* ParentProfilePromptViewModel.swift */,"

        # Replace the children list
        old_section = viewmodels_match.group(1)
        new_section = old_section.replace(children_content, new_children)
        content = content.replace(old_section, new_section, 1)
        print("✓ Added ViewModel file to ParentControls ViewModels group")
    else:
        print("⚠ Could not find ParentControls ViewModels group")

    # 5. Add to Sources build phase
    sources_phase_pattern = r'(/\* Sources \*/ = \{[^}]+isa = PBXSourcesBuildPhase;[^}]+files = \()'
    sources_files = re.search(sources_phase_pattern + r'((?:[^)]|\n)*?)\)', content)

    if sources_files:
        files_content = sources_files.group(2)
        new_files = files_content.rstrip() + f"\n\t\t\t\t{view_build_id} /* ParentProfilePromptView.swift in Sources */,\n\t\t\t\t{viewmodel_build_id} /* ParentProfilePromptViewModel.swift in Sources */,"

        # Replace
        content = content.replace(files_content, new_files, 1)
        print("✓ Added files to Sources build phase")

    # Write back
    with open(project_path, 'w') as f:
        f.write(content)

    print("\n✅ Successfully added ParentProfilePrompt files to Xcode project!")
    print("\nYou can now:")
    print("  1. Open FocusPal.xcodeproj in Xcode")
    print("  2. Verify the files appear in the project navigator")
    print("  3. Build the project to ensure everything compiles")


if __name__ == '__main__':
    add_files_to_project()
