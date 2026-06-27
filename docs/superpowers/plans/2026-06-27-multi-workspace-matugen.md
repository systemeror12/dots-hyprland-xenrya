# Multi-Workspace Wallpaper + Decoupled Matugen — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-workspace wallpaper (workspaces 1..10) with a decoupled Matugen baseline wallpaper for global color generation, plus Settings pages and a standalone picker window.

**Architecture:** Two independent concepts: (A) Matugen settings page picks a baseline wallpaper driving the switchwall color pipeline; (B) per-workspace wallpaper assigns display images to workspace slots 1..10, swapped in QML (no matugen run). Existing wallpaper picker becomes display-only.

**Tech Stack:** Bash (switchwall.sh), QML/Quickshell (pages, picker, Background.qml), jq (config.json), Lua (hyprland keybinds)

**Branch:** `feat/per-workspace-wallpaper`

## Global Constraints

- Edits on `feat/per-workspace-wallpaper` branch based on `dev`
- Additive appends to Config.qml and settings.qml only
- New settings pages follow existing `ContentPage` pattern (see SddmConfig.qml)
- Keybind `SUPER+SHIFT+W` verified free
- For assignMode dispatch, use `GlobalStates.wallpaperSelectorAssignMode` (shared singleton) so any QML component can set the mode before opening the wallpaper selector grid

---

### Task 1: Config.qml — add matugen baseline + per-workspace state fields

**Files:**
- Modify: `dots/.config/quickshell/ii/modules/common/Config.qml`

**Interfaces:**
- Produces: `Config.options.background.matugenWallpaperPath`, `Config.options.background.matugenThumbnailPath`, `Config.options.workspaces.enabled`, `Config.options.workspaces.wallpapers`

- [ ] **Step 1: Append matugen fields to the `background` block**

After the `parallax` block's closing `}` (line 229) and before the `background` block's closing `}` (line 230), add two properties:

```qml
                property string matugenWallpaperPath: ""
                property string matugenThumbnailPath: ""
            }
```

So the edited region looks like:
```qml
                }
                property string matugenWallpaperPath: ""
                property string matugenThumbnailPath: ""
            }
```

- [ ] **Step 2: Append the `workspaces` block**

After the `sddm` block's closing line `            }` at line 156 and before `            property JsonObject apps:` at line 158, insert:

```qml
            property JsonObject workspaces: JsonObject {
                property bool enabled: false
                property var wallpapers: ({
                    "1":"", "2":"", "3":"", "4":"", "5":"",
                    "6":"", "7":"", "8":"", "9":"", "10":""
                })
            }
```

- [ ] **Step 3: Verify**

```bash
jq '.background.matugenWallpaperPath' ~/.config/illogical-impulse/config.json
jq '.workspaces' ~/.config/illogical-impulse/config.json
```

Expected: both return non-null values (empty string / object).

- [ ] **Step 4: Commit**

```bash
git add dots/.config/quickshell/ii/modules/common/Config.qml
git commit -m "feat(config): add matugen baseline + per-workspace config fields"
```

---

### Task 2: GlobalStates.qml — add wallpaperSelectorAssignMode shared state

**Files:**
- Modify: `dots/.config/quickshell/ii/GlobalStates.qml`

- [ ] **Step 1: Add assignMode property**

After `wallpaperSelectorOpen` at line 31, add:

```qml
    property string wallpaperSelectorAssignMode: "global-default" // "global-default", "matugen-baseline", or "per-workspace:<N>"
```

- [ ] **Step 2: Commit**

```bash
git add dots/.config/quickshell/ii/GlobalStates.qml
git commit -m "feat: add wallpaperSelectorAssignMode to GlobalStates"
```

---

### Task 3: switchwall.sh — add --display-only, --matugen-only, set_matugen_path, reroute color source

**Files:**
- Modify: `dots/.config/quickshell/ii/scripts/colors/switchwall.sh`

- [ ] **Step 1: Add `set_matugen_path()` and `set_matugen_thumbnail_path()` helpers**

After `set_thumbnail_path()` (ends at line 187), insert:

```bash
set_matugen_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.matugenWallpaperPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

set_matugen_thumbnail_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.matugenThumbnailPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}
```

