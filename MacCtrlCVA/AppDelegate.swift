import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let eventTapManager = EventTapManager()
    private let accessibilityManager = AccessibilityPermissionManager()
    private let launchAtLoginManager = LaunchAtLoginManager()

    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private let statusMenuItem = NSMenuItem(title: "Status: Disabled", action: nil, keyEquivalent: "")
    private let accessibilityMenuItem = NSMenuItem(title: "Grant Accessibility Access", action: #selector(requestAccessibilityPermission), keyEquivalent: "")
    private let enableMenuItem = NSMenuItem(title: "Enable Remapping", action: #selector(toggleEnabled), keyEquivalent: "")
    private let launchAtLoginMenuItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private let aboutMenuItem = NSMenuItem(title: "About MacCtrlCVA", action: #selector(showAbout), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("MacCtrlCVA launched")
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configureMenu()
        syncAccessibilityState(promptIfNeeded: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        eventTapManager.stop()
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = makeStatusBarIcon()
            button.image?.isTemplate = true
            button.imagePosition = .imageOnly
            button.toolTip = "MacCtrlCVA"
        } else {
            print("MacCtrlCVA failed to create status bar button")
        }
        statusItem.menu = menu
    }

    private func configureMenu() {
        statusMenuItem.isEnabled = false

        accessibilityMenuItem.target = self
        enableMenuItem.target = self
        launchAtLoginMenuItem.target = self
        aboutMenuItem.target = self
        launchAtLoginMenuItem.state = launchAtLoginManager.isEnabled ? .on : .off

        menu.addItem(statusMenuItem)
        menu.addItem(.separator())
        menu.addItem(aboutMenuItem)
        menu.addItem(accessibilityMenuItem)
        menu.addItem(enableMenuItem)
        menu.addItem(launchAtLoginMenuItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q").target = self
    }

    private func syncAccessibilityState(promptIfNeeded: Bool) {
        let isTrusted = accessibilityManager.ensurePermission(prompt: promptIfNeeded)
        print("Accessibility trusted: \(isTrusted)")
        accessibilityMenuItem.isHidden = isTrusted
        enableMenuItem.isEnabled = isTrusted

        if isTrusted {
            eventTapManager.start()
            statusMenuItem.title = eventTapManager.isEnabled ? "Status: Enabled" : "Status: Disabled"
            enableMenuItem.title = eventTapManager.isEnabled ? "Disable Remapping" : "Enable Remapping"
            if !eventTapManager.isEnabled {
                showAlert(
                    title: "Event Tap Failed",
                    message: "MacCtrlCVA started, but the global keyboard event tap could not be created."
                )
            }
        } else {
            eventTapManager.stop()
            statusMenuItem.title = "Status: Accessibility Permission Required"
            enableMenuItem.title = "Enable Remapping"
            showAlert(
                title: "Accessibility Permission Required",
                message: "Open System Settings > Privacy & Security > Accessibility, enable MacCtrlCVA, then relaunch the app."
            )
        }
    }

    @objc
    private func requestAccessibilityPermission() {
        syncAccessibilityState(promptIfNeeded: true)
    }

    @objc
    private func toggleEnabled() {
        guard accessibilityManager.isTrusted else {
            syncAccessibilityState(promptIfNeeded: true)
            return
        }

        if eventTapManager.isEnabled {
            eventTapManager.stop()
        } else {
            eventTapManager.start()
        }

        statusMenuItem.title = eventTapManager.isEnabled ? "Status: Enabled" : "Status: Disabled"
        enableMenuItem.title = eventTapManager.isEnabled ? "Disable Remapping" : "Enable Remapping"
    }

    @objc
    private func toggleLaunchAtLogin() {
        do {
            if launchAtLoginManager.isEnabled {
                try launchAtLoginManager.disable()
                launchAtLoginMenuItem.state = .off
            } else {
                try launchAtLoginManager.enable()
                launchAtLoginMenuItem.state = .on
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Launch at Login Error"
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    @objc
    private func showAbout() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"

        showAlert(
            title: "About MacCtrlCVA",
            message: """
            Version \(version) (\(build))

            Windows-style shortcut remapping for macOS:
            Ctrl+C/V/A/Z, Option+Tab, and Ctrl+Shift input switching.
            """
        )
    }

    @objc
    private func quit() {
        NSApp.terminate(nil)
    }

    private func showAlert(title: String, message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func makeStatusBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.black.setStroke()

        let strokeWidth: CGFloat = 1.8
        let capRadius: CGFloat = 3.2
        let topY: CGFloat = 5.5
        let bottomY: CGFloat = 12.5
        let leftX: CGFloat = 5.5
        let rightX: CGFloat = 12.5
        let midX: CGFloat = 9.0
        let midY: CGFloat = 9.0

        let vertical = NSBezierPath()
        vertical.lineWidth = strokeWidth
        vertical.lineCapStyle = .round
        vertical.move(to: NSPoint(x: midX, y: 2.8))
        vertical.line(to: NSPoint(x: midX, y: 15.2))
        vertical.stroke()

        let horizontal = NSBezierPath()
        horizontal.lineWidth = strokeWidth
        horizontal.lineCapStyle = .round
        horizontal.move(to: NSPoint(x: 2.8, y: midY))
        horizontal.line(to: NSPoint(x: 15.2, y: midY))
        horizontal.stroke()

        for center in [
            NSPoint(x: leftX, y: topY),
            NSPoint(x: rightX, y: topY),
            NSPoint(x: leftX, y: bottomY),
            NSPoint(x: rightX, y: bottomY)
        ] {
            let loop = NSBezierPath()
            loop.lineWidth = strokeWidth
            loop.appendOval(in: NSRect(x: center.x - capRadius, y: center.y - capRadius, width: capRadius * 2, height: capRadius * 2))
            loop.stroke()
        }

        let centerCutout = NSBezierPath(roundedRect: NSRect(x: midX - 1.7, y: midY - 1.7, width: 3.4, height: 3.4), xRadius: 0.8, yRadius: 0.8)
        NSColor.clear.setFill()
        centerCutout.fill()

        image.unlockFocus()
        return image
    }
}
