#!/usr/bin/env bash
# Refresh the Rofi wallpaper cache.
# Resolves the effective wallpaper path (priority: rofi.wallpaperPath > background.wallpaperPath)
# and regenerates ~/.cache/rofi-wall/{wall.thmb,wall.blur,wall.src} if stale.
set -euo pipefail

CACHE_DIR="${HOME}/.cache/rofi-wall"
ROFI_CONFIG_FILE="${HOME}/.config/illogical-impulse/config.json"

# Resolve the wallpaper path Rofi should use.
get_effective_wallpaper() {
    local path=""
    if [[ -f "$ROFI_CONFIG_FILE" ]] && command -v jq &>/dev/null; then
        path="$(jq -r '.rofi.wallpaperPath // ""' "$ROFI_CONFIG_FILE" 2>/dev/null)"
        if [[ -n "$path" && -f "$path" ]]; then
            printf '%s' "$path"
            return
        fi
        path="$(jq -r '.background.wallpaperPath // ""' "$ROFI_CONFIG_FILE" 2>/dev/null)"
        if [[ -n "$path" && -f "$path" ]]; then
            printf '%s' "$path"
            return
        fi
    fi
}

cache_is_fresh() {
    local wallpaper_path="$1"
    local cache_file="$2"
    local src_file="${CACHE_DIR}/wall.src"

    [[ -f "$cache_file" ]] || return 1
    [[ -f "$wallpaper_path" ]] || return 1
    [[ -f "$src_file" ]] || return 1
    [[ "$(cat "$src_file")" == "$wallpaper_path" ]] || return 1

    local wall_mtime cache_mtime
    wall_mtime=$(stat -c %Y "$wallpaper_path")
    cache_mtime=$(stat -c %Y "$cache_file")

    (( cache_mtime >= wall_mtime ))
}

generate_cache() {
    local wallpaper_path="$1"
    local thmb="$CACHE_DIR/wall.thmb"
    local blur="$CACHE_DIR/wall.blur"

    mkdir -p "$CACHE_DIR"

    magick "$wallpaper_path" \
        -resize 1200x1200\> \
        -strip \
        "$thmb"

    magick "$wallpaper_path" \
        -resize 800x800\> \
        -blur 0x10 \
        -modulate 70 \
        -strip \
        "$blur"

    printf '%s' "$wallpaper_path" > "$CACHE_DIR/wall.src"
}

main() {
    local wallpaper_path
    wallpaper_path="$(get_effective_wallpaper)"

    if [[ -z "$wallpaper_path" || ! -f "$wallpaper_path" ]]; then
        exit 0
    fi

    if ! command -v magick &>/dev/null; then
        exit 0
    fi

    local thmb="$CACHE_DIR/wall.thmb"
    local blur="$CACHE_DIR/wall.blur"

    if cache_is_fresh "$wallpaper_path" "$thmb" && \
       cache_is_fresh "$wallpaper_path" "$blur"; then
        exit 0
    fi

    generate_cache "$wallpaper_path"
}

main "$@"
