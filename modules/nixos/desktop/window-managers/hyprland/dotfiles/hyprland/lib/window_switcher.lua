local M = {}

local switcher_cmd = "quickshell --path ~/.config/quickshell/shell ipc call window-switcher "
local next_session_id = 0

local function call(action, mode, session_id)
  local args = mode and (" " .. mode) or ""
  args = args .. (session_id and (" " .. session_id) or "")
  hl.dispatch(hl.dsp.exec_cmd(switcher_cmd .. action .. args))
end

function M.setup(opts)
  local switcher_open = false
  local session_id
  local modifier = assert(opts.modifier, "window switcher modifier is required")
  local mode = assert(opts.mode, "window switcher mode is required")

  hl.bind(modifier .. " + TAB", function()
    if not switcher_open then
      next_session_id = next_session_id + 1
      session_id = tostring(next_session_id)
    end
    switcher_open = true
    call("advance", mode, session_id)
  end)
  hl.bind(modifier .. " + SHIFT + TAB", function()
    if not switcher_open then
      next_session_id = next_session_id + 1
      session_id = tostring(next_session_id)
    end
    switcher_open = true
    call("reverse", mode, session_id)
  end)

  -- This is the sole modifier-release confirmation path. The QML panel must
  -- not also confirm the release: a delayed duplicate would arm the backend's
  -- fast-tap fallback and immediately confirm the next invocation.
  for _, key in ipairs(opts.release_keys) do
    hl.bind(key, function()
      if switcher_open then
        switcher_open = false
        call("confirm", nil, session_id)
        session_id = nil
      end
    end, { release = true, non_consuming = true, transparent = true, ignore_mods = true })
  end
end

return M
