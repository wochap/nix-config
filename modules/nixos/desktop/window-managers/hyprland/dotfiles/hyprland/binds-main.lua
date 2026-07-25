local constants = require("hyprland.constants")
local scratchpad = require("hyprland.lib.scratchpad")
local previous_ws = require("hyprland.lib.previous_ws")
local mod = "SUPER"

hl.bind(mod .. " + mouse:272", hl.dsp.window.float(), { mouse = true, click = true })
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
-- hl.bind(mod .. " + SHIFT + mouse:273", hl.dsp.window.resize({ keep_aspect_ratio = true }), { mouse = true })

--- SYSTEM KEYBINDINGS

-- Open scratchpad terminal
hl.bind(mod .. " + i", function()
  scratchpad.raise_or_run("kitty-scratch", "$HOME/.config/kitty/scripts/kitty-scratch.sh", { use_uwsm = true })
end)

-- Lock screen
hl.bind(mod .. " + l", hl.dsp.exec_cmd("loginctl lock-session"))

-- Open power menu
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd("uwsm-app -- tofi-powermenu"))

-- Open app launcher
hl.bind(mod .. " + space", hl.dsp.exec_cmd("tofi-launcher --uwsm"))

-- Take fullscreen screenshot
hl.bind(mod .. " + Print", hl.dsp.exec_cmd("uwsm-app -- takeshot --now"))

-- Open calc
hl.bind(mod .. " + c", hl.dsp.exec_cmd("uwsm-app -- tofi-calc"))

-- Show clipboard
hl.bind(mod .. " + v", hl.dsp.exec_cmd("uwsm-app -- clipboard-manager --menu"))

-- Clear clipboard
hl.bind(mod .. " + SHIFT + v", hl.dsp.exec_cmd("clipboard-manager --clear"))

-- Show emojis
hl.bind(mod .. " + e", hl.dsp.exec_cmd("uwsm-app -- tofi-emoji"))

-- Toggle bar
hl.bind(mod .. " + b", hl.dsp.exec_cmd("quickshell -p ~/.config/quickshell/shell ipc call bar toggle"))

-- Toggle idle inhibitor
hl.bind(mod .. " + m", hl.dsp.exec_cmd("shell-idle-inhibit --toggle"))

-- Toggle offlinemsmtp
hl.bind(mod .. " + o", hl.dsp.exec_cmd("offlinemsmtp-toggle-mode --toggle"))

-- Toggle control center
hl.bind(
  mod .. " + SHIFT + c",
  hl.dsp.exec_cmd("quickshell --path ~/.config/quickshell/shell ipc call control-center toggle")
)

--- WM KEYBINDINGS

-- Close focused window
hl.bind(mod .. " + SHIFT + w", hl.dsp.window.close())

-- Close focused window
hl.bind(mod .. " + CTRL + SHIFT + w", hl.dsp.window.kill())

-- Toggle float
hl.bind(mod .. " + s", hl.dsp.window.float())

-- Toggle fullscreen
hl.bind(mod .. " + f", hl.dsp.window.fullscreen())
hl.bind(mod .. " + SHIFT + f", hl.dsp.window.fullscreen_state({ internal = 0, client = 1 }))

-- Set sticky
hl.bind(mod .. " + CTRL + y", hl.dsp.window.pin())

-- Focus direction
hl.bind(mod .. " + n", hl.dsp.layout("cyclenext"))
hl.bind(mod .. " + p", hl.dsp.layout("cycleprev"))
hl.bind(mod .. " + left", function()
  hl.dispatch(hl.dsp.focus({ direction = "l" }))
  hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)
hl.bind(mod .. " + down", function()
  hl.dispatch(hl.dsp.focus({ direction = "d" }))
  hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)
hl.bind(mod .. " + up", function()
  hl.dispatch(hl.dsp.focus({ direction = "u" }))
  hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)
hl.bind(mod .. " + right", function()
  hl.dispatch(hl.dsp.focus({ direction = "r" }))
  hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)

-- Swap direction
hl.bind(mod .. " + SHIFT + n", hl.dsp.layout("swapnext"))
hl.bind(mod .. " + SHIFT + p", hl.dsp.layout("swapprev"))
hl.bind(mod .. " + SHIFT + left", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.window.swap({ direction = "d" }))
hl.bind(mod .. " + SHIFT + up", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "r" }))

