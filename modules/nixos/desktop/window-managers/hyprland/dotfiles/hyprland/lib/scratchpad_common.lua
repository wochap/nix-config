local M = {}

M.tags = {
  persistent = "scratchpad",
  temporary = "tmpscratchpad",
  harpoon = "harpoon-scratchpad-",
}

M.workspaces = {
  persistent = "scratchpads",
  temporary = "tmpscratchpads",
  harpoon = "harpoon-scratchpads",
}

function M.has_tag_prefix(window, prefix)
  for _, tag in ipairs(window.tags or {}) do
    if tag:sub(1, #prefix) == prefix then
      return true
    end
  end
  return false
end

function M.remove_tags_with_prefix(window, prefix)
  if not window then
    return false
  end
  local removed = false
  for _, tag in ipairs(window.tags or {}) do
    if tag:sub(1, #prefix) == prefix then
      hl.dispatch(hl.dsp.window.tag({ tag = "-" .. tag, window = window }))
      removed = true
    end
  end
  return removed
end

function M.same_monitor(a, b)
  return a and b and a.id == b.id
end

function M.raise(window)
  if not window then
    return false
  end
  hl.dispatch(hl.dsp.focus({ window = window }))
  hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = window }))
  return true
end

function M.hide(window, workspace)
  if not window then
    return false
  end
  if window.group then
    hl.dispatch(hl.dsp.window.move({ out_of_group = true, window = window, follow = false }))
  end
  hl.dispatch(hl.dsp.window.move({
    workspace = "special:" .. workspace,
    window = window,
    follow = false,
  }))
  return true
end

-- Bring a window to the workspace and monitor active at invocation time.
function M.show(window)
  if not window then
    return false
  end
  local workspace = hl.get_active_workspace()
  local monitor = hl.get_active_monitor()
  local other_monitor = not M.same_monitor(window.monitor, monitor)
  hl.dispatch(hl.dsp.window.move({ workspace = workspace, window = window, follow = false }))
  if other_monitor then
    hl.dispatch(hl.dsp.window.center({ window = window }))
  end
  return M.raise(window)
end

return M
