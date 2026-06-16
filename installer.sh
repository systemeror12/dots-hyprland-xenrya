#!/usr/bin/env bash
#
# installer.sh — Standalone Rofi installer for end_4 / illogical-impulse dotfiles
#
# This script installs rofi-wayland, copies the custom Rofi config, wires it
# into Hyprland keybinds (SUPER+D), and integrates it with matugen theming.
# It does NOT rerun the full ./setup install script.
#
# Run with:  ./installer.sh
#            ./installer.sh --dry-run   (preview only)
#

set -e

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=false

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
ROFI_SOURCE="$REPO_ROOT/dots/.config/rofi"
ROFI_TARGET="$XDG_CONFIG_HOME/rofi"
MATUGEN_SOURCE="$REPO_ROOT/dots/.config/matugen"
MATUGEN_TARGET="$XDG_CONFIG_HOME/matugen"
HYPRLAND_CUSTOM_KEYBINDS="$XDG_CONFIG_HOME/hypr/custom/keybinds.lua"

# Colors for output
C_RESET='\033[0m'
C_BLUE='\033[1;34m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[1;31m'
C_CYAN='\033[1;36m'

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------
log()    { echo -e "${C_BLUE}[installer]${C_RESET} $*"; }
ok()     { echo -e "${C_GREEN}[ok]${C_RESET} $*"; }
warn()   { echo -e "${C_YELLOW}[warn]${C_RESET} $*" >&2; }
err()    { echo -e "${C_RED}[error]${C_RESET} $*" >&2; }
info()   { echo -e "${C_CYAN}[info]${C_RESET} $*"; }

die() { err "$*"; exit 1; }

run() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "    [dry-run] $*"
    else
        "$@"
    fi
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

has_aur_helper() {
    command_exists yay || command_exists paru
}

append_block() {
    local file="$1"
    shift
    if [[ "$DRY_RUN" == true ]]; then
        echo "    [dry-run] Would append to $file:"
        printf '        %s\n' "$@"
    else
        printf '%s\n' "$@" >> "$file"
    fi
}

# -----------------------------------------------------------------------------
# Optional flags
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            info "Dry-run mode: no system changes will be made."
            shift
            ;;
        -h|--help)
            cat <<'EOF'
Usage: ./installer.sh [OPTIONS]

Options:
  --dry-run     Preview changes without applying them
  -h, --help    Show this help message

This installer sets up a custom Rofi launcher for end_4 dotfiles,
bound to SUPER+D. It does NOT run the full ./setup install.
EOF
            exit 0
            ;;
        *)
            die "Unknown option: $1"
            ;;
    esac
done

# -----------------------------------------------------------------------------
# Step 1: Install rofi-wayland
# -----------------------------------------------------------------------------
log "Checking for Rofi..."
if command_exists rofi; then
    ok "Rofi already installed: $(rofi -version 2>&1 | head -n1)"
else
    warn "Rofi not found. Attempting to install rofi-wayland..."

    if [[ "$DRY_RUN" == true ]]; then
        info "Would install rofi-wayland here."
    else
        if command_exists pacman; then
            if has_aur_helper; then
                if command_exists yay; then
                    yay -S --needed --noconfirm rofi-wayland
                else
                    paru -S --needed --noconfirm rofi-wayland
                fi
            else
                warn "No AUR helper found (yay/paru). Attempting pacman fallback..."
                if sudo pacman -S --needed --noconfirm rofi-wayland 2>/dev/null; then
                    ok "Installed rofi-wayland from repos."
                else
                    die "Could not install rofi-wayland. Please install it manually (e.g. yay -S rofi-wayland) and rerun."
                fi
            fi
        elif command_exists dnf; then
            sudo dnf install -y rofi-wayland || die "Failed to install rofi-wayland via dnf."
        elif command_exists apt; then
            # Debian/Ubuntu: rofi-wayland may not exist; fallback to rofi
            sudo apt install -y rofi-wayland 2>/dev/null || sudo apt install -y rofi
        elif command_exists zypper; then
            sudo zypper install -y rofi-wayland || die "Failed to install rofi-wayland via zypper."
        else
            die "Could not detect package manager. Please install rofi-wayland manually and rerun."
        fi
    fi
fi

# -----------------------------------------------------------------------------
# Step 2: Backup existing Rofi config
# -----------------------------------------------------------------------------
if [[ -e "$ROFI_TARGET" ]]; then
    BACKUP_NAME="rofi.bak.$(date +%Y%m%d-%H%M%S)"
    BACKUP_PATH="$XDG_CONFIG_HOME/$BACKUP_NAME"
    log "Backing up existing Rofi config to $BACKUP_NAME"
    run mv "$ROFI_TARGET" "$BACKUP_PATH"
else
    info "No existing Rofi config found; skipping backup."
fi