-- Resize tiling/floating windows
hl.bind(mod .. " + ALT + SHIFT + left", hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
hl.bind(mod .. " + ALT + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }))
hl.bind(mod .. " + ALT + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
hl.bind(mod .. " + ALT + SHIFT + right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }))

-- Move floating windows
hl.bind(mod .. " + ALT + left", hl.dsp.window.move({ x = -40, y = 0, relative = true }))
hl.bind(mod .. " + ALT + down", hl.dsp.window.move({ x = 0, y = 40, relative = true }))
hl.bind(mod .. " + ALT + up", hl.dsp.window.move({ x = 0, y = -40, relative = true }))
hl.bind(mod .. " + ALT + right", hl.dsp.window.move({ x = 40, y = 0, relative = true }))

-- Focus next/previous workspace
hl.bind(mod .. " + comma", hl.dsp.focus({ workspace = "r-1", on_current_monitor = true }))
hl.bind(mod .. " + period", hl.dsp.focus({ workspace = "r+1", on_current_monitor = true }))
hl.bind(mod .. " + CTRL + comma", hl.dsp.focus({ workspace = "m-1", on_current_monitor = true }))
hl.bind(mod .. " + CTRL + period", hl.dsp.focus({ workspace = "m+1", on_current_monitor = true }))
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({
  fingers = 3,
  direction = "right",
  action = function()
    hl.dispatch(hl.dsp.focus({ workspace = "m-1", on_current_monitor = true }))
  end,
})
hl.gesture({
  fingers = 3,
  direction = "left",
  action = function()
    hl.dispatch(hl.dsp.focus({ workspace = "m+1", on_current_monitor = true }))
  end,
})
hl.gesture({
  fingers = 3,
  direction = "right",
  mods = "SUPER",
  action = function()
    hl.dispatch(hl.dsp.focus({ workspace = "r-1", on_current_monitor = true }))
  end,
})
hl.gesture({
  fingers = 3,
  direction = "left",
  mods = "SUPER",
  action = function()
    hl.dispatch(hl.dsp.focus({ workspace = "r+1", on_current_monitor = true }))
  end,
})
hl.gesture({
  fingers = 3,
  direction = "down",
  action = function()
    hl.dispatch(hl.dsp.layout("cyclenext"))
  end,
})
hl.gesture({
  fingers = 3,
  direction = "up",
  action = function()
    hl.dispatch(hl.dsp.layout("cycleprev"))
  end,
})

-- Send focused window to the next/previous workspace
hl.bind(mod .. " + SHIFT + comma", hl.dsp.window.move({ workspace = "r-1", follow = false }))
hl.bind(mod .. " + SHIFT + period", hl.dsp.window.move({ workspace = "r+1", follow = false }))

-- Bump focused window to the top of the layout stack
hl.bind(mod .. " + return", hl.dsp.layout("swapwithmaster"))

-- Focus next/prev monitor
hl.bind(mod .. " + bracketleft", hl.dsp.focus({ monitor = "-1" }))
hl.bind(mod .. " + bracketright", hl.dsp.focus({ monitor = "+1" }))

-- Move focused window to next/prev monitor
hl.bind(mod .. " + SHIFT + bracketleft", hl.dsp.window.move({ monitor = "-1", follow = false }))
hl.bind(mod .. " + SHIFT + bracketright", hl.dsp.window.move({ monitor = "+1", follow = false }))

hl.bind(mod .. " + 1", hl.dsp.focus({ workspace = 1, on_current_monitor = true }))
hl.bind(mod .. " + 2", hl.dsp.focus({ workspace = 2, on_current_monitor = true }))
hl.bind(mod .. " + 3", hl.dsp.focus({ workspace = 3, on_current_monitor = true }))
hl.bind(mod .. " + 4", hl.dsp.focus({ workspace = 4, on_current_monitor = true }))
hl.bind(mod .. " + 5", hl.dsp.focus({ workspace = 5, on_current_monitor = true }))
hl.bind(mod .. " + 6", hl.dsp.focus({ workspace = 6, on_current_monitor = true }))
hl.bind(mod .. " + 7", hl.dsp.focus({ workspace = 7, on_current_monitor = true }))
hl.bind(mod .. " + 8", hl.dsp.focus({ workspace = 8, on_current_monitor = true }))
hl.bind(mod .. " + 9", hl.dsp.focus({ workspace = 9, on_current_monitor = true }))

hl.bind(mod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1, follow = false }))
hl.bind(mod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2, follow = false }))
hl.bind(mod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3, follow = false }))
hl.bind(mod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4, follow = false }))
hl.bind(mod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5, follow = false }))
hl.bind(mod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6, follow = false }))
hl.bind(mod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7, follow = false }))
hl.bind(mod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8, follow = false }))
hl.bind(mod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9, follow = false }))

