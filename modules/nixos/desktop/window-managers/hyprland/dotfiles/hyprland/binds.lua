local constants = require("hyprland.constants")
local harpoon = require("hyprland.lib.harpoon")
local harpoon_scratchpad = require("hyprland.lib.harpoon_scratchpad")
local scratchpad = require("hyprland.lib.scratchpad")
local previous_ws = require("hyprland.lib.previous_ws")
local ws_offset = require("hyprland.lib.ws_offset")
local window_switcher = require("hyprland.lib.window_switcher")
local which_keys = require("hyprland.lib.which_keys")
local zoom = require("hyprland.lib.zoom")
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

which_keys.setup()

hl.bind(mod .. " + mouse:272", hl.dsp.window.float(), { mouse = true, click = true, description = "Float" })
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move" })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize" })
-- hl.bind(mod .. " + SHIFT + mouse:273", hl.dsp.window.resize({ keep_aspect_ratio = true }), { mouse = true })

--- SYSTEM KEYBINDINGS

-- Open scratchpad terminal
hl.bind(mod .. " + i", function()
  scratchpad.raise_or_run("kitty-scratch", "$HOME/.config/kitty/scripts/kitty-scratch.sh", scratchpad_opts)
end, { description = "Terminal Scratchpad" })

-- Lock screen
hl.bind(mod .. " + l", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock" })

-- Open power menu
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd(session_cmd("tofi-powermenu")), { description = "Power Menu" })

-- Open app launcher
hl.bind(
  mod .. " + space",
  hl.dsp.exec_cmd(constants.is_kiosk and "tofi-launcher" or "tofi-launcher --uwsm"),
  { description = "Launcher" }
)

-- Take fullscreen screenshot
hl.bind(mod .. " + Print", hl.dsp.exec_cmd(session_cmd("takeshot --now")), { description = "Screenshot Monitor" })

-- Open calc
hl.bind(mod .. " + c", hl.dsp.exec_cmd(session_cmd("tofi-calc")), { description = "Calculator" })

-- Show clipboard
hl.bind(mod .. " + v", hl.dsp.exec_cmd(session_cmd("clipboard-manager --menu")), { description = "Clipboard" })

-- Clear clipboard
hl.bind(mod .. " + SHIFT + v", hl.dsp.exec_cmd("clipboard-manager --clear"), { description = "Clear" })

-- Show emojis
hl.bind(mod .. " + e", hl.dsp.exec_cmd(session_cmd("tofi-emoji")), { description = "Emoji" })

if not constants.is_kiosk then
  -- Toggle bar
  hl.bind(
    mod .. " + b",
    hl.dsp.exec_cmd("quickshell -p ~/.config/quickshell/shell ipc call bar toggle"),
    { description = "Bar" }
  )

  -- Toggle idle inhibitor
  hl.bind(mod .. " + m", hl.dsp.exec_cmd("shell-idle-inhibit --toggle"), { description = "Idle" })

  -- Toggle offlinemsmtp
  hl.bind(mod .. " + o", hl.dsp.exec_cmd("offlinemsmtp-toggle-mode --toggle"), { description = "Offlinemsmtp" })

  -- Toggle control center
  hl.bind(
    mod .. " + SHIFT + c",
    hl.dsp.exec_cmd("quickshell --path ~/.config/quickshell/shell ipc call control-center toggle"),
    { description = "Control Center" }
  )
end

--- WM KEYBINDINGS

-- Close focused window
hl.bind(mod .. " + SHIFT + w", hl.dsp.window.close(), { description = "Close" })

-- Close focused window
hl.bind(mod .. " + CTRL + SHIFT + w", hl.dsp.window.kill(), { description = "Kill" })

-- Toggle float
hl.bind(mod .. " + s", hl.dsp.window.float(), { description = "Float" })

-- Toggle fullscreen
hl.bind(mod .. " + f", hl.dsp.window.fullscreen(), { description = "Fullscreen" })
hl.bind(
  mod .. " + SHIFT + f",
  hl.dsp.window.fullscreen_state({ internal = 0, client = 1 }),
  { description = "Maximize" }
)

