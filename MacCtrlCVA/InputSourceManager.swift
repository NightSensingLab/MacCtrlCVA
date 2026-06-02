import CoreGraphics
import Foundation

final class InputSourceManager {
    private static let inputSourceShortcutKeyCode: CGKeyCode = 49

    func selectNextInputSource() {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            return
        }

        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: Self.inputSourceShortcutKeyCode, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: Self.inputSourceShortcutKeyCode, keyDown: false)
        else {
            return
        }

        for event in [keyDown, keyUp] {
            event.flags = [.maskControl]
            event.post(tap: .cghidEventTap)
        }
    }
}
