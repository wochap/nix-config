local M = {}
local which_keys = require("hyprland.lib.which_keys")

local tag_prefix = "harpoon-"
local hint_slots = {}

-- Hyprland does not emit a socket2 event when static window tags change.
-- Notify consumers such as Quickshell so they can refresh `hyprctl clients`.
local function emit_changed()
  hl.dispatch(hl.dsp.event("harpoon_changed"))
end

local function window_description(window)
  for _, value in ipairs({ window.title, window.class, window.initialTitle, window.initialClass }) do
    if type(value) == "string" and value ~= "" then
      return value
    end
  end
  return "Occupied"
end

local function update_hint(slot, window)
  local hint = hint_slots[slot]
  if not hint then
    return
  end
  if window then
    which_keys.add_hint(hint.submap, hint.key, window_description(window))
  else
    which_keys.remove_hint(hint.submap, hint.key)
  end
end

local function tag_for(slot)
  assert(type(slot) == "string" and slot:match("^[%w_-]+$"), "harpoon slot must contain only letters, digits, _ or -")
  return tag_prefix .. slot
end

function M.register_hint(slot, submap, key)
  tag_for(slot)
  assert(type(submap) == "string" and submap ~= "", "harpoon hint submap is required")
  assert(type(key) == "string" and key ~= "", "harpoon hint key is required")
  hint_slots[slot] = { submap = submap, key = key }
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

function M.sync_hints(submap)
  which_keys.clear_hints(submap)
  for slot, hint in pairs(hint_slots) do
    if hint.submap == submap then
      local window = M.get(slot)
      if window then
        update_hint(slot, window)
      end
    end
  end
end

-- Assign a particular window to a slot. This is useful for callers which need
-- to focus or move other windows before completing the assignment.
function M.assign(slot, window)
  if not window then
    return false
  end

  local tag = tag_for(slot)
  for _, candidate in ipairs(hl.get_windows()) do
    if has_tag(candidate, tag) and candidate.address ~= window.address then
      hl.dispatch(hl.dsp.window.tag({ tag = "-" .. tag, window = candidate }))
    end
  end

  if not has_tag(window, tag) then
    hl.dispatch(hl.dsp.window.tag({ tag = "+" .. tag, window = window }))
  end
  update_hint(slot, window)
  emit_changed()
  return true
end

-- Assign the active window to slot, replacing any previous assignment.
function M.mark(slot)
  local active = hl.get_active_window()
  return M.assign(slot, active)
end

function M.clear(slot, window)
  window = window or M.get(slot)
  if not window then
    return false
  end
  hl.dispatch(hl.dsp.window.tag({ tag = "-" .. tag_for(slot), window = window }))
  update_hint(slot, nil)
  emit_changed()
  return true
end

-- Remove the focused window (or a supplied window) from every harpoon slot.
function M.remove(window)
  window = window or hl.get_active_window()
  if not window then
    return false
  end

  local removed = false
  for _, tag in ipairs(window.tags or {}) do
    if tag:sub(1, #tag_prefix) == tag_prefix then
      hl.dispatch(hl.dsp.window.tag({ tag = "-" .. tag, window = window }))
      update_hint(tag:sub(#tag_prefix + 1), nil)
      removed = true
    end
  end
  if removed then
    emit_changed()
  end
  return removed
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
  local remove_binding = opts.remove_binding or "SUPER + SHIFT + h"
  local keys = opts.keys or {}
  local submap = opts.submap or "harpoon"

  for _, key in ipairs(keys) do
    local slot = opts.slots and opts.slots[key] or key
    M.register_hint(slot, submap, key)
  end

  hl.bind(leader, function()
    M.sync_hints(submap)
    hl.dispatch(hl.dsp.submap(submap))
  end, { description = "+Harpoon" })
  hl.bind(remove_binding, M.remove, { description = "Harpoon Remove" })
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
    hl.bind("escape", hl.dsp.submap("reset"), { description = "Exit" })
  end)
end

return M