-- Set sticky
hl.bind(mod .. " + CTRL + y", hl.dsp.window.pin(), { description = "Pin" })

-- Focus direction
hl.bind(mod .. " + n", hl.dsp.layout("cyclenext"), { description = "Focus Next" })
hl.bind(mod .. " + p", hl.dsp.layout("cycleprev"), { description = "Focus Previous" })
hl.bind(mod .. " + left", function()
  hl.dispatch(hl.dsp.focus({ direction = "l" }))
  hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end, { description = "Focus Left" })
hl.bind(mod .. " + down", function()
  hl.dispatch(hl.dsp.focus({ direction = "d" }))
  hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end, { description = "Focus Down" })
hl.bind(mod .. " + up", function()
  hl.dispatch(hl.dsp.focus({ direction = "u" }))
  hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end, { description = "Focus Up" })
hl.bind(mod .. " + right", function()
  hl.dispatch(hl.dsp.focus({ direction = "r" }))
  hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end, { description = "Focus Right" })

-- Swap direction
hl.bind(mod .. " + SHIFT + n", hl.dsp.layout("swapnext"), { description = "Swap Next" })
hl.bind(mod .. " + SHIFT + p", hl.dsp.layout("swapprev"), { description = "Swap Previous" })
hl.bind(mod .. " + SHIFT + left", hl.dsp.window.swap({ direction = "l" }), { description = "Swap Left" })
hl.bind(mod .. " + SHIFT + down", hl.dsp.window.swap({ direction = "d" }), { description = "Swap Down" })
hl.bind(mod .. " + SHIFT + up", hl.dsp.window.swap({ direction = "u" }), { description = "Swap Up" })
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "r" }), { description = "Swap Right" })

-- Resize tiling/floating windows
hl.bind(
  mod .. " + ALT + SHIFT + left",
  hl.dsp.window.resize({ x = -40, y = 0, relative = true }),
  { description = "Narrower" }
)
hl.bind(
  mod .. " + ALT + SHIFT + down",
  hl.dsp.window.resize({ x = 0, y = 40, relative = true }),
  { description = "Taller" }
)
hl.bind(
  mod .. " + ALT + SHIFT + up",
  hl.dsp.window.resize({ x = 0, y = -40, relative = true }),
  { description = "Shorter" }
)
hl.bind(
  mod .. " + ALT + SHIFT + right",
  hl.dsp.window.resize({ x = 40, y = 0, relative = true }),
  { description = "Wider" }
)

-- Move floating windows
hl.bind(mod .. " + ALT + left", hl.dsp.window.move({ x = -40, y = 0, relative = true }), { description = "Move Left" })
hl.bind(mod .. " + ALT + down", hl.dsp.window.move({ x = 0, y = 40, relative = true }), { description = "Move Down" })
hl.bind(mod .. " + ALT + up", hl.dsp.window.move({ x = 0, y = -40, relative = true }), { description = "Move Up" })
hl.bind(mod .. " + ALT + right", hl.dsp.window.move({ x = 40, y = 0, relative = true }), { description = "Move Right" })

-- Focus next/previous workspace
hl.bind(
  mod .. " + comma",
  hl.dsp.focus({ workspace = "r-1", on_current_monitor = true }),
  { description = "Focus Prev Workspace" }
)
hl.bind(
  mod .. " + period",
  hl.dsp.focus({ workspace = "r+1", on_current_monitor = true }),
  { description = "Focus Next Workspace" }
)
hl.bind(
  mod .. " + CTRL + comma",
  hl.dsp.focus({ workspace = "m-1", on_current_monitor = true }),
  { description = "Focus Prev Busy Workspace" }
)
hl.bind(
  mod .. " + CTRL + period",
  hl.dsp.focus({ workspace = "m+1", on_current_monitor = true }),
  { description = "Focus Next Busy Workspace" }
)
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
hl.bind(
  mod .. " + SHIFT + comma",
  hl.dsp.window.move({ workspace = "r-1", follow = false }),
  { description = "Send To Prev Workspace" }
)
hl.bind(
  mod .. " + SHIFT + period",
  hl.dsp.window.move({ workspace = "r+1", follow = false }),
  { description = "Send To Next Workspace" }
)
hl.bind(
  mod .. " + SHIFT + comma",
  hl.dsp.window.move({ workspace = "m-1", follow = false }),
  { description = "Send To Prev Busy Workspace" }
)
hl.bind(
  mod .. " + SHIFT + period",
  hl.dsp.window.move({ workspace = "m+1", follow = false }),
  { description = "Send To Next Busy Workspace" }
)

