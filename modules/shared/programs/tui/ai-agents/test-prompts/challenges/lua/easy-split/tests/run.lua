package.path = './?.lua;' .. package.path

local failures, total = 0, 0

local function show(t)
  if type(t) ~= 'table' then
    return tostring(t)
  end
  local out = {}
  for i = 1, #t do
    out[i] = string.format('%q', t[i])
  end
  return '{ ' .. table.concat(out, ', ') .. ' }'
end

local function same(a, b)
  if type(a) ~= 'table' or type(b) ~= 'table' or #a ~= #b then
    return false
  end
  for k, v in pairs(a) do
    if b[k] ~= v then
      return false
    end
  end
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end
  return true
end

local function test(name, fn)
  total = total + 1
  local ok, err = pcall(fn)
  if ok then
    print('ok   ' .. name)
  else
    failures = failures + 1
    print('FAIL ' .. name .. ': ' .. tostring(err))
  end
end

local globals_before = {}
for k in pairs(_G) do
  globals_before[k] = true
end

local ok_load, mod = pcall(require, 'split')
if not ok_load then
  print('FAIL require split: ' .. tostring(mod))
  os.exit(1)
end
local split = mod.split

local function eq(s, sep, want)
  local got = split(s, sep)
  if not same(got, want) then
    error(string.format('split(%q, %q): got %s, want %s', s, sep, show(got), show(want)), 2)
  end
end

test('module returns a table with split', function()
  assert(type(mod) == 'table' and type(split) == 'function', 'expected { split = function }')
end)
test('basic', function()
  eq('a,b,c', ',', { 'a', 'b', 'c' })
end)
test('no separator present', function()
  eq('abc', ',', { 'abc' })
end)
test('empty string', function()
  eq('', ',', { '' })
end)
test('empty pieces are kept', function()
  eq('a,,b,', ',', { 'a', '', 'b', '' })
  eq(',a', ',', { '', 'a' })
  eq(',', ',', { '', '' })
  eq(',,,', ',', { '', '', '', '' })
end)
test('dot is literal', function()
  eq('1.2.3', '.', { '1', '2', '3' })
end)
test('percent is literal', function()
  eq('50%off%now', '%', { '50', 'off', 'now' })
end)
test('dash and brackets are literal', function()
  eq('a-b--c', '-', { 'a', 'b', '', 'c' })
  eq('x[y[z', '[', { 'x', 'y', 'z' })
  eq('f(a)(b)', ')(', { 'f(a', 'b)' })
  eq('a.*b.*c', '.*', { 'a', 'b', 'c' })
end)
test('multi-char separator', function()
  eq('a::b:c', '::', { 'a', 'b:c' })
  eq('a:::b', '::', { 'a', ':b' })
  eq('::', '::', { '', '' })
end)
test('separator longer than input', function()
  eq('ab', 'abc', { 'ab' })
end)
test('whitespace is kept', function()
  eq(' a , b ', ',', { ' a ', ' b ' })
end)
test('many pieces', function()
  local s = string.rep('x;', 1000)
  local got = split(s, ';')
  assert(#got == 1001, 'want 1001 pieces, got ' .. #got)
  assert(got[1000] == 'x' and got[1001] == '', 'wrong last pieces')
end)
test('returns a new table each call', function()
  local a = split('a,b', ',')
  local b = split('a,b', ',')
  assert(a ~= b, 'same table returned twice')
end)
test('empty sep raises', function()
  local ok, err = pcall(split, 'abc', '')
  assert(not ok, 'expected an error')
  assert(tostring(err):find('sep', 1, true), 'error should mention sep: ' .. tostring(err))
end)
test('non-string sep raises', function()
  local ok, err = pcall(split, 'abc', nil)
  assert(not ok, 'expected an error')
  assert(tostring(err):find('sep', 1, true), 'error should mention sep: ' .. tostring(err))
  ok = pcall(split, 'a1b', 1)
  assert(not ok, 'expected an error for a number sep')
end)
test('no globals created', function()
  for k in pairs(_G) do
    if not globals_before[k] then
      error('new global: ' .. tostring(k))
    end
  end
end)

print(string.format('%d/%d passed', total - failures, total))
os.exit(failures == 0 and 0 or 1)
