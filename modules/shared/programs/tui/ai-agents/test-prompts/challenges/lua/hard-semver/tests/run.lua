package.path = './?.lua;' .. package.path

local failures, total = 0, 0

local function show(v)
  if type(v) == 'table' then
    local keys = {}
    for k in pairs(v) do
      keys[#keys + 1] = tostring(k)
    end
    table.sort(keys)
    local out = {}
    for _, k in ipairs(keys) do
      local val = v[k] ~= nil and v[k] or v[tonumber(k)]
      out[#out + 1] = k .. '=' .. show(val)
    end
    return '{' .. table.concat(out, ',') .. '}'
  elseif type(v) == 'string' then
    return string.format('%q', v)
  end
  return tostring(v)
end

local function deep_eq(a, b)
  if type(a) ~= type(b) then
    return false
  end
  if type(a) ~= 'table' then
    return a == b
  end
  for k, v in pairs(a) do
    if not deep_eq(v, b[k]) then
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

local ok_load, semver = pcall(require, 'semver')
if not ok_load then
  print('FAIL require semver: ' .. tostring(semver))
  os.exit(1)
end

local function check(cond, msg)
  if not cond then
    error(msg, 2)
  end
end

test('parse full version', function()
  local got = semver.parse('1.2.3-alpha.1+001.sha-5')
  local want = {
    major = 1,
    minor = 2,
    patch = 3,
    prerelease = { 'alpha', 1 },
    build = { '001', 'sha-5' },
  }
  check(deep_eq(got, want), 'got ' .. show(got))
end)

test('parse plain version', function()
  local got = semver.parse('10.20.30')
  local want = { major = 10, minor = 20, patch = 30, prerelease = {}, build = {} }
  check(deep_eq(got, want), 'got ' .. show(got))
end)

test('parse prerelease with dashes and zero', function()
  local got = semver.parse('0.0.0-x-y.0.z--')
  check(got and deep_eq(got.prerelease, { 'x-y', 0, 'z--' }), 'got ' .. show(got))
end)

test('parse build only', function()
  local got = semver.parse('1.0.0+20130313144700')
  check(got and deep_eq(got.build, { '20130313144700' }), 'got ' .. show(got))
  check(got and deep_eq(got.prerelease, {}), 'prerelease should be empty')
end)

test('parse rejects invalid versions', function()
  local bad = {
    '',
    '1',
    '1.2',
    '1.2.3.4',
    'v1.2.3',
    ' 1.2.3',
    '1.2.3 ',
    '01.2.3',
    '1.02.3',
    '1.2.03',
    '1.2.3-',
    '1.2.3+',
    '1.2.3-01',
    '1.2.3-a..b',
    '1.2.3-a.',
    '1.2.3-a_b',
    '1.2.3+a..b',
    '1.2.3+a+b',
    '-1.2.3',
    '1.2.x',
    'a.b.c',
  }
  for _, s in ipairs(bad) do
    local v, err = semver.parse(s)
    check(v == nil, 'expected nil for ' .. string.format('%q', s) .. ', got ' .. show(v))
    check(type(err) == 'string', 'expected an error message for ' .. string.format('%q', s))
  end
  local v, err = semver.parse(nil)
  check(v == nil and type(err) == 'string', 'parse(nil) should return nil, msg')
end)

test('parse accepts leading zeros in build', function()
  check(semver.parse('1.2.3+0001') ~= nil, '1.2.3+0001 is valid')
  check(semver.parse('1.2.3-0a') ~= nil, '1.2.3-0a is valid (not numeric)')
end)

test('compare core parts numerically', function()
  check(semver.compare('1.0.0', '1.0.0') == 0, '1.0.0 == 1.0.0')
  check(semver.compare('1.0.0', '2.0.0') == -1, '1.0.0 < 2.0.0')
  check(semver.compare('2.0.0', '1.9.9') == 1, '2.0.0 > 1.9.9')
  check(semver.compare('1.10.0', '1.9.0') == 1, '1.10.0 > 1.9.0 (numeric, not string)')
  check(semver.compare('1.0.10', '1.0.9') == 1, '1.0.10 > 1.0.9')
end)

test('compare prerelease precedence chain', function()
  local chain = {
    '1.0.0-alpha',
    '1.0.0-alpha.1',
    '1.0.0-alpha.beta',
    '1.0.0-beta',
    '1.0.0-beta.2',
    '1.0.0-beta.11',
    '1.0.0-rc.1',
    '1.0.0',
  }
  for i = 1, #chain do
    for j = 1, #chain do
      local want = i < j and -1 or (i > j and 1 or 0)
      local got = semver.compare(chain[i], chain[j])
      check(
        got == want,
        ('compare(%s, %s) = %s, want %d'):format(chain[i], chain[j], tostring(got), want)
      )
    end
  end
end)

test('compare ignores build metadata', function()
  check(semver.compare('1.0.0+a', '1.0.0+b') == 0, 'builds are ignored')
  check(semver.compare('1.0.0-rc.1+x', '1.0.0-rc.1') == 0, 'builds are ignored with prerelease')
end)

test('compare numeric ids are lower than alphanumeric', function()
  check(semver.compare('1.0.0-1', '1.0.0-a') == -1, '1 < a')
  check(semver.compare('1.0.0-A', '1.0.0-a') == -1, 'ASCII: A < a')
  check(semver.compare('1.0.0-9', '1.0.0-10') == -1, '9 < 10 numerically')
end)

test('compare raises on invalid', function()
  check(not pcall(semver.compare, '1.0', '1.0.0'), 'expected error')
  check(not pcall(semver.compare, '1.0.0', 'x'), 'expected error')
end)

local function sat(v, r, want)
  local ok, got = pcall(semver.satisfies, v, r)
  if not ok then
    error(('satisfies(%q, %q) raised: %s'):format(v, r, tostring(got)), 2)
  end
  if got ~= want then
    error(('satisfies(%q, %q) = %s, want %s'):format(v, r, tostring(got), tostring(want)), 2)
  end
end

test('satisfies exact and operators', function()
  sat('1.2.3', '1.2.3', true)
  sat('1.2.3', '=1.2.3', true)
  sat('1.2.4', '1.2.3', false)
  sat('1.2.3+build', '1.2.3', true)
  sat('1.2.3', '>1.2.2', true)
  sat('1.2.3', '>1.2.3', false)
  sat('1.2.3', '>=1.2.3', true)
  sat('1.2.3', '<1.2.3', false)
  sat('1.2.3', '<=1.2.3', true)
  sat('0.9.9', '<1.0.0', true)
end)

test('satisfies sets (AND)', function()
  sat('1.5.0', '>=1.0.0 <2.0.0', true)
  sat('2.0.0', '>=1.0.0 <2.0.0', false)
  sat('1.5.0', '  >=1.0.0    <2.0.0  ', true)
  sat('0.5.0', '>=1.0.0 <2.0.0', false)
end)

test('satisfies alternatives (OR)', function()
  sat('3.1.0', '<2.0.0 || >=3.0.0 <4.0.0', true)
  sat('2.5.0', '<2.0.0 || >=3.0.0 <4.0.0', false)
  sat('1.0.0', '<2.0.0||>=3.0.0', true)
  sat('5.0.0', '1.0.0 || 2.0.0 || 5.0.0', true)
end)

test('satisfies any', function()
  sat('1.2.3', '*', true)
  sat('0.0.0', '', true)
  sat('9.9.9', '1.0.0 || *', true)
end)

test('satisfies tilde', function()
  sat('1.2.3', '~1.2.3', true)
  sat('1.2.9', '~1.2.3', true)
  sat('1.3.0', '~1.2.3', false)
  sat('1.2.2', '~1.2.3', false)
  sat('0.2.5', '~0.2.3', true)
end)

test('satisfies caret', function()
  sat('1.4.0', '^1.2.3', true)
  sat('1.2.3', '^1.2.3', true)
  sat('2.0.0', '^1.2.3', false)
  sat('1.2.2', '^1.2.3', false)
  sat('0.2.9', '^0.2.3', true)
  sat('0.3.0', '^0.2.3', false)
  sat('0.0.3', '^0.0.3', true)
  sat('0.0.4', '^0.0.3', false)
  sat('0.1.0', '^0.0.3', false)
end)

test('satisfies prerelease rule', function()
  sat('1.2.3-beta.2', '>=1.2.3-beta.1', true)
  sat('1.2.4-beta', '>=1.2.3-beta.1', false)
  sat('1.2.4', '>=1.2.3-beta.1', true)
  sat('2.0.0-rc.1', '^1.0.0', false)
  sat('1.5.0-rc.1', '^1.0.0', false)
  sat('1.0.0-rc.2', '^1.0.0-rc.1', true)
  sat('1.0.1-rc.2', '^1.0.0-rc.1', false)
  sat('1.0.0-rc.1', '1.0.0-rc.1', true)
  sat('1.0.0-rc.1', '*', false)
  sat('1.2.3-alpha', '<1.2.3', false)
  sat('1.2.3-alpha', '<1.2.3 || >=1.2.3-alpha', true)
  sat('1.2.3-alpha', '>=1.2.3-alpha <1.2.3', true)
end)

test('satisfies invalid version is false', function()
  sat('1.2', '*', false)
  sat('v1.2.3', '>=1.0.0', false)
end)

test('satisfies invalid range raises', function()
  local bad = { '>>1.0.0', '~>1.0.0', '1.0', '>=1.0.0 <x', '!1.0.0', '=>1.0.0' }
  for _, r in ipairs(bad) do
    local ok, err = pcall(semver.satisfies, '1.0.0', r)
    check(not ok, 'expected error for range ' .. string.format('%q', r))
    check(
      tostring(err):find('invalid range', 1, true),
      'error should contain "invalid range": ' .. tostring(err)
    )
  end
  local ok = pcall(semver.satisfies, '1.0.0', nil)
  check(not ok, 'expected error for nil range')
end)

test('large numbers', function()
  check(semver.compare('2147483647.0.0', '2147483646.99.99') == 1, 'large majors')
  sat('1.0.2147483647', '^1.0.0', true)
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
