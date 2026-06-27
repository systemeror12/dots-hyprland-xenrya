# Spec: Multi-Workspace Wallpaper + Decoupled Matugen

**Date:** 2026-06-27  
**Status:** Draft  
**Design session with: @systemeror12 (Jerome Vrixen DC Mendoza / Xenrya)**

## 1. Goal

Two new capabilities, cleanly separated:

1. **Per-workspace wallpaper** — assign a display image to each of workspaces 1..10. Switching workspaces swaps the displayed image instantly in QML (no script, no flicker, no matugen run).
2. **Decoupled Matugen** — a new Settings page ("Matugen") lets the user pick a single **baseline wallpaper** that drives the global Material You color scheme via the full `switchwall.sh` color pipeline. This baseline is a *color source*, independent of the displayed wallpaper.

The existing wallpaper picker (`CTRL+SUPER+T`) becomes **display-only** (full decoupling): picking a wallpaper no longer runs matugen; only the Matugen page regenerates colors.

## 2. Non-goals

- No per-workspace color scheme (the ml4w owner's failed attempt is deliberately avoided).
- No per-workspace video (mpvpaper stays global-only).
- No support for workspace IDs beyond 1..10 (those fall back to the global default). Workspace-group awareness (>10) is out of scope.

## 3. State model (Config.qml — additive `JsonObject` appends)

```qml
// Extended existing `background` block (additive fields at the end):
property JsonObject background: JsonObject {
    // existing: wallpaperPath, thumbnailPath, parallax.*, widgets.*
    property string matugenWallpaperPath: ""   // NEW: matugen baseline (color source)
    property string matugenThumbnailPath: ""   // NEW: grid preview for the Matugen page
}

// NEW top-level block, appended like the existing `sddm` block:
property JsonObject workspaces: JsonObject {
    property bool enabled: false
    property var wallpapers: ({
        "1":"", "2":"", "3":"", "4":"", "5":"",
        "6":"", "7":"", "8":"", "9":"", "10":""
    })
}
```

- `background.wallpaperPath` → global default *displayed* wallpaper (meaning unchanged, but no longer the matugen source).
- `background.matugenWallpaperPath` → matugen color source; never displayed unless also set as a workspace/global wallpaper.
- `workspaces.wallpapers` → plain object keyed by string id 1..10. `JsonAdapter` auto-persists.

## 4. `switchwall.sh` refactor (Approach A)

### New argument model

| Flag | Runs matugen? | Sets `background.wallpaperPath`? |
|---|---|---|
| `--display-only --image <p>` *(new)* | No | Yes |
| `--matugen-only --image <p>` *(new)* | Yes | No (sets `matugenWallpaperPath`) |
| no flag (existing kdialog picker) | No (now routes to display-only) | Yes |
| `--mode dark\|light` *(existing)* | Yes — regenerates from `matugenWallpaperPath` | No |
| `--type <scheme>` *(existing)* | Yes — from `matugenWallpaperPath` | No |
| `--color <hex\|clear>` *(existing)* | Yes — from `matugenWallpaperPath` | No |
| `--noswitch` *(existing)* | Yes — from `matugenWallpaperPath` | No |

### Behavior details

- New `set_matugen_path()` jq helper (mirrors existing `set_wallpaper_path()` at switchwall.sh:175-187).
- `--matugen-only` runs the existing `switch()` color portion: matugen → `generate_colors_material.py` → `applycolor.sh` → post_process color fan-out (KDE material-you, material-code, SDDM *color* sync).
- `--display-only` sets `wallpaperPath`/`thumbnailPath`, regenerates **rofi wallpaper cache** (launcher preview matches the displayed wallpaper), and triggers **SDDM wallpaper sync** (so the greeter preview matches). Skips matugen + GTK/terminal/code color regen.
- SDDM sync (`sddm/update-active-theme.sh`) is called from **both** modes (idempotent — wallpaper side from display-only, color side from matugen-only).
- Existing `--mode`/`--type`/`--color`/`--noswitch` flows get their *source image* changed from `wallpaperPath` to `matugenWallpaperPath`. This is the core edit to existing upstream lines.
- **First-run / Welcome / `FirstRunExperience.qml`**: currently call `switchwall.sh <defaultWallpaperPath>`. To preserve "pick once → themed" first-run UX, change to: `switchwall.sh --matugen-only --image <default>` then `switchwall.sh --display-only --image <default>` (same image seeds both).

### Behavior change flagged for existing users

Picking a wallpaper via `CTRL+SUPER+T` will, after this change, no longer recolor the session. Recoloring now lives only at Settings → Matugen. This is the intended result of full decoupling.

## 5. QML changes

### 5a. `Background.qml` — minimal surgical edit

Replace the `Image.source` binding on `Config.options.background.wallpaperPath` with:

```qml
readonly property string currentWallpaperPath: {
    if (Config.options.workspaces.enabled) {
        const wsId = monitor.activeWorkspace?.id
        if (wsId >= 1 && wsId <= 10) {
            const p = Config.options.workspaces.wallpapers[String(wsId)]
            if (p && p.length > 0) return p
        }
    }
    return Config.options.background.wallpaperPath
}
```

Pure QML binding on `monitor.activeWorkspace` (already used for parallax, Background.qml:138). **Instant swap, no script, no flicker.** IDs 11+ fall through to the global default.

### 5b. `services/Wallpapers.qml` extensions

- `apply(path, darkMode)` → switch to `--display-only --image <path>` (existing picker behavior, decoupled).
- `setMatugenBaseline(path)` → `switchwall.sh --matugen-only --image <path>`; emits `changed()`.
- `setWorkspaceWallpaper(wsid, path)` → writes `Config.options.workspaces.wallpapers[String(wsid)] = path`; emits `changed()`. **No script.** If `wsid` is the active workspace, `Background.qml` re-renders via binding.
- `clearWorkspaceWallpaper(wsid)` → sets slot to `""`.

### 5c. Workspace wallpaper picker window (new)

**`modules/ii/workspaceWallpaperPicker/WorkspaceWallpaperPicker.qml`** (new):

- `GlobalShortcut` `workspaceWallpaperPickerToggle` (new IPC name).
- Header: 10 chips (1..10), default = active workspace.
- Body: reuses `WallpaperSelectorContent.qml` with `assignMode: "per-workspace:<N>"`.

### 5d. `WallpaperSelectorContent.qml` edit

Add an optional `assignMode` property (default `"global-default"`):

| `assignMode` | On select |
|---|---|
| `"global-default"` | `Wallpapers.apply(path)` → `--display-only` |
| `"per-workspace:<N>"` | `Wallpapers.setWorkspaceWallpaper(N, path)` (QML-only) |
| `"matugen-baseline"` | `Wallpapers.setMatugenBaseline(path)` → `--matugen-only` |

Existing entry points (`wallpaperSelectorToggle`, QuickConfig "Choose file", `Welcome.qml`) keep default `"global-default"` — backward compatible.

### 5e. New Settings pages

1. **`modules/settings/MatugenConfig.qml`** — thumbnail preview of `matugenThumbnailPath`; "Choose baseline wallpaper" button opens the grid in `"matugen-baseline"` mode; help line "This wallpaper drives your color theme. It is independent of the wallpaper shown on your desktop." (added to `en_US.json`).

2. **`modules/settings/WorkspacesConfig.qml`** — master `enabled` toggle; `Repeater` over 1..10 with chip number, 64×36 thumbnail or "— none —" placeholder, "Set…" button (opens grid `"per-workspace:N"`), "Clear" button, and an "Open picker window" button that fires `workspaceWallpaperPicker:toggle` via quickshell IPC.

### 5f. `settings.qml` `pages` array (additive appends)

New rail order: Quick, General, Bar, Background, **Matugen**, **Workspaces**, Interface, Login, Services, Advanced, About.

## 6. Keybind (upstream-safe via `custom/keybinds.lua`)

Append `SUPER + SHIFT + W` → `quickshell:workspaceWallpaperPickerToggle`. Verified free (only `SUPER+W` = browser, `SUPER+SHIFT+T` = screen translate are nearby conflicts — both avoided).

## 7. Files touched

### New (zero conflict)

- `dots/.config/quickshell/ii/modules/ii/workspaceWallpaperPicker/WorkspaceWallpaperPicker.qml`
- `dots/.config/quickshell/ii/modules/settings/MatugenConfig.qml`
- `dots/.config/quickshell/ii/modules/settings/WorkspacesConfig.qml`

### Additive appends (low conflict)

- `dots/.config/quickshell/ii/modules/common/Config.qml` (new `matugenWallpaperPath`/`matugenThumbnailPath` + new `workspaces` block)
- `dots/.config/quickshell/ii/settings.qml` (two `pages` entries)
- `dots/.config/quickshell/ii/translations/en_US.json` (new strings)
- `dots/.config/hypr/custom/keybinds.lua` (new keybind — already your custom file)

### Surgical edits to upstream files (the real conflict surface)

- `dots/.config/quickshell/ii/scripts/colors/switchwall.sh` — new modes + re-route color toggles to `matugenWallpaperPath`
- `dots/.config/quickshell/ii/modules/ii/background/Background.qml` — `Image.source` binding swap
- `dots/.config/quickshell/ii/services/Wallpapers.qml` — `apply`→`--display-only`, new `setMatugenBaseline`/`setWorkspaceWallpaper`/`clearWorkspaceWallpaper`
- `dots/.config/quickshell/ii/modules/ii/wallpaperSelector/WallpaperSelectorContent.qml` — `assignMode` property

### Install wiring

The quickshell dir is synced wholesale by `sdata/subcmd-install/3.files-exp.yaml` and the legacy script, so new QML files are picked up automatically. No install-path changes needed. The fish `conf.d` exclusion memo does not apply.

## 8. Rebase strategy (per AGENTS.md)

Every quickshell/settings/matugen edit is additive where possible. The unavoidable existing-line edits are scoped to: `switchwall.sh` (mode logic + source-image re-route), `Background.qml` (one binding), `Wallpapers.qml` (apply + new methods), `WallpaperSelectorContent.qml` (one property + dispatch). On next `upstream` sync, conflicts here are resolvable in minutes because the surface is small and the intent is documented in this spec.

## 9. Testing plan

- `bash -n` + `shellcheck` on `switchwall.sh` and any new scripts.
- Manual: pick baseline in Matugen page → session recolors (GTK/rofi/terminal all change). Pick a different wallpaper via `CTRL+SUPER+T` → image changes, colors unchanged. Assign per-workspace via `SUPER+SHIFT+W` or Settings → Workspaces → switch workspaces → image swaps instantly without recolor.
- Workspace 11+ → global default displayed (regression check).
- First-run flow → both baseline and display seeded (themed out-of-box).
- SDDM: after each mode, verify greeter wallpaper and colors sync without dangling `#null`.
- `./installer.sh --dry-run` if applicable; `./setup install-files` in a sandbox to confirm new files sync.

## 10. Out-of-scope / future

- Workspace groups (11..20 dynamic per-group slots).
- Per-workspace accent override or image-derived micro-coloring (the explicitly rejected ml4w approach).
- Per-workspace video.
