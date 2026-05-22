# MacCtrlCVA v2.0.0

MacCtrlCVA v2.0.0 adds configurable editing shortcut mappings, so users are no longer limited to the default `Control + C/V/X/A/Z` behavior.

## New In v2.0.0

- Added a `Shortcut Mapping` menu in the menu bar app
- Added configurable editing shortcut triggers for:
  - Copy
  - Paste
  - Cut
  - Select All
  - Undo
- Added support for `Fn + C/V/X/A/Z`
- Added support for enabling both `Control + Letter` and `Fn + Letter` at the same time
- Added `Restore Default Mapping`

## Current Shortcut Support

- Editing shortcuts:
  - `Control + C/V/X/A/Z`
  - `Fn + C/V/X/A/Z`
  - User-selectable from the menu bar
- App switcher:
  - `Option + Tab` -> `Command + Tab`
- Input source switching:
  - `Control + Shift` -> next input source

## Included In This Release

- Menu bar background app
- Accessibility-based system-wide remapping
- Activation flow with machine code and activation code
- Seller activation code generator scripts
- DMG package for installation

## Installation

1. Download `MacCtrlCVA-v2.0.0.dmg`
2. Drag `MacCtrlCVA.app` into `Applications`
3. Launch the app
4. Activate the app with your activation code
5. Grant Accessibility permission when prompted

## Required Permission

MacCtrlCVA requires:

- `System Settings > Privacy & Security > Accessibility`

Without Accessibility permission, global shortcut remapping will not work.

## Notes

- `Fn` handling depends on the keyboard and macOS device behavior, so this release is intended to improve ergonomics especially on Mac laptops
- Existing activation flows remain supported
- If macOS blocks the first launch, use right-click `Open` or allow it in System Settings
