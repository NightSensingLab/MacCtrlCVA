import Foundation
import ServiceManagement

final class LaunchAtLoginManager {
    var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    func enable() throws {
        guard #available(macOS 13.0, *) else {
            throw LaunchAtLoginError.unsupportedOS
        }
        try SMAppService.mainApp.register()
    }

    func disable() throws {
        guard #available(macOS 13.0, *) else {
            throw LaunchAtLoginError.unsupportedOS
        }
        try SMAppService.mainApp.unregister()
    }
}

enum LaunchAtLoginError: LocalizedError {
    case unsupportedOS

    var errorDescription: String? {
        switch self {
        case .unsupportedOS:
            return "Launch at Login requires macOS 13 or newer."
        }
    }
}
