# lua cartridge — target: Lua 5.1 / LuaJIT 2.1 (as in Neovim); 5.4 notes marked

## Rules (DON'T → DO)
- DON'T use `!=` → DO use `~=`
- DON'T use `!x`, `&&`, `||` → DO use `not x`, `and`, `or`
- DON'T use `+` to join strings → DO use `..` (`+` coerces to number and errors)
- DON'T declare globals by accident (`x = 1`) → DO write `local x = 1`
- DON'T start indexes at 0 → DO start at 1: `t[1]` is the first element, `for i = 1, #t`
- DON'T use `continue` (does not exist) → DO use `goto continue` with a `::continue::` label (LuaJIT, 5.2+)
- DON'T use `//` integer division in LuaJIT → DO use `math.floor(a / b)` (`//` is 5.3+)
- DON'T use `&`, `|`, `~`, `<<`, `>>` in LuaJIT → DO use `bit.band`, `bit.bor`, `bit.bxor`, `bit.lshift`, `bit.rshift` (operators are 5.3+)
- DON'T use `table.unpack` in LuaJIT → DO use `unpack` (5.2+ moved it to `table.unpack`); portable: `local unpack = table.unpack or unpack`
- DON'T use `table.pack` in LuaJIT → DO use `{ n = select('#', ...), ... }`
- DON'T use `utf8.*` in LuaJIT (missing) → DO use byte-level code or `vim.str_utfindex` in Neovim
- DON'T use `string.split` / `str:split` (not in stdlib) → DO use `gmatch`: `for p in s:gmatch('[^,]+')`
- DON'T use regex syntax (`\d`, `\s`, `|`, `{n}`) → DO use Lua patterns (`%d`, `%s`, no alternation, no counts)
- DON'T escape magic chars with `\` → DO escape with `%`: `%.`, `%-`, `%(`, `%%`
- DON'T use `#t` on tables with holes → DO track `n` yourself or use `select('#', ...)` for varargs
- DON'T use `ipairs` on sparse tables or maps → DO use `pairs` (unordered)
- DON'T expect `pairs` order → DO sort keys first if order matters
- DON'T `s:len()` for UTF-8 char count → DO know `#s` is bytes
- DON'T throw strings and parse them → DO `error({ code = 1 })` or `error(msg, 2)` (level 2 blames caller)

## Gotchas
- Only `nil` and `false` are falsy. `0` and `""` are truthy.
- `a and b or c` breaks when `b` is `false`/`nil`; use an `if` then.
- `#` on a table with `nil` holes is undefined (any border); trailing nils are dropped.
- Setting `t[k] = nil` removes the key; you cannot store `nil` in a table.
- `t.x` is `t["x"]`, not `t[x]`.
- `obj:method(a)` is `obj.method(obj, a)`; mixing `.` and `:` gives wrong `self`.
- `string.gsub` and `string.find` return multiple values; wrap in parens to keep one: `(s:gsub('a', 'b'))`.
- `string.find(s, '.')` treats `.` as a pattern; pass plain: `s:find('.', 1, true)`.
- `-` is a lazy quantifier in patterns: `'foo-bar'` does not match a literal dash; use `'foo%-bar'`.
- Pattern classes: `%a` letters, `%d` digits, `%s` space, `%w` alnum, `%p` punct, `%x` hex, `.` any; `%b()` balanced; `%f[%w]` frontier.
- `tostring(nil)` is `"nil"`; `..` with nil raises an error; guard with `tostring(x)` or `x or ''`.
- Numbers: 5.1/LuaJIT have only doubles. `7 / 2 == 3.5`, `10 / 2 == 5`. 5.3+ adds integers (`10 // 2 == 5`, `math.type`).
- `string.format('%d', 3.7)` truncates in LuaJIT; errors in 5.3+ (needs an integer-valued number).
- Varargs: `...` is not a table; `select('#', ...)` counts trailing nils, `#{...}` may not.
- Upvalues in loops: each iteration gets a fresh `local i`, so closures capture the right value.
- `goto` cannot jump into the scope of a local; put `::continue::` as the last statement of the loop body.
- `require 'a.b'` searches `a/b.lua`; modules are cached in `package.loaded`.
- Modules should `return M`; do not set globals from modules.
- `loadstring` (5.1) vs `load` with string (5.2+); `setfenv` is 5.1/LuaJIT only (5.2+ uses `_ENV`).
- 5.4: `<const>` and `<close>` local attributes; integer for-loops do not overflow; not in LuaJIT.

## Correct API names
- `string.format`, `string.rep`, `string.sub`, `string.byte`, `string.char`, `string.upper/lower`, `string.match`, `string.gmatch`, `string.gsub`, `string.find`.
- No `string.trim`, `string.startswith`, `string.split`: use `s:match('^%s*(.-)%s*$')`, `s:sub(1, #p) == p`.
- `table.insert(t, v)` / `table.insert(t, pos, v)`, `table.remove(t [, pos])`, `table.concat(t, sep)`, `table.sort(t, cmp)`.
- No `table.contains`, `table.keys`, `table.length`, `table.copy`: write a loop.
- `math.floor`, `math.ceil`, `math.huge`, `math.max`, `math.min`, `math.random`, `math.fmod`; no `math.round` (use `math.floor(x + 0.5)`).
- `tonumber(s)`, `tonumber(s, 16)`, `tostring(x)`, `type(x)`.
- `pcall(f, ...)` → `ok, err_or_result`; `xpcall(f, debug.traceback, ...)` (extra args work in LuaJIT and 5.2+).
- `os.time`, `os.date('%Y-%m-%d')`, `os.getenv`, `os.clock`, `io.open(path, 'r')` → `f:read('*a')` (5.1) / `'a'` (5.3+).

## Idioms
```lua
for i, v in ipairs(list) do
  if v == skip then goto continue end
  process(v)
  ::continue::
end
```
```lua
local function trim(s) return (s:gsub('^%s+', ''):gsub('%s+$', '')) end
local escaped = s:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%0')  -- escape for patterns
```
```lua
local M = {}
function M.setup(opts) opts = opts or {} end
return M
```
```lua
local f = assert(io.open(path, 'r')); local data = f:read('*a'); f:close()
```

## Tooling
- Format: `stylua .` (config `stylua.toml` / `.stylua.toml`); check: `stylua --check .`
- Lint: `selene .` (config `selene.toml`, `std = "lua51"` or `"vim"`) or `luacheck .`
- LSP: `lua-language-server`; set `runtime.version = "LuaJIT"` in `.luarc.json`
- Run: `luajit file.lua`, `lua5.1 file.lua`, `lua file.lua` (check `lua -v`)
- Test: `busted` (`describe`/`it`/`assert.are.same`)
