---- KEYWORDS

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")


---- AUTOSTART

require("hyprland.lib.active_border").setup()

hl.on("hyprland.start", function()
  hl.exec_cmd("pypr")
end)
