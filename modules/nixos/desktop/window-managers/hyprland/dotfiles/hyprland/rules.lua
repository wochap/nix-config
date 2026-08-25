local colors = require("colors")
local constants = require("hyprland.constants")

---- MONITOR

hl.monitor({ output = "", mode = "highres", position = "auto", scale = "auto", bitdepth = 8, cm = "auto" })
hl.monitor({ output = "", reserved_area = { top = 0, bottom = 0, left = 0, right = 0 } })

-- HACK: disable ghost monitor when running Hyprland and other wayland wm
hl.monitor({ output = "WAYLAND-1", disabled = true })

---- WINDOW

hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
  match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
  no_focus = true,
})

-- center all floating
hl.window_rule({ match = { float = true, xwayland = false }, center = true })

-- remove rounding and shadow from tiling
hl.window_rule({ match = { float = false }, rounding = 0, no_shadow = true })

-- border color for focused floating windows
hl.window_rule({ match = { focus = true, float = true }, border_color = colors.primary })

-- tags rules
hl.window_rule({ match = { tag = "float_md" }, float = true, size = { 1200, 800 } })
hl.window_rule({
  match = { tag = "share_screen_popup" },
  float = true,
  pin = true,
  move = { "(monitor_w-window_w)/2", "(monitor_h-window_h)" },
  no_blur = true,
  no_initial_focus = true,
  decorate = false,
})

-- scratchpads
-- TODO: test if tag = "+float_md +scratchpad" works in single rule
hl.window_rule({ match = { class = "kitty-scratch" }, tag = "+float_md" })
hl.window_rule({ match = { class = "kitty-scratch" }, tag = "+scratchpad" })
hl.window_rule({ match = { class = "tui-monitor" }, tag = "+float_md" })
hl.window_rule({ match = { class = "tui-monitor" }, tag = "+scratchpad" })
hl.window_rule({ match = { class = "^(tui-notes)$" }, tag = "+float_md" })
hl.window_rule({ match = { class = "^(tui-notes)$" }, tag = "+scratchpad" })
hl.window_rule({ match = { class = "tui-notes-obsidian" }, tag = "+float_md" })
hl.window_rule({ match = { class = "tui-notes-obsidian" }, tag = "+scratchpad" })
hl.window_rule({ match = { class = "tui-email" }, tag = "+float_md" })
hl.window_rule({ match = { class = "tui-email" }, tag = "+scratchpad" })
hl.window_rule({ match = { class = "tui-rss" }, tag = "+float_md" })
hl.window_rule({ match = { class = "tui-rss" }, tag = "+scratchpad" })
hl.window_rule({ match = { class = "tui-music" }, tag = "+float_md" })
hl.window_rule({ match = { class = "tui-music" }, tag = "+scratchpad" })
hl.window_rule({ match = { class = "tui-calendar" }, tag = "+float_md" })
hl.window_rule({ match = { class = "tui-calendar" }, tag = "+scratchpad" })
hl.window_rule({ match = { class = "tui-bookmarks" }, tag = "+float_md" })
hl.window_rule({ match = { class = "tui-bookmarks" }, tag = "+scratchpad" })
hl.window_rule({
  match = { class = "^(" .. constants.bitwarden_appid .. ")$" },
  tag = "+float_md",
  no_screen_share = true,
})
hl.window_rule({ match = { class = "^(" .. constants.bitwarden_appid .. ")$" }, tag = "+scratchpad" })
hl.window_rule({ match = { class = "^(" .. constants.bing_gpt_appid .. ")$" }, tag = "+float_md" })
hl.window_rule({ match = { class = "^(" .. constants.bing_gpt_appid .. ")$" }, tag = "+scratchpad" })
hl.window_rule({ match = { class = "^(" .. constants.chat_gpt_appid .. ")$" }, tag = "+float_md" })
hl.window_rule({ match = { class = "^(" .. constants.chat_gpt_appid .. ")$" }, tag = "+scratchpad" })
hl.window_rule({ match = { class = "^(" .. constants.gemini_appid .. ")$" }, tag = "+float_md" })
hl.window_rule({ match = { class = "^(" .. constants.gemini_appid .. ")$" }, tag = "+scratchpad" })
hl.window_rule({ match = { class = "^(" .. constants.openwebui_appid .. ")$" }, tag = "+float_md" })
hl.window_rule({ match = { class = "^(" .. constants.openwebui_appid .. ")$" }, tag = "+scratchpad" })
hl.window_rule({ match = { class = "^(" .. constants.ytmusic_appid .. ")$" }, tag = "+float_md" })
hl.window_rule({ match = { class = "^(" .. constants.ytmusic_appid .. ")$" }, tag = "+scratchpad" })
hl.window_rule({ match = { class = "^([tT]hunar)$" }, tag = "+scratchpad", float = true })