-- Bump focused window to the top of the layout stack
hl.bind(mod .. " + return", hl.dsp.layout("swapwithmaster"), { description = "Promote" })

-- Focus next/prev monitor
hl.bind(mod .. " + bracketleft", hl.dsp.focus({ monitor = "-1" }), { description = "Focus Prev Monitor" })
hl.bind(mod .. " + bracketright", hl.dsp.focus({ monitor = "+1" }), { description = "Focus Next Monitor" })

-- Move focused window to next/prev monitor
hl.bind(
  mod .. " + SHIFT + bracketleft",
  hl.dsp.window.move({ monitor = "-1", follow = false }),
  { description = "Send To Prev Monitor" }
)
hl.bind(
  mod .. " + SHIFT + bracketright",
  hl.dsp.window.move({ monitor = "+1", follow = false }),
  { description = "Send To Next Monitor" }
)

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
hl.bind(mod .. " + 0", ws_offset.cycle, { description = "Workspace Page" })
hl.bind(mod .. " + SHIFT + 0", function()
  ws_offset.cycle()
  local ws_id = hl.get_active_workspace().id
  local next_ws_id = ws_offset.get() + ws_id
  if ws_id > 10 then
    next_ws_id = ws_id - 10
  end
  hl.dispatch(hl.dsp.focus({ workspace = next_ws_id, on_current_monitor = true }))
end, { description = "Follow Workspace Page" })

hl.bind(mod .. " + grave", previous_ws.focus_previous, { description = "Focus Last Workspace" })

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

--- WM WINDOW SWITCHER

window_switcher.setup({
  modifier = "ALT",
  mode = "floating",
  release_keys = { "ALT_L", "ALT_R" },
})

window_switcher.setup({
  modifier = mod,
  mode = "tiling",
  release_keys = { "SUPER_L", "SUPER_R" },
})

--- WM SCRATCHPAD

-- Open scratchpad
hl.bind(mod .. " + d", scratchpad.toggle, { description = "Toggle Scratchpad" })

-- Send to scratchpad
hl.bind(mod .. " + SHIFT + d", scratchpad.toggle_in, { description = "Stash Scratchpad" })

-- Open last scratchpad
hl.bind(mod .. " + SHIFT + grave", scratchpad.focus_last, { description = "Last Scratchpad" })

-- WM GROUPS

hl.bind(mod .. " + g", hl.dsp.submap("group"), { description = "+Groups" })
hl.define_submap("group", "reset", function()
  hl.bind("g", hl.dsp.group.toggle(), { description = "Toggle" })
  -- TODO: verify into_or_create_group matches old movewindoworgroup behavior
  hl.bind("left", hl.dsp.window.move({ into_or_create_group = "l" }), { description = "Move Left" })
  hl.bind("down", hl.dsp.window.move({ into_or_create_group = "d" }), { description = "Move Down" })
  hl.bind("up", hl.dsp.window.move({ into_or_create_group = "u" }), { description = "Move Up" })
  hl.bind("right", hl.dsp.window.move({ into_or_create_group = "r" }), { description = "Move Right" })
  hl.bind("n", hl.dsp.group.next(), { description = "Focus Next" })
  hl.bind("p", hl.dsp.group.prev(), { description = "Focus Previous" })
  hl.bind("SHIFT + n", hl.dsp.group.move_window({ forward = true }), { description = "Move Next" })
  hl.bind("SHIFT + p", hl.dsp.group.move_window({ forward = false }), { description = "Move Previous" })
  for key = 1, 9 do
    hl.bind("SHIFT + " .. key, function()
      hl.dispatch(hl.dsp.window.move({ workspace = ws_offset.ws(key), follow = false }))
    end)
  end
  hl.bind("escape", hl.dsp.submap("reset"), { description = "+Exit" })
end)

