hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- App launcher: Rofi (replaces maximize on SUPER+D)
hl.bind("SUPER + D", hl.dsp.exec_cmd("rofi -show drun -config ~/.config/rofi/config.rasi"),
    { description = "App launcher: Rofi" })

-- Window maximize moved from SUPER+D to SUPER+SHIFT+D
hl.bind("SUPER + SHIFT + D", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),
    { description = "Window: Maximize" })
