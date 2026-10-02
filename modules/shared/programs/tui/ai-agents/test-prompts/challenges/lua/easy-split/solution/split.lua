local M = {}

function M.split(s, sep)
  if type(sep) ~= 'string' or sep == '' then
    error('split: sep must be a non-empty string', 2)
  end
  local parts = {}
  local start = 1
  while true do
    local i, j = s:find(sep, start, true)
    if not i then
      parts[#parts + 1] = s:sub(start)
      return parts
    end
    parts[#parts + 1] = s:sub(start, i - 1)
    start = j + 1
  end
end

return M
