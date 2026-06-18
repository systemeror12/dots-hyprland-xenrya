#!/usr/bin/env bash
# Rofi launcher wrapper.
# Refreshes the rofi wallpaper cache from the currently selected wallpaper
# (the one changed with Ctrl+Super+T, etc.) so the launcher background always
# matches the desktop wallpaper.

set -euo pipefail

WALLPAPER_PATH_FILE="${HOME}/.local/state/quickshell/user/generated/wallpaper/path.txt"
CACHE_DIR="${HOME}/.cache/rofi-wall"

refresh_wallpaper_cache() {
    local wallpaper_path=""

    if [[ -f "$WALLPAPER_PATH_FILE" ]]; then
        wallpaper_path="$(cat "$WALLPAPER_PATH_FILE")"
    fi

    if [[ -z "$wallpaper_path" || ! -f "$wallpaper_path" ]]; then
        return 0
    fi

    if ! command -v magick &>/dev/null; then
        return 0
    fi

    mkdir -p "$CACHE_DIR"

    # Left panel: cropped/resized wallpaper
    magick "$wallpaper_path" \
        -resize 1920x1920\> \
        "$CACHE_DIR/wall.thmb"

    # Sidebar: blurred/dimmed wallpaper
    magick "$wallpaper_path" \
        -resize 1920x1920\> \
        -blur 0x16 \
        -modulate 70 \
        "$CACHE_DIR/wall.blur"
}

refresh_wallpaper_cache

exec rofi -show drun -config "${HOME}/.config/rofi/config.rasi" "$@"
