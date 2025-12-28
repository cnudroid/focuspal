#!/usr/bin/env python3
"""
Script to remove stale file references from the Xcode project.
"""

import re


def cleanup_stale_references():
    """Remove stale ParentProfile references from project."""

    project_path = '/Users/srinivasgurana/self/claude/focuspal/FocusPal.xcodeproj/project.pbxproj'

    print("Cleaning up stale references...")

    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()

    # List of stale file references to remove (file IDs and their build IDs)
    stale_patterns = [
        # ParentProfileView.swift (standalone, not ParentProfilePromptView)
        r'\t\t32306130616264322D633363 /\* ParentProfileView\.swift in Sources \*/ = \{isa = PBXBuildFile; fileRef = 37663562663537352D303561 /\* ParentProfileView\.swift \*/; \};\n',
        r'\t\t37663562663537352D303561 /\* ParentProfileView\.swift \*/ = \{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = ParentProfileView\.swift; sourceTree = "<group>"; \};\n',
        r'\t\t\t\t32306130616264322D633363 /\* ParentProfileView\.swift in Sources \*/,\n',
        r'\t\t\t\t37663562663537352D303561 /\* ParentProfileView\.swift \*/,\n',

        # Old ProfileSelection references
        r'\t\t93F1C396EBCE0EFC1B22E6E7 /\* ProfileSelectionView\.swift in Sources \*/ = \{isa = PBXBuildFile; fileRef = 157CC61C424E8E993ACE6CBF /\* ProfileSelectionView\.swift \*/; \};\n',
        r'\t\t98D2D0865E9B467C739FEE1F /\* ProfileSelectionViewModel\.swift in Sources \*/ = \{isa = PBXBuildFile; fileRef = 5C084BC47C8ED4EECA50CA9C /\* ProfileSelectionViewModel\.swift \*/; \};\n',
        r'\t\t157CC61C424E8E993ACE6CBF /\* ProfileSelectionView\.swift \*/ = \{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = ProfileSelectionView\.swift; sourceTree = "<group>"; \};\n',
        r'\t\t5C084BC47C8ED4EECA50CA9C /\* ProfileSelectionViewModel\.swift \*/ = \{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = ProfileSelectionViewModel\.swift; sourceTree = "<group>"; \};\n',
        r'\t\t\t\t93F1C396EBCE0EFC1B22E6E7 /\* ProfileSelectionView\.swift in Sources \*/,\n',
        r'\t\t\t\t98D2D0865E9B467C739FEE1F /\* ProfileSelectionViewModel\.swift in Sources \*/,\n',
        r'\t\t\t\t157CC61C424E8E993ACE6CBF /\* ProfileSelectionView\.swift \*/,\n',
        r'\t\t\t\t5C084BC47C8ED4EECA50CA9C /\* ProfileSelectionViewModel\.swift \*/,\n',
    ]

    # Remove each stale pattern
    for pattern in stale_patterns:
        content = re.sub(pattern, '', content)
        if re.search(pattern, content) is None:
            print(f"  ✓ Removed pattern")

    # Also remove the ProfileSelection group if it's empty or only has these files
    # First, let's check what's in the ProfileSelection group
    profile_selection_group = re.search(
        r'4F501028C7DA394D2F9572DA /\* ProfileSelection \*/ = \{\s+isa = PBXGroup;\s+children = \(((?:[^)]|\n)*?)\);\s+path = ProfileSelection;\s+sourceTree = "<group>";\s+\};',
        content
    )

    if profile_selection_group:
        children = profile_selection_group.group(1).strip()
        # If children only contains the files we're removing, or is empty, remove the whole group
        if not children or all(id in children for id in ['5C084BC47C8ED4EECA50CA9C', '157CC61C424E8E993ACE6CBF']):
            # Remove the group definition
            content = re.sub(
                r'\t\t4F501028C7DA394D2F9572DA /\* ProfileSelection \*/ = \{\s+isa = PBXGroup;\s+children = \((?:[^)]|\n)*?\);\s+path = ProfileSelection;\s+sourceTree = "<group>";\s+\};\n',
                '',
                content
            )
            # Remove reference to the group in Features
            content = re.sub(
                r'\t\t\t\t4F501028C7DA394D2F9572DA /\* ProfileSelection \*/,\n',
                '',
                content
            )
            print("  ✓ Removed ProfileSelection group")

    # Write back
    with open(project_path, 'w') as f:
        f.write(content)

    print("\n✅ Successfully cleaned up stale references!")


if __name__ == '__main__':
    cleanup_stale_references()
