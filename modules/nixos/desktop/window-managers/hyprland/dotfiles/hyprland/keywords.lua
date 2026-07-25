---- KEYWORDS

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")


---- AUTOSTART

hl.on("hyprland.start", function()
  hl.exec_cmd("pypr")
  hl.exec_cmd("hyprland-previous-ws --init")
  hl.exec_cmd("hyprland-socket")
end)
