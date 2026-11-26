-- fallback focus when focus becomes empty with input.focus_on_close = 1 and no
-- window is under the cursor (e.g. center master layout after closing, moving,
-- or hiding a window): focus the MRU window on the active workspace instead of
-- leaving nothing focused

local M = {}

local FALLBACK_DELAY_MS = 10
local LAYER_INTERACTIVITY_EXCLUSIVE = 1
local scheduled = false

local function is_more_recent(a, b)
  if not b then
    return true
  end
  local ah, bh = a.focus_history_id or -1, b.focus_history_id or -1
  if ah < 0 then
    return false
  end
  if bh < 0 then
    return true
  end
  return ah < bh
end

local function has_exclusive_layer(monitor)
  if not monitor then
    return false
  end
  for _, layer in ipairs(hl.get_layers({ monitor = monitor })) do
    if layer.mapped and layer.interactivity == LAYER_INTERACTIVITY_EXCLUSIVE then
      return true
    end
  end
  return false
end

local function focus_mru()
  scheduled = false

  local monitor = hl.get_active_monitor()
  local ws = (monitor and hl.get_active_special_workspace(monitor)) or hl.get_active_workspace()
  if not ws or has_exclusive_layer(monitor) then
    return
  end

  local active = hl.get_active_window()
  if active and (active.pinned or (active.workspace and active.workspace.id == ws.id)) then
    return
  end

  local best = nil
  for _, w in ipairs(hl.get_windows({ workspace = ws, mapped = true })) do
    if not w.hidden and w.accepts_input and is_more_recent(w, best) then
      best = w
    end
  end

  if best then
    hl.dispatch(hl.dsp.focus({ window = best }))
  end
end

local function schedule_fallback()
  if scheduled or hl.get_active_window() then
    return
  end
  scheduled = true
  hl.timer(focus_mru, { timeout = FALLBACK_DELAY_MS, type = "oneshot" })
end

function M.setup()
  hl.on("window.active", schedule_fallback)
end

return M
