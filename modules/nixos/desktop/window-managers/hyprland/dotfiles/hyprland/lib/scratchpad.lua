-- scratchpad helpers, ported from scripts/hyprland-scratchpad.sh
-- NOTE: add windowrule so those scratchpads have the tag scratchpad
-- e.g.: hl.window_rule({ match = { class = "kitty-scratch" }, tag = "+scratchpad" })

local M = {}

local function has_tag_prefix(w, prefix)
  for _, tag in ipairs(w.tags or {}) do
    if tag:sub(1, #prefix) == prefix then
      return true
    end
  end
  return false
end

local function sort_by_focus(wins)
  table.sort(wins, function(a, b)
    return a.focus_history_id < b.focus_history_id
  end)
  return wins
end

local function same_monitor(a, b)
  return a and b and a.id == b.id
end

-- raise a window of the given class, or run cmd if none exists.
-- opts.use_uwsm: launch cmd via uwsm-app (default false)
function M.raise_or_run(class, cmd, opts)
  opts = opts or {}
  local use_uwsm = opts.use_uwsm == true

  local active_ws = hl.get_active_workspace()
  local current_monitor = hl.get_active_monitor()
  local current_ws = active_ws.id

  local windows = hl.get_windows({ class = class })
  local window = windows[1]

  if window then
    local window_ws = window.workspace
    local window_monitor = window.monitor
    local is_focused = window.focus_history_id == 0
    local is_visible = window_ws and window_ws.id == current_ws
      and same_monitor(window_monitor, current_monitor)

    if is_visible then
      if is_focused then
        -- hide
        if window.group then
          hl.dispatch(hl.dsp.window.move({ out_of_group = true, window = window }))
        end
        hl.dispatch(hl.dsp.window.move({
          workspace = "special:scratchpads",
          window = "class:^(" .. class .. ")$",
        }))
      else
        -- focus
        hl.dispatch(hl.dsp.focus({ window = "class:^(" .. class .. ")$" }))
        hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = window }))
      end
    else
      -- focus from another workspace/monitor
      local other_monitor = not same_monitor(window_monitor, current_monitor)
      if other_monitor then
        -- HACK: move scratchpads ws to current monitor
        hl.dispatch(hl.dsp.workspace.move({
          workspace = "special:scratchpads",
          monitor = current_monitor,
        }))
      end
      hl.dispatch(hl.dsp.window.move({
        workspace = current_ws,
        window = "class:^(" .. class .. ")$",
      }))
      hl.dispatch(hl.dsp.focus({ window = "class:^(" .. class .. ")$" }))
      hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = window }))
      if other_monitor then
        hl.dispatch(hl.dsp.window.center({ window = window }))
        -- HACK: move cursor to window after it has been centered
        hl.dispatch(hl.dsp.focus({ window = "class:^(" .. class .. ")$" }))
      end
    end
  else
    if cmd and cmd ~= "" then
      if use_uwsm then
        hl.dispatch(hl.dsp.exec_cmd("uwsm-app -- " .. cmd))
      else
        hl.dispatch(hl.dsp.exec_cmd(cmd))
      end
    end
  end

  -- hide all other scratchpads on the current workspace
  for _, w in ipairs(hl.get_windows({ mapped = true })) do
    if w.workspace and w.workspace.id == current_ws
      and same_monitor(w.monitor, current_monitor)
      and w.class ~= class
      and has_tag_prefix(w, "scratchpad") then
      hl.dispatch(hl.dsp.window.move({ workspace = "special:scratchpads", window = w }))
    end
  end
end

function M.focus_last()
  local matched = {}
  for _, w in ipairs(hl.get_windows({ mapped = true })) do
    if has_tag_prefix(w, "scratchpad") then
      table.insert(matched, w)
    end
  end
  sort_by_focus(matched)
  local first = matched[1]
  if first then
    M.raise_or_run(first.class, nil)
  end
end

