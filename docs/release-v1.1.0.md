# MacCtrlCVA v1.1.0

This release expands MacCtrlCVA beyond copy and paste muscle memory and adds app switching, input source switching, and version info in the menu bar.

## New In v1.1.0

- `Option+Tab` -> `Command+Tab`
- `Ctrl+Shift` switches to the next enabled input source
- New `About MacCtrlCVA` menu item with version information

## Current Shortcut Support

- `Ctrl+C` -> `Command+C`
- `Ctrl+V` -> `Command+V`
- `Ctrl+A` -> `Command+A`
- `Ctrl+Z` -> `Command+Z`
- `Option+Tab` -> `Command+Tab`
- `Ctrl+Shift` -> next enabled input source

## Behavior Notes

- Character shortcuts are remapped using physical `keyCode`
- Input source switching uses macOS input source APIs directly
- Native macOS shortcuts are preserved when `Command` is already held
- The app continues to run as a lightweight menu bar utility

## Installation

1. Download `MacCtrlCVA.dmg`
2. Open the DMG
3. Drag `MacCtrlCVA.app` into `Applications`
4. Launch the app

If macOS blocks the app on first launch:

1. Right-click the app
2. Choose `Open`
3. Confirm the system prompt

## Required Permission

MacCtrlCVA needs Accessibility permission to monitor and post keyboard events:

1. Open `System Settings`
2. Go to `Privacy & Security` -> `Accessibility`
3. Enable `MacCtrlCVA`

## Notes

- macOS 13 or later is recommended
- This release is intended for direct download distribution
