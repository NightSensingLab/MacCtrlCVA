# MacCtrlCVA v2.0.1

MacCtrlCVA v2.0.1 is a bugfix release for the configurable shortcut mapping introduced in v2.0.0.

## Fixed

- Made `Control + Letter` and `Fn + Letter` mutually exclusive shortcut modes
- Updated input source switching to follow the selected shortcut mode:
  - `Control + Letter` mode uses `Control + Shift`
  - `Fn + Letter` mode uses `Fn + Shift`
- Improved input source switching by routing through macOS' native input source shortcut path
- Added migration for older v2.0.0 settings where both shortcut modes may have been enabled

## Current Shortcut Support

- Editing shortcuts:
  - `Control + C/V/X/A/Z`
  - or `Fn + C/V/X/A/Z`
  - selected from the menu bar
- App switcher:
  - `Option + Tab` -> `Command + Tab`
- Input source switching:
  - follows the selected shortcut mode

## Installation

1. Download `MacCtrlCVA-v2.0.1.dmg`
2. Drag `MacCtrlCVA.app` into `Applications`
3. Launch the app
4. Activate the app with your activation code
5. Grant Accessibility permission when prompted

## Notes

- If upgrading from v2.0.0, check the `Shortcut Mapping` menu after launch
- Existing activation codes remain supported
- macOS may require right-click `Open` or manual approval in System Settings on first launch
