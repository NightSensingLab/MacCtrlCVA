import CoreGraphics
import Foundation

enum ShortcutTriggerModifier: String, CaseIterable {
    case control
    case function

    var menuTitle: String {
        switch self {
        case .control:
            return "Control + Letter"
        case .function:
            return "Fn + Letter"
        }
    }

    var displayName: String {
        switch self {
        case .control:
            return "Ctrl"
        case .function:
            return "Fn"
        }
    }

    var flag: CGEventFlags {
        switch self {
        case .control:
            return .maskControl
        case .function:
            return .maskSecondaryFn
        }
    }

    func matches(_ flags: CGEventFlags) -> Bool {
        guard flags.contains(flag), !flags.contains(.maskCommand) else {
            return false
        }

        switch self {
        case .control:
            return !flags.contains(.maskSecondaryFn) &&
                !flags.contains(.maskAlternate) &&
                !flags.contains(.maskShift)
        case .function:
            return !flags.contains(.maskControl) &&
                !flags.contains(.maskAlternate) &&
                !flags.contains(.maskShift)
        }
    }
}

struct ShortcutMappingSettings {
    private static let enabledModifiersKey = "shortcutMapping.enabledModifiers"

    var enabledModifiers: Set<ShortcutTriggerModifier>

    static var defaultSettings: ShortcutMappingSettings {
        ShortcutMappingSettings(enabledModifiers: [.control])
    }

    static func load() -> ShortcutMappingSettings {
        let defaults = UserDefaults.standard
        guard let rawValues = defaults.array(forKey: enabledModifiersKey) as? [String] else {
            return defaultSettings
        }

        let modifiers = Set(rawValues.compactMap(ShortcutTriggerModifier.init(rawValue:)))
        guard !modifiers.isEmpty else {
            return defaultSettings
        }

        return ShortcutMappingSettings(enabledModifiers: modifiers)
    }

    func save() {
        let rawValues = enabledModifiers.map(\.rawValue).sorted()
        UserDefaults.standard.set(rawValues, forKey: Self.enabledModifiersKey)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: enabledModifiersKey)
    }

    func matchingModifier(for flags: CGEventFlags) -> ShortcutTriggerModifier? {
        ShortcutTriggerModifier.allCases.first { modifier in
            enabledModifiers.contains(modifier) && modifier.matches(flags)
        }
    }

    var summary: String {
        ShortcutTriggerModifier.allCases
            .filter { enabledModifiers.contains($0) }
            .map(\.displayName)
            .joined(separator: " / ")
    }
}