- [ ] **Step 2: Add flag variables in `main()`**

After `noswitch_flag=""` at line 356, add:

```bash
    display_only_flag=""
    matugen_only_flag=""
```

- [ ] **Step 3: Add flags in the argument parsing loop**

Before the `--image)` case at line 398, insert:

```bash
            --display-only)
                display_only_flag="1"
                shift
                ;;
            --matugen-only)
                matugen_only_flag="1"
                shift
                ;;
```

- [ ] **Step 4: Change `--noswitch` to read from matugenWallpaperPath (fallback wallpaperPath)**

Replace line 404:
```bash
                imgpath=$(jq -r '.background.wallpaperPath' ...
```
with:
```bash
                imgpath=$(jq -r '.background.matugenWallpaperPath // .background.wallpaperPath // ""' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "")
```

- [ ] **Step 5: Replace `post_process()` with display-aware variant**

Replace lines 82-91 with:

```bash
post_process() {
    local screen_width="$1"
    local screen_height="$2"
    local wallpaper_path="$3"

    generate_rofi_wallpaper_cache "$wallpaper_path" &
    if [[ "$display_only_flag" != "1" ]]; then
        handle_kde_material_you_colors &
        "$SCRIPT_DIR/code/material-code-set-color.sh" &
    fi
    "$SCRIPT_DIR"/../sddm/update-active-theme.sh &
}
```

- [ ] **Step 6: Rewrite `switch()` for new modes**

Replace the `switch()` function (lines 195-348) with the full version below. Key behavioral changes:
- When `$display_only_flag == "1"`: set wallpaperPath/thumbnailPath, handle video, run post_process (rofi cache + SDDM), skip matugen pipeline, return early
- When `$matugen_only_flag == "1"`: set matugenWallpaperPath/matugenThumbnailPath, fall through to color pipeline
- Color source chain: for non-matugen-only operations (mode/type/color/noswitch toggles), source image from existing matugenWallpaperPath if set, fallback to wallpaperPath
- For backward compat (no flag): write BOTH wallpaperPath (via set_wallpaper_path inside the color pipeline block, guarded by `matugen_only_flag != "1"`)

