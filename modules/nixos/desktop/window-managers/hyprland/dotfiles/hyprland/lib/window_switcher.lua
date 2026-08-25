local M = {}

local switcher_cmd = "quickshell --path ~/.config/quickshell/shell ipc call window-switcher "

local function call(action, mode)
  local suffix = mode and (" " .. mode) or ""
  hl.dispatch(hl.dsp.exec_cmd(switcher_cmd .. action .. suffix))
end

function M.setup(opts)
  local switcher_open = false
  local modifier = assert(opts.modifier, "window switcher modifier is required")
  local mode = assert(opts.mode, "window switcher mode is required")

  hl.bind(modifier .. " + TAB", function()
    switcher_open = true
    call("advance", mode)
  end)
  hl.bind(modifier .. " + SHIFT + TAB", function()
    switcher_open = true
    call("reverse", mode)
  end)

  for _, key in ipairs(opts.release_keys) do
    hl.bind(key, function()
      if switcher_open then
        switcher_open = false
        call("confirm")
      end
    end, { release = true, non_consuming = true, transparent = true, ignore_mods = true })
  end
end

return M
