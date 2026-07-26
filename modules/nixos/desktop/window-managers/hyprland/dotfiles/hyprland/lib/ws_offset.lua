-- workspace "page" offset: number keys 1-9 map to workspace (key + offset).
-- cycle the offset to reach workspaces beyond 1-9 without extra keys.
-- emits a "wsoffset>>N" event to socket2 on change, so external programs
-- (e.g. bars) can subscribe and show the current page.

local M = {}

local steps = { 0, 10 }
local index = 1

local function emit()
  hl.dispatch(hl.dsp.event("wsoffset>>" .. steps[index]))
end

-- current offset (the value added to number keys)
function M.get()
  return steps[index]
end

-- map a number key (1-9) to its workspace on the current page
function M.ws(key)
  return key + steps[index]
end

-- advance to the next page, wrapping around; returns the new offset
function M.cycle()
  index = index % #steps + 1
  emit()
  return steps[index]
end

return M
