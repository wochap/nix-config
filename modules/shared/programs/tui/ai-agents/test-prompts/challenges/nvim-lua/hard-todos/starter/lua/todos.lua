local M = {}

M.namespace = vim.api.nvim_create_namespace('todos')

-- TODO: implement (see PROMPT.md)
function M.setup(opts)
  return opts
end

function M.scan(buf)
  return { buf }
end

function M.refresh(buf)
  return buf
end

return M
