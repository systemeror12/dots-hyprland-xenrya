# Agent Guide

This repository contains a customized Hyprland dotfiles setup based on [end-4/illogical-impulse](https://github.com/end-4/illogical-impulse). It is licensed under GPL-3.0.

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
- **Change install behavior**: edit files in `sdata/lib/` or the `setup` script.
- **Test an installer change**: use `./installer.sh --dry-run` for the Rofi installer, or run the relevant `./setup` subcommand in a test environment.
- **Verify Bash syntax**: run `bash -n <script>` or `shellcheck` on executable scripts.

## Testing

- **When modifying the Rofi Launcher UI**, always run a dry run first: `./installer.sh --dry-run`.

## What to Avoid

- Do not run `./setup` or `./installer.sh` as root or with `sudo`; `prevent_sudo_or_root()` will abort.
- Do not edit generated state files such as `diagnose.result`, `cache/`, `.update-lock`, or files under `$HOME/.config/illogical-impulse/`.
- Do not modify the `rounded-polygon-qmljs` submodule directly; treat it as upstream code.
- Do not commit local agent state such as `.agents/` or `skills-lock.json`; they are already gitignored.