--- APPLICATION KEYBINDINGS (Super + Alt + Key)

-- Open primary terminal
hl.bind(
  mod .. " + ALT + t",
  hl.dsp.exec_cmd(constants.is_kiosk and "foot" or "uwsm-app -- footclient"),
  { description = "Terminal" }
)

-- Open file manager
hl.bind(mod .. " + ALT + f", function()
  scratchpad.raise_or_run("Thunar", "thunar --name Thunar", scratchpad_opts)
end, { description = "Files" })

-- Show ruler
hl.bind(mod .. " + ALT + m", hl.dsp.exec_cmd(session_cmd("ruler")), { description = "Ruler" })

-- Screencast/record region to mp4
hl.bind(mod .. " + ALT + r", hl.dsp.exec_cmd(session_cmd("recorder --area")), { description = "Record" })

-- Open screenshoot utility
hl.bind(mod .. " + ALT + s", hl.dsp.exec_cmd(session_cmd("takeshot --area")), { description = "Screenshot" })

-- Open ocr utility
hl.bind(mod .. " + ALT + o", hl.dsp.exec_cmd(session_cmd("ocr")), { description = "OCR" })

-- Open ocr-math utility
hl.bind(mod .. " + ALT + h", hl.dsp.exec_cmd(session_cmd("ocr-math")), { description = "Math OCR" })

-- Open color picker
hl.bind(mod .. " + ALT + c", hl.dsp.exec_cmd(session_cmd("color-picker")), { description = "Color" })

-- Magnifying glass
hl.bind(mod .. " + ALT + z", zoom.zoom, { description = "Zoom" })

hl.bind(
  mod .. " + ALT + v",
  hl.dsp.exec_cmd(session_cmd("supertonic-clipboard primary --voice=F1 --speed=1.5 --steps=5 --chunking=on")),
  { description = "Speak" }
)
hl.bind(
  mod .. " + ALT + SHIFT + v",
  hl.dsp.exec_cmd(session_cmd("supertonic-clipboard --toggle-pause")),
  { description = "Speak Pause" }
)

hl.bind(mod .. " + ALT + d", hl.dsp.exec_cmd(session_cmd("clean-voice")), { description = "Clean Voice" })

--- MEDIA KEYBINDINGS

if not constants.is_kiosk then
  hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("shell-pipewire --volume-output 5%+"),
    { locked = true, repeating = true, description = "Volume Up" }
  )
  hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("shell-pipewire --volume-output 5%-"),
    { locked = true, repeating = true, description = "Volume Down" }
  )
  hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"),
    { locked = true, description = "Mute" }
  )

  hl.bind(
    "XF86AudioMicMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"),
    { locked = true, description = "Mic Mute" }
  )

  hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Next" })
  hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Previous" })
  hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl pause"), { locked = true, description = "Pause" })
  hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play" })

  hl.bind(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd("backlight 5%+"),
    { locked = true, repeating = true, description = "Brighter" }
  )
  hl.bind(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd("backlight 5%-"),
    { locked = true, repeating = true, description = "Dimmer" }
  )

  hl.bind(
    "XF86KbdBrightnessDown",
    hl.dsp.exec_cmd("kbd-backlight 5%-"),
    { locked = true, repeating = true, description = "Keys Dimmer" }
  )
  hl.bind(
    "XF86KbdBrightnessUp",
    hl.dsp.exec_cmd("kbd-backlight 5%+"),
    { locked = true, repeating = true, description = "Keys Brighter" }
  )
end

--- OTHERS

if not constants.is_kiosk then
  hl.bind(
    mod .. " + CTRL + ALT + m",
    hl.dsp.exec_cmd('hyprctl output create headless "HEADLESS-2"'),
    { description = "Add Headless Monitor" }
  )
  hl.bind(
    mod .. " + CTRL + SHIFT + ALT + m",
    hl.dsp.exec_cmd('hyprctl output remove "HEADLESS-2"'),
    { description = "Remove Headless Monitor" }
  )
