#!/usr/bin/env python3
"""
Script to fix duplicate file references in the Xcode project.
"""

import re


def fix_duplicate_references():
    """Fix duplicate ParentProfilePrompt references."""

    project_path = '/Users/srinivasgurana/self/claude/focuspal/FocusPal.xcodeproj/project.pbxproj'

    print("Fixing duplicate references...")

    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()

    # Remove duplicate PBXBuildFile entries (keep only one of each)
    # Remove line 12 and 13 (duplicates)
    content = re.sub(
        r'\t\t5C8E349F31B8FBD661E5EBDB /\* ParentProfilePromptView\.swift in Sources \*/ = \{isa = PBXBuildFile; fileRef = 38BADC7E99EA23D4DF5A0BB8 /\* ParentProfilePromptView\.swift \*/; \};\n.*0A3CCC58F4D4BE19A771065B /\* ParentProfilePromptViewModel\.swift in Sources \*/ = \{isa = PBXBuildFile; fileRef = 5DFF8BCB5E0C85F8DEEAC370 /\* ParentProfilePromptViewModel\.swift \*/; \};\n',
        '',
        content,
        count=1  # Remove only one occurrence (the duplicate)
    )
    print("  ✓ Removed duplicate PBXBuildFile entries")

    # Remove duplicate PBXFileReference entries (keep only one of each)
    # Remove lines 217 and 218 (duplicates)
    content = re.sub(
        r'\t\t38BADC7E99EA23D4DF5A0BB8 /\* ParentProfilePromptView\.swift \*/ = \{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = ParentProfilePromptView\.swift; sourceTree = "<group>"; \};\n.*5DFF8BCB5E0C85F8DEEAC370 /\* ParentProfilePromptViewModel\.swift \*/ = \{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = ParentProfilePromptViewModel\.swift; sourceTree = "<group>"; \};\n',
        '',
        content,
        count=1  # Remove only one occurrence (the duplicate)
    )
    print("  ✓ Removed duplicate PBXFileReference entries")

    # Remove duplicate references in groups (malformed syntax with ");")
    # Fix line 424
    content = re.sub(
        r'(\t\t\t\t5DFF8BCB5E0C85F8DEEAC370 /\* ParentProfilePromptViewModel\.swift \*/,)\);',
        r'\1',
        content
    )
    # Fix line 482
    content = re.sub(
        r'(\t\t\t\t38BADC7E99EA23D4DF5A0BB8 /\* ParentProfilePromptView\.swift \*/,)\);',
        r'\1',
        content
    )
    # Fix line 731 - this one might be in a different group, let's check
    # Remove if it's a duplicate in another group
    pattern = r'\t\t\t\t38BADC7E99EA23D4DF5A0BB8 /\* ParentProfilePromptView\.swift \*/,\);'
    matches = re.findall(pattern, content)
    if len(matches) > 1:
        # Remove one of them
        content = re.sub(pattern, '', content, count=len(matches) - 1)

    # Fix line 1120
    content = re.sub(
        r'(\t\t\t\t5DFF8BCB5E0C85F8DEEAC370 /\* ParentProfilePromptViewModel\.swift \*/,)\);',
        r'\1',
        content
    )

    print("  ✓ Fixed malformed group references")

    # Remove duplicate entries in Sources build phase (lines 1498-1499)
    # Keep only one set of these entries
    sources_section = re.search(
        r'(/\* Begin PBXSourcesBuildPhase section \*/.*?/\* End PBXSourcesBuildPhase section \*/)',
        content,
        re.DOTALL
    )

    if sources_section:
        section_content = sources_section.group(1)
        # Count occurrences
        view_count = len(re.findall(r'5C8E349F31B8FBD661E5EBDB /\* ParentProfilePromptView\.swift in Sources \*/', section_content))
        vm_count = len(re.findall(r'0A3CCC58F4D4BE19A771065B /\* ParentProfilePromptViewModel\.swift in Sources \*/', section_content))

        if view_count > 1:
            # Remove duplicates
            section_content = re.sub(
                r'\t\t\t\t5C8E349F31B8FBD661E5EBDB /\* ParentProfilePromptView\.swift in Sources \*/,\n',
                '',
                section_content,
                count=view_count - 1
            )
        if vm_count > 1:
            section_content = re.sub(
                r'\t\t\t\t0A3CCC58F4D4BE19A771065B /\* ParentProfilePromptViewModel\.swift in Sources \*/,\n',
                '',
                section_content,
                count=vm_count - 1
            )

        content = content.replace(sources_section.group(1), section_content)
        print("  ✓ Removed duplicate entries in Sources build phase")

    # Remove any remaining ");"-style endings in group children
    content = re.sub(r',\);', ',', content)

    # Write back
    with open(project_path, 'w') as f:
        f.write(content)

    print("\n✅ Successfully fixed duplicate references!")


if __name__ == '__main__':
    fix_duplicate_references()
