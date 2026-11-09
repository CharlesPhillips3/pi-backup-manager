#!/usr/bin/env bash
# Install or upgrade Pi Backup Manager to the latest version from GitHub:
#   curl -fsSL https://raw.githubusercontent.com/CharlesPhillips3/pi-backup-manager/main/upgrade.sh | sudo bash
# Your settings, schedule and backups are kept.
set -euo pipefail
REPO="https://github.com/CharlesPhillips3/pi-backup-manager.git"
SRC="/opt/pibackup-src"
if [ "$EUID" -ne 0 ]; then echo "Run with sudo:  curl -fsSL <link> | sudo bash" >&2; exit 1; fi
OLD="$(/opt/pibackup/pibackup-helper --version 2>/dev/null | awk '{print $NF}' || true)"
command -v git >/dev/null || apt-get install -y git
if [ -d "$SRC/.git" ]; then
  git -C "$SRC" fetch --quiet --depth 1 origin main
  git -C "$SRC" reset --quiet --hard origin/main
else
  rm -rf "$SRC"
  git clone --quiet --depth 1 "$REPO" "$SRC"
fi
bash "$SRC/install.sh"
NEW="$(cat "$SRC/VERSION")"
echo
if [ -n "$OLD" ] && [ "$OLD" != "$NEW" ]; then echo "Upgraded Pi Backup Manager $OLD -> $NEW."; else echo "Pi Backup Manager $NEW is installed."; fi
echo "Close and reopen the app to use the new version."
