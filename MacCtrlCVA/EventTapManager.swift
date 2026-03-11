import ApplicationServices
import CoreGraphics
import Foundation

final class EventTapManager {
    private enum CommandShortcutKey: Int64 {
        case a = 0
        case c = 8
        case v = 9
        case z = 6
    }

    private enum AppSwitcherKey: Int64 {
        case tab = 48
    }

    private static let syntheticEventMarker: Int64 = 0x4D435641

    private let inputSourceManager = InputSourceManager()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var previousFlags: CGEventFlags = []

    var isEnabled: Bool {
        eventTap != nil
    }

    func start() {
        guard eventTap == nil else { return }

        let eventMask = CGEventMask((1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue))

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            let manager = Unmanaged<EventTapManager>.fromOpaque(refcon!).takeUnretainedValue()
            return manager.handle(type: type, event: event)
        }

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: refcon
        ) else {
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
        previousFlags = []
    }

    func stop() {
        guard let tap = eventTap, let source = runLoopSource else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        eventTap = nil
        runLoopSource = nil
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        if event.getIntegerValueField(.eventSourceUserData) == Self.syntheticEventMarker {
            return Unmanaged.passUnretained(event)
        }

        if type == .flagsChanged {
            let result = handleFlagsChanged(event)
            previousFlags = event.flags
            return result
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        if flags.contains(.maskControl), !flags.contains(.maskCommand), CommandShortcutKey(rawValue: keyCode) != nil {
            postSyntheticShortcut(for: event, keyCode: keyCode, removing: .maskControl, adding: .maskCommand)
            return nil
        }

        if flags.contains(.maskAlternate), !flags.contains(.maskCommand), AppSwitcherKey(rawValue: keyCode) == .tab {
            postSyntheticShortcut(for: event, keyCode: keyCode, removing: .maskAlternate, adding: .maskCommand)
            return nil
        }

        return Unmanaged.passUnretained(event)
    }

    private func handleFlagsChanged(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        let currentFlags = event.flags
        let isCtrlShiftOnly = currentFlags.contains(.maskControl) &&
            currentFlags.contains(.maskShift) &&
            !currentFlags.contains(.maskCommand) &&
            !currentFlags.contains(.maskAlternate)
        let wasCtrlShiftOnly = previousFlags.contains(.maskControl) &&
            previousFlags.contains(.maskShift) &&
            !previousFlags.contains(.maskCommand) &&
            !previousFlags.contains(.maskAlternate)

        guard isCtrlShiftOnly, !wasCtrlShiftOnly else {
            return Unmanaged.passUnretained(event)
        }

        inputSourceManager.selectNextInputSource()
        return nil
    }

    private func postSyntheticShortcut(
        for originalEvent: CGEvent,
        keyCode: Int64,
        removing removedModifier: CGEventFlags,
        adding addedModifier: CGEventFlags
    ) {
        guard
            let source = CGEventSource(stateID: .hidSystemState),
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: false)
        else {
            return
        }

        var forwardedFlags = originalEvent.flags
        forwardedFlags.remove(removedModifier)
        forwardedFlags.insert(addedModifier)

        for event in [keyDown, keyUp] {
            event.flags = forwardedFlags
            event.setIntegerValueField(.eventSourceUserData, value: Self.syntheticEventMarker)
            event.post(tap: .cghidEventTap)
        }
    }
}
