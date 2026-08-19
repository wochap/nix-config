local constants = require("hyprland.constants")
local harpoon = require("hyprland.lib.harpoon")
local harpoon_scratchpad = require("hyprland.lib.harpoon_scratchpad")
local scratchpad = require("hyprland.lib.scratchpad")
local previous_ws = require("hyprland.lib.previous_ws")
local ws_offset = require("hyprland.lib.ws_offset")
local mod = "SUPER"
local scratchpad_opts
if not constants.is_kiosk then
  scratchpad_opts = { use_uwsm = true }
end

local function session_cmd(command)
  if constants.is_kiosk then
    return command
  end
  return "uwsm-app -- " .. command
end

hl.bind(mod .. " + mouse:272", hl.dsp.window.float(), { mouse = true, click = true })
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
-- hl.bind(mod .. " + SHIFT + mouse:273", hl.dsp.window.resize({ keep_aspect_ratio = true }), { mouse = true })

--- SYSTEM KEYBINDINGS

-- Open scratchpad terminal
hl.bind(mod .. " + i", function()
  scratchpad.raise_or_run("kitty-scratch", "$HOME/.config/kitty/scripts/kitty-scratch.sh", scratchpad_opts)
end)

-- Lock screen
hl.bind(mod .. " + l", hl.dsp.exec_cmd("loginctl lock-session"))

-- Open power menu
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd(session_cmd("tofi-powermenu")))

-- Open app launcher
hl.bind(mod .. " + space", hl.dsp.exec_cmd(constants.is_kiosk and "tofi-launcher" or "tofi-launcher --uwsm"))

-- Take fullscreen screenshot
hl.bind(mod .. " + Print", hl.dsp.exec_cmd(session_cmd("takeshot --now")))

-- Open calc
hl.bind(mod .. " + c", hl.dsp.exec_cmd(session_cmd("tofi-calc")))

-- Show clipboard
hl.bind(mod .. " + v", hl.dsp.exec_cmd(session_cmd("clipboard-manager --menu")))

-- Clear clipboard
hl.bind(mod .. " + SHIFT + v", hl.dsp.exec_cmd("clipboard-manager --clear"))

-- Show emojis
hl.bind(mod .. " + e", hl.dsp.exec_cmd(session_cmd("tofi-emoji")))

if not constants.is_kiosk then
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
end

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

-- number keys focus/move to workspace (key + page offset); see lib/ws_offset.lua
for key = 1, 9 do
  hl.bind(mod .. " + " .. key, function()
    hl.dispatch(hl.dsp.focus({ workspace = ws_offset.ws(key), on_current_monitor = true }))
  end)
  hl.bind(mod .. " + SHIFT + " .. key, function()
    hl.dispatch(hl.dsp.window.move({ workspace = ws_offset.ws(key), follow = false }))
  end)
end

-- cycle workspace page (offset added to number keys 1-9)
hl.bind(mod .. " + 0", ws_offset.cycle)
hl.bind(mod .. " + SHIFT + 0", function()
  ws_offset.cycle()
  local ws_id = hl.get_active_workspace().id
  local next_ws_id = ws_offset.get() + ws_id
  if ws_id > 10 then
    next_ws_id = ws_id - 10
  end
  hl.dispatch(hl.dsp.focus({ workspace = next_ws_id, on_current_monitor = true }))
end)

hl.bind(mod .. " + grave", previous_ws.focus_previous)

--- WM HARPOON

local harpoon_keys = {}
for _, keys in ipairs({ constants.alphabet_keys, constants.number_keys }) do
  for _, key in ipairs(keys) do
    table.insert(harpoon_keys, key)
  end
end

harpoon.setup({
  leader = mod .. " + h",
  keys = harpoon_keys,
})

harpoon_scratchpad.setup({
  leader = mod .. " + a",
  keys = harpoon_keys,
})

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
  for key = 1, 9 do
    hl.bind("SHIFT + " .. key, function()
      hl.dispatch(hl.dsp.window.move({ workspace = ws_offset.ws(key), follow = false }))
    end)
  end
  hl.bind("escape", hl.dsp.submap("reset"))
end)

