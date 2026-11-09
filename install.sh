#!/usr/bin/env bash
# Pi Backup Manager installer:  sudo bash install.sh
# Installs the app, its menu entry and its polkit rule. It changes no drives;
# you pick where backups go inside the app (Backup location tab).
set -euo pipefail
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
if [ "$EUID" -ne 0 ]; then exec sudo bash "$0" "$@"; fi

echo "== Installing packages"
apt-get update -qq || echo "(apt update failed; continuing with what's cached)"
PK=pkexec
apt-cache show pkexec >/dev/null 2>&1 || PK=policykit-1
apt-get install -y python3-gi gir1.2-gtk-3.0 zstd dosfstools e2fsprogs util-linux fdisk "$PK"
apt-get install -y exfatprogs mdadm >/dev/null 2>&1 || true   # optional: exFAT drives, RAID rebuilds

echo "== Installing to /opt/pibackup"
install -d /opt/pibackup
install -m 755 "$HERE/pibackup-helper" "$HERE/pibackup-gui" "$HERE/install.sh" /opt/pibackup/
install -m 644 "$HERE/README.md" /opt/pibackup/
ln -sf /opt/pibackup/pibackup-gui /usr/local/bin/pibackup

cat > /usr/share/polkit-1/actions/io.github.pibackup.policy <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <action id="io.github.pibackup.helper">
    <description>Run Pi Backup Manager</description>
    <message>Pi Backup Manager needs administrator rights to read and restore the whole system</message>
    <icon_name>drive-harddisk</icon_name>
    <defaults>
      <allow_any>auth_admin</allow_any>
      <allow_inactive>auth_admin</allow_inactive>
      <allow_active>auth_admin_keep</allow_active>
    </defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/opt/pibackup/pibackup-helper</annotate>
  </action>
</policyconfig>
EOF

cat > /usr/share/applications/pibackup.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Pi Backup Manager
Comment=Compressed, restorable whole-system backups with a schedule
Exec=/opt/pibackup/pibackup-gui
Icon=drive-harddisk
Terminal=false
Categories=System;Utility;
EOF

# Refresh the copy of the app kept next to the backups (used for restoring from a rescue system)
if [ -f /etc/pibackup.conf ] && findmnt -rn /mnt/pibackup >/dev/null; then
  SUB="$(python3 -c 'import json;print((json.load(open("/etc/pibackup.conf")).get("location") or {}).get("subdir",""))')"
  T="/mnt/pibackup${SUB:+/$SUB}/tools"
  install -d "$T" && install -m 644 "$HERE"/{pibackup-helper,pibackup-gui,install.sh,README.md} "$T/" || true
fi

echo
echo "Done. Open 'Pi Backup Manager' from the menu (System Tools), or run: pibackup"
