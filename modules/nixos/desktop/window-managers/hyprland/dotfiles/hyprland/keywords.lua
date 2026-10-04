local active_border = require("hyprland.lib.active_border")
local float_guard = require("hyprland.lib.float_guard")
local constants = require("hyprland.constants")

---- KEYWORDS

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

---- AUTOSTART

active_border.setup()
float_guard.setup()

if not constants.is_kiosk then
  -- We set XDG_* manually because the UWSM session may use a different name.
  hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm finalize XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
  end)
end
