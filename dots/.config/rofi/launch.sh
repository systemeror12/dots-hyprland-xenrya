#!/usr/bin/env bash
# Rofi launcher wrapper.
# Refreshes the rofi wallpaper cache from the currently selected wallpaper
# (the one changed with Ctrl+Super+T, etc.) so the launcher background always
# matches the desktop wallpaper.
#
# Performance note:
# The expensive ImageMagick work is normally done by switchwall.sh when the
# wallpaper changes. This script only regenerates the cache if it is missing or
# older than the current wallpaper, so common Rofi invocations open instantly.

set -euo pipefail

WALLPAPER_PATH_FILE="${HOME}/.local/state/quickshell/user/generated/wallpaper/path.txt"
CACHE_DIR="${HOME}/.cache/rofi-wall"

# Return 0 if cache_file exists and is at least as new as wallpaper_path.
cache_is_fresh() {
    local wallpaper_path="$1"
    local cache_file="$2"

    [[ -f "$cache_file" ]] || return 1
    [[ -f "$wallpaper_path" ]] || return 1

    local wall_mtime cache_mtime
    wall_mtime=$(stat -c %Y "$wallpaper_path")
    cache_mtime=$(stat -c %Y "$cache_file")

    (( cache_mtime >= wall_mtime ))
}

# Return 0 if the rofi drun desktop-file cache is at least as new as every
# applications/ directory under XDG_DATA_DIRS and XDG_DATA_HOME.
# Uses two checks:
#   1. Any .desktop file recursively newer than the cache → added or modified.
#   2. Directory mtime newer than the cache → a file was deleted.
# Both must pass for the cache to be considered fresh.
drun_cache_is_fresh() {
    local cache="${XDG_CACHE_HOME:-${HOME}/.cache}/rofi-drun-desktop.cache"
    [[ -f "$cache" ]] || return 1

    local cache_mtime
    cache_mtime=$(stat -c %Y "$cache")

    # Collect applications directories from XDG_DATA_DIRS + XDG_DATA_HOME
    local data_dirs="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    local data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
    local IFS_save="$IFS"
    IFS=:
    set -- $data_dirs $data_home
    IFS="$IFS_save"

    local dir
    for dir; do
        [[ -n "$dir" ]] || continue
        local appdir="${dir}/applications"
        [[ -d "$appdir" ]] || continue

        # Any desktop file modified or added since the cache was built?
        if find "$appdir" -type f -name '*.desktop' -newer "$cache" -print -quit 2>/dev/null | grep -q .; then
            return 1
        fi

        # Any desktop file deleted since the cache was built?
        # (Directory mtime changes on unlink of any child.)
        local dir_mtime
        dir_mtime=$(stat -c %Y "$appdir")
        if (( dir_mtime > cache_mtime )); then
            return 1
        fi
    done

    return 0
}

# Delete the stale drun cache so rofi rebuilds it on next invocation.
refresh_drun_cache() {
    local cache="${XDG_CACHE_HOME:-${HOME}/.cache}/rofi-drun-desktop.cache"
    if drun_cache_is_fresh; then
        return 0
    fi
    rm -f "$cache"
}

# Generate the cache images. Kept in sync with switchwall.sh.
generate_cache() {
    local wallpaper_path="$1"
    local thmb="$CACHE_DIR/wall.thmb"
    local blur="$CACHE_DIR/wall.blur"

    mkdir -p "$CACHE_DIR"

    # Left panel: scaled wallpaper, Rofi crops to panel height.
    # 1200px on the long edge is plenty for the rendered Rofi window while
    # keeping decode/render and blur costs low.
    magick "$wallpaper_path" \
        -resize 1200x1200\> \
        -strip \
        "$thmb"

    # Sidebar background: blurred and dimmed wallpaper.
    # Resize smaller before blurring so the expensive blur operation works on
    # fewer pixels; the heavy blur hides the lower resolution anyway.
    magick "$wallpaper_path" \
        -resize 800x800\> \
        -blur 0x10 \
        -modulate 70 \
        -strip \
        "$blur"
}

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

    local thmb="$CACHE_DIR/wall.thmb"
    local blur="$CACHE_DIR/wall.blur"

    if cache_is_fresh "$wallpaper_path" "$thmb" && \
       cache_is_fresh "$wallpaper_path" "$blur"; then
        return 0
    fi

    generate_cache "$wallpaper_path"
}

refresh_wallpaper_cache
refresh_drun_cache

exec rofi -show drun -config "${HOME}/.config/rofi/config.rasi" "$@"
