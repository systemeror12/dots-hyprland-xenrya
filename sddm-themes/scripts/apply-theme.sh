#!/usr/bin/env bash
# apply-theme.sh <theme-name>
# Privileged helper: sets the active SDDM theme in /etc/sddm.conf.d.

set -euo pipefail

THEME="${1:-end-4-sddm}"
SDDM_THEMES_DIR="/usr/share/sddm/themes"
SDDM_DATA_DIR="/var/lib/sddm/illogical-impulse"
DROP_IN="/etc/sddm.conf.d/99-end-4-sddm.conf"

if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root (use pkexec)." >&2
    exit 1
fi

if [[ ! -d "$SDDM_THEMES_DIR/$THEME" ]]; then
    echo "Theme '$THEME' is not installed in $SDDM_THEMES_DIR" >&2
    exit 1
fi

mkdir -p /etc/sddm.conf.d

cat > "$DROP_IN" <<EOF
[Theme]
Current=$THEME
EOF
chmod 644 "$DROP_IN"

# Create the writable data dir for this theme
mkdir -p "$SDDM_DATA_DIR/$THEME"
chown -R sddm:sddm "$SDDM_DATA_DIR"
chmod 2775 "$SDDM_DATA_DIR"
chmod 2775 "$SDDM_DATA_DIR/$THEME"

# Ensure the theme.conf.user symlink exists
if [[ ! -L "$SDDM_THEMES_DIR/$THEME/theme.conf.user" ]]; then
    ln -sf "$SDDM_DATA_DIR/$THEME/theme.conf.user" "$SDDM_THEMES_DIR/$THEME/theme.conf.user"
fi

# Make sure the symlink target exists so SDDM doesn't see a dangling link
if [[ ! -f "$SDDM_DATA_DIR/$THEME/theme.conf.user" ]]; then
    touch "$SDDM_DATA_DIR/$THEME/theme.conf.user"
    chown sddm:sddm "$SDDM_DATA_DIR/$THEME/theme.conf.user"
    chmod 644 "$SDDM_DATA_DIR/$THEME/theme.conf.user"
fi

echo "SDDM theme set to '$THEME'. It will be used on next login/shutdown prompt."
