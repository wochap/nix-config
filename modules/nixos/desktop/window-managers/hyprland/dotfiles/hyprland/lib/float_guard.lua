-- keep floating windows in view when a monitor is removed
-- remembers each floating window's position relative to its monitor and, once
-- hyprland reassigns workspaces, restores the same relative position on the
-- new monitor; windows that don't fit get centered

local M = {}

local SNAPSHOT_INTERVAL_MS = 10000
local RESTORE_DELAY_MS = 300

-- address -> { monitor = name, rx = 0..1, ry = 0..1 }
local snapshots = {}
-- true between monitor removal and restore, so snapshots keep pre-removal state
local pending = false

local function monitor_rect(m)
  local scale = (m.scale and m.scale > 0) and m.scale or 1
  local w, h = m.width / scale, m.height / scale
  if m.transform and m.transform % 2 == 1 then
    w, h = h, w
  end
  return { x = m.x, y = m.y, w = w, h = h }
end

local function is_candidate(w)
  return w.floating and w.mapped and w.monitor and (w.fullscreen or 0) == 0
end

-- fraction of the free space left/above the window, so position survives
-- resolution changes (same resolution -> same pixel offset)
local function ratio(offset, free)
  if free <= 0 then
    return 0.5
  end
  return math.min(math.max(offset / free, 0), 1)
end

local function snapshot()
  if pending then
    return
  end
  local seen = {}
  for _, w in ipairs(hl.get_windows({ mapped = true })) do
    if is_candidate(w) then
      local r = monitor_rect(w.monitor)
      snapshots[w.address] = {
        monitor = w.monitor.name,
        rx = ratio(w.at.x - r.x, r.w - w.size.x),
        ry = ratio(w.at.y - r.y, r.h - w.size.y),
      }
      seen[w.address] = true
    end
  end
  for addr in pairs(snapshots) do
    if not seen[addr] then
      snapshots[addr] = nil
    end
  end
end

local function inside(w, r)
  return w.at.x >= r.x and w.at.y >= r.y and w.at.x + w.size.x <= r.x + r.w and w.at.y + w.size.y <= r.y + r.h
end

local function restore()
  pending = false
  for _, w in ipairs(hl.get_windows({ mapped = true })) do
    if is_candidate(w) then
      local r = monitor_rect(w.monitor)
      local snap = snapshots[w.address]
      local moved = snap and snap.monitor ~= w.monitor.name
      if moved or not inside(w, r) then
        local free_x, free_y = r.w - w.size.x, r.h - w.size.y
        if snap and free_x >= 0 and free_y >= 0 then
          local x = math.floor(r.x + snap.rx * free_x + 0.5)
          local y = math.floor(r.y + snap.ry * free_y + 0.5)
          hl.dispatch(hl.dsp.window.move({ x = x - w.at.x, y = y - w.at.y, relative = true, window = w }))
        else
          hl.dispatch(hl.dsp.window.center({ window = w }))
        end
      end
    end
  end
  snapshot()
end

function M.setup()
  snapshot()
  hl.timer(snapshot, { timeout = SNAPSHOT_INTERVAL_MS, type = "repeat" })

  hl.on("monitor.removed", function()
    pending = true
    hl.timer(restore, { timeout = RESTORE_DELAY_MS, type = "oneshot" })
  end)
end

return M
