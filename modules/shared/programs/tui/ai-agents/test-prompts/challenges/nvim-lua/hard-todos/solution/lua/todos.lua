local M = {}

M.namespace = vim.api.nvim_create_namespace('todos')

local keywords = { 'TODO', 'FIXME', 'HACK' }

local severity = {
  FIXME = vim.diagnostic.severity.ERROR,
  HACK = vim.diagnostic.severity.WARN,
}

local function resolve(buf)
  if buf == nil or buf == 0 then
    return vim.api.nvim_get_current_buf()
  end
  return buf
end

local function match_line(line)
  local best
  for _, kw in ipairs(keywords) do
    local s, e = line:find('%f[%w_]' .. vim.pesc(kw) .. ':')
    if s and (not best or s < best.col) then
      best = { col = s, keyword = kw, text = vim.trim(line:sub(e + 1)) }
    end
  end
  return best
end

function M.scan(buf)
  buf = resolve(buf)
  local items = {}
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local m = match_line(line)
    if m then
      m.lnum = i
      items[#items + 1] = m
    end
  end
  return items
end

local function attach(buf)
  local function jump(count)
    return function()
      vim.diagnostic.jump({ count = count, namespace = M.namespace, wrap = true })
    end
  end
  vim.keymap.set('n', ']t', jump(1), { buf = buf, desc = 'Next todo' })
  vim.keymap.set('n', '[t', jump(-1), { buf = buf, desc = 'Previous todo' })
end

function M.refresh(buf)
  buf = resolve(buf)
  vim.api.nvim_buf_clear_namespace(buf, M.namespace, 0, -1)
  local diags = {}
  for _, item in ipairs(M.scan(buf)) do
    local col = item.col - 1
    vim.api.nvim_buf_set_extmark(buf, M.namespace, item.lnum - 1, col, {
      end_col = col + #item.keyword,
      hl_group = 'TodoKeyword',
    })
    diags[#diags + 1] = {
      lnum = item.lnum - 1,
      col = col,
      end_col = col + #item.keyword,
      severity = severity[item.keyword] or vim.diagnostic.severity.INFO,
      message = item.text ~= '' and item.text or item.keyword,
      source = 'todos',
    }
  end
  vim.diagnostic.set(M.namespace, buf, diags)
  attach(buf)
end

function M.setup(opts)
  opts = opts or {}
  keywords = opts.keywords or { 'TODO', 'FIXME', 'HACK' }
  vim.api.nvim_set_hl(0, 'TodoKeyword', { link = 'Todo', default = true })

  local group = vim.api.nvim_create_augroup('todos', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'TextChanged', 'InsertLeave' }, {
    group = group,
    callback = function(args)
      M.refresh(args.buf)
    end,
  })

  vim.api.nvim_create_user_command('TodoList', function()
    local buf = vim.api.nvim_get_current_buf()
    local items = {}
    for _, item in ipairs(M.scan(buf)) do
      items[#items + 1] = {
        bufnr = buf,
        lnum = item.lnum,
        col = item.col,
        text = item.keyword .. ': ' .. item.text,
      }
    end
    vim.fn.setloclist(0, {}, ' ', { title = 'Todos', items = items })
  end, { force = true, desc = 'List todos in the location list' })
end

return M
