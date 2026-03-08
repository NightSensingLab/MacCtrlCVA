# MacCtrlCVA v1.0.0

First public release of MacCtrlCVA.

## What It Does

MacCtrlCVA is a lightweight macOS menu bar utility that remaps common Windows-style `Ctrl` shortcuts into native macOS `Command` shortcuts:

- `Ctrl+C` -> `Command+C`
- `Ctrl+V` -> `Command+V`
- `Ctrl+A` -> `Command+A`
- `Ctrl+Z` -> `Command+Z`

The remapping is based on physical `keyCode`, not typed characters, so it works correctly across different input methods such as English and Chinese Pinyin.

## Included In This Release

- Global Quartz Event Tap keyboard remapping
- Menu bar background app
- Enable / disable toggle
- Launch at login toggle
- Accessibility permission prompt flow
- DMG packaging support for local release builds

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
- Native macOS shortcuts are not overridden when `Command` is already pressed
