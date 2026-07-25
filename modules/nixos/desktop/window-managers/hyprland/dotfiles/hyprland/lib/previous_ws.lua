-- focus the previous workspace on the current monitor,
-- ported from scripts/hyprland-previous-ws.sh (uses Hyprland's built-in history)

local M = {}

function M.focus_previous()
  local ws = hl.get_last_workspace()
  if ws then
    hl.dispatch(hl.dsp.focus({ workspace = ws, on_current_monitor = true }))
  else
    hl.dispatch(hl.dsp.focus({ workspace = "previous", on_current_monitor = true }))
  end
end

return M
