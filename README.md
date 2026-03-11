# MacCtrlCVA

MacCtrlCVA is a lightweight macOS menu bar utility that lets Windows-style `Ctrl` shortcuts work like native macOS `Command` shortcuts.

It is built for people who switch between Windows and macOS and want their copy, paste, select-all, undo, app switching, and input method muscle memory to keep working.

## Features

- Remaps `Ctrl+C` to `Command+C`
- Remaps `Ctrl+V` to `Command+V`
- Remaps `Ctrl+A` to `Command+A`
- Remaps `Ctrl+Z` to `Command+Z`
- Remaps `Option+Tab` to `Command+Tab` for Windows-style app switching
- Remaps `Ctrl+Shift` to switch to the next enabled input source
- Uses physical `keyCode`, so it works across input methods like English and Chinese Pinyin
- Runs as a lightweight menu bar app
- Supports enable / disable from the menu bar
- Supports launch at login
- Includes an `About` item in the menu bar menu

## How It Works

MacCtrlCVA uses a global Quartz Event Tap to listen for `keyDown` and `flagsChanged` events system-wide.

When all of the following are true:

- `Control` is pressed
- `Command` is not pressed
- The pressed `keyCode` matches one of the supported shortcuts

the app:

1. Suppresses the original event
2. Posts a synthetic event with the `Command` modifier instead

Supported key codes:

- `A = 0`
- `C = 8`
- `V = 9`
- `Z = 6`

This keeps the remapping stable regardless of the active input method.

For input source switching, the app uses macOS input source APIs directly instead of simulating characters, so `Ctrl+Shift` can rotate through enabled keyboard input sources reliably.

## Requirements

- macOS 13 or later
- Accessibility permission enabled for the app
- Full Xcode if you want to build from source

## Install

### Option 1: Download a release

1. Download the latest `.dmg` from the [Releases](https://github.com/NightSensingLab/MacCtrlCVA/releases) page.
2. Open the DMG.
3. Drag `MacCtrlCVA.app` into `Applications`.
4. Launch the app.

If macOS blocks the app on first launch:

1. Right-click `MacCtrlCVA.app`
2. Click `Open`
3. Confirm the security prompt

### Option 2: Build from source

1. Open [MacCtrlCVA.xcodeproj](/Users/maguamale/Projects/MacCtrlCVA/MacCtrlCVA.xcodeproj) in Xcode
2. Select the `MacCtrlCVA` target
3. Set your signing team in `Signing & Capabilities`
4. Build and run

## First Run Setup

MacCtrlCVA needs Accessibility permission to monitor and post keyboard events.

1. Launch `MacCtrlCVA`
2. Open `System Settings`
3. Go to `Privacy & Security` -> `Accessibility`
4. Enable access for `MacCtrlCVA`
5. Quit and relaunch the app if needed

After permission is granted, the menu bar app will start remapping shortcuts system-wide.

## Menu Bar Controls

The menu bar app includes:

- About dialog with version information
- Enable / disable remapping
- Launch at login toggle
- Quick access to the Accessibility permission flow
- Quit action

## Build a DMG

You can package the app into a DMG with:

```bash
chmod +x scripts/make-dmg.sh
./scripts/make-dmg.sh
```

The script will:

1. Build the app in `Release`
2. Copy `MacCtrlCVA.app` into a staging folder
3. Add an `Applications` shortcut
4. Create `release/MacCtrlCVA.dmg`

To build a debug DMG instead:

```bash
CONFIGURATION=Debug ./scripts/make-dmg.sh
```

## Project Structure

- `MacCtrlCVA/AppDelegate.swift`: menu bar app bootstrap and menu actions
- `MacCtrlCVA/EventTapManager.swift`: global keyboard interception and remapping
- `MacCtrlCVA/InputSourceManager.swift`: keyboard input source enumeration and switching
- `MacCtrlCVA/AccessibilityPermissionManager.swift`: permission checks and prompt flow
- `MacCtrlCVA/LaunchAtLoginManager.swift`: launch-at-login integration
- `MacCtrlCVA/Info.plist`: app metadata and background app configuration
- `scripts/make-dmg.sh`: local DMG packaging script

## Notes

- Native macOS shortcuts are preserved when `Command` is already pressed
- `Option+Tab` is intentionally remapped to `Command+Tab` to match the Windows `Alt+Tab` habit
- The app runs in the menu bar and does not show a Dock icon
- Launch at login uses `SMAppService.mainApp`
- For open source distribution without paid Apple signing, users may need to manually confirm the app on first launch
