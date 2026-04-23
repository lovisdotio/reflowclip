import AppKit
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
        hotKey = HotKey(
            keyCode: UInt32(kVK_ANSI_V),
            modifiers: UInt32(cmdKey | optionKey)
        ) { [weak self] in
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
        guard Reflow.looksLikeTuiBlock(original) else {
            flash(title: "Skipped", systemImage: "minus.circle")
            return
        }
        let reflowed = Reflow.apply(original)
        if reflowed == original || reflowed.isEmpty {
            flash(title: "No change", systemImage: "minus.circle")
            return
        }
        pasteboard.clearContents()
        pasteboard.setString(reflowed, forType: .string)
        flash(title: "Reflowed", systemImage: "checkmark.circle.fill")
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

let delegate = AppDelegate()
let app = NSApplication.shared
app.delegate = delegate
app.run()
