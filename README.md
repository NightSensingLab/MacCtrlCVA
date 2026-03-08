# MacCtrlCVA

MacCtrlCVA is a lightweight macOS menu bar utility that remaps Windows-style `Ctrl+C`, `Ctrl+V`, `Ctrl+A`, and `Ctrl+Z` into native macOS `Command+C`, `Command+V`, `Command+A`, and `Command+Z`.

## Project architecture

- `MacCtrlCVA/AppDelegate.swift`: Menu bar app bootstrap, menu actions, enable/disable toggle, launch-at-login toggle.
- `MacCtrlCVA/EventTapManager.swift`: Quartz event tap setup and global `keyDown` interception.
- `MacCtrlCVA/AccessibilityPermissionManager.swift`: Accessibility trust check and permission prompt.
- `MacCtrlCVA/LaunchAtLoginManager.swift`: `SMAppService.mainApp` wrapper for login item registration.
- `MacCtrlCVA/Info.plist`: Background-agent app configuration (`LSUIElement`).
- `MacCtrlCVA.xcodeproj`: Xcode project file.

## Keyboard remapping logic

The event tap listens for global `keyDown` events only. For each event:

1. Read the physical `keyCode`.
2. Check that `Control` is pressed.
3. Check that `Command` is not pressed.
4. Match the `keyCode` against:
   - `A = 0`
   - `C = 8`
   - `V = 9`
   - `Z = 6`
5. Suppress the original event.
6. Post synthetic `Command` key down/up events with the same `keyCode`.

Because the logic uses `keyCode` instead of characters, it remains stable across input methods like English and Chinese Pinyin.

## Accessibility permission

This app uses a Quartz event tap and posts synthetic keyboard events, so macOS requires Accessibility permission.

1. Launch the app.
2. When prompted, open System Settings.
3. Go to `Privacy & Security` -> `Accessibility`.
4. Enable access for `MacCtrlCVA`.
5. Quit and relaunch the app if macOS does not activate the permission immediately.

## Build and run in Xcode

1. Open [MacCtrlCVA.xcodeproj](/Users/maguamale/Projects/MacCtrlCVA/MacCtrlCVA.xcodeproj) in Xcode.
2. Select the `MacCtrlCVA` target.
3. Set your own signing team in `Signing & Capabilities`.
4. Build and run.
5. After launch, a keyboard icon appears in the menu bar.
6. Grant Accessibility permission when prompted.
7. Use the menu bar menu to enable or disable remapping and to toggle launch at login.

## Create a DMG

To build a release app and package it as a DMG:

```bash
chmod +x scripts/make-dmg.sh
./scripts/make-dmg.sh
```

The script:

1. Builds the `MacCtrlCVA` scheme in `Release`
2. Copies `MacCtrlCVA.app` into a DMG staging folder
3. Adds an `Applications` symlink for drag-and-drop install
4. Writes the final DMG to `release/MacCtrlCVA.dmg`

If you want a different build configuration, run:

```bash
CONFIGURATION=Debug ./scripts/make-dmg.sh
```

## Notes

- The app does not remap anything when `Command` is already held, so native macOS shortcuts continue to work.
- The app is a menu bar background app and does not show a Dock icon.
- Launch at login uses `SMAppService.mainApp`, which requires macOS 13 or newer.
