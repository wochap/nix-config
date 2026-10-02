local H = dofile('tests/helper.lua')
local test, eq = H.test, H.eq

-- A user-defined highlight made before setup must survive it.
vim.api.nvim_set_hl(0, 'TodoKeyword', { fg = '#ff0000' })

local ok_load, todos = pcall(require, 'todos')
if not ok_load then
  H.say('FAIL require todos: ' .. tostring(todos))
  os.exit(1)
end

local S = vim.diagnostic.severity

local sample = {
  'local x = 1 -- TODO: write docs  ',
  'nothing here',
  '  -- FIXME:fix overflow',
  'MYTODO: not a todo',
  'TODOS: not a todo either',
  'TODO no colon',
  '(HACK: temporary) and TODO: later',
  'x_TODO: no',
  '-- TODO:',
}

local function marks(buf)
  local out = {}
  local list = vim.api.nvim_buf_get_extmarks(buf, todos.namespace, 0, -1, { details = true })
  for _, m in ipairs(list) do
    out[#out + 1] = { m[2], m[3], m[4].end_col, m[4].hl_group }
  end
  return out
end

local function diags(buf)
  local out = {}
  local list = vim.diagnostic.get(buf, { namespace = todos.namespace })
  table.sort(list, function(a, b)
    return a.lnum < b.lnum
  end)
  for _, d in ipairs(list) do
    out[#out + 1] = {
      lnum = d.lnum,
      col = d.col,
      end_col = d.end_col,
      severity = d.severity,
      message = d.message,
      source = d.source,
    }
  end
  return out
end

local function keymap(buf, lhs)
  for _, m in ipairs(vim.api.nvim_buf_get_keymap(buf, 'n')) do
    if m.lhs == lhs then
      return m
    end
  end
end

test('setup runs twice', function()
  todos.setup()
  todos.setup()
end)

test('namespace', function()
  eq(vim.api.nvim_create_namespace('todos'), todos.namespace, 'namespace')
end)

test('scan finds todos', function()
  todos.setup()
  local buf = H.buf(sample)
  eq({
    { lnum = 1, col = 16, keyword = 'TODO', text = 'write docs' },
    { lnum = 3, col = 6, keyword = 'FIXME', text = 'fix overflow' },
    { lnum = 7, col = 2, keyword = 'HACK', text = 'temporary) and TODO: later' },
    { lnum = 9, col = 4, keyword = 'TODO', text = '' },
  }, todos.scan(buf), 'scan')
  eq(todos.scan(buf), todos.scan(0), 'scan(0)')
  eq(todos.scan(buf), todos.scan(), 'scan()')
end)

test('scan empty buffer', function()
  todos.setup()
  eq({}, todos.scan(H.buf({})), 'scan')
end)

test('custom keywords replace defaults', function()
  todos.setup({ keywords = { 'NOTE', 'X.Y' } })
  local buf = H.buf({ 'TODO: old', 'NOTE: new', 'XzY: no', ' X.Y: yes' })
  eq({
    { lnum = 2, col = 1, keyword = 'NOTE', text = 'new' },
    { lnum = 4, col = 2, keyword = 'X.Y', text = 'yes' },
  }, todos.scan(buf), 'scan')
  todos.refresh(buf)
  eq(S.INFO, diags(buf)[1].severity, 'custom keyword severity')
  todos.setup()
  eq(1, #todos.scan(H.buf({ 'TODO: back' })), 'setup() restores defaults')
end)

test('refresh sets extmarks', function()
  todos.setup()
  local buf = H.buf(sample)
  todos.refresh(buf)
  eq({
    { 0, 15, 19, 'TodoKeyword' },
    { 2, 5, 10, 'TodoKeyword' },
    { 6, 1, 5, 'TodoKeyword' },
    { 8, 3, 7, 'TodoKeyword' },
  }, marks(buf), 'extmarks')
end)

test('refresh sets diagnostics', function()
  todos.setup()
  local buf = H.buf(sample)
  todos.refresh(buf)
  eq({
    {
      lnum = 0,
      col = 15,
      end_col = 19,
      severity = S.INFO,
      message = 'write docs',
      source = 'todos',
    },
    {
      lnum = 2,
      col = 5,
      end_col = 10,
      severity = S.ERROR,
      message = 'fix overflow',
      source = 'todos',
    },
    {
      lnum = 6,
      col = 1,
      end_col = 5,
      severity = S.WARN,
      message = 'temporary) and TODO: later',
      source = 'todos',
    },
    { lnum = 8, col = 3, end_col = 7, severity = S.INFO, message = 'TODO', source = 'todos' },
  }, diags(buf), 'diagnostics')
end)

test('refresh replaces previous results', function()
  todos.setup()
  local buf = H.buf(sample)
  todos.refresh(buf)
  todos.refresh(buf)
  eq(4, #marks(buf), 'extmarks after two refreshes')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'HACK: only one' })
  todos.refresh(buf)
  eq(1, #marks(buf), 'extmarks after edit')
  eq(1, #diags(buf), 'diagnostics after edit')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'clean' })
  todos.refresh(0)
  eq(0, #marks(buf), 'extmarks when clean')
  eq(0, #diags(buf), 'diagnostics when clean')
end)

test('refresh only touches its buffer', function()
  todos.setup()
  local a = H.buf({ 'TODO: a' })
  local b = H.buf({ 'TODO: b' })
  todos.refresh(a)
  todos.refresh(b)
  vim.api.nvim_buf_set_lines(b, 0, -1, false, { 'none' })
  todos.refresh(b)
  eq(1, #diags(a), 'diagnostics in other buffer')
  eq(1, #marks(a), 'extmarks in other buffer')
end)

test('highlight group', function()
  todos.setup()
  local hl = vim.api.nvim_get_hl(0, { name = 'TodoKeyword' })
  eq(tonumber('ff0000', 16), hl.fg, 'user definition kept')
  vim.api.nvim_set_hl(0, 'TodoKeyword', {})
  todos.setup()
  eq('Todo', vim.api.nvim_get_hl(0, { name = 'TodoKeyword' }).link, 'default link')
end)

test('autocmds', function()
  todos.setup()
  todos.setup()
  local events = {}
  for _, au in ipairs(vim.api.nvim_get_autocmds({ group = 'todos' })) do
    events[#events + 1] = au.event
  end
  table.sort(events)
  eq({ 'BufEnter', 'BufWritePost', 'InsertLeave', 'TextChanged' }, events, 'autocmd events')
end)

test('TextChanged refreshes', function()
  todos.setup()
  local buf = H.buf({ 'plain' })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'x', 'FIXME: now' })
  vim.api.nvim_exec_autocmds('TextChanged', { buffer = buf })
  eq(1, #diags(buf), 'diagnostics after TextChanged')
  eq(S.ERROR, diags(buf)[1].severity, 'severity')
end)

test('BufEnter refreshes', function()
  todos.setup()
  local buf = H.buf({ 'TODO: on enter' })
  vim.cmd('enew')
  vim.cmd('buffer ' .. buf)
  eq(1, #marks(buf), 'extmarks after BufEnter')
end)

test('TodoList fills the location list', function()
  todos.setup()
  local buf = H.buf(sample)
  vim.cmd('TodoList')
  local ll = vim.fn.getloclist(0, { items = 1, title = 1 })
  eq('Todos', ll.title, 'title')
  local got = {}
  for _, it in ipairs(ll.items) do
    got[#got + 1] = { it.bufnr, it.lnum, it.col, it.text }
  end
  eq({
    { buf, 1, 16, 'TODO: write docs' },
    { buf, 3, 6, 'FIXME: fix overflow' },
    { buf, 7, 2, 'HACK: temporary) and TODO: later' },
    { buf, 9, 4, 'TODO: ' },
  }, got, 'items')
  eq(0, vim.fn.getqflist({ size = 1 }).size, 'quickfix list untouched')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'TODO: one' })
  vim.cmd('TodoList')
  eq(1, #vim.fn.getloclist(0), 'list replaced')
end)

test('mappings', function()
  todos.setup()
  local buf = H.buf(sample)
  todos.refresh(buf)
  local next_map, prev_map = keymap(buf, ']t'), keymap(buf, '[t')
  eq(true, next_map ~= nil and prev_map ~= nil, 'buffer-local ]t and [t exist')
  eq('Next todo', next_map.desc, ']t desc')
  eq('Previous todo', prev_map.desc, '[t desc')
  for _, m in ipairs(vim.api.nvim_get_keymap('n')) do
    if m.desc == 'Next todo' or m.desc == 'Previous todo' then
      error('mapping must be buffer-local, found global ' .. m.lhs)
    end
  end
end)

test(']t and [t move between todos and wrap', function()
  todos.setup()
  local buf = H.buf(sample)
  todos.refresh(buf)
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_cursor(win, { 2, 0 })
  local function press(keys)
    vim.cmd('normal ' .. keys)
    return vim.api.nvim_win_get_cursor(win)
  end
  eq({ 3, 5 }, press(']t'), 'next from line 2')
  eq({ 7, 1 }, press(']t'), 'next')
  eq({ 9, 3 }, press(']t'), 'next')
  eq({ 1, 15 }, press(']t'), 'wrap to first')
  eq({ 9, 3 }, press('[t'), 'wrap to last')
  eq({ 7, 1 }, press('[t'), 'previous')
end)

H.finish()
