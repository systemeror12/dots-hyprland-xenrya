#!/usr/bin/env bash
# Rofi launcher wrapper.
# Delegates wallpaper cache refresh to the shared refresh-wallpaper-cache.sh
# so the launcher background always matches the desktop wallpaper.
#
# Performance note:
# The expensive ImageMagick work is normally done by switchwall.sh when the
# wallpaper changes. This script only invokes the cache script before
# launching rofi, so common Rofi invocations open instantly.

set -euo pipefail

# Return 0 if the rofi drun desktop-file index is at least as new as every
# applications/ directory under XDG_DATA_DIRS and XDG_DATA_HOME.
# A newer directory mtime means a desktop file was added or removed since
# the cache was written → stale cache → return 1 so the caller invalidates it.
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
        # Find the newest mtime anywhere under this applications tree
        local newest_mtime
        newest_mtime=$(find "$appdir" -type f -o -type d | xargs -r stat -c %Y 2>/dev/null | sort -rn | head -n1)
        # If find returned nothing, use the directory itself
        newest_mtime="${newest_mtime:-$(stat -c %Y "$appdir")}"
        if (( newest_mtime > cache_mtime )); then
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/refresh-wallpaper-cache.sh"
refresh_drun_cache

exec rofi -show drun -config "${HOME}/.config/rofi/config.rasi" "$@"
