hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- Remove the conflicting SUPER+D maximize binding defined in hyprland/keybinds.lua
hl.unbind("SUPER + D")

-- Remove duplicate terminal binds so only SUPER+Return opens the terminal
hl.unbind("SUPER + T")
hl.unbind("CTRL + ALT + T")

-- Free up SUPER+SHIFT+M from the upstream speaker mute toggle so we can use it for maximize
hl.unbind("SUPER + SHIFT + M")

-- App launcher: Rofi (replaces maximize on SUPER+D)
hl.bind("SUPER + D", hl.dsp.exec_cmd("rofi -show drun -config ~/.config/rofi/config.rasi"),
    { description = "App launcher: Rofi" })

-- Window maximize on SUPER+SHIFT+M
hl.bind("SUPER + SHIFT + M", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),
    { description = "Window: Maximize" })

-- Speaker mute, relocated from SUPER+SHIFT+M (which is now Maximize)
hl.bind("SUPER + SHIFT + ALT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"),
    { locked = true, description = "Media: Toggle mute" })
