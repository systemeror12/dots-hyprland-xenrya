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
| `sddm-themes/` | Custom SDDM theme sources and install/sync scripts (not in upstream). |
| `.agents/` | Local agent-only files (gitignored). |
| `skills-lock.json` | Local opencode skill lockfile (gitignored). |

## Branch Model & Upstream Sync

This repo is a customized fork of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland), owned and maintained independently. **The intent is to customize and own, not to contribute back to upstream** (the `upstream` remote is fetch-only and is used solely to pull in end-4's improvements). Two remotes are configured:

| Remote | URL | Role |
|--------|-----|------|
| `origin` | `github.com/systemeror12/dots-hyprland-xenrya` | Your fork; where `dev` and `main` are pushed. |
| `upstream` | `github.com/end-4/dots-hyprland` | The source project; **fetch-only, never pushed to**. |

### Branch roles

- **`dev`** is the **GitHub default branch** and the home of all custom work. It is what visitors and `git clone` see, and what `./setup install-files` installs from. It is a strict superset of upstream — always contains upstream's latest merged code plus your customizations on top. Use `git diff main..dev` to see exactly what you've changed relative to upstream.
- **`main`** is a **clean mirror of `upstream/main`**. It must contain zero custom commits. Its sole purpose is to be a stable upstream baseline for `dev` to rebase onto, making syncs trivial and keeping `git diff main..dev` a precise list of your changes. `main` tracks `upstream/main`.
- Do **not** let custom merge commits accumulate on `main` (if they do, reset `main` to `upstream/main` with `git push --force-with-lease`). Custom commits belong on `dev` only.

### Where custom changes live (conflict surface)

Most custom work is in **new files/dirs** that never touch upstream, so they never conflict: `sddm-themes/`, `installer.sh`, `dots/.config/rofi/`, `dots/.config/matugen/templates/rofi/`, `dots/.config/quickshell/ii/modules/settings/SddmConfig.qml`, `dots/.config/hypr/custom/` (upstream-sanctioned override dir), `dots/.config/fastfetch/`, `dots/.config/fish/conf.d/`, and this file.

The only edits to **upstream files** (the real conflict surface during rebases) are small appends in:
- `dots/.config/matugen/config.toml`
- `dots/.config/quickshell/ii/modules/common/Config.qml`
- `dots/.config/quickshell/ii/settings.qml`
- `dots/.config/quickshell/ii/translations/en_US.json`
- `dots/.config/quickshell/ii/scripts/colors/switchwall.sh`

Prefer additive edits (append blocks, new files, upstream-sanctioned slots like `hypr/custom/`) over modifying existing upstream lines, to keep future rebases clean.

### Sync workflow

When `upstream` (end-4) advances:
```bash
git fetch upstream
git checkout main && git merge --ff-only upstream/main && git push origin main
git checkout dev && git rebase main && git push --force-with-lease origin dev
```
If the rebase hits conflicts, they should be limited to the append-edits listed above. After resolving, continue with `git rebase --continue` and push with `--force-with-lease` (never `--force`, to protect against remote races).

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

## Fish Shell Autostart

Interactive-session autostart hooks (e.g. fastfetch on terminal open) belong in **`dots/.config/fish/conf.d/NN-name.fish`**, never in `config.fish`.

- **Why `conf.d` and not `config.fish`**: fish sources `conf.d/*.fish` **before** `config.fish`. Putting autostart in `conf.d` makes it run before starship/prompt setup in `config.fish`, which avoids image/prompt race conditions (e.g. a fastfetch kitty-graphics image being lost because the prompt drew over it before the terminal finished decoding). This was a real bug — see the commit that added `30-autostart.fish`.
- **Load order**: files are sourced alphabetically, so the `NN` numeric prefix controls order. Use `30-` for late autostart (after `fish_frozen_*` migrations), lower numbers for early setup.
- **`conf.d` is excluded from the fish dir sync** in both install paths (`3.files-exp.yaml: excludes: ["conf.d"]` and `3.files-legacy.sh: install_dir__sync_exclude ... "conf.d"`). This is intentional — `conf.d` holds fish-generated state files (`fish_frozen_key_bindings.fish`, `fish_frozen_theme.fish`) that must not be wiped on sync. **Do not remove this exclusion.**
- **To ship a repo-managed `conf.d` file**, add a separate targeted entry for the specific file in **both** install paths:
  - `sdata/subcmd-install/3.files-exp.yaml`: a pattern with `mode: "soft-backup"` and the fish `condition`.
  - `sdata/subcmd-install/3.files-legacy.sh`: inside the `SKIP_FISH` block, `v mkdir -p "${XDG_CONFIG_HOME}/fish/conf.d"` then `install_file__auto_backup <src> <dst>` (call it **without** the `v`/`x` prefix — see the function's doc-comment in `3.files.sh`). The `mkdir -p` is required because the excluded dir isn't created by the sync.
- **Guard with `status is-interactive`** inside the snippet so the hook doesn't fire in non-interactive shells.

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