end
hl.bind(
  mod .. " + CTRL + SHIFT + l",
  hl.dsp.exec_cmd("hyprctl switchxkblayout all next"),
  { locked = true, description = "Switch Keyboard Layout" }
)
-- if not constants.is_kiosk then
--   hl.bind(mod .. " + ALT + x", function()
--     scratchpad.raise_or_run("xwaylandvideobridge", "xwaylandvideobridge", scratchpad_opts)
--   end, { description = "XWayland Video" })
-- end
hl.bind(mod .. " + CTRL + SHIFT + q", hl.dsp.exec_cmd("hyprshutdown"), { description = "Shutdown" })
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
end, { description = "Keyboard HUD" })

-- SUBMAPS

-- Layout
hl.bind(mod .. " + r", hl.dsp.submap("layout"), { description = "+Layout" })
hl.define_submap("layout", "reset", function()
  hl.bind("c", hl.dsp.window.center(), { description = "Center" })
  hl.bind("e", function()
    hl.workspace_rule({
      workspace = hl.get_active_workspace().name,
      layout = "master",
      layout_opts = { orientation = "center" },
    })
  end, { description = "Centered" })
  hl.bind("t", function()
    hl.workspace_rule({
      workspace = hl.get_active_workspace().name,
      layout = "master",
      layout_opts = { orientation = "left" },
    })
  end, { description = "Tall" })
  hl.bind("f", function()
    hl.workspace_rule({
      workspace = hl.get_active_workspace().name,
      layout = "master",
      layout_opts = { orientation = "top" },
    })
  end, { description = "Fat" })
  hl.bind("m", function()
    hl.workspace_rule({
      workspace = hl.get_active_workspace().name,
      layout = "monocle",
    })
  end, { description = "Monocle" })
  hl.bind("1", function()
    hl.dispatch(hl.dsp.window.move({ out_of_group = true }))
    hl.dispatch(hl.dsp.window.float({ action = "on" }))
    hl.dispatch(hl.dsp.window.resize({ x = 1200, y = 800 }))
    hl.dispatch(hl.dsp.window.center())
  end, { description = "Float Preset" })
  hl.bind("left", hl.dsp.layout("addmaster"), { description = "Add Master" })
  hl.bind("right", hl.dsp.layout("removemaster"), { description = "Remove Master" })
  hl.bind("SHIFT + left", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { description = "Shrink Width" })
  hl.bind("SHIFT + down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { description = "Grow Height" })
  hl.bind("SHIFT + up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { description = "Shrink Height" })
  hl.bind("SHIFT + right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { description = "Grow Width" })
  hl.bind("escape", hl.dsp.submap("reset"), { description = "+Exit" })
end)

-- Open Browser
hl.bind(mod .. " + ALT + b", hl.dsp.submap("browser"), { description = "+Browsers" })
hl.define_submap("browser", "reset", function()
  -- TODO: find workaround for exec rules + uwsm-app
  hl.bind("f", hl.dsp.exec_cmd(session_cmd("firefox")), { description = "Firefox" })
  hl.bind("b", hl.dsp.exec_cmd(session_cmd("brave")), { description = "Brave" })
  hl.bind("g", hl.dsp.exec_cmd(session_cmd("google-chrome-stable")), { description = "Chrome" })
  hl.bind("m", hl.dsp.exec_cmd(session_cmd("microsoft-edge")), { description = "Edge" })
  if not constants.is_kiosk then
    hl.bind("t", function()
      scratchpad.raise_or_run(constants.bitwarden_appid, "bitwarden", scratchpad_opts)
    end, { description = "Bitwarden" })
  end
  hl.bind("SHIFT + i", function()
    scratchpad.raise_or_run(
      constants.bing_gpt_appid,
      "microsoft-edge --profile-directory=Default --app=https://www.bing.com/chat",
      scratchpad_opts
    )
  end, { description = "Copilot" })
  hl.bind("i", function()
    scratchpad.raise_or_run(
      constants.chat_gpt_appid,
      "google-chrome-stable --profile-directory=Default --app=https://chat.openai.com",
      scratchpad_opts
    )
  end, { description = "ChatGPT" })
  hl.bind("e", function()
    scratchpad.raise_or_run(
      constants.gemini_appid,
      "google-chrome-stable --profile-directory=Default --app=https://gemini.google.com/app",
      scratchpad_opts
    )
  end, { description = "Gemini" })
  hl.bind("w", function()
    scratchpad.raise_or_run(
      constants.openwebui_appid,
      "google-chrome-stable --profile-directory=Default --app=https://openwebui.wochap.local",
      scratchpad_opts
    )
  end, { description = "OpenWebUI" })
  hl.bind("u", function()
    scratchpad.raise_or_run(
      constants.ytmusic_appid,
      "google-chrome-stable --profile-directory=Default --app=https://music.youtube.com",
      scratchpad_opts
    )
  end, { description = "YouTube Music" })
  hl.bind("escape", hl.dsp.submap("reset"), { description = "+Exit" })
end)

-- Terminal TUI
hl.bind(mod .. " + ALT + u", hl.dsp.submap("tui"), { description = "+TUIs" })
hl.define_submap("tui", "reset", function()
  hl.bind("n", function()
    scratchpad.raise_or_run("tui-notes", "tui-notes", scratchpad_opts)
  end, { description = "Notes" })
  hl.bind("i", function()
    scratchpad.raise_or_run("tui-notes-obsidian", "tui-notes-obsidian", scratchpad_opts)
  end, { description = "Obsidian" })
  hl.bind("m", function()
    scratchpad.raise_or_run("tui-monitor", "tui-monitor", scratchpad_opts)
  end, { description = "Monitor" })
  hl.bind("e", function()
    scratchpad.raise_or_run("tui-email", "tui-email", scratchpad_opts)
  end, { description = "Email" })
  hl.bind("r", function()
    scratchpad.raise_or_run("tui-rss", "tui-rss", scratchpad_opts)
  end, { description = "RSS" })
  hl.bind("u", function()
    scratchpad.raise_or_run("tui-music", "tui-music", scratchpad_opts)
  end, { description = "Music" })
  hl.bind("c", function()
    scratchpad.raise_or_run("tui-calendar", "tui-calendar", scratchpad_opts)
  end, { description = "Calendar" })
  hl.bind("b", function()
    scratchpad.raise_or_run("tui-bookmarks", "tui-bookmarks --select", scratchpad_opts)
  end, { description = "Bookmarks" })
  hl.bind("SHIFT + b", function()
    scratchpad.raise_or_run("tui-bookmarks", "tui-bookmarks --add", scratchpad_opts)
  end, { description = "Add Bookmark" })
  hl.bind("CTRL + SHIFT + b", function()
    scratchpad.raise_or_run("tui-bookmarks", "tui-bookmarks --edit", scratchpad_opts)
  end, { description = "Edit Bookmarks" })
  hl.bind("escape", hl.dsp.submap("reset"), { description = "+Exit" })
end)

-- Notification
if not constants.is_kiosk then
  hl.bind(mod .. " + ALT + n", hl.dsp.submap("notification"), { description = "+Notifications" })
  hl.define_submap("notification", "reset", function()
    hl.bind(
      "n",
      hl.dsp.exec_cmd("quickshell --path ~/.config/quickshell/shell ipc call notifications togglePanel"),
      { description = "Panel" }
    )
    hl.bind(
      "c",
      hl.dsp.exec_cmd("quickshell --path ~/.config/quickshell/shell ipc call notifications dismissPopups"),
      { description = "Dismiss" }
    )
    hl.bind(
      "SHIFT + C",
      hl.dsp.exec_cmd("quickshell --path ~/.config/quickshell/shell ipc call notifications discardPopups"),
      { description = "Discard" }
    )
    hl.bind("escape", hl.dsp.submap("reset"), { description = "+Exit" })
  end)
end

-- HACK: disable all hyprland keymappings
hl.bind(mod .. " + ALT + CTRL + g", hl.dsp.submap("kb_inhibit"), { description = "+Inhibit Keys" })
hl.define_submap("kb_inhibit", function()
  hl.bind(mod .. " + ALT + CTRL + g", hl.dsp.submap("reset"), { description = "+Restore Keys" })
end)
