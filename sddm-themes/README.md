# end-4 SDDM themes

A custom SDDM theme family for the end_4 / illogical-impulse dotfiles setup.

## Included theme

- `end-4-sddm` — Material You styled login screen with glassmorphism panel,
  current wallpaper background, and matching colors.

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

## Theme selector

Open **Settings → Login** to pick the active SDDM theme.

## Test a theme

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/end-4-sddm/
```

## Add a new theme in the future

1. Copy `sddm-themes/end-4-sddm/` to `sddm-themes/<your-theme>/`.
2. Edit `theme.conf` (name, default colors, fonts, geometry).
3. Adjust the QML to your taste.
4. Re-run `sudo ./sddm-themes/scripts/install.sh`.
5. Select it from **Settings → Login**.
