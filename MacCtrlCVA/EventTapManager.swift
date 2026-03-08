import ApplicationServices
import CoreGraphics
import Foundation

final class EventTapManager {
    private enum ShortcutKey: Int64 {
        case a = 0
        case c = 8
        case v = 9
        case z = 6
    }

    private static let syntheticEventMarker: Int64 = 0x4D435641

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var isEnabled: Bool {
        eventTap != nil
    }

    func start() {
        guard eventTap == nil else { return }

        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)

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

        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        guard flags.contains(.maskControl), !flags.contains(.maskCommand) else {
            return Unmanaged.passUnretained(event)
        }

        guard ShortcutKey(rawValue: keyCode) != nil else {
            return Unmanaged.passUnretained(event)
        }

        postSyntheticCommandShortcut(for: event, keyCode: keyCode)
        return nil
    }

    private func postSyntheticCommandShortcut(for originalEvent: CGEvent, keyCode: Int64) {
        guard
            let source = CGEventSource(stateID: .hidSystemState),
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: false)
        else {
            return
        }

        var forwardedFlags = originalEvent.flags
        forwardedFlags.remove(.maskControl)
        forwardedFlags.insert(.maskCommand)

        for event in [keyDown, keyUp] {
            event.flags = forwardedFlags
            event.setIntegerValueField(.eventSourceUserData, value: Self.syntheticEventMarker)
            event.post(tap: .cghidEventTap)
        }
    }
}
