local M = {}

local tag_prefix = "harpoon-"

local function tag_for(slot)
  assert(type(slot) == "string" and slot:match("^[%w_-]+$"), "harpoon slot must contain only letters, digits, _ or -")
  return tag_prefix .. slot
end

local function has_tag(window, wanted)
  for _, tag in ipairs(window.tags or {}) do
    if tag == wanted then
      return true
    end
  end
  return false
end

local function same_monitor(a, b)
  return a and b and a.id == b.id
end

local function is_special(workspace)
  return workspace
    and ((workspace.id and workspace.id < 0) or (workspace.name and workspace.name:sub(1, 8) == "special:"))
end

-- Return the live window assigned to slot. Static window tags are deliberately
-- used instead of a Lua table: tags remain attached across `hyprctl reload` and
-- disappear with the client, so an old address can never select a new client.
function M.get(slot)
  local tag = tag_for(slot)
  for _, window in ipairs(hl.get_windows()) do
    if has_tag(window, tag) then
      return window
    end
  end
end

-- Assign the active window to slot, replacing any previous assignment.
function M.mark(slot)
  local active = hl.get_active_window()
  if not active then
    return false
  end

  local tag = tag_for(slot)
  for _, window in ipairs(hl.get_windows()) do
    if has_tag(window, tag) and window ~= active then
      hl.dispatch(hl.dsp.window.tag({ tag = "-" .. tag, window = window }))
    end
  end

  if not has_tag(active, tag) then
    hl.dispatch(hl.dsp.window.tag({ tag = "+" .. tag, window = active }))
  end
  return true
end

function M.clear(slot)
  local window = M.get(slot)
  if not window then
    return false
  end
  hl.dispatch(hl.dsp.window.tag({ tag = "-" .. tag_for(slot), window = window }))
  return true
end

-- Focus a marked window. Normal workspaces are visited on their owning
-- monitor. A hidden special-workspace window is instead brought to the
-- workspace and monitor from which harpoon was invoked.
function M.focus(slot)
  local window = M.get(slot)
  if not window or not window.workspace then
    return false
  end

  local source_workspace = hl.get_active_workspace()
  local source_monitor = hl.get_active_monitor()

  if is_special(window.workspace) then
    hl.dispatch(hl.dsp.window.move({
      workspace = source_workspace,
      window = window,
      follow = false,
    }))
  else
    if window.monitor and not same_monitor(window.monitor, source_monitor) then
      hl.dispatch(hl.dsp.focus({ monitor = window.monitor }))
    end
    hl.dispatch(hl.dsp.focus({ workspace = window.workspace }))
  end

  hl.dispatch(hl.dsp.focus({ window = window }))
  hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = window }))
  return true
end

-- Define a one-shot harpoon submap. For every key, KEY focuses its slot and
-- SHIFT+KEY marks the active window. Example:
--   harpoon.setup({ leader = "SUPER + h", keys = { "b", "t" } })
function M.setup(opts)
  opts = opts or {}
  local leader = opts.leader or "SUPER + h"
  local keys = opts.keys or {}
  local submap = opts.submap or "harpoon"

  hl.bind(leader, hl.dsp.submap(submap))
  hl.define_submap(submap, "reset", function()
    for _, key in ipairs(keys) do
      local slot = opts.slots and opts.slots[key] or key
      hl.bind(key, function()
        M.focus(slot)
      end)
      hl.bind("SHIFT + " .. key, function()
        M.mark(slot)
      end)
    end
    hl.bind("escape", hl.dsp.submap("reset"))
  end)
end

return M