hl.bind(mod .. " + grave", previous_ws.focus_previous)

--- WM ALTTAB

hl.bind(mod .. " + TAB", hl.dsp.window.cycle_next({ tiled = true }))
hl.bind(mod .. " + SHIFT + TAB", hl.dsp.layout("cycleprev"))
hl.bind("ALT + TAB", function()
  hl.dispatch(hl.dsp.window.cycle_next({ floating = true }))
  hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)
hl.bind("ALT + SHIFT + TAB", function()
  hl.dispatch(hl.dsp.window.cycle_next({ next = false, floating = true }))
  hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)

--- WM SCRATCHPAD

-- Open scratchpad
hl.bind(mod .. " + d", scratchpad.toggle)

-- Send to scratchpad
hl.bind(mod .. " + SHIFT + d", scratchpad.toggle_in)

-- Open last scratchpad
hl.bind(mod .. " + SHIFT + grave", scratchpad.focus_last)

-- WM GROUPS

hl.bind(mod .. " + g", hl.dsp.submap("group"))
hl.define_submap("group", "reset", function()
  hl.bind("g", hl.dsp.group.toggle())
  -- TODO: verify into_or_create_group matches old movewindoworgroup behavior
  hl.bind("left", hl.dsp.window.move({ into_or_create_group = "l" }))
  hl.bind("down", hl.dsp.window.move({ into_or_create_group = "d" }))
  hl.bind("up", hl.dsp.window.move({ into_or_create_group = "u" }))
  hl.bind("right", hl.dsp.window.move({ into_or_create_group = "r" }))
  hl.bind("n", hl.dsp.group.next())
  hl.bind("p", hl.dsp.group.prev())
  hl.bind("SHIFT + n", hl.dsp.group.move_window({ forward = true }))
  hl.bind("SHIFT + p", hl.dsp.group.move_window({ forward = false }))
  hl.bind("SHIFT + 1", hl.dsp.window.move({ workspace = 1, follow = false }))
  hl.bind("SHIFT + 2", hl.dsp.window.move({ workspace = 2, follow = false }))
  hl.bind("SHIFT + 3", hl.dsp.window.move({ workspace = 3, follow = false }))
  hl.bind("SHIFT + 4", hl.dsp.window.move({ workspace = 4, follow = false }))
  hl.bind("SHIFT + 5", hl.dsp.window.move({ workspace = 5, follow = false }))
  hl.bind("SHIFT + 6", hl.dsp.window.move({ workspace = 6, follow = false }))
  hl.bind("SHIFT + 7", hl.dsp.window.move({ workspace = 7, follow = false }))
  hl.bind("SHIFT + 8", hl.dsp.window.move({ workspace = 8, follow = false }))
  hl.bind("SHIFT + 9", hl.dsp.window.move({ workspace = 9, follow = false }))
  hl.bind("escape", hl.dsp.submap("reset"))
end)

--- APPLICATION KEYBINDINGS (Super + Alt + Key)

-- Open primary terminal
hl.bind(mod .. " + ALT + t", hl.dsp.exec_cmd("uwsm-app -- footclient"))

-- Open file manager
hl.bind(mod .. " + ALT + f", function()
  scratchpad.raise_or_run("Thunar", "thunar --name Thunar", { use_uwsm = true })
end)

-- Show ruler
hl.bind(mod .. " + ALT + m", hl.dsp.exec_cmd("uwsm-app -- ruler"))

-- Screencast/record region to mp4
hl.bind(mod .. " + ALT + r", hl.dsp.exec_cmd("uwsm-app -- recorder --area"))

-- Open screenshoot utility
hl.bind(mod .. " + ALT + s", hl.dsp.exec_cmd("uwsm-app -- takeshot --area"))

-- Open ocr utility
hl.bind(mod .. " + ALT + o", hl.dsp.exec_cmd("uwsm-app -- ocr"))

