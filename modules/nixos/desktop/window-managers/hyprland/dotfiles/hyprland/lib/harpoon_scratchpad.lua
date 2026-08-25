local harpoon = require("hyprland.lib.harpoon")
local common = require("hyprland.lib.scratchpad_common")

local M = {}

local slot_prefix = "scratchpad-"

local function slot_for(key)
  return slot_prefix .. key
end

local function same_window(a, b)
  return a and b and a.address == b.address
end

local function is_visible_here(window)
  local active_workspace = hl.get_active_workspace()
  local active_monitor = hl.get_active_monitor()
  return window
    and window.workspace
    and active_workspace
    and window.workspace.id == active_workspace.id
    and window.monitor
    and active_monitor
    and window.monitor.id == active_monitor.id
end

function M.toggle(key)
  local window = harpoon.get(slot_for(key))
  if not window then
    return false
  end
  if is_visible_here(window) then
    if same_window(window, hl.get_active_window()) then
      return common.hide(window, common.workspaces.harpoon)
    end
    return common.raise(window)
  end
  return common.show(window)
end

function M.toggle_in(key)
  local selected = hl.get_active_window()
  if not selected then
    return false
  end

  local slot = slot_for(key)
  local previous = harpoon.get(slot)
  if previous and not same_window(previous, selected) then
    common.show(previous)
    harpoon.clear(slot, previous)
  end

  -- Moving a generic temporary scratchpad into a letter slot transfers its
  -- ownership instead of leaving it controlled by both scratchpad systems.
  common.remove_tags_with_prefix(selected, common.tags.temporary)
  harpoon.assign(slot, selected)
  common.hide(selected, common.workspaces.harpoon)
  return true
end

function M.setup(opts)
  opts = opts or {}
  local leader = opts.leader or "SUPER + a"
  local keys = opts.keys or {}
  local submap = opts.submap or "scratchpad"

  for _, key in ipairs(keys) do
    harpoon.register_hint(slot_for(key), submap, key)
  end

  hl.bind(leader, function()
    harpoon.sync_hints(submap)
    hl.dispatch(hl.dsp.submap(submap))
  end, { description = "+Harpoon Scratchpads" })
  hl.define_submap(submap, "reset", function()
    for _, key in ipairs(keys) do
      hl.bind(key, function()
        M.toggle(key)
      end)
      hl.bind("SHIFT + " .. key, function()
        M.toggle_in(key)
      end)
    end
    hl.bind("escape", hl.dsp.submap("reset"), { description = "Exit" })
  end)
end

return M
