local M = {}

local switcher_cmd = "quickshell --path ~/.config/quickshell/shell ipc call window-switcher "
local next_session_id = 0

local function call(action, mode, order, session_id)
  local args = mode and (" " .. mode) or ""
  args = args .. (order and (" " .. order) or "")
  args = args .. (session_id and (" " .. session_id) or "")
  hl.dispatch(hl.dsp.exec_cmd(switcher_cmd .. action .. args))
end

function M.setup(opts)
  local switcher_open = false
  local session_id
  local modifier = assert(opts.modifier, "window switcher modifier is required")
  local mode = assert(opts.mode, "window switcher mode is required")
  -- "mru" cycles by focus history; "stable" cycles by window open order.
  local order = opts.order or "mru"
  -- While the switcher is open its own submap is active, so global bindings
  -- such as SUPER + mouse:272 (float/drag) cannot swallow clicks on the
  -- overlay. Quickshell hides submaps prefixed with "window-switcher".
  local submap = opts.submap or ("window-switcher-" .. mode)

  local function step(action)
    if not switcher_open then
      next_session_id = next_session_id + 1
      session_id = tostring(next_session_id)
      hl.dispatch(hl.dsp.submap(submap))
    end
    switcher_open = true
    call(action, mode, order, session_id)
  end

  local function advance()
    step("advance")
  end

  local function reverse()
    step("reverse")
  end

  hl.bind(modifier .. " + TAB", advance)
  hl.bind(modifier .. " + SHIFT + TAB", reverse)

  -- Keep cycling inside the submap; unbound keys (Escape, Enter) fall
  -- through to the overlay, which owns exclusive keyboard focus.
  hl.define_submap(submap, function()
    hl.bind(modifier .. " + TAB", advance)
    hl.bind(modifier .. " + SHIFT + TAB", reverse)
  end)

  -- This is the sole modifier-release confirmation path. The QML panel must
  -- not also confirm the release: a delayed duplicate would arm the backend's
  -- fast-tap fallback and immediately confirm the next invocation.
  -- Universal so the release is still observed while the submap is active.
  for _, key in ipairs(opts.release_keys) do
    hl.bind(key, function()
      if switcher_open then
        switcher_open = false
        hl.dispatch(hl.dsp.submap("reset"))
        call("confirm", nil, nil, session_id)
        session_id = nil
      end
    end, { release = true, non_consuming = true, transparent = true, ignore_mods = true, submap_universal = true })
  end
end

return M