--- APPLICATION KEYBINDINGS (Super + Alt + Key)

-- Open primary terminal
hl.bind(mod .. " + ALT + t", hl.dsp.exec_cmd(constants.is_kiosk and "foot" or "uwsm-app -- footclient"))

-- Open file manager
hl.bind(mod .. " + ALT + f", function()
  scratchpad.raise_or_run("Thunar", "thunar --name Thunar", scratchpad_opts)
end)

-- Show ruler
hl.bind(mod .. " + ALT + m", hl.dsp.exec_cmd(session_cmd("ruler")))

-- Screencast/record region to mp4
hl.bind(mod .. " + ALT + r", hl.dsp.exec_cmd(session_cmd("recorder --area")))

-- Open screenshoot utility
hl.bind(mod .. " + ALT + s", hl.dsp.exec_cmd(session_cmd("takeshot --area")))

-- Open ocr utility
hl.bind(mod .. " + ALT + o", hl.dsp.exec_cmd(session_cmd("ocr")))

-- Open ocr-math utility
hl.bind(mod .. " + ALT + h", hl.dsp.exec_cmd(session_cmd("ocr-math")))

-- Open color picker
hl.bind(mod .. " + ALT + c", hl.dsp.exec_cmd(session_cmd("color-picker")))

-- Magnifying glass
hl.bind(mod .. " + ALT + z", hl.dsp.exec_cmd(session_cmd("pypr zoom")))

hl.bind(
  mod .. " + ALT + v",
  hl.dsp.exec_cmd(session_cmd("tts-clipboard primary --voice=F1 --speed=1.5 --steps=5 --chunking=on"))
)

hl.bind(
  mod .. " + ALT + d",
    hl.dsp.exec_cmd(session_cmd("clean-voice"))
)

--- MEDIA KEYBINDINGS

if not constants.is_kiosk then
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
end

--- OTHERS

if not constants.is_kiosk then
  hl.bind(mod .. " + CTRL + ALT + m", hl.dsp.exec_cmd('hyprctl output create headless "HEADLESS-2"'))
  hl.bind(mod .. " + CTRL + SHIFT + ALT + m", hl.dsp.exec_cmd('hyprctl output remove "HEADLESS-2"'))
end
hl.bind(mod .. " + CTRL + SHIFT + l", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"), { locked = true })
if not constants.is_kiosk then
  hl.bind(mod .. " + ALT + x", function()
    scratchpad.raise_or_run("xwaylandvideobridge", "xwaylandvideobridge", scratchpad_opts)
  end)
end
hl.bind(mod .. " + CTRL + SHIFT + q", hl.dsp.exec_cmd("hyprshutdown"))
hl.bind(mod .. " + k", function()
  local window
  for _, candidate in ipairs(hl.get_windows({ class = "kb-hud" })) do
    if candidate.title == "kb-hud overlay" then
      window = candidate
      break
    end
  end
  if not window then
    return
  end

  if window.workspace and window.workspace.name == "special:kb-hud-minimized" then
    hl.dispatch(hl.dsp.window.move({ workspace = hl.get_active_workspace(), window = window, follow = false }))
    hl.dispatch(hl.dsp.window.pin({ action = "set", window = window }))
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = window }))
  else
    hl.dispatch(hl.dsp.window.pin({ action = "unset", window = window }))
    hl.dispatch(hl.dsp.window.move({ workspace = "special:kb-hud-minimized", window = window, follow = false }))
  end
end)

-- SUBMAPS

