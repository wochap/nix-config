# Neovim Lua: trim trailing whitespace

Target: Neovim 0.12. Write `lua/trim.lua`, a module (`require('trim')`) with:

## `trim.trim_trailing(buf, first, last)` → number

- Removes trailing spaces and tabs from lines `first`..`last` (1-based, inclusive) of buffer `buf`.
  `buf = 0` means the current buffer. `first` defaults to 1, `last` defaults to the last line.
- Returns how many lines were changed.
- Lines that do not change must not be rewritten: if nothing changes, the buffer stays unmodified
  (`'modified'` remains off and `b:changedtick` does not change).
- Other whitespace (leading indentation, spaces inside the line) is kept.

## `trim.setup()`

Creates the user command `:TrimTrailing`. Without a range it trims the whole current buffer;
with a range (`:2,4TrimTrailing`) only those lines. Calling `setup()` twice must not fail.

Tests run headless: `nvim --headless --clean -l tests/run.lua` (the project root is on
`'runtimepath'`). Deprecated Neovim APIs are disabled in the tests (calling them raises an error).
The code must pass `stylua --check .` (config in `stylua.toml`) and `luacheck .`
(config in `.luacheckrc`).
