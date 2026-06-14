#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/install-codex-obsidian-launch-agent.sh --vault "/path/to/Obsidian Vault"
  scripts/install-codex-obsidian-launch-agent.sh --output "/path/to/output/folder"

Options:
  --vault PATH   Obsidian vault path. Notes are written to PATH/Codex Logs.
  --output PATH  Exact output folder for Codex Markdown notes.
  --recent N     Number of recent sessions to keep updated. Default: 20.
  --flat         Write all notes directly to the output folder.
USAGE
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
NODE_SCRIPT="${PROJECT_DIR}/scripts/codex-to-obsidian.js"
NODE_BIN="$(command -v node)"
LABEL="com.llmwiki.codex-obsidian-sync"
PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
RECENT="20"
DEST_KIND=""
DEST_VALUE=""
FLAT="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)
      DEST_KIND="--vault"
      DEST_VALUE="${2:-}"
      shift 2
      ;;
    --output)
      DEST_KIND="--output"
      DEST_VALUE="${2:-}"
      shift 2
      ;;
    --recent)
      RECENT="${2:-20}"
      shift 2
      ;;
    --flat)
      FLAT="true"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "${DEST_KIND}" || -z "${DEST_VALUE}" ]]; then
  echo "Pass either --vault or --output." >&2
  usage >&2
  exit 1
fi

mkdir -p "${HOME}/Library/LaunchAgents"

if launchctl print "gui/$(id -u)/${LABEL}" >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)" "${PLIST}" >/dev/null 2>&1 || true
fi

cat > "${PLIST}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${NODE_BIN}</string>
    <string>${NODE_SCRIPT}</string>
    <string>--watch</string>
    <string>${DEST_KIND}</string>
    <string>${DEST_VALUE}</string>
$(if [[ "${FLAT}" == "true" ]]; then printf '    <string>--flat</string>\n'; fi)
    <string>--recent</string>
    <string>${RECENT}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${HOME}/Library/Logs/${LABEL}.out.log</string>
  <key>StandardErrorPath</key>
  <string>${HOME}/Library/Logs/${LABEL}.err.log</string>
</dict>
</plist>
PLIST

plutil -lint "${PLIST}"
launchctl bootstrap "gui/$(id -u)" "${PLIST}"
launchctl enable "gui/$(id -u)/${LABEL}"
launchctl kickstart -k "gui/$(id -u)/${LABEL}"

echo "Installed and started ${LABEL}"
echo "Plist: ${PLIST}"
