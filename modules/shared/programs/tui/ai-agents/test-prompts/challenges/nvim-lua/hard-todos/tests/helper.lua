-- Shared test helpers: deprecated APIs raise, tiny test runner.
local H = {}

vim.opt.rtp:prepend(vim.uv.cwd())
package.path = vim.uv.cwd() .. '/lua/?.lua;' .. package.path

vim.deprecate = function(name, alternative)
  error(('deprecated API used: %s (use %s)'):format(name, tostring(alternative)), 2)
end
local deprecated_api = {
  'nvim_buf_add_highlight',
  'nvim_buf_set_option',
  'nvim_buf_get_option',
  'nvim_win_set_option',
  'nvim_win_get_option',
  'nvim_set_option',
  'nvim_get_option',
  'nvim_get_option_info',
  'nvim_err_writeln',
  'nvim_err_write',
  'nvim_out_write',
  'nvim_buf_get_number',
  'nvim_exec',
  'nvim_get_hl_by_name',
  'nvim_get_hl_by_id',
}
for _, name in ipairs(deprecated_api) do
  vim.api[name] = function()
    error('deprecated API used: vim.api.' .. name, 2)
  end
end
for _, name in ipairs({ 'tbl_islist', 'tbl_flatten', 'tbl_add_reverse_lookup' }) do
  vim[name] = function()
    error('deprecated API used: vim.' .. name, 2)
  end
end

local failures, total = 0, 0

function H.say(msg)
  io.stdout:write(msg, '\n')
end

function H.test(name, fn)
  total = total + 1
  local ok, err = pcall(fn)
  if ok then
    H.say('ok   ' .. name)
  else
    failures = failures + 1
    H.say('FAIL ' .. name .. ': ' .. tostring(err))
  end
  vim.cmd('silent! %bwipeout!')
end

function H.eq(want, got, what)
  if not vim.deep_equal(want, got) then
    local function show(v)
      return vim.inspect(v, { newline = ' ', indent = '' })
    end
    error(('%s: want %s, got %s'):format(what or 'value', show(want), show(got)), 2)
  end
end

function H.buf(lines)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modified = false
  vim.api.nvim_set_current_buf(buf)
  return buf
end

function H.lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

function H.finish()
  H.say(('%d/%d passed'):format(total - failures, total))
  io.stdout:flush()
  os.exit(failures == 0 and 0 or 1)
end

return H
