local M = {}

-- TODO: implement (see PROMPT.md)
function M.parse(s)
  return nil, 'not implemented: ' .. tostring(s)
end

function M.compare(a, b)
  return a == b and 0 or -1
end

function M.satisfies(version, range)
  return version == range
end

return M