-- Layout
hl.bind(mod .. " + r", hl.dsp.submap("layout"))
hl.define_submap("layout", "reset", function()
  hl.bind("c", hl.dsp.window.center())
  hl.bind("e", function()
    hl.workspace_rule({
      workspace = hl.get_active_workspace().name,
      layout = "master",
      layout_opts = { orientation = "center" },
    })
  end)
  hl.bind("t", function()
    hl.workspace_rule({
      workspace = hl.get_active_workspace().name,
      layout = "master",
      layout_opts = { orientation = "left" },
    })
  end)
  hl.bind("f", function()
    hl.workspace_rule({
      workspace = hl.get_active_workspace().name,
      layout = "master",
      layout_opts = { orientation = "top" },
    })
  end)
  hl.bind("m", function()
    hl.workspace_rule({
      workspace = hl.get_active_workspace().name,
      layout = "monocle",
    })
  end)
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
  hl.bind("f", hl.dsp.exec_cmd(session_cmd("firefox")))
  hl.bind("b", hl.dsp.exec_cmd(session_cmd("brave")))
  hl.bind("g", hl.dsp.exec_cmd(session_cmd("google-chrome-stable")))
  hl.bind("m", hl.dsp.exec_cmd(session_cmd("microsoft-edge")))
  if not constants.is_kiosk then
    hl.bind("t", function()
      scratchpad.raise_or_run(constants.bitwarden_appid, "bitwarden", scratchpad_opts)
    end)
  end
  hl.bind("SHIFT + i", function()
    scratchpad.raise_or_run(
      constants.bing_gpt_appid,
      "microsoft-edge --profile-directory=Default --app=https://www.bing.com/chat",
      scratchpad_opts
    )
  end)
  hl.bind("i", function()
    scratchpad.raise_or_run(
      constants.chat_gpt_appid,
      "google-chrome-stable --profile-directory=Default --app=https://chat.openai.com",
      scratchpad_opts
    )
  end)
  hl.bind("e", function()
    scratchpad.raise_or_run(
      constants.gemini_appid,
      "google-chrome-stable --profile-directory=Default --app=https://gemini.google.com/app",
      scratchpad_opts
    )
  end)
  hl.bind("w", function()
    scratchpad.raise_or_run(
      constants.openwebui_appid,
      "google-chrome-stable --profile-directory=Default --app=https://openwebui.wochap.local",
      scratchpad_opts
    )
  end)
  hl.bind("u", function()
    scratchpad.raise_or_run(
      constants.ytmusic_appid,
      "google-chrome-stable --profile-directory=Default --app=https://music.youtube.com",
      scratchpad_opts
    )
  end)
  hl.bind("escape", hl.dsp.submap("reset"))
end)

-- Terminal TUI
hl.bind(mod .. " + ALT + u", hl.dsp.submap("tui"))
hl.define_submap("tui", "reset", function()
  hl.bind("n", function()
    scratchpad.raise_or_run("tui-notes", "tui-notes", scratchpad_opts)
  end)
  hl.bind("i", function()
    scratchpad.raise_or_run("tui-notes-obsidian", "tui-notes-obsidian", scratchpad_opts)
  end)
  hl.bind("m", function()
    scratchpad.raise_or_run("tui-monitor", "tui-monitor", scratchpad_opts)
  end)
  hl.bind("e", function()
    scratchpad.raise_or_run("tui-email", "tui-email", scratchpad_opts)
  end)
  hl.bind("r", function()
    scratchpad.raise_or_run("tui-rss", "tui-rss", scratchpad_opts)
  end)
  hl.bind("u", function()
    scratchpad.raise_or_run("tui-music", "tui-music", scratchpad_opts)
  end)
  hl.bind("c", function()
    scratchpad.raise_or_run("tui-calendar", "tui-calendar", scratchpad_opts)
  end)
  hl.bind("b", function()
    scratchpad.raise_or_run("tui-bookmarks", "tui-bookmarks --select", scratchpad_opts)
  end)
  hl.bind("SHIFT + b", function()
    scratchpad.raise_or_run("tui-bookmarks", "tui-bookmarks --add", scratchpad_opts)
  end)
  hl.bind("CTRL + SHIFT + b", function()
    scratchpad.raise_or_run("tui-bookmarks", "tui-bookmarks --edit", scratchpad_opts)
  end)
  hl.bind("escape", hl.dsp.submap("reset"))
end)

-- Notification
if not constants.is_kiosk then
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
end

-- HACK: disable all hyprland keymappings
hl.bind(mod .. " + ALT + CTRL + g", hl.dsp.submap("kb_inhibit"))
hl.define_submap("kb_inhibit", function()
  hl.bind(mod .. " + ALT + CTRL + g", hl.dsp.submap("reset"))
end)
