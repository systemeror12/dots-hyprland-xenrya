# end-4 SDDM themes

A custom SDDM theme family for the end_4 / illogical-impulse dotfiles setup.

## Included theme

- `end-4-sddm` — Quickshell-lockscreen-inspired login screen.
  - Full-wallpaper background.
  - Large top-left clock and date.
  - Left-aligned vertical login form: user selector, password field with
    Quickshell-style shape animation, Login button, session selector, and
    power actions.
  - Dynamic Material You colors synced from the current wallpaper.

## Install

Run the install script with root privileges:

```bash
sudo ./sddm-themes/scripts/install.sh
```

This will:

1. Add your user to the `sddm` group.
2. Create `/var/lib/sddm/illogical-impulse/` (writable by the `sddm` group).
3. Copy `end-4-sddm` to `/usr/share/sddm/themes/`.
4. Activate `end-4-sddm` in `/etc/sddm.conf.d/99-end-4-sddm.conf`.

**Log out and back in** so the group change takes effect.

## Wallpaper & color sync

The theme syncs automatically when you change your desktop wallpaper via the
normal illogical-impulse flow. The hook is wired into
`~/.config/quickshell/ii/scripts/colors/switchwall.sh`.

You can also trigger a sync manually:

```bash
~/.config/quickshell/ii/scripts/sddm/update-active-theme.sh
```

## Test a theme

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/end-4-sddm/
```

## Customizing the design (modifiable hotspots)

Most visual tweaks can be made in `sddm-themes/end-4-sddm/theme.conf` before
installation, or in the installed copy at
`/usr/share/sddm/themes/end-4-sddm/theme.conf`.

Look for the `HOTSPOT:` comments in these files for the safest places to
adjust:

- `sddm-themes/end-4-sddm/theme.conf`
  - Clock position (`clockTopMargin`, `clockLeftMargin`).
  - Login form position and width (`formTopMargin`, `formLeftMargin`,
    `formWidth`).
  - Row/button sizes (`rowHeight`, `rowSpacing`, `buttonHeight`,
    `sessionButtonHeight`, `powerButtonSize`).
  - Time/date formats (`timeFormat`, `dateFormat`).
  - Optional left-side readability scrim (`useLeftScrim`, `scrimColor`,
    `scrimWidth`).
  - Fallback Material You colors and fonts.

- `sddm-themes/end-4-sddm/Main.qml`
  - Color token aliases (auto-filled from `colors.json`).
  - Geometry property wiring.

- `sddm-themes/end-4-sddm/panels/LoginForm.qml`
  - Order and visibility of the user row, password field, Login button,
    session selector, and power buttons.

- `sddm-themes/end-4-sddm/components/PasswordShapes.qml`
  - Password shape icons and animation timing.

After changing files, reinstall the theme:

```bash
sudo ./sddm-themes/scripts/install.sh
```

## Add a new theme in the future

1. Copy `sddm-themes/end-4-sddm/` to `sddm-themes/<your-theme>/`.
2. Edit `theme.conf` (name, default colors, fonts, geometry).
3. Adjust the QML to your taste.
4. Re-run `sudo ./sddm-themes/scripts/install.sh`.
5. Select it from **Settings → Login**.