# -----------------------------------------------------------------------------
# Step 3: Copy Rofi config
# -----------------------------------------------------------------------------
log "Copying Rofi configuration..."
run mkdir -p "$ROFI_TARGET"
run cp -r "$ROFI_SOURCE"/* "$ROFI_TARGET/"
ok "Rofi config installed to $ROFI_TARGET"

# -----------------------------------------------------------------------------
# Step 4: Install matugen template
# -----------------------------------------------------------------------------
log "Installing matugen Rofi template..."
run mkdir -p "$MATUGEN_TARGET/templates/rofi"
run cp "$MATUGEN_SOURCE/templates/rofi/colors.rasi" "$MATUGEN_TARGET/templates/rofi/colors.rasi"
ok "Matugen template installed."

# -----------------------------------------------------------------------------
# Step 5: Patch matugen config.toml
# -----------------------------------------------------------------------------
MATUGEN_CONFIG_SOURCE="$MATUGEN_SOURCE/config.toml"
MATUGEN_CONFIG_TARGET="$MATUGEN_TARGET/config.toml"

if [[ ! -f "$MATUGEN_CONFIG_TARGET" ]]; then
    log "No existing matugen config; copying default."
    run mkdir -p "$MATUGEN_TARGET"
    run cp "$MATUGEN_CONFIG_SOURCE" "$MATUGEN_CONFIG_TARGET"
fi

if grep -q '\[templates.rofi\]' "$MATUGEN_CONFIG_TARGET" 2>/dev/null; then
    info "matugen config already contains [templates.rofi]; skipping."
else
    log "Adding [templates.rofi] to matugen config..."
    append_block "$MATUGEN_CONFIG_TARGET" \
        "" \
        "[templates.rofi]" \
        "input_path = '~/.config/matugen/templates/rofi/colors.rasi'" \
        "output_path = '~/.config/rofi/colors.rasi'"
    ok "Patched matugen config.toml."
fi

# -----------------------------------------------------------------------------
# Step 6: Patch Hyprland custom keybinds
# -----------------------------------------------------------------------------
log "Patching Hyprland keybinds..."
run mkdir -p "$(dirname "$HYPRLAND_CUSTOM_KEYBINDS")"

if [[ ! -f "$HYPRLAND_CUSTOM_KEYBINDS" ]]; then
    run touch "$HYPRLAND_CUSTOM_KEYBINDS"
fi

# Add Rofi binds if not already present
if grep -q 'rofi -show drun' "$HYPRLAND_CUSTOM_KEYBINDS" 2>/dev/null; then
    info "Rofi keybind already present in custom/keybinds.lua; skipping."
else
    append_block "$HYPRLAND_CUSTOM_KEYBINDS" \
        "" \
        "-- App launcher: Rofi (replaces maximize on SUPER+D)" \
        'hl.bind("SUPER + D", hl.dsp.exec_cmd("rofi -show drun -config ~/.config/rofi/config.rasi"),' \
        '    { description = "App launcher: Rofi" })' \
        "" \
        "-- Window maximize moved from SUPER+D to SUPER+SHIFT+D" \
        'hl.bind("SUPER + SHIFT + D", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),' \
        '    { description = "Window: Maximize" })'
    ok "Added Rofi and moved maximize keybinds."
fi

# -----------------------------------------------------------------------------
# Step 7: Regenerate Rofi colors with matugen if possible
# -----------------------------------------------------------------------------
log "Attempting to regenerate Rofi colors with matugen..."
if command_exists matugen; then
    WALLPAPER_FILE="$HOME/.local/state/quickshell/user/generated/wallpaper/path.txt"
    if [[ -f "$WALLPAPER_FILE" ]]; then
        WALLPAPER="$(cat "$WALLPAPER_FILE")"
        if [[ -f "$WALLPAPER" ]]; then
            # Match end_4's switchwall behavior
            current_mode=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
            if [[ "$current_mode" == "prefer-light" ]]; then
                mode="light"
            else
                mode="dark"
            fi
            if run matugen --source-color-index 0 --mode "$mode" image "$WALLPAPER"; then
                ok "Regenerated colors from current wallpaper (mode: $mode)."
            else
                warn "matugen color regeneration failed. Fallback colors.rasi is in place."
            fi
        else
            warn "Wallpaper path not found; using fallback colors.rasi."
        fi
    else
        warn "No matugen wallpaper state found; using fallback colors.rasi."
    fi
else
    warn "matugen not found; using fallback colors.rasi. Colors will auto-update once matugen is available and a wallpaper is set."
fi

# -----------------------------------------------------------------------------
# Step 8: Reload Hyprland
# -----------------------------------------------------------------------------
log "Reloading Hyprland configuration..."
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    run hyprctl reload
    ok "Hyprland config reloaded."
else
    warn "Hyprland environment not detected; please reload manually or log out/in."
fi

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
echo ""
ok "Rofi setup complete!"
info "Keybinds:"
echo "  SUPER + D          → Rofi app launcher"
echo "  SUPER + SHIFT + D  → Maximize window"
echo ""
info "You can switch Rofi modes with Ctrl+Tab while Rofi is open."