```bash
switch() {
    imgpath="$1"
    mode_flag="$2"
    type_flag="$3"
    color_flag="$4"
    color="$5"

    aiStylingEnabled=$(jq -r '.background.widgets.clock.cookie.aiStyling' "$SHELL_CONFIG_FILE")
    if [[ "$aiStylingEnabled" == "true" ]]; then
        categorize_wallpaper "$imgpath" &
    fi

    read scale screenx screeny screensizey < <(hyprctl monitors -j | jq '.[] | select(.focused) | .scale, .x, .y, .height' | xargs)
    cursorposx=$(hyprctl cursorpos -j | jq '.x' 2>/dev/null) || cursorposx=960
    cursorposx=$(bc <<< "scale=0; ($cursorposx - $screenx) * $scale / 1")
    cursorposy=$(hyprctl cursorpos -j | jq '.y' 2>/dev/null) || cursorposy=540
    cursorposy=$(bc <<< "scale=0; ($cursorposy - $screeny) * $scale / 1")
    cursorposy_inverted=$((screensizey - cursorposy))

    enable_apps_shell="true"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        enable_apps_shell=$(jq -r '.appearance.wallpaperTheming.enableAppsAndShell' "$SHELL_CONFIG_FILE")
    fi

    # ==============================
    # DISPLAY-ONLY MODE
    # ==============================
    if [[ "$display_only_flag" == "1" ]]; then
        if is_video "$imgpath"; then
            mkdir -p "$THUMBNAIL_DIR"
            missing_deps=()
            if ! command -v mpvpaper &> /dev/null; then missing_deps+=("mpvpaper"); fi
            if ! command -v ffmpeg &> /dev/null; then missing_deps+=("ffmpeg"); fi
            if [ ${#missing_deps[@]} -gt 0 ]; then
                echo "Missing deps: ${missing_deps[*]}"
                echo "Arch: sudo pacman -S ${missing_deps[*]}"
                action=$(notify-send -a "Wallpaper switcher" -c "im.error" -A "install_arch=Install (Arch)" "Can't switch to video wallpaper" "Missing dependencies: ${missing_deps[*]}")
                if [[ "$action" == "install_arch" ]]; then
                    kitty -1 sudo pacman -S "${missing_deps[*]}"
                    if command -v mpvpaper &>/dev/null && command -v ffmpeg &>/dev/null; then
                        notify-send 'Wallpaper switcher' 'Alright, try again!' -a "Wallpaper switcher"
                    fi
                fi
                exit 0
            fi
            set_wallpaper_path "$imgpath"
            local video_path="$imgpath"
            monitors=$(hyprctl monitors -j | jq -r '.[] | .name')
            for monitor in $monitors; do
                mpvpaper -o "$VIDEO_OPTS" "$monitor" "$video_path" &
                sleep 0.1
            done
            thumbnail="$THUMBNAIL_DIR/$(basename "$imgpath").jpg"
            ffmpeg -y -i "$imgpath" -vframes 1 "$thumbnail" 2>/dev/null
            set_thumbnail_path "$thumbnail"
            create_restore_script "$video_path"
        else
            set_wallpaper_path "$imgpath"
            remove_restore
        fi
        # Note: thumbnailPath is only set for videos (above). Static images use
        # wallpaperPath directly; thumbnailPath stays as-is or from a prior video.
        max_width_desired="$(hyprctl monitors -j | jq '([.[].width] | min)' | xargs)"
        max_height_desired="$(hyprctl monitors -j | jq '([.[].height] | min)' | xargs)"
        post_process "$max_width_desired" "$max_height_desired" "$imgpath"
        return
    fi

    # ==============================
    # MATUGEN-ONLY MODE — set baseline
    # ==============================
    if [[ "$matugen_only_flag" == "1" ]]; then
        if is_video "$imgpath"; then
            thumbnail="$THUMBNAIL_DIR/$(basename "$imgpath").jpg"
            mkdir -p "$THUMBNAIL_DIR"
            ffmpeg -y -i "$imgpath" -vframes 1 "$thumbnail" 2>/dev/null
            if [ -f "$thumbnail" ]; then
                set_matugen_thumbnail_path "$thumbnail"
            else
                echo "Cannot create thumbnail for video"
                exit 1
            fi
        else
            set_matugen_thumbnail_path "$imgpath"
        fi
        set_matugen_path "$imgpath"
    fi

    # ==============================
    # COLOR PIPELINE
    # ==============================
    if [[ "$matugen_only_flag" != "1" ]]; then
        local matugen_path
        matugen_path=$(jq -r '.background.matugenWallpaperPath // ""' "$SHELL_CONFIG_FILE" 2>/dev/null)
        if [[ -n "$matugen_path" && -f "$matugen_path" ]]; then
            imgpath="$matugen_path"
        fi
    fi

    matugen_args=(--source-color-index 0)

    if [[ "$color_flag" == "1" ]]; then
        matugen_args+=(color hex "$color")
        generate_colors_material_args=(--color "$color")
    else
        if [[ -z "$imgpath" ]]; then
            echo 'Aborted'; exit 0
        fi
        check_and_prompt_upscale "$imgpath" &
        kill_existing_mpvpaper

        if is_video "$imgpath"; then
            mkdir -p "$THUMBNAIL_DIR"
            missing_deps=()
            if ! command -v mpvpaper &> /dev/null; then missing_deps+=("mpvpaper"); fi
            if ! command -v ffmpeg &> /dev/null; then missing_deps+=("ffmpeg"); fi
            if [ ${#missing_deps[@]} -gt 0 ]; then
                echo "Missing deps: ${missing_deps[*]}"
                echo "Arch: sudo pacman -S ${missing_deps[*]}"
                action=$(notify-send -a "Wallpaper switcher" -c "im.error" -A "install_arch=Install (Arch)" "Can't switch to video wallpaper" "Missing dependencies: ${missing_deps[*]}")
                if [[ "$action" == "install_arch" ]]; then
                    kitty -1 sudo pacman -S "${missing_deps[*]}"
                    if command -v mpvpaper &>/dev/null && command -v ffmpeg &>/dev/null; then
                        notify-send 'Wallpaper switcher' 'Alright, try again!' -a "Wallpaper switcher"
                    fi
                fi
                exit 0
            fi
            if [[ "$matugen_only_flag" != "1" ]]; then
                set_wallpaper_path "$imgpath"
                local video_path="$imgpath"
                monitors=$(hyprctl monitors -j | jq -r '.[] | .name')
                for monitor in $monitors; do
                    mpvpaper -o "$VIDEO_OPTS" "$monitor" "$video_path" &
                    sleep 0.1
                done
            fi
            thumbnail="$THUMBNAIL_DIR/$(basename "$imgpath").jpg"
            ffmpeg -y -i "$imgpath" -vframes 1 "$thumbnail" 2>/dev/null
            if [[ "$matugen_only_flag" != "1" ]]; then
                set_thumbnail_path "$thumbnail"
            fi
            if [ -f "$thumbnail" ]; then
                matugen_args+=(image "$thumbnail")
                generate_colors_material_args=(--path "$thumbnail")
                if [[ "$matugen_only_flag" != "1" ]]; then
                    create_restore_script "$video_path"
                fi
            else
                echo "Cannot create image to colorgen"
                remove_restore; exit 1
            fi
        else
            matugen_args+=(image "$imgpath")
            generate_colors_material_args=(--path "$imgpath")
            if [[ "$matugen_only_flag" != "1" ]]; then
                set_wallpaper_path "$imgpath"
                remove_restore
            fi
        fi
    fi

    if [[ -z "$mode_flag" ]]; then
        current_mode=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
        [[ "$current_mode" == "prefer-dark" ]] && mode_flag="dark" || mode_flag="light"
    fi

    if [[ -n "$mode_flag" ]]; then
        matugen_args+=(--mode "$mode_flag")
        if [[ $(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode' "$SHELL_CONFIG_FILE") == "true" ]]; then
            generate_colors_material_args+=(--mode "dark")
        else
            generate_colors_material_args+=(--mode "$mode_flag")
        fi
    fi
    [[ -n "$type_flag" ]] && matugen_args+=(--type "$type_flag") && generate_colors_material_args+=(--scheme "$type_flag")
    generate_colors_material_args+=(--termscheme "$terminalscheme" --blend_bg_fg)
    generate_colors_material_args+=(--cache "$STATE_DIR/user/generated/color.txt")

    pre_process "$mode_flag"

    if [ "$enable_apps_shell" == "false" ]; then
        echo "App and shell theming disabled, skipping matugen and color generation"
        return
    fi

    if [ -f "$SHELL_CONFIG_FILE" ]; then
        harmony=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.harmony' "$SHELL_CONFIG_FILE")
        harmonize_threshold=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold' "$SHELL_CONFIG_FILE")
        term_fg_boost=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost' "$SHELL_CONFIG_FILE")
        [[ "$harmony" != "null" && -n "$harmony" ]] && generate_colors_material_args+=(--harmony "$harmony")
        [[ "$harmonize_threshold" != "null" && -n "$harmonize_threshold" ]] && generate_colors_material_args+=(--harmonize_threshold "$harmonize_threshold")
        [[ "$term_fg_boost" != "null" && -n "$term_fg_boost" ]] && generate_colors_material_args+=(--term_fg_boost "$term_fg_boost")
    fi

    matugen "${matugen_args[@]}"
    source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
    python3 "$SCRIPT_DIR/generate_colors_material.py" "${generate_colors_material_args[@]}" \
        > "$STATE_DIR"/user/generated/material_colors.scss
    deactivate
    "$SCRIPT_DIR"/applycolor.sh

    max_width_desired="$(hyprctl monitors -j | jq '([.[].width] | min)' | xargs)"
    max_height_desired="$(hyprctl monitors -j | jq '([.[].height] | min)' | xargs)"
    post_process "$max_width_desired" "$max_height_desired" "$imgpath"
}
```

