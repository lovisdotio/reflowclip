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

One line. No Apple Developer account. No Gatekeeper dialog.

## Use

1. Copy a wrapped command from your terminal (Terminal, iTerm, Ghostty, Warp, VS Code, Cursor — whatever).
2. Press `⌥⌘V` — the clipboard gets reflowed **and pasted** in one shot.

On first use, macOS will prompt for **Accessibility** permission (needed so ReflowClip can send the `⌘V` keystroke on your behalf). Grant it once and you're done.

## How it works

- A menu-bar app registers `⌥⌘V` as a global hotkey via Carbon.
- When triggered, it reads the clipboard, strips any TUI borders, joins wrapped lines with spaces, writes the cleaned version back, then posts a synthetic `⌘V` to paste into the frontmost app.
- Clipboard is only read when you press the hotkey. No background polling.

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
