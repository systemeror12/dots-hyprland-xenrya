#!/usr/bin/env bash
# update-active-theme.sh
# Syncs the current Quickshell wallpaper + Material You colors to the active
# SDDM theme's writable data directory.

set -euo pipefail

XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
SDDM_DATA_DIR="/var/lib/sddm/illogical-impulse"
WALLPAPER_STATE="$XDG_STATE_HOME/quickshell/user/generated/wallpaper/path.txt"
COLORS_STATE="$XDG_STATE_HOME/quickshell/user/generated/colors.json"
SDDM_CONF="/etc/sddm.conf"
SDDM_CONF_D="/etc/sddm.conf.d/99-end-4-sddm.conf"

err() { echo "[update-active-theme] $*" >&2; }

# ---- Sanity checks ---------------------------------------------------------
if [[ ! -d "$SDDM_DATA_DIR" ]]; then
    err "Data directory $SDDM_DATA_DIR does not exist. Run install.sh first."
    exit 0
fi

if [[ ! -w "$SDDM_DATA_DIR" ]]; then
    err "Cannot write to $SDDM_DATA_DIR. Are you in the 'sddm' group? Log out/in after install."
    exit 0
fi

if [[ ! -f "$WALLPAPER_STATE" ]]; then
    err "No wallpaper state found at $WALLPAPER_STATE"
    exit 0
fi

if [[ ! -f "$COLORS_STATE" ]]; then
    err "No colors state found at $COLORS_STATE"
    exit 0
fi

# ---- Determine active theme ------------------------------------------------
active_theme=""
if [[ -f "$SDDM_CONF_D" ]]; then
    active_theme=$(grep -E '^\s*Current\s*=\s*' "$SDDM_CONF_D" | tail -n1 | sed 's/.*=\s*//;s/\s*$//')
fi
if [[ -z "$active_theme" && -f "$SDDM_CONF" ]]; then
    active_theme=$(grep -E '^\s*Current\s*=\s*' "$SDDM_CONF" | tail -n1 | sed 's/.*=\s*//;s/\s*$//')
fi
if [[ -z "$active_theme" ]]; then
    active_theme="end-4-sddm"
fi

THEME_DIR="$SDDM_DATA_DIR/$active_theme"
mkdir -p "$THEME_DIR"

# ---- Copy wallpaper --------------------------------------------------------
wallpaper=$(cat "$WALLPAPER_STATE")
wallpaper=${wallpaper//\"/}

if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
    err "Wallpaper path is empty or missing: $wallpaper"
    exit 0
fi

ext="${wallpaper##*.}"
ext="${ext,,}"
[[ "$ext" =~ ^(jpg|jpeg|png|webp|bmp|gif)$ ]] || ext="png"

cp -f "$wallpaper" "$THEME_DIR/wallpaper.$ext"
chmod 644 "$THEME_DIR/wallpaper.$ext"

# ---- Generate theme.conf.user ---------------------------------------------
mapfile -t keys < <(jq -r 'keys[]' "$COLORS_STATE" 2>/dev/null || true)

{
    echo "[General]"
    echo "wallpaperPath=$THEME_DIR/wallpaper.$ext"
    for key in "${keys[@]}"; do
        val=$(jq -r --arg k "$key" '.[$k]' "$COLORS_STATE")
        # Skip missing/null values so we don't write broken colors like background=#null
        if [[ -z "$val" || "$val" == "null" ]]; then
            continue
        fi
        # Strip leading # if present; theme.conf stores raw hex without #
        # But config.key returns string; Main.qml cfg.color expects #
        val="${val//#/}"
        echo "${key}=#${val}"
    done
} > "$THEME_DIR/theme.conf.user.tmp"

mv "$THEME_DIR/theme.conf.user.tmp" "$THEME_DIR/theme.conf.user"
chmod 644 "$THEME_DIR/theme.conf.user"

# ---- Ensure the theme's symlink points here -------------------------------
theme_install="/usr/share/sddm/themes/$active_theme"
if [[ -d "$theme_install" ]]; then
    if [[ ! -L "$theme_install/theme.conf.user" ]]; then
        ln -sf "$THEME_DIR/theme.conf.user" "$theme_install/theme.conf.user"
    fi
fi

err "Updated SDDM theme '$active_theme' with wallpaper: $wallpaper"