- [ ] **Step 7: Verify syntax**

```bash
bash -n dots/.config/quickshell/ii/scripts/colors/switchwall.sh
```

Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add dots/.config/quickshell/ii/scripts/colors/switchwall.sh
git commit -m "feat(switchwall): add --display-only, --matugen-only flags and reroute color source chain"
```

---

### Task 4: Wallpapers.qml + Background.qml — service methods and computed wallpaper path

**Files:**
- Modify: `dots/.config/quickshell/ii/services/Wallpapers.qml`
- Modify: `dots/.config/quickshell/ii/modules/ii/background/Background.qml`

- [ ] **Step 1: Add new methods to Wallpapers.qml**

After `openFallbackPicker()` (line 40), add:

```qml
    function setMatugenBaseline(path) {
        if (!path || path.length === 0) return;
        Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--matugen-only", "--image", path]);
        root.changed()
    }

    function setWorkspaceWallpaper(wsid, path) {
        Config.setNestedValue("workspaces.wallpapers." + wsid, path);
        root.changed()
    }

    function clearWorkspaceWallpaper(wsid) {
        Config.setNestedValue("workspaces.wallpapers." + wsid, "");
        root.changed()
    }
```

- [ ] **Step 2: Update `openFallbackPicker()` and `apply()` to pass `--display-only`**

Replace lines 38-40 (`openFallbackPicker`):

```qml
    function openFallbackPicker(darkMode = Appearance.m3colors.darkmode) {
        Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--display-only", "--mode", darkMode ? "dark" : "light"]);
    }
