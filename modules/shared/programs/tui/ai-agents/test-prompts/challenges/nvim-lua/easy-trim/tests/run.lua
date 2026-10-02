local H = dofile('tests/helper.lua')
local test, eq = H.test, H.eq

local ok_load, trim = pcall(require, 'trim')
if not ok_load then
  H.say('FAIL require trim: ' .. tostring(trim))
  os.exit(1)
end

test('trims spaces and tabs at line ends', function()
  local buf = H.buf({ 'a  ', 'b\t', 'c \t ', 'd' })
  eq(3, trim.trim_trailing(buf), 'changed count')
  eq({ 'a', 'b', 'c', 'd' }, H.lines(buf), 'lines')
end)

test('keeps indentation and inner whitespace', function()
  local buf = H.buf({ '  x  y  ', '\tz\t', '    ' })
  eq(3, trim.trim_trailing(buf), 'changed count')
  eq({ '  x  y', '\tz', '' }, H.lines(buf), 'lines')
end)

test('buf 0 is the current buffer', function()
  local buf = H.buf({ 'one ', 'two' })
  eq(1, trim.trim_trailing(0), 'changed count')
  eq({ 'one', 'two' }, H.lines(buf), 'lines')
end)

test('line range is 1-based inclusive', function()
  local buf = H.buf({ 'a ', 'b ', 'c ', 'd ' })
  eq(2, trim.trim_trailing(buf, 2, 3), 'changed count')
  eq({ 'a ', 'b', 'c', 'd ' }, H.lines(buf), 'lines')
  eq(1, trim.trim_trailing(buf, 4), 'last defaults to the last line')
  eq({ 'a ', 'b', 'c', 'd' }, H.lines(buf), 'lines')
end)

test('unchanged buffer stays unmodified', function()
  local buf = H.buf({ 'clean', '  indented', '' })
  local tick = vim.b[buf].changedtick
  eq(0, trim.trim_trailing(buf), 'changed count')
  eq(false, vim.bo[buf].modified, 'modified')
  eq(tick, vim.b[buf].changedtick, 'changedtick')
end)

test('only changed lines are rewritten', function()
  local buf = H.buf({ 'keep', 'fix ', 'keep', 'keep', 'fix\t' })
  local touched = {}
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function(_, _, _, firstline, lastline)
      for l = firstline, lastline - 1 do
        touched[#touched + 1] = l + 1
      end
    end,
  })
  eq(2, trim.trim_trailing(buf), 'changed count')
  table.sort(touched)
  eq({ 2, 5 }, vim.fn.uniq(touched), 'rewritten lines')
end)

test('empty buffer', function()
  local buf = H.buf({})
  eq(0, trim.trim_trailing(buf), 'changed count')
  eq({ '' }, H.lines(buf), 'lines')
end)

test('setup creates :TrimTrailing for the whole buffer', function()
  trim.setup()
  trim.setup()
  local buf = H.buf({ 'a ', 'b ', 'c' })
  vim.cmd('TrimTrailing')
  eq({ 'a', 'b', 'c' }, H.lines(buf), 'lines')
end)

test(':TrimTrailing with a range', function()
  trim.setup()
  local buf = H.buf({ 'a ', 'b ', 'c ', 'd ' })
  vim.cmd('2,3TrimTrailing')
  eq({ 'a ', 'b', 'c', 'd ' }, H.lines(buf), 'lines')
end)

test('works on a non-current buffer', function()
  local other = H.buf({ 'x  ', 'y' })
  H.buf({ 'current ' })
  eq(1, trim.trim_trailing(other), 'changed count')
  eq({ 'x', 'y' }, H.lines(other), 'lines')
end)

H.finish()
