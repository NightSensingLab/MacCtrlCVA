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
    private static let activeModifierKey = "shortcutMapping.activeModifier"
    private static let legacyEnabledModifiersKey = "shortcutMapping.enabledModifiers"

    var activeModifier: ShortcutTriggerModifier

    static var defaultSettings: ShortcutMappingSettings {
        ShortcutMappingSettings(activeModifier: .control)
    }

    static func load() -> ShortcutMappingSettings {
        let defaults = UserDefaults.standard
        if let rawValue = defaults.string(forKey: activeModifierKey),
           let modifier = ShortcutTriggerModifier(rawValue: rawValue) {
            return ShortcutMappingSettings(activeModifier: modifier)
        }

        guard let rawValues = defaults.array(forKey: legacyEnabledModifiersKey) as? [String] else {
            return defaultSettings
        }

        guard let modifier = rawValues.compactMap(ShortcutTriggerModifier.init(rawValue:)).first else {
            return defaultSettings
        }

        let migratedSettings = ShortcutMappingSettings(activeModifier: modifier)
        migratedSettings.save()
        defaults.removeObject(forKey: legacyEnabledModifiersKey)
        return migratedSettings
    }

    func save() {
        UserDefaults.standard.set(activeModifier.rawValue, forKey: Self.activeModifierKey)
        UserDefaults.standard.removeObject(forKey: Self.legacyEnabledModifiersKey)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: activeModifierKey)
        UserDefaults.standard.removeObject(forKey: legacyEnabledModifiersKey)
    }

    func matchingModifier(for flags: CGEventFlags) -> ShortcutTriggerModifier? {
        activeModifier.matches(flags) ? activeModifier : nil
    }

    var summary: String {
        activeModifier.displayName
    }
}
