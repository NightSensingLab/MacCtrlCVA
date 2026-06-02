import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let eventTapManager = EventTapManager()
    private let accessibilityManager = AccessibilityPermissionManager()
    private let licensingManager = LicensingManager()
    private let launchAtLoginManager = LaunchAtLoginManager()
    private var hasShownActivationGuidance = false

    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private let statusMenuItem = NSMenuItem(title: "Status: Disabled", action: nil, keyEquivalent: "")
    private let licenseStatusMenuItem = NSMenuItem(title: "License: Not activated", action: nil, keyEquivalent: "")
    private let machineCodeStatusMenuItem = NSMenuItem(title: "Machine Code: Loading...", action: nil, keyEquivalent: "")
    private let machineCodeMenuItem = NSMenuItem(title: "Copy Machine Code", action: #selector(showMachineCode), keyEquivalent: "")
    private let activationMenuItem = NSMenuItem(title: "Open Activation Settings", action: #selector(showActivationSettings), keyEquivalent: "")
    private let accessibilityMenuItem = NSMenuItem(title: "Grant Accessibility Access", action: #selector(requestAccessibilityPermission), keyEquivalent: "")
    private let enableMenuItem = NSMenuItem(title: "Enable Remapping", action: #selector(toggleEnabled), keyEquivalent: "")
    private let shortcutMappingMenuItem = NSMenuItem(title: "Shortcut Mapping", action: nil, keyEquivalent: "")
    private let shortcutMappingMenu = NSMenu()
    private let shortcutMappingSummaryMenuItem = NSMenuItem(title: "Editing shortcuts: Ctrl + C/V/X/A/Z", action: nil, keyEquivalent: "")
    private let controlShortcutMenuItem = NSMenuItem(title: ShortcutTriggerModifier.control.menuTitle, action: #selector(toggleShortcutModifier(_:)), keyEquivalent: "")
    private let functionShortcutMenuItem = NSMenuItem(title: ShortcutTriggerModifier.function.menuTitle, action: #selector(toggleShortcutModifier(_:)), keyEquivalent: "")
    private let resetShortcutMappingMenuItem = NSMenuItem(title: "Restore Default Mapping", action: #selector(resetShortcutMapping), keyEquivalent: "")
    private let launchAtLoginMenuItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private let aboutMenuItem = NSMenuItem(title: "About MacCtrlCVA", action: #selector(showAbout), keyEquivalent: "")

    private enum ActivationDialogAction {
        case activate(String)
        case deactivate
        case cancel
    }

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
        licenseStatusMenuItem.isEnabled = false
        machineCodeStatusMenuItem.isEnabled = false

        machineCodeMenuItem.target = self
        activationMenuItem.target = self
        accessibilityMenuItem.target = self
        enableMenuItem.target = self
        controlShortcutMenuItem.target = self
        functionShortcutMenuItem.target = self
        resetShortcutMappingMenuItem.target = self
        controlShortcutMenuItem.representedObject = ShortcutTriggerModifier.control.rawValue
        functionShortcutMenuItem.representedObject = ShortcutTriggerModifier.function.rawValue
        shortcutMappingSummaryMenuItem.isEnabled = false
        launchAtLoginMenuItem.target = self
        aboutMenuItem.target = self
        launchAtLoginMenuItem.state = launchAtLoginManager.isEnabled ? .on : .off

        shortcutMappingMenu.addItem(shortcutMappingSummaryMenuItem)
        shortcutMappingMenu.addItem(.separator())
        shortcutMappingMenu.addItem(controlShortcutMenuItem)
        shortcutMappingMenu.addItem(functionShortcutMenuItem)
        shortcutMappingMenu.addItem(.separator())
        shortcutMappingMenu.addItem(resetShortcutMappingMenuItem)
        shortcutMappingMenuItem.submenu = shortcutMappingMenu
        refreshShortcutMappingMenuState()

        menu.addItem(statusMenuItem)
        menu.addItem(.separator())
        menu.addItem(licenseStatusMenuItem)
        menu.addItem(machineCodeStatusMenuItem)
        menu.addItem(.separator())
        menu.addItem(aboutMenuItem)
        menu.addItem(machineCodeMenuItem)
        menu.addItem(activationMenuItem)
        menu.addItem(accessibilityMenuItem)
        menu.addItem(enableMenuItem)
        menu.addItem(shortcutMappingMenuItem)
        menu.addItem(launchAtLoginMenuItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q").target = self
    }

    private func syncAccessibilityState(promptIfNeeded: Bool) {
        refreshLicenseMenuState()

        guard licensingManager.isActivated else {
            eventTapManager.stop()
            statusMenuItem.title = "Status: Activation Required"
            activationMenuItem.title = "Activate MacCtrlCVA"
            enableMenuItem.isEnabled = false
            enableMenuItem.title = "Enable Remapping"
            accessibilityMenuItem.isHidden = false
            maybeShowActivationGuidance()
            return
        }

        let isTrusted = accessibilityManager.ensurePermission(prompt: promptIfNeeded)
        print("Accessibility trusted: \(isTrusted)")
        activationMenuItem.title = "Activation Settings"
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

    private func refreshLicenseMenuState() {
        let machineCode: String
        do {
            machineCode = try licensingManager.currentMachineCode()
        } catch {
            machineCode = "Unavailable"
        }

        machineCodeStatusMenuItem.title = "Machine Code: \(machineCode)"

        if let license = licensingManager.currentLicense() {
            licenseStatusMenuItem.title = "License: Activated (\(license.machineCodes.count)/\(license.maxMachines) machine slots)"
        } else {
            licenseStatusMenuItem.title = "License: Not activated"
        }
    }

    private func maybeShowActivationGuidance() {
        guard !hasShownActivationGuidance else { return }
        hasShownActivationGuidance = true

        showAlert(
            title: "Activation Required",
            message: """
            1. Open “Copy Machine Code”
            2. Send the machine code to the seller
            3. Paste the activation code into “Activation Settings”
            """
        )
    }

    @objc
    private func requestAccessibilityPermission() {
        syncAccessibilityState(promptIfNeeded: true)
    }

    @objc
    private func toggleEnabled() {
        guard licensingManager.isActivated else {
            showAlert(
                title: "Activation Required",
                message: "Generate a machine code, send it to the seller, then enter the activation code in Activation Settings."
            )
            return
        }

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
        let activationState = licensingManager.isActivated ? "Activated" : "Not activated"
        let machineCode = (try? licensingManager.currentMachineCode()) ?? "Unavailable"

        showAlert(
            title: "About MacCtrlCVA",
            message: """
            Version \(version) (\(build))
            \(activationState)
            Machine code: \(machineCode)

            Windows-style shortcut remapping for macOS:
            configurable copy/paste/cut/select-all/undo shortcuts,
            Option+Tab, and mode-aware input switching.
            """
        )
    }

    @objc
    private func toggleShortcutModifier(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let modifier = ShortcutTriggerModifier(rawValue: rawValue)
        else {
            return
        }

        let settings = ShortcutMappingSettings(activeModifier: modifier)
        settings.save()
        eventTapManager.reloadShortcutSettings()
        refreshShortcutMappingMenuState()
    }

    @objc
    private func resetShortcutMapping() {
        ShortcutMappingSettings.reset()
        eventTapManager.reloadShortcutSettings()
        refreshShortcutMappingMenuState()
    }

    private func refreshShortcutMappingMenuState() {
        let settings = ShortcutMappingSettings.load()
        controlShortcutMenuItem.state = settings.activeModifier == .control ? .on : .off
        functionShortcutMenuItem.state = settings.activeModifier == .function ? .on : .off
        shortcutMappingSummaryMenuItem.title = "Editing: \(settings.summary) + C/V/X/A/Z, Input: \(settings.summary) + Shift"
    }

    @objc
    private func showMachineCode() {
        do {
            let machineCode = try licensingManager.currentMachineCode()
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(machineCode, forType: .string)

            showAlert(
                title: "Machine Code",
                message: """
                \(machineCode)

                The machine code has been copied to the clipboard.
                Send this code to the seller to receive an activation code.
                """
            )
        } catch {
            showAlert(title: "Machine Code Error", message: error.localizedDescription)
        }
    }

    @objc
    private func showActivationSettings() {
        let machineCode: String
        do {
            machineCode = try licensingManager.currentMachineCode()
        } catch {
            machineCode = "Unavailable"
        }

        switch runActivationDialog(machineCode: machineCode, existingActivationCode: licensingManager.activationCode()) {
        case .activate(let activationCode):
            do {
                try licensingManager.activate(with: activationCode)
                syncAccessibilityState(promptIfNeeded: true)
                let activationStatus = licenseStatusMenuItem.title.replacingOccurrences(of: "License: ", with: "")
                showAlert(
                    title: "Activation Successful",
                    message: """
                    MacCtrlCVA has been activated on this Mac.

                    \(activationStatus)
                    """
                )
            } catch {
                showAlert(title: "Activation Failed", message: error.localizedDescription)
            }
        case .deactivate:
            licensingManager.deactivate()
            syncAccessibilityState(promptIfNeeded: false)
            showAlert(title: "Activation Removed", message: "The stored activation code has been removed from this Mac.")
        case .cancel:
            return
        }
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

    private func runActivationDialog(machineCode: String, existingActivationCode: String?) -> ActivationDialogAction {
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Activation Settings"
        panel.isFloatingPanel = true
        panel.level = .modalPanel
        panel.center()

        let contentView = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
        contentView.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = contentView
        let stackView = NSStackView()

        let titleLabel = NSTextField(labelWithString: "Activation Settings")
        titleLabel.font = .boldSystemFont(ofSize: 18)

        let statusText = licensingManager.isActivated ? "Status: Activated" : "Status: Not activated"
        let statusLabel = NSTextField(labelWithString: statusText)
        statusLabel.textColor = licensingManager.isActivated ? .systemGreen : .secondaryLabelColor

        let instructionsLabel = NSTextField(wrappingLabelWithString: "Paste the activation code you received from the seller. The activation code must match this machine code.")
        instructionsLabel.textColor = .secondaryLabelColor

        let machineCodeTitleLabel = NSTextField(labelWithString: "Current machine code")
        machineCodeTitleLabel.font = .systemFont(ofSize: 12, weight: .semibold)

        let machineCodeField = NSTextField(string: machineCode)
        machineCodeField.isEditable = false
        machineCodeField.isBordered = true
        machineCodeField.focusRingType = .none
        machineCodeField.lineBreakMode = .byTruncatingMiddle

        let copyButton = NSButton(title: "Copy", target: nil, action: nil)

        let activationCodeTitleLabel = NSTextField(labelWithString: "Activation code")
        activationCodeTitleLabel.font = .systemFont(ofSize: 12, weight: .semibold)

        let activationCodeField = NSTextField(string: existingActivationCode ?? "")
        activationCodeField.placeholderString = "Paste activation code here"

        let activateButton = NSButton(title: "Activate", target: nil, action: nil)
        activateButton.bezelStyle = .rounded
        activateButton.keyEquivalent = "\r"

        let deactivateButton = NSButton(title: "Deactivate", target: nil, action: nil)
        deactivateButton.isEnabled = licensingManager.isActivated

        let cancelButton = NSButton(title: "Cancel", target: nil, action: nil)

        let machineCodeRow = NSStackView(views: [machineCodeField, copyButton])
        machineCodeRow.orientation = .horizontal
        machineCodeRow.alignment = .centerY
        machineCodeRow.spacing = 8

        let buttonRow = NSStackView(views: [cancelButton, NSView(), deactivateButton, activateButton])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 8

        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        [
            titleLabel,
            statusLabel,
            instructionsLabel,
            machineCodeTitleLabel,
            machineCodeRow,
            activationCodeTitleLabel,
            activationCodeField,
            buttonRow
        ].forEach { stackView.addArrangedSubview($0) }

        contentView.addSubview(stackView)

        machineCodeField.translatesAutoresizingMaskIntoConstraints = false
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        activationCodeField.translatesAutoresizingMaskIntoConstraints = false
        activateButton.translatesAutoresizingMaskIntoConstraints = false
        deactivateButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        machineCodeRow.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),

            machineCodeRow.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            activationCodeField.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            buttonRow.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            machineCodeField.heightAnchor.constraint(equalToConstant: 24),
            activationCodeField.heightAnchor.constraint(equalToConstant: 24),
            copyButton.widthAnchor.constraint(equalToConstant: 72)
        ])

        final class ActionTarget: NSObject {
            var action: (() -> Void)?

            @objc func performAction() {
                action?()
            }
        }

        var result: ActivationDialogAction = .cancel
        let modalTarget = ActionTarget()
        let activateTarget = ActionTarget()
        let deactivateTarget = ActionTarget()
        let cancelTarget = ActionTarget()
        let copyTarget = ActionTarget()

        activateTarget.action = {
            result = .activate(activationCodeField.stringValue)
            NSApp.stopModal()
            panel.orderOut(nil)
        }
        deactivateTarget.action = {
            result = .deactivate
            NSApp.stopModal()
            panel.orderOut(nil)
        }
        cancelTarget.action = {
            result = .cancel
            NSApp.stopModal()
            panel.orderOut(nil)
        }
        copyTarget.action = {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(machineCode, forType: .string)
        }
        modalTarget.action = {
            result = .cancel
            NSApp.stopModal()
            panel.orderOut(nil)
        }

        activateButton.target = activateTarget
        activateButton.action = #selector(ActionTarget.performAction)
        deactivateButton.target = deactivateTarget
        deactivateButton.action = #selector(ActionTarget.performAction)
        cancelButton.target = cancelTarget
        cancelButton.action = #selector(ActionTarget.performAction)
        copyButton.target = copyTarget
        copyButton.action = #selector(ActionTarget.performAction)

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: panel,
            queue: nil
        ) { _ in
            modalTarget.performAction()
        }

        panel.initialFirstResponder = activationCodeField
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(activationCodeField)
        NSApp.runModal(for: panel)
        return result
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
