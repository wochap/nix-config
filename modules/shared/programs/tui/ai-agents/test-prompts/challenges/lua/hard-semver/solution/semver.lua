local M = {}

local function is_numeric_id(id)
  return id:match('^%d+$') ~= nil
end

local function valid_num(s)
  return s:match('^%d+$') ~= nil and (s == '0' or s:sub(1, 1) ~= '0')
end

local function split_ids(s)
  local ids = {}
  for id in (s .. '.'):gmatch('([^.]*)%.') do
    ids[#ids + 1] = id
  end
  return ids
end

function M.parse(s)
  if type(s) ~= 'string' then
    return nil, 'version must be a string'
  end
  local core, rest = s:match('^([^-+]*)(.*)$')
  local pre, build = '', nil
  if rest ~= '' then
    local plus = rest:find('+', 1, true)
    if plus then
      build = rest:sub(plus + 1)
      rest = rest:sub(1, plus - 1)
    end
    if rest ~= '' then
      if rest:sub(1, 1) ~= '-' then
        return nil, 'invalid version: ' .. s
      end
      pre = rest:sub(2)
      if pre == '' then
        return nil, 'invalid version: ' .. s
      end
    end
  end
  local ma, mi, pa = core:match('^(%d+)%.(%d+)%.(%d+)$')
  if not ma or not valid_num(ma) or not valid_num(mi) or not valid_num(pa) then
    return nil, 'invalid version: ' .. s
  end
  local v = {
    major = tonumber(ma),
    minor = tonumber(mi),
    patch = tonumber(pa),
    prerelease = {},
    build = {},
  }
  if pre ~= '' then
    for _, id in ipairs(split_ids(pre)) do
      if id == '' or id:find('[^%w%-]') or (is_numeric_id(id) and not valid_num(id)) then
        return nil, 'invalid version: ' .. s
      end
      v.prerelease[#v.prerelease + 1] = is_numeric_id(id) and tonumber(id) or id
    end
  end
  if build then
    for _, id in ipairs(split_ids(build)) do
      if id == '' or id:find('[^%w%-]') then
        return nil, 'invalid version: ' .. s
      end
      v.build[#v.build + 1] = id
    end
  end
  return v
end

local function cmp(a, b)
  if a < b then
    return -1
  elseif a > b then
    return 1
  end
  return 0
end

local function compare_parsed(a, b)
  local c = cmp(a.major, b.major)
  if c == 0 then
    c = cmp(a.minor, b.minor)
  end
  if c == 0 then
    c = cmp(a.patch, b.patch)
  end
  if c ~= 0 then
    return c
  end
  local pa, pb = a.prerelease, b.prerelease
  if #pa == 0 or #pb == 0 then
    return cmp(#pb, #pa)
  end
  for i = 1, math.max(#pa, #pb) do
    local x, y = pa[i], pb[i]
    if x == nil then
      return -1
    elseif y == nil then
      return 1
    end
    local tx, ty = type(x), type(y)
    if tx ~= ty then
      return tx == 'number' and -1 or 1
    end
    c = cmp(x, y)
    if c ~= 0 then
      return c
    end
  end
  return 0
end

local function must_parse(s)
  local v, err = M.parse(s)
  if not v then
    error(err, 3)
  end
  return v
end

function M.compare(a, b)
  return compare_parsed(must_parse(a), must_parse(b))
end

local function upper(major, minor, patch)
  return { op = '<', v = { major = major, minor = minor, patch = patch, prerelease = {} } }
end

local function parse_comparator(tok, set)
  if tok == '*' then
    return
  end
  local op, rest = tok:match('^([<>=~^]*)(.*)$')
  local v = M.parse(rest)
  if not v then
    error('invalid range: ' .. tok, 0)
  end
  if #v.prerelease > 0 then
    set.pre[#set.pre + 1] = v
  end
  if op == '' then
    op = '='
  end
  if op == '^' then
    set[#set + 1] = { op = '>=', v = v }
    if v.major > 0 then
      set[#set + 1] = upper(v.major + 1, 0, 0)
    elseif v.minor > 0 then
      set[#set + 1] = upper(0, v.minor + 1, 0)
    else
      set[#set + 1] = upper(0, 0, v.patch + 1)
    end
  elseif op == '~' then
    set[#set + 1] = { op = '>=', v = v }
    set[#set + 1] = upper(v.major, v.minor + 1, 0)
  elseif op == '=' or op == '<' or op == '<=' or op == '>' or op == '>=' then
    set[#set + 1] = { op = op, v = v }
  else
    error('invalid range: ' .. tok, 0)
  end
end

local function parse_range(range)
  if type(range) ~= 'string' then
    error('invalid range', 0)
  end
  local sets = {}
  local start = 1
  repeat
    local i, j = range:find('||', start, true)
    local set = { pre = {} }
    for tok in range:sub(start, (i or 0) - 1):gmatch('%S+') do
      parse_comparator(tok, set)
    end
    sets[#sets + 1] = set
    start = (j or #range) + 1
  until not i
  return sets
end

local function test_set(set, v)
  for _, c in ipairs(set) do
    local r = compare_parsed(v, c.v)
    local ok = (c.op == '=' and r == 0)
      or (c.op == '<' and r < 0)
      or (c.op == '<=' and r <= 0)
      or (c.op == '>' and r > 0)
      or (c.op == '>=' and r >= 0)
    if not ok then
      return false
    end
  end
  if #v.prerelease > 0 then
    for _, p in ipairs(set.pre) do
      if p.major == v.major and p.minor == v.minor and p.patch == v.patch then
        return true
      end
    end
    return false
  end
  return true
end

function M.satisfies(version, range)
  local sets = parse_range(range)
  local v = M.parse(version)
  if not v then
    return false
  end
  for _, set in ipairs(sets) do
    if test_set(set, v) then
      return true
    end
  end
  return false
end

return M
