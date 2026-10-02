local M = {}

function M.trim_trailing(buf, first, last)
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  first = first or 1
  last = last or vim.api.nvim_buf_line_count(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, first - 1, last, false)
  local changed = 0
  for i, line in ipairs(lines) do
    local trimmed = line:gsub('[ \t]+$', '')
    if trimmed ~= line then
      local lnum = first + i - 2
      vim.api.nvim_buf_set_lines(buf, lnum, lnum + 1, false, { trimmed })
      changed = changed + 1
    end
  end
  return changed
end

function M.setup()
  vim.api.nvim_create_user_command('TrimTrailing', function(opts)
    M.trim_trailing(0, opts.line1, opts.line2)
  end, { range = '%', force = true, desc = 'Trim trailing whitespace' })
end

return M
