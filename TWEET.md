# Tweet options

## Option A — punchy (239 chars)

copying commands from claude code / codex always breaks — TUI wraps, paste explodes.

built a tiny mac menu-bar app. one line to install:

```
curl -fsSL https://raw.githubusercontent.com/lovisdotio/reflowclip/main/install.sh | bash
```

copy → ⌥⌘V → it's pasted clean.

---

## Option B — with frustration (254 chars)

using claude code or codex in the terminal is great until you try to copy a command — wraps to multiple lines, paste fails.

fixed it in a mac menu-bar app:

```
curl -fsSL https://raw.githubusercontent.com/lovisdotio/reflowclip/main/install.sh | bash
```

copy → ⌥⌘V → one-shot reflow + paste.

---

## Option C — lowercase, very casual (197 chars)

ok this drove me nuts. copy a command from claude code or codex → paste → broken because the TUI wrapped it.

fix:

```
curl -fsSL https://raw.githubusercontent.com/lovisdotio/reflowclip/main/install.sh | bash
```

then just ⌥⌘V. reflowed + pasted in one go.
