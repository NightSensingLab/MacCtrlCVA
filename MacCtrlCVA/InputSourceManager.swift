import Carbon
import Foundation

final class InputSourceManager {
    func selectNextInputSource() {
        guard
            let sources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource],
            let current = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
        else {
            return
        }

        let availableSources = sources.filter { source in
            stringValue(for: source, key: kTISPropertyInputSourceCategory) == (kTISCategoryKeyboardInputSource as String) &&
            boolValue(for: source, key: kTISPropertyInputSourceIsEnabled) &&
            boolValue(for: source, key: kTISPropertyInputSourceIsSelectCapable)
        }

        guard
            !availableSources.isEmpty,
            let currentID = stringValue(for: current, key: kTISPropertyInputSourceID),
            let currentIndex = availableSources.firstIndex(where: { stringValue(for: $0, key: kTISPropertyInputSourceID) == currentID })
        else {
            return
        }

        let nextIndex = availableSources.index(after: currentIndex) == availableSources.endIndex ? availableSources.startIndex : availableSources.index(after: currentIndex)
        TISSelectInputSource(availableSources[nextIndex])
    }

    private func stringValue(for source: TISInputSource, key: CFString) -> String? {
        guard let value = TISGetInputSourceProperty(source, key) else {
            return nil
        }

        return Unmanaged<CFString>.fromOpaque(value).takeUnretainedValue() as String
    }

    private func boolValue(for source: TISInputSource, key: CFString) -> Bool {
        guard let value = TISGetInputSourceProperty(source, key) else {
            return false
        }

        return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(value).takeUnretainedValue())
    }
}
