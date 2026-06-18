#!/usr/bin/env bash
# install.sh
# Installs the end-4-sddm theme (and any siblings) to the system.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_THEME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SDDM_THEMES_DIR="/usr/share/sddm/themes"
SDDM_DATA_DIR="/var/lib/sddm/illogical-impulse"
TARGET_USER="${SUDO_USER:-$USER}"

if [[ "$EUID" -ne 0 ]]; then
    echo "Please run this installer with sudo or as root." >&2
    exit 1
fi

# ---- Dependencies ----------------------------------------------------------
for bin in sddm sddm-greeter-qt6; do
    if ! command -v "$bin" &>/dev/null; then
        echo "Warning: $bin not found on PATH. Install sddm (Qt6) first." >&2
    fi
done

if [[ ! -d /usr/lib/qt6/qml/Qt5Compat/GraphicalEffects ]]; then
    echo "Warning: Qt5Compat.GraphicalEffects QML module not found." >&2
    echo "         Install qt6-5compat (or your distro's equivalent) before using this theme." >&2
fi

# ---- Add user to sddm group ------------------------------------------------
if ! getent group sddm &>/dev/null; then
    echo "Creating sddm group..."
    groupadd --system sddm
fi

if ! id -nG "$TARGET_USER" | grep -qw sddm; then
    echo "Adding $TARGET_USER to the sddm group..."
    usermod -aG sddm "$TARGET_USER"
    echo "NOTE: Log out and back in for the group change to take effect."
fi

# ---- Writable data directory -----------------------------------------------
mkdir -p "$SDDM_DATA_DIR"
chown sddm:sddm "$SDDM_DATA_DIR"
chmod 2775 "$SDDM_DATA_DIR"

# ---- Install themes --------------------------------------------------------
for theme_src in "$REPO_THEME_DIR"/end-4-sddm; do
    [[ -d "$theme_src" ]] || continue
    theme_name=$(basename "$theme_src")
    echo "Installing theme: $theme_name"

    rm -rf "$SDDM_THEMES_DIR/$theme_name"
    cp -r "$theme_src" "$SDDM_THEMES_DIR/$theme_name"
    chown -R root:root "$SDDM_THEMES_DIR/$theme_name"
    find "$SDDM_THEMES_DIR/$theme_name" -type d -exec chmod 755 {} \;
    find "$SDDM_THEMES_DIR/$theme_name" -type f -exec chmod 644 {} \;

    # Writable data dir for this theme
    mkdir -p "$SDDM_DATA_DIR/$theme_name"
    chown sddm:sddm "$SDDM_DATA_DIR/$theme_name"
    chmod 2775 "$SDDM_DATA_DIR/$theme_name"

    # Symlink runtime config into the theme directory
    ln -sf "$SDDM_DATA_DIR/$theme_name/theme.conf.user" "$SDDM_THEMES_DIR/$theme_name/theme.conf.user"

    # Ensure the symlink target exists so SDDM doesn't see a dangling link on first install
    if [[ ! -f "$SDDM_DATA_DIR/$theme_name/theme.conf.user" ]]; then
        touch "$SDDM_DATA_DIR/$theme_name/theme.conf.user"
        chown sddm:sddm "$SDDM_DATA_DIR/$theme_name/theme.conf.user"
        chmod 644 "$SDDM_DATA_DIR/$theme_name/theme.conf.user"
    fi
done

# ---- Install common fonts system-wide so the sddm user can load them -------
SYSTEM_FONT_DIR="/usr/local/share/fonts/illogical-impulse-sddm"
mkdir -p "$SYSTEM_FONT_DIR"
FONTS=(
    "Google Sans Flex"
    "Material Symbols Rounded"
    "JetBrains Mono NF"
)
for font in "${FONTS[@]}"; do
    mapfile -t files < <(fc-list ":family=$font" | cut -d: -f1 | sort -u)
    for f in "${files[@]}"; do
        [[ -f "$f" ]] || continue
        cp -n "$f" "$SYSTEM_FONT_DIR/" 2>/dev/null || true
    done
done
fc-cache -f "$SYSTEM_FONT_DIR" 2>/dev/null || true
chmod 755 "$SYSTEM_FONT_DIR"
find "$SYSTEM_FONT_DIR" -type f -exec chmod 644 {} \;

# ---- Copy user-side helper scripts -----------------------------------------
TARGET_USER_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
USER_SDDM_SCRIPTS="$TARGET_USER_HOME/.config/quickshell/ii/scripts/sddm"
mkdir -p "$USER_SDDM_SCRIPTS"
cp -f "$SCRIPT_DIR/update-active-theme.sh" "$USER_SDDM_SCRIPTS/"
cp -f "$SCRIPT_DIR/apply-theme.sh" "$USER_SDDM_SCRIPTS/"
chown -R "$TARGET_USER:$TARGET_USER" "$USER_SDDM_SCRIPTS"
chmod 755 "$USER_SDDM_SCRIPTS/update-active-theme.sh"
chmod 755 "$USER_SDDM_SCRIPTS/apply-theme.sh"

# ---- Activate the first theme by default -----------------------------------
"$SCRIPT_DIR/apply-theme.sh" end-4-sddm

echo ""
echo "Installation complete."
echo "Next steps:"
echo "  1. Log out and back in so your user is in the 'sddm' group."
echo "  2. Change your wallpaper; SDDM will sync automatically."
echo "  3. Test with: sddm-greeter-qt6 --test-mode"