-- Open ocr-math utility
hl.bind(mod .. " + ALT + h", hl.dsp.exec_cmd("uwsm-app -- ocr-math"))

-- Open color picker
hl.bind(mod .. " + ALT + c", hl.dsp.exec_cmd("uwsm-app -- color-picker"))

-- Magnifying glass
hl.bind(mod .. " + ALT + z", hl.dsp.exec_cmd("uwsm-app -- pypr zoom"))

--- MEDIA KEYBINDINGS

hl.bind(
  "XF86AudioRaiseVolume",
  hl.dsp.exec_cmd("shell-pipewire --volume-output 5%+"),
  { locked = true, repeating = true }
)
hl.bind(
  "XF86AudioLowerVolume",
  hl.dsp.exec_cmd("shell-pipewire --volume-output 5%-"),
  { locked = true, repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), { locked = true })

hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("backlight 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("backlight 5%-"), { locked = true, repeating = true })

hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("kbd-backlight 5%-"), { locked = true, repeating = true })
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("kbd-backlight 5%+"), { locked = true, repeating = true })

--- OTHERS

hl.bind(mod .. " + CTRL + ALT + m", hl.dsp.exec_cmd('hyprctl output create headless "HEADLESS-2"'))
hl.bind(mod .. " + CTRL + SHIFT + ALT + m", hl.dsp.exec_cmd('hyprctl output remove "HEADLESS-2"'))
hl.bind(mod .. " + CTRL + SHIFT + l", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"), { locked = true })
hl.bind(mod .. " + ALT + x", function()
  scratchpad.raise_or_run("xwaylandvideobridge", "xwaylandvideobridge", { use_uwsm = true })
end)
hl.bind(mod .. " + CTRL + SHIFT + q", hl.dsp.exec_cmd("hyprshutdown"))

-- SUBMAPS

-- Layout
hl.bind(mod .. " + r", hl.dsp.submap("layout"))
hl.define_submap("layout", "reset", function()
  hl.bind("c", hl.dsp.window.center())
  hl.bind(
    "e",
    hl.dsp.exec_cmd(
      'hyprctl keyword workspace $(hyprctl activeworkspace -j | jq -r ".name"),layout:master && hyprctl dispatch layoutmsg orientationcenter'
    )
  )
  hl.bind(
    "t",
    hl.dsp.exec_cmd(
      'hyprctl keyword workspace $(hyprctl activeworkspace -j | jq -r ".name"),layout:master && hyprctl dispatch layoutmsg orientationleft'
    )
  )
  hl.bind(
    "f",
    hl.dsp.exec_cmd(
      'hyprctl keyword workspace $(hyprctl activeworkspace -j | jq -r ".name"),layout:master && hyprctl dispatch layoutmsg orientationtop'
    )
  )
  hl.bind(
    "m",
    hl.dsp.exec_cmd('hyprctl keyword workspace $(hyprctl activeworkspace -j | jq -r ".name"),layout:monocle')
  )
  hl.bind("1", function()
    hl.dispatch(hl.dsp.window.move({ out_of_group = true }))
    hl.dispatch(hl.dsp.window.float({ action = "on" }))
    hl.dispatch(hl.dsp.window.resize({ x = 1200, y = 800 }))
    hl.dispatch(hl.dsp.window.center())
  end)
  hl.bind("left", hl.dsp.layout("addmaster"))
  hl.bind("right", hl.dsp.layout("removemaster"))
  hl.bind("SHIFT + left", hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
  hl.bind("SHIFT + down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }))
  hl.bind("SHIFT + up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
  hl.bind("SHIFT + right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }))
  hl.bind("escape", hl.dsp.submap("reset"))
end)

-- Open Browser
hl.bind(mod .. " + ALT + b", hl.dsp.submap("browser"))
hl.define_submap("browser", "reset", function()
  -- TODO: find workaround for exec rules + uwsm-app
  hl.bind("f", hl.dsp.exec_cmd("uwsm-app -- firefox"))
  hl.bind("b", hl.dsp.exec_cmd("uwsm-app -- brave"))
  hl.bind("g", hl.dsp.exec_cmd("uwsm-app -- google-chrome-stable"))
  hl.bind("m", hl.dsp.exec_cmd("uwsm-app -- microsoft-edge"))
  hl.bind("t", function()
    scratchpad.raise_or_run(constants.bitwarden_appid, "bitwarden", { use_uwsm = true })
  end)
  hl.bind("SHIFT + i", function()
    scratchpad.raise_or_run(
      constants.bing_gpt_appid,
      "microsoft-edge --profile-directory=Default --app=https://www.bing.com/chat",
      { use_uwsm = true }
    )
  end)
  hl.bind("i", function()
    scratchpad.raise_or_run(
      constants.chat_gpt_appid,
      "google-chrome-stable --profile-directory=Default --app=https://chat.openai.com",
      { use_uwsm = true }
    )
  end)
  hl.bind("e", function()
    scratchpad.raise_or_run(
      constants.gemini_appid,
      "google-chrome-stable --profile-directory=Default --app=https://gemini.google.com/app",
      { use_uwsm = true }
    )
  end)
  hl.bind("o", function()
    scratchpad.raise_or_run(
      constants.ollama_appid,
      "google-chrome-stable --profile-directory=Default --app=https://ollama.wochap.local",
      { use_uwsm = true }
    )
  end)
  hl.bind("w", function()
    scratchpad.raise_or_run(
      constants.openwebui_appid,
      "google-chrome-stable --profile-directory=Default --app=https://openwebui.wochap.local",
      { use_uwsm = true }
    )
  end)
  hl.bind("u", function()
    scratchpad.raise_or_run(
      constants.ytmusic_appid,
      "google-chrome-stable --profile-directory=Default --app=https://music.youtube.com",
      { use_uwsm = true }
    )
  end)
  hl.bind("escape", hl.dsp.submap("reset"))
end)

-- Terminal TUI
hl.bind(mod .. " + ALT + u", hl.dsp.submap("tui"))
hl.define_submap("tui", "reset", function()
  hl.bind("n", function()
    scratchpad.raise_or_run("tui-notes", "tui-notes", { use_uwsm = true })
  end)
  hl.bind("i", function()
    scratchpad.raise_or_run("tui-notes-obsidian", "tui-notes-obsidian", { use_uwsm = true })
  end)
  hl.bind("m", function()
    scratchpad.raise_or_run("tui-monitor", "tui-monitor", { use_uwsm = true })
  end)
  hl.bind("e", function()
    scratchpad.raise_or_run("tui-email", "tui-email", { use_uwsm = true })
  end)
  hl.bind("r", function()
    scratchpad.raise_or_run("tui-rss", "tui-rss", { use_uwsm = true })
  end)
  hl.bind("u", function()
    scratchpad.raise_or_run("tui-music", "tui-music", { use_uwsm = true })
  end)
  hl.bind("c", function()
    scratchpad.raise_or_run("tui-calendar", "tui-calendar", { use_uwsm = true })
  end)
  hl.bind("b", function()
    scratchpad.raise_or_run("tui-bookmarks", "tui-bookmarks --select", { use_uwsm = true })
  end)
  hl.bind("SHIFT + b", function()
    scratchpad.raise_or_run("tui-bookmarks", "tui-bookmarks --add", { use_uwsm = true })
  end)
  hl.bind("CTRL + SHIFT + b", function()
    scratchpad.raise_or_run("tui-bookmarks", "tui-bookmarks --edit", { use_uwsm = true })
  end)
  hl.bind("escape", hl.dsp.submap("reset"))
end)

-- Notification
hl.bind(mod .. " + ALT + n", hl.dsp.submap("notification"))
hl.define_submap("notification", "reset", function()
  hl.bind("n", hl.dsp.exec_cmd("quickshell --path ~/.config/quickshell/shell ipc call notifications togglePanel"))
  hl.bind("c", hl.dsp.exec_cmd("quickshell --path ~/.config/quickshell/shell ipc call notifications dismissPopups"))
  hl.bind(
    "SHIFT + C",
    hl.dsp.exec_cmd("quickshell --path ~/.config/quickshell/shell ipc call notifications discardPopups")
  )
  hl.bind("escape", hl.dsp.submap("reset"))
end)

-- HACK: disable all hyprland keymappings
hl.bind(mod .. " + ALT + CTRL + g", hl.dsp.submap("kb_inhibit"))
hl.define_submap("kb_inhibit", function()
  hl.bind(mod .. " + ALT + CTRL + g", hl.dsp.submap("reset"))
end)
