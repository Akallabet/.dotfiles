#!/usr/bin/env bash
# Configure an Apple-layout USB keyboard and natural mouse scrolling on
# Raspberry Pi OS / Debian running the Labwc Wayland desktop.
#
# Usage:
#   sudo ./setup-mac-input.sh [--keyboard-id VENDOR:PRODUCT] [--user USER]
#
# Default keyboard ID: 026d:0005 (the keyboard configured on this machine).
# Find another keyboard's ID with: sudo keyd monitor

set -Eeuo pipefail

KEYBOARD_ID="026d:0005"
TARGET_USER="${SUDO_USER:-${USER}}"
KEYD_VERSION="v2.6.0"

usage() {
    sed -n '2,10p' "$0"
}

while (($#)); do
    case "$1" in
        --keyboard-id)
            KEYBOARD_ID="${2:?--keyboard-id requires VENDOR:PRODUCT}"
            shift 2
            ;;
        --user)
            TARGET_USER="${2:?--user requires a username}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if ((EUID != 0)); then
    exec sudo -- "$0" --keyboard-id "$KEYBOARD_ID" --user "$TARGET_USER"
fi

if [[ ! "$KEYBOARD_ID" =~ ^[[:xdigit:]]{4}:[[:xdigit:]]{4}$ ]]; then
    printf 'Invalid keyboard ID: %s (expected VENDOR:PRODUCT)\n' "$KEYBOARD_ID" >&2
    exit 2
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
if [[ -z "$TARGET_HOME" || ! -d "$TARGET_HOME" ]]; then
    printf 'Cannot determine a home directory for user: %s\n' "$TARGET_USER" >&2
    exit 2
fi

if ! command -v apt-get >/dev/null; then
    printf 'This script currently supports apt-based Debian/Raspberry Pi OS systems.\n' >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends build-essential git

build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT

git clone --depth 1 --branch "$KEYD_VERSION" https://github.com/rvaiya/keyd.git "$build_dir/keyd"
make -C "$build_dir/keyd"
make -C "$build_dir/keyd" install

install -d -m 0755 /etc/keyd
cat > /etc/keyd/mac-external-keyboard.conf <<EOF
# Apple-style modifiers for USB keyboard ${KEYBOARD_ID} only.
[ids]
k:${KEYBOARD_ID}

[main]
# Command acts as Linux Control; physical Control becomes Super/Meta.
leftmeta = layer(control)
rightmeta = layer(control)
leftcontrol = layer(meta)
rightcontrol = layer(meta)
capslock = esc

# Physical Control+C sends Ctrl+C. In a terminal, this is SIGINT.
[meta]
c = C-c

# Command+Tab switches applications using Alt+Tab.
[control]
tab = swapm(cmd_tab, A-tab)

[cmd_tab:A]
tab = A-S-tab
EOF

keyd check /etc/keyd/mac-external-keyboard.conf
systemctl enable --now keyd

labwc_dir="$TARGET_HOME/.config/labwc"
labwc_rc="$labwc_dir/rc.xml"
install -d -o "$TARGET_USER" -g "$TARGET_USER" -m 0755 "$labwc_dir"
if [[ ! -f "$labwc_rc" ]]; then
    install -o "$TARGET_USER" -g "$TARGET_USER" -m 0644 /etc/xdg/labwc/rc.xml "$labwc_rc"
fi

python3 - "$labwc_rc" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
marker = "<!-- mac-input-setup:natural-scroll -->"
managed = re.compile(
    r"\n?\s*<!-- mac-input-setup:natural-scroll -->\n"
    r"\s*<libinput>\n"
    r"\s*<device category=\"non-touch\">\n"
    r"\s*<naturalScroll>yes</naturalScroll>\n"
    r"\s*</device>\n"
    r"\s*</libinput>\n?",
)
text = managed.sub("\n", text)
block = '''
  <!-- mac-input-setup:natural-scroll -->
  <libinput>
    <device category="non-touch">
      <naturalScroll>yes</naturalScroll>
    </device>
  </libinput>
'''
if "</mouse>" not in text:
    raise SystemExit(f"{path}: cannot find </mouse> for the Labwc setting")
path.write_text(text.replace("</mouse>", "</mouse>" + block, 1))
PY
chown "$TARGET_USER:$TARGET_USER" "$labwc_rc"

# Apply the setting immediately when the target user's Labwc socket is available.
uid="$(id -u "$TARGET_USER")"
runtime_dir="/run/user/$uid"
reloaded=no
if command -v labwc >/dev/null && [[ -d "$runtime_dir" ]]; then
    labwc_pid="$(pgrep -u "$TARGET_USER" -x labwc | head -n 1 || true)"
    for socket in "$runtime_dir"/wayland-*; do
        [[ -n "$labwc_pid" && -S "$socket" ]] || continue
        if runuser -u "$TARGET_USER" -- env \
            LABWC_PID="$labwc_pid" \
            XDG_RUNTIME_DIR="$runtime_dir" \
            WAYLAND_DISPLAY="${socket##*/}" \
            labwc -r; then
            reloaded=yes
            break
        fi
    done
fi

printf 'Configured keyd for %s and enabled natural mouse scrolling for %s.\n' \
    "$KEYBOARD_ID" "$TARGET_USER"
if [[ "$reloaded" != yes ]]; then
    printf 'Log out and back in (or restart Labwc) to apply the scroll setting.\n'
fi