-- custom
hl.window_rule({
  match = { class = "^(xwaylandvideobridge)$" },
  no_initial_focus = true,
  no_focus = true,
  no_anim = true,
  no_blur = true,
  max_size = { 1, 1 },
  opacity = "0.0",
})
hl.window_rule({ match = { class = "^(org.gnome.Calculator)$" }, float = true })
hl.window_rule({
  match = { class = "^(showmethekey-gtk)$" },
  float = true,
  no_focus = true,
  no_blur = true,
  decorate = false,
  pin = true,
  move = { "(monitor_w-window_w-7)", "(monitor_h-window_h-7)" },
})
hl.window_rule({
  match = { class = "^(kb-hud)$", title = ".*overlay$" },
  float = true,
  no_focus = true,
  no_blur = true,
  decorate = false,
  pin = true,
  move = { "(monitor_w - 600) / 2", "monitor_h - window_h" },
  size = { "600", "window_h" },
  no_initial_focus = true,
})
hl.window_rule({ match = { class = "^(xdg-desktop-portal-gtk)$" }, float = true, persistent_size = true })
hl.window_rule({
  match = { class = "^(org.freedesktop.impl.portal.desktop.kde)$" },
  float = true,
  persistent_size = true,
})
hl.window_rule({ match = { class = "^(Slack)$" }, workspace = "4" })
hl.window_rule({ match = { class = "^(discord)$", title = "(Discord Updater)" }, float = true })
hl.window_rule({ match = { class = "com.gabm.satty" }, float = true })
hl.window_rule({ match = { title = "(?i).*\\.com is sharing your screen\\.$" }, tag = "+share_screen_popup" })
hl.window_rule({ match = { title = "(?i).*\\.com is sharing a window\\.$" }, tag = "+share_screen_popup" })
hl.window_rule({ match = { title = "^(?i)select what to share$" }, tag = "+float_md", pin = true })
hl.window_rule({ match = { class = "^(firefox)$" }, workspace = "5" })
hl.window_rule({ match = { class = "^(microsoft-edge)$" }, workspace = "9" })
hl.window_rule({ match = { class = "kitty-chill" }, no_blur = true })
hl.window_rule({ match = { class = "footclient-chill" }, no_blur = true })
hl.window_rule({ match = { class = "foot-chill" }, no_blur = true })
hl.window_rule({ match = { class = "^(?i)steam_app_.*" }, content = "game" })
hl.window_rule({
  match = { class = "^(opensnitch_ui)$", title = "^OpenSnitch v1.8.0$" },
  pin = true,
  no_initial_focus = true,
})

-- rules for xwayland apps
hl.window_rule({
  match = { xwayland = true },
  float = true,
  no_anim = true,
  no_blur = true,
  immediate = true,
  idle_inhibit = "focus",
  rounding = 0,
  decorate = false,
})
hl.window_rule({ match = { class = "steam", title = "Steam", xwayland = true }, tile = true })
hl.window_rule({
  match = { class = ".gamescope-wrapped" },
  float = true,
  immediate = true,
  idle_inhibit = "focus",
  decorate = false,
})

---- LAYER
hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur = true, blur_popups = true, ignore_alpha = 0.4 })
hl.layer_rule({ match = { namespace = "quickshell:notifications-popups" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "quickshell:window-switcher" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:which-keys" }, ignore_alpha = 0.9, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:harpoon" }, ignore_alpha = 0.9, no_anim = true })
-- hl.layer_rule({ match = { namespace = "quickshell:notifications" }, no_anim = true })

---- WORKSPACE

-- disable removing gaps when maximized
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, border_size = 0, no_rounding = true })

---- ANIMATION

hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "windowsIn", enabled = false })
hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "layersIn", enabled = false })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "fadeIn", enabled = false })
hl.animation({ leaf = "fadeLayersIn", enabled = false })
hl.animation({ leaf = "fadePopupsIn", enabled = false })
hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = false })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 2, bezier = "default", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2, bezier = "default", style = "fade" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = false })
hl.animation({ leaf = "monitorAdded", enabled = true, speed = 2, bezier = "default" })
-- hl.animation({ leaf = "zoomFactor", enabled = true, speed = 2, bezier = "default" })