-- returns true if the window was handled (caller should stop)
local function process_scratchpad(window, ws_name, ctx)
  if not window then
    return false
  end

  local window_ws = window.workspace
  local is_focused = window.focus_history_id == 0
  local is_visible = window_ws and window_ws.id == ctx.current_ws
    and same_monitor(window.monitor, ctx.current_monitor)

  if not is_visible then
    return false
  end

  if is_focused then
    if ws_name:sub(1, #"tmpscratchpad") == "tmpscratchpad" then
      -- hide all tmpscratchpads on the current workspace
      for _, w in ipairs(hl.get_windows({ mapped = true })) do
        if w.workspace and w.workspace.id == ctx.current_ws
          and same_monitor(w.monitor, ctx.current_monitor)
          and has_tag_prefix(w, "tmpscratchpad") then
          hl.dispatch(hl.dsp.window.move({ workspace = "special:" .. ws_name, window = w }))
        end
      end
      return true
    else
      -- hide
      hl.dispatch(hl.dsp.window.move({ workspace = "special:" .. ws_name, window = window }))
      return true
    end
  else
    if ws_name:sub(1, #"tmpscratchpad") == "tmpscratchpad" then
      -- focus
      hl.dispatch(hl.dsp.focus({ window = window }))
      hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = window }))
      return true
    end
  end

  return false
end

function M.toggle()
  local active_ws = hl.get_active_workspace()
  local current_monitor = hl.get_active_monitor()
  local ctx = { current_ws = active_ws.id, current_monitor = current_monitor }

  -- process scratchpads created by raise_or_run
  for _, w in ipairs(hl.get_windows({ mapped = true })) do
    if w.workspace and w.workspace.id == ctx.current_ws
      and same_monitor(w.monitor, current_monitor)
      and has_tag_prefix(w, "scratchpad") then
      if process_scratchpad(w, "scratchpads", ctx) then
        return
      end
    end
  end

  -- process scratchpads created by toggle / toggle_in
  local visible_tmp = {}
  for _, w in ipairs(hl.get_windows({ mapped = true })) do
    if w.workspace and w.workspace.id == ctx.current_ws
      and same_monitor(w.monitor, current_monitor)
      and has_tag_prefix(w, "tmpscratchpad") then
      table.insert(visible_tmp, w)
    end
  end
  sort_by_focus(visible_tmp)
  for _, w in ipairs(visible_tmp) do
    if process_scratchpad(w, "tmpscratchpads", ctx) then
      return
    end
  end

  -- show all hidden tmpscratchpads and focus the most recent one
  local hidden_tmp = {}
  for _, w in ipairs(hl.get_windows({ mapped = true })) do
    if (not same_monitor(w.monitor, current_monitor)
        or (w.workspace and w.workspace.id ~= ctx.current_ws))
      and has_tag_prefix(w, "tmpscratchpad") then
      table.insert(hidden_tmp, w)
    end
  end
  sort_by_focus(hidden_tmp)

  local recent = hidden_tmp[1]
  for _, w in ipairs(hidden_tmp) do
    hl.dispatch(hl.dsp.window.move({ workspace = ctx.current_ws, window = w }))
    if not same_monitor(w.monitor, current_monitor) then
      hl.dispatch(hl.dsp.window.center({ window = w }))
    end
  end
  if recent then
    hl.dispatch(hl.dsp.focus({ window = recent }))
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = recent }))
  end
end

function M.toggle_in()
  local active_ws = hl.get_active_workspace()
  local current_ws = active_ws.id

  local focused = hl.get_active_window()
  if focused and has_tag_prefix(focused, "tmpscratchpad") then
    -- move out of scratchpad
    hl.dispatch(hl.dsp.window.tag({ tag = "-tmpscratchpad", window = focused }))
    hl.dispatch(hl.dsp.window.move({ workspace = current_ws, window = focused }))
  else
    if not focused then
      return
    end
    -- move into scratchpad
    hl.dispatch(hl.dsp.window.tag({ tag = "+tmpscratchpad", window = focused }))
    if focused.group then
      hl.dispatch(hl.dsp.window.move({ out_of_group = true, window = focused }))
    end
    hl.dispatch(hl.dsp.window.move({ workspace = "special:tmpscratchpads", window = focused }))
  end
end

return M
