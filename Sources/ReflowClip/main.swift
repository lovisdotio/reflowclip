import AppKit
import ApplicationServices
import Carbon.HIToolbox

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotKey: HotKey?
    private var enabled = true
    private var toggleItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        registerHotKey()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "text.alignleft",
                accessibilityDescription: "ReflowClip"
            )
        }

        let menu = NSMenu()

        toggleItem = NSMenuItem(
            title: "Enabled",
            action: #selector(toggleEnabled(_:)),
            keyEquivalent: ""
        )
        toggleItem.state = .on
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let hint = NSMenuItem(title: "Hotkey: ⌥⌘V", action: nil, keyEquivalent: "")
        hint.isEnabled = false
        menu.addItem(hint)

        menu.addItem(NSMenuItem.separator())

        let about = NSMenuItem(
            title: "About ReflowClip",
            action: #selector(showAbout(_:)),
            keyEquivalent: ""
        )
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(
            title: "Quit",
            action: #selector(quit(_:)),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    private func registerHotKey() {
        // ⌥⌘V — free in Terminal.app, iTerm2, Ghostty, VS Code. Three keys, easy reach.
        fputs("ReflowClip: registering ⌥⌘V hotkey\n", stderr)
        hotKey = HotKey(
            keyCode: UInt32(kVK_ANSI_V),
            modifiers: UInt32(cmdKey | optionKey)
        ) { [weak self] in
            fputs("ReflowClip: hotkey fired\n", stderr)
            self?.reflowClipboard()
        }
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        enabled.toggle()
        sender.state = enabled ? .on : .off
    }

    @objc private func showAbout(_ sender: Any?) {
        let alert = NSAlert()
        alert.messageText = "ReflowClip"
        alert.informativeText = """
        Fixes multi-line copies from Claude Code, Codex, and other TUI tools.

        Copy a wrapped command, press ⌥⌘V, paste with ⌘V.

        github.com/lovisdotio/reflowclip
        """
        alert.runModal()
    }

    @objc private func quit(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    private func reflowClipboard() {
        guard enabled else {
            flash(title: "Off", systemImage: "pause.circle")
            return
        }
        let pasteboard = NSPasteboard.general
        guard let original = pasteboard.string(forType: .string), !original.isEmpty else {
            flash(title: "Empty", systemImage: "exclamationmark.circle")
            return
        }
        let wasReflowed: Bool
        if let reflowed = Reflow.apply(original) {
            pasteboard.clearContents()
            pasteboard.setString(reflowed, forType: .string)
            wasReflowed = true
        } else {
            wasReflowed = false
        }
        // Post ⌘V off-main so our polling for modifier release doesn't block UI.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.simulatePaste()
        }
        flash(
            title: wasReflowed ? "Reflowed + pasted" : "Pasted",
            systemImage: "checkmark.circle.fill"
        )
    }

    private func simulatePaste() {
        // Requires Accessibility permission. On first use, macOS will prompt
        // the user to enable it for ReflowClip.
        if !AXIsProcessTrusted() {
            fputs("ReflowClip: Accessibility not granted — prompting\n", stderr)
            let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(opts)
            return
        }

        // Wait up to 500ms for the user's ⌥ / ⌘ / ⇧ / ⌃ to release, so our
        // synthetic ⌘V isn't merged with held modifiers into a different
        // shortcut (which is what caused "had to press twice").
        let start = Date()
        let keys: [CGKeyCode] = [
            CGKeyCode(kVK_Option), CGKeyCode(kVK_RightOption),
            CGKeyCode(kVK_Command), CGKeyCode(kVK_RightCommand),
            CGKeyCode(kVK_Shift), CGKeyCode(kVK_RightShift),
            CGKeyCode(kVK_Control), CGKeyCode(kVK_RightControl)
        ]
        while Date().timeIntervalSince(start) < 0.5 {
            let anyDown = keys.contains { CGEventSource.keyState(.combinedSessionState, key: $0) }
            if !anyDown { break }
            usleep(8_000) // 8ms
        }

        let src = CGEventSource(stateID: .combinedSessionState)
        let vKey = CGKeyCode(kVK_ANSI_V)
        let down = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    private func flash(title: String, systemImage: String) {
        guard let button = statusItem.button else { return }
        let previousImage = button.image
        button.title = " \(title)"
        button.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: title)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            button.title = ""
            button.image = previousImage
        }
    }
}

// CLI modes (no menu bar).
let args = CommandLine.arguments.dropFirst()

if args.contains("--reflow-now") || args.contains("--test") {
    let pasteboard = NSPasteboard.general
    guard let original = pasteboard.string(forType: .string) else {
        fputs("clipboard is empty or non-text\n", stderr)
        exit(1)
    }
    print("BEFORE (\(original.count) chars):")
    print(original)
    print("---")
    guard let reflowed = Reflow.apply(original) else {
        print("NO CHANGE (single line or already clean)")
        exit(0)
    }
    let wrote = pasteboard.clearContents()
    let ok = pasteboard.setString(reflowed, forType: .string)
    print("AFTER (\(reflowed.count) chars, setString=\(ok), changeCount=\(wrote)):")
    print(reflowed)
    print("---")
    if let verify = NSPasteboard.general.string(forType: .string) {
        print("VERIFY pbpaste (\(verify.count) chars):")
        print(verify)
    } else {
        print("VERIFY pbpaste: nil")
    }
    exit(0)
}

let delegate = AppDelegate()
let app = NSApplication.shared
app.delegate = delegate
app.run()
