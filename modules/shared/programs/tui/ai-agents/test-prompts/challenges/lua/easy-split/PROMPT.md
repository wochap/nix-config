# Lua: split

Runtime: LuaJIT 2.1 (`luajit`, Lua 5.1 semantics).

Write `split.lua`, a module used as:

```lua
local split = require('split').split
local parts = split(s, sep)
```

- `s` is a string, `sep` is a non-empty string used literally (characters like `.` `%` `-` `[` `(`
  have no special meaning).
- Returns a new array (sequence) with the pieces of `s` between occurrences of `sep`, scanning left
  to right without overlaps. Empty pieces are kept.
- `split('', ',')` returns `{ '' }`.
- If `sep` is not a string or is empty, raise an error whose message contains `sep`.
- The module must not create global variables.

Examples:

```lua
split('a,b,c', ',')    --> { 'a', 'b', 'c' }
split('a,,b,', ',')    --> { 'a', '', 'b', '' }
split('1.2.3', '.')    --> { '1', '2', '3' }
split('a::b:c', '::')  --> { 'a', 'b:c' }
split('abc', ',')      --> { 'abc' }
```

Tests: `luajit tests/run.lua`. The code must pass `stylua --check .` (config in `stylua.toml`)
and `luacheck .` (config in `.luacheckrc`).
