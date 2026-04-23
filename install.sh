#!/bin/sh
set -e

REPO="${REFLOWCLIP_REPO:-lovisdotio/reflowclip}"
VERSION="${REFLOWCLIP_VERSION:-latest}"
APP_NAME="ReflowClip"
BIN_NAME="reflowclip"
LABEL="com.lovisdotio.reflowclip"

INSTALL_DIR="${HOME}/Applications"
APP_PATH="${INSTALL_DIR}/${APP_NAME}.app"
PLIST_PATH="${HOME}/Library/LaunchAgents/${LABEL}.plist"

printf '\n→ Installing %s…\n' "${APP_NAME}"

if [ "$(uname)" != "Darwin" ]; then
  printf '✗ This installer is macOS only.\n' >&2
  exit 1
fi

if [ "${VERSION}" = "latest" ]; then
  URL="https://github.com/${REPO}/releases/latest/download/${APP_NAME}.app.zip"
else
  URL="https://github.com/${REPO}/releases/download/${VERSION}/${APP_NAME}.app.zip"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

printf '→ Downloading from %s\n' "${URL}"
curl -fsSL "${URL}" -o "${TMP}/app.zip"

printf '→ Extracting…\n'
ditto -x -k "${TMP}/app.zip" "${TMP}"

mkdir -p "${INSTALL_DIR}"
rm -rf "${APP_PATH}"
mv "${TMP}/${APP_NAME}.app" "${APP_PATH}"

# Remove any quarantine attribute (defensive — curl shouldn't set it, but some tooling does).
xattr -dr com.apple.quarantine "${APP_PATH}" 2>/dev/null || true

printf '→ Registering LaunchAgent so it auto-starts at login…\n'
mkdir -p "${HOME}/Library/LaunchAgents"
cat > "${PLIST_PATH}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${APP_PATH}/Contents/MacOS/${BIN_NAME}</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ProcessType</key><string>Interactive</string>
</dict>
</plist>
PLIST

launchctl unload "${PLIST_PATH}" 2>/dev/null || true
launchctl load "${PLIST_PATH}"

printf '\n✓ Installed: %s\n' "${APP_PATH}"
printf '✓ Running now — look for the menu bar icon.\n\n'
printf 'Usage:\n'
printf '  1. Copy a wrapped command from Claude Code / Codex / any TUI.\n'
printf '  2. Press ⌥⌘V to reflow the clipboard.\n'
printf '  3. Paste with ⌘V — one clean line.\n\n'
printf 'Uninstall:\n'
printf '  launchctl unload %s\n' "${PLIST_PATH}"
printf '  rm -rf %s %s\n' "${APP_PATH}" "${PLIST_PATH}"
