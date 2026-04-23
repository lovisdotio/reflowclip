# ReflowClip

Fixes broken multi-line copies from **Claude Code**, **Codex**, and other TUI tools — system-wide on macOS.

## The problem

When you copy a command from a TUI-rendered code block, the terminal inserts real `\n` characters wherever the TUI visually wrapped the line. This command:

    rm -rf foo && mkdir bar && cd bar

…gets pasted as:

    rm -rf foo && mkdir
    bar && cd bar

Which fails to run.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/lovisdotio/reflowclip/main/install.sh | bash
```

One line. No Apple Developer account. No Gatekeeper dialog. No Accessibility permission.

## Use

1. Copy a wrapped command from your terminal (Terminal, iTerm, Ghostty, Warp, VS Code, Cursor — whatever).
2. Press `⌥⌘V` — the clipboard gets reflowed in place.
3. Paste with `⌘V` — one clean line.

Works from any app, pastes into any app. If the clipboard doesn't look like a TUI block, nothing happens — regular copies are never modified.

## How it works

- A small menu-bar app registers `⌥⌘V` as a global hotkey via Carbon (no Accessibility permission required).
- When triggered, it reads the clipboard.
- If the text contains box-drawing characters (`│ ┃ ╭ ╰ ┌ └ ─ ━` etc.), it strips the borders, joins wrapped lines, and writes the cleaned version back.
- Otherwise: no-op. Regular copies are never touched.
- Clipboard is only read when you press the hotkey. No background polling, no privacy banners.

## Uninstall

```sh
launchctl unload ~/Library/LaunchAgents/com.lovisdotio.reflowclip.plist
rm -rf ~/Applications/ReflowClip.app ~/Library/LaunchAgents/com.lovisdotio.reflowclip.plist
```

## Build from source

```sh
./build.sh
open build/ReflowClip.app
```

Requires Swift 5.9+ and macOS 13+.

## License

MIT