```

Replace lines 42-46 (`apply`):

```qml
    function apply(path, darkMode = Appearance.m3colors.darkmode) {
        if (!path || path.length === 0) return;
        Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--display-only", "--mode", darkMode ? "dark" : "light", "--image", path]);
        root.changed()
    }
```

- [ ] **Step 3: Add `currentWallpaperPath` to Background.qml**

After `wallpaperSafetyTriggered` (line 50) and before `parallaxRation` (line 51), add:

```qml
        readonly property string currentWallpaperPath: {
            if (Config.options.workspaces.enabled) {
                const wsId = bgRoot.monitor.activeWorkspace?.id
                if (wsId >= 1 && wsId <= 10) {
                    const p = Config.options.workspaces.wallpapers[String(wsId)]
                    if (p && p.length > 0) return p
                }
            }
            return Config.options.background.wallpaperPath
        }
```

- [ ] **Step 4: Update wallpaperPath and wallpaperIsVideo**

Replace line 43:
```qml
        property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4") || ...
```
with:
```qml
        property bool wallpaperIsVideo: bgRoot.currentWallpaperPath.endsWith(".mp4") || bgRoot.currentWallpaperPath.endsWith(".webm") || bgRoot.currentWallpaperPath.endsWith(".mkv") || bgRoot.currentWallpaperPath.endsWith(".avi") || bgRoot.currentWallpaperPath.endsWith(".mov")
```

Replace line 44:
```qml
        property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
```
with:
```qml
        property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : bgRoot.currentWallpaperPath
```

- [ ] **Step 5: Commit**

```bash
git add dots/.config/quickshell/ii/services/Wallpapers.qml dots/.config/quickshell/ii/modules/ii/background/Background.qml
git commit -m "feat: add per-workspace wallpaper methods and computed path in Background.qml"
```

---

### Task 5: WallpaperSelectorContent.qml + QuickConfig.qml — assignMode dispatch and display-only

**Files:**
- Modify: `dots/.config/quickshell/ii/modules/ii/wallpaperSelector/WallpaperSelectorContent.qml`
- Modify: `dots/.config/quickshell/ii/modules/settings/QuickConfig.qml`

- [ ] **Step 1: Add `assignMode` property to WallpaperSelectorContent.qml**

After `useDarkMode` at line 17, add:

```qml
    property string assignMode: GlobalStates.wallpaperSelectorAssignMode
```

- [ ] **Step 2: Update `selectWallpaperPath` to dispatch by mode**

Replace lines 43-48:

```qml
    function selectWallpaperPath(filePath) {
        if (filePath && filePath.length > 0) {
            if (root.assignMode === "global-default") {
                Wallpapers.apply(filePath, root.useDarkMode);
            } else if (root.assignMode === "matugen-baseline") {
                Wallpapers.setMatugenBaseline(filePath);
            } else if (root.assignMode.startsWith("per-workspace:")) {
                const wsid = root.assignMode.split(":")[1];
                Wallpapers.setWorkspaceWallpaper(wsid, filePath);
            }
            GlobalStates.wallpaperSelectorAssignMode = "global-default";
            filterField.text = "";
            GlobalStates.wallpaperSelectorOpen = false;
        }
    }
