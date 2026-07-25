---- AUTOSTART

-- we set XDG_* manually because we might use a different name
hl.on("hyprland.start", function()
  hl.exec_cmd("uwsm finalize XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
end)
