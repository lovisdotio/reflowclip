# Tweet options

## Option A — short & direct (214 chars)

claude code + codex: every time you copy a command, the terminal breaks it mid-line and paste fails.

fixed it. one line on macOS:

```
curl -fsSL https://raw.githubusercontent.com/lovisdotio/reflowclip/main/install.sh | bash
```

copy → ⇧⌘V → paste clean.

---

## Option B — with the frustration (242 chars)

using claude code or codex in the terminal is amazing until you try to copy a command — wraps to multiple lines and the paste is broken.

built a tiny mac app to fix it:

```
curl -fsSL https://raw.githubusercontent.com/lovisdotio/reflowclip/main/install.sh | bash
```

copy, hit ⇧⌘V, paste.

---

## Option C — punchy (191 chars)

copying commands from claude code / codex always breaks — TUI wraps, paste explodes.

one line to fix it on mac:

```
curl -fsSL https://raw.githubusercontent.com/lovisdotio/reflowclip/main/install.sh | bash
```

then ⇧⌘V before paste.

---

## Option D — lowercase, very casual (174 chars)

ok this drove me nuts. copy a command from claude code or codex → paste → broken because the TUI wrapped it.

fix:

```
curl -fsSL https://raw.githubusercontent.com/lovisdotio/reflowclip/main/install.sh | bash
```

⇧⌘V before ⌘V. done.
