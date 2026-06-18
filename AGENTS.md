# Agent Guide

This repository contains a customized Hyprland dotfiles setup based on [end-4/illogical-impulse](https://github.com/end-4/dots-hyprland). It is licensed under GPL-3.0.

## Repository Layout

| Path | Purpose |
|------|---------|
| `dots/` | Main configuration files, copied to `$HOME/.config` and `$HOME/.local` during install. |
| `dots-extra/` | Optional configuration variants, e.g. tweaks for `--via-nix`. |
| `sdata/` | Supporting data and Bash library files used by `./setup`. |
| `sdata/lib/` | Reusable Bash functions, environment variables, package installers, and distro detection. |
| `installer.sh` | Standalone Rofi installer; does not run the full `./setup` flow. |
| `setup` | Main install/update/uninstall entry point. |
| `.agents/` | Local agent-only files (gitignored). |
| `skills-lock.json` | Local opencode skill lockfile (gitignored). |

## Conventions

- **Bash scripts** in `sdata/lib/` are meant to be sourced, not executed directly. They intentionally omit shebangs.
- The setup script uses `set -e` and helpers from `sdata/lib/functions.sh` such as `v()`, `x()`, `try()`, and `prevent_sudo_or_root()`.
- Output styling variables are defined in `sdata/lib/environment-variables.sh` (e.g. `STY_RED`, `STY_RST`).
- Config paths respect XDG Base Directory variables, defaulting to `$HOME/.config` and `$HOME/.local`.
- User-specific install state lives under `$XDG_CONFIG_HOME/illogical-impulse/` (see `environment-variables.sh`).

## Common Tasks

- **Add or edit app configs**: modify files under `dots/.config/` or `dots/.local/`.
- **Install the custom SDDM theme**: run `sudo ./sddm-themes/scripts/install.sh` and select the theme in Settings → Login.
- **Change install behavior**: edit files in `sdata/lib/` or the `setup` script.
- **Test an installer change**: use `./installer.sh --dry-run` for the Rofi installer, or run the relevant `./setup` subcommand in a test environment.
- **Verify Bash syntax**: run `bash -n <script>` or `shellcheck` on executable scripts.

## Testing

- **When modifying the Rofi Launcher UI**, always run a dry run first: `./installer.sh --dry-run`.
- **When modifying the SDDM theme**:
  - Test the local source with `sddm-greeter-qt6 --test-mode --theme /path/to/sddm-themes/<theme>/`.
  - Check the system journal for QML/runtime errors: `journalctl -f | grep sddm-greeter`.
  - Verify the installed copy in `/usr/share/sddm/themes/<theme>/` after running `sudo ./sddm-themes/scripts/install.sh`.
  - Ensure the Settings app shows **Settings → Login** after syncing Quickshell with `./setup install-files`. If the page is missing, the installed `~/.config/quickshell/ii/settings.qml` is stale.

## SDDM Theme Standards

- Theme sources live under `sddm-themes/<theme-name>/`.
- Themes are installed to `/usr/share/sddm/themes/<theme-name>/` via `sudo ./sddm-themes/scripts/install.sh`. Installation requires root; do **not** configure passwordless `sudo`/`pkexec` for this.
- Runtime-generated data (wallpaper, colors) goes to `/var/lib/sddm/illogical-impulse/<theme-name>/`, which is writable by the `sddm` group.
- Each theme uses `theme.conf` for static defaults and a `theme.conf.user` symlink that points to its writable data dir. The install script must create the symlink target (even an empty file) so it is never dangling.
- QML subfolders (`components/`, `panels/`) must be imported explicitly in each file, e.g. `import "components"`.
- SDDM QML must use only standard Qt6 / `Qt5Compat.GraphicalEffects`. Do **not** import Quickshell modules inside SDDM themes.
- Greeter context objects:
  - Use `userModel` and `sessionModel` as top-level context properties.
  - Use `sddm` only for actions (`sddm.login`, `sddm.suspend`, etc.) and properties like `sddm.defaultUser`.
  - Do **not** use `sddm.userModel` or `sddm.sessionModel`; they are `undefined`.
- Pre-select the last-used user and session with `currentIndex: model.lastIndex`, and always provide a fallback when the model is empty.
- Fonts used by the greeter must be installed system-wide (the installer copies them to `/usr/local/share/fonts/illogical-impulse-sddm/`) so the `sddm` user can load them.
- Helper scripts belong in `sddm-themes/scripts/`. The install script copies the user-side helpers to `~/.config/quickshell/ii/scripts/sddm/`.
- Wallpaper/color sync is triggered from `dots/.config/quickshell/ii/scripts/colors/switchwall.sh`.
- When generating `theme.conf.user`, guard against `null`/missing color values so the theme never receives entries like `background=#null`.

- Do not run `./setup` or `./installer.sh` as root or with `sudo`; `prevent_sudo_or_root()` will abort.
- Do not edit generated state files such as `diagnose.result`, `cache/`, `.update-lock`, or files under `$HOME/.config/illogical-impulse/`.
- Do not modify the `rounded-polygon-qmljs` submodule directly; treat it as upstream code.
- Do not commit local agent state such as `.agents/` or `skills-lock.json`; they are already gitignored.