```

- [ ] **Step 3: Update `Grid.onActivated` to pass `root.assignMode` context**

The existing delegate's `onActivated` at line ~~332 calls `root.selectWallpaperPath(fileModelData.filePath)`. Since `selectWallpaperPath` now reads `root.assignMode`, no change needed — it dispatches correctly.

- [ ] **Step 4: Update QuickConfig.qml "Choose file" button**

Replace line 126:
```qml
                        Quickshell.execDetached(`${Directories.wallpaperSwitchScriptPath}`);
```
with:
```qml
                        Quickshell.execDetached(`${Directories.wallpaperSwitchScriptPath} --display-only`);
```

- [ ] **Step 5: Commit**

```bash
git add dots/.config/quickshell/ii/modules/ii/wallpaperSelector/WallpaperSelectorContent.qml dots/.config/quickshell/ii/modules/settings/QuickConfig.qml
git commit -m "feat: add assignMode dispatch in wallpaper selector; update QuickConfig to display-only"
```

---

### Task 6: MatugenConfig.qml — new Matugen settings page

**Files:**
- Create: `dots/.config/quickshell/ii/modules/settings/MatugenConfig.qml`

- [ ] **Step 1: Create the page**

```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: matugenPage
    forceWidth: true

    ContentSection {
        icon: "palette"
        title: Translation.tr("Matugen")

        ConfigRow {
            Layout.bottomMargin: 8
            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Appearance.colors.colOnLayer0
                text: Translation.tr("This wallpaper drives your color theme. It is independent of the wallpaper shown on your desktop.")
                font.pixelSize: Appearance.font.pixelSize.small
            }
        }

        ConfigRow {
            visible: Config.options.background.matugenThumbnailPath.length > 0
            Item {
                Layout.preferredWidth: 200
                Layout.preferredHeight: 112
                Layout.alignment: Qt.AlignHCenter

                Image {
                    anchors.fill: parent
                    source: Config.options.background.matugenThumbnailPath.length > 0
                        ? Config.options.background.matugenThumbnailPath
                        : ""
                    fillMode: Image.PreserveAspectCrop
                    radius: Appearance.rounding.screenRounding - 4
                    clip: true
                }
            }
        }

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 48
            buttonRadius: Appearance.rounding.full

            contentItem: RowLayout {
                anchors.centerIn: parent
                spacing: 8
                MaterialSymbol {
                    iconSize: 20
                    text: "wallpaper"
                    fill: 1
                }
                StyledText {
                    text: Config.options.background.matugenWallpaperPath.length > 0
                        ? Translation.tr("Change baseline wallpaper")
                        : Translation.tr("Choose baseline wallpaper")
                }
            }

            onClicked: {
                GlobalStates.wallpaperSelectorAssignMode = "matugen-baseline";
                GlobalStates.wallpaperSelectorOpen = true;
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add dots/.config/quickshell/ii/modules/settings/MatugenConfig.qml
git commit -m "feat: add Matugen settings page for baseline wallpaper picker"
```

---

### Task 7: WorkspacesConfig.qml — new Workspaces settings page

**Files:**
- Create: `dots/.config/quickshell/ii/modules/settings/WorkspacesConfig.qml`

- [ ] **Step 1: Create the page**

```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: workspacesPage
    forceWidth: true

    ContentSection {
        icon: "workspaces"
        title: Translation.tr("Workspaces")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable per-workspace wallpapers")
            checked: Config.options.workspaces.enabled
            onCheckedChanged: {
                Config.options.workspaces.enabled = checked;
            }
        }

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 42
            buttonRadius: Appearance.rounding.full
            visible: Config.options.workspaces.enabled

            contentItem: RowLayout {
                anchors.centerIn: parent
                spacing: 8
                MaterialSymbol {
                    iconSize: 20
                    text: "open_in_new"
                }
                StyledText {
                    text: Translation.tr("Open picker window")
                }
            }

            onClicked: {
                Quickshell.callIpc("workspaceWallpaperPicker:toggle");
            }
        }
    }

    Repeater {
        model: 10

        ContentSection {
            required property int index
            title: Translation.tr("Workspace") + " " + (index + 1)
            visible: Config.options.workspaces.enabled

            ConfigRow {
                Item {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 45
                    Image {
                        anchors.fill: parent
                        source: {
                            const path = Config.options.workspaces.wallpapers[String(index + 1)];
                            return (path && path.length > 0) ? path : "";
                        }
                        fillMode: Image.PreserveAspectCrop
                        radius: 6
                        clip: true
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        const path = Config.options.workspaces.wallpapers[String(index + 1)];
                        return (path && path.length > 0)
                            ? path.split("/").pop()
                            : Translation.tr("— none —");
                    }
                    elide: Text.ElideRight
                }

                RippleButtonWithIcon {
                    materialIcon: "wallpaper"
                    mainText: Translation.tr("Set")
                    onClicked: {
                        GlobalStates.wallpaperSelectorAssignMode = "per-workspace:" + (index + 1);
                        GlobalStates.wallpaperSelectorOpen = true;
                    }
                }

                RippleButtonWithIcon {
                    materialIcon: "close"
                    mainText: Translation.tr("Clear")
                    onClicked: {
                        Wallpapers.clearWorkspaceWallpaper(String(index + 1));
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add dots/.config/quickshell/ii/modules/settings/WorkspacesConfig.qml
git commit -m "feat: add Workspaces settings page with per-workspace wallpaper management"
```

---

### Task 8: WorkspaceWallpaperPicker.qml — standalone per-workspace picker window + keybind

**Files:**
- Create: `dots/.config/quickshell/ii/modules/ii/workspaceWallpaperPicker/WorkspaceWallpaperPicker.qml`
- Modify: `dots/.config/hypr/custom/keybinds.lua`

- [ ] **Step 1: Create the picker window**

Create directory and file:

```bash
mkdir -p dots/.config/quickshell/ii/modules/ii/workspaceWallpaperPicker
```

```qml
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property int activeWorkspace: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1

    // Chip model for workspace selector
    property var workspaceChips: [1,2,3,4,5,6,7,8,9,10]
    property int selectedWorkspace: Math.min(root.activeWorkspace, 10)

    Loader {
        id: pickerLoader
        active: GlobalStates.wallpaperSelectorOpen

        sourceComponent: PanelWindow {
            id: panelWindow
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:workspaceWallpaperPicker"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors.top: true
            margins {
                top: Config?.options.bar.vertical ? Appearance.sizes.hyprlandGapsOut : Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut
            }

            mask: Region { item: content }

            implicitHeight: Appearance.sizes.wallpaperSelectorHeight + 60
            implicitWidth: Appearance.sizes.wallpaperSelectorWidth

            Component.onCompleted: GlobalFocusGrab.addDismissable(panelWindow)
            Component.onDestruction: GlobalFocusGrab.removeDismissable(panelWindow)
            Connections {
                target: GlobalFocusGrab
                function onDismissed() { GlobalStates.wallpaperSelectorOpen = false; }
            }

            ColumnLayout {
                id: content
                anchors.fill: parent
                spacing: 4

                // Workspace chip selector
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 8
                    spacing: 4

                    StyledText {
                        text: Translation.tr("Assign to:")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                    }

                    Repeater {
                        model: root.workspaceChips
                        RippleButton {
                            required property int modelData
                            implicitWidth: 36
                            implicitHeight: 36
                            buttonRadius: Appearance.rounding.full
                            toggled: root.selectedWorkspace === modelData
                            colBackgroundToggled: Appearance.colors.colSecondaryContainer
                            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                            colRippleToggled: Appearance.colors.colSecondaryContainerActive

                            contentItem: StyledText {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: Appearance.font.pixelSize.small
                            }

                            onClicked: {
                                root.selectedWorkspace = modelData;
                                GlobalStates.wallpaperSelectorAssignMode = "per-workspace:" + modelData;
                            }
                        }
                    }
                }

                // Wallpaper grid
                WallpaperSelectorContent {
                    id: wsContent
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    assignMode: "per-workspace:" + root.selectedWorkspace
                }
            }
        }
    }

    IpcHandler {
        target: "workspaceWallpaperPicker"

        function toggle(): void {
            GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen;
            if (GlobalStates.wallpaperSelectorOpen) {
                root.selectedWorkspace = Math.min(root.activeWorkspace, 10);
                GlobalStates.wallpaperSelectorAssignMode = "per-workspace:" + root.selectedWorkspace;
            }
        }
    }

    GlobalShortcut {
        name: "workspaceWallpaperPickerToggle"
        description: "Toggle per-workspace wallpaper picker"
        onPressed: {
            root.selectedWorkspace = Math.min(root.activeWorkspace, 10);
            GlobalStates.wallpaperSelectorAssignMode = "per-workspace:" + root.selectedWorkspace;
            GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen;
        }
    }
}
```

- [ ] **Step 2: Add keybind to `custom/keybinds.lua`**

Append at the end of the file:

```lua
-- Per-workspace wallpaper picker
hl.bind("SUPER + SHIFT + W", hl.dsp.global("quickshell:workspaceWallpaperPickerToggle"),
    { description = "Shell: Toggle per-workspace wallpaper picker" })
```

- [ ] **Step 3: Commit**

```bash
git add dots/.config/quickshell/ii/modules/ii/workspaceWallpaperPicker/WorkspaceWallpaperPicker.qml dots/.config/hypr/custom/keybinds.lua
git commit -m "feat: add WorkspaceWallpaperPicker window with SUPER+SHIFT+W keybind"
```

---

### Task 9: Settings rail registration + translations

**Files:**
- Modify: `dots/.config/quickshell/ii/settings.qml` (add 2 pages to rail)
- Modify: `dots/.config/quickshell/ii/translations/en_US.json` (add new strings)

- [ ] **Step 1: Register the two new pages in `settings.qml`**

In the `pages` array, insert Matugen and Workspaces between Background (index 3) and Interface (index 4). After the Background entry (which ends at line 46) and before the Interface entry (which starts at line 47), insert:

```qml
        {
            name: Translation.tr("Matugen"),
            icon: "palette",
            component: "modules/settings/MatugenConfig.qml"
        },
        {
            name: Translation.tr("Workspaces"),
            icon: "workspaces",
            component: "modules/settings/WorkspacesConfig.qml"
        },
```

- [ ] **Step 2: Add translation strings to `en_US.json`**

Append at the end of the JSON file, before the closing `}`:

```json
  "Matugen": "Matugen",
  "Workspaces": "Workspaces",
  "This wallpaper drives your color theme. It is independent of the wallpaper shown on your desktop.": "This wallpaper drives your color theme. It is independent of the wallpaper shown on your desktop.",
  "Choose baseline wallpaper": "Choose baseline wallpaper",
  "Change baseline wallpaper": "Change baseline wallpaper",
  "Enable per-workspace wallpapers": "Enable per-workspace wallpapers",
  "Open picker window": "Open picker window",
  "Set": "Set",
  "— none —": "— none —",
  "Assign to:": "Assign to:"
}
```

Note: en_US.json already has "Workspaces" at line 220 and "Clear" at line 93, so don't add duplicates.

- [ ] **Step 3: Verify JSON validity**

```bash
jq . dots/.config/quickshell/ii/translations/en_US.json > /dev/null && echo "valid"
jq . dots/config 2>/dev/null || true
```

Expected: "valid"

- [ ] **Step 4: Commit**

```bash
git add dots/.config/quickshell/ii/settings.qml dots/.config/quickshell/ii/translations/en_US.json
git commit -m "feat: register Matugen and Workspaces settings pages; add translations"
```

---

### Post-implementation verification

```bash
# Full syntax check
bash -n dots/.config/quickshell/ii/scripts/colors/switchwall.sh

# Config hot-reload test
jq '.background.matugenWallpaperPath' ~/.config/illogical-impulse/config.json
jq '.workspaces' ~/.config/illogical-impulse/config.json

# QML quickshell no-error test (restart quickshell and watch journal)
# Kill and restart quickshell, check for errors
killall qs quickshell
journalctl -f | grep -i error &
qs -c ~/.config/quickshell/ii &
```

Expected: no QML or quickshell errors on startup. All new settings pages visible in the Settings app rail. SUPER+SHIFT+W opens the per-workspace picker. Matugen page baseline pick triggers matugen (watch terminal colors change). Per-workspace picker assigns wallpaper to workspace (verify via jq after selecting). Workspace switch swaps background image (verify visually).
