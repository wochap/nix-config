# Neovim Lua: todo comments

Target: Neovim 0.12. Write `lua/todos.lua`, a module (`require('todos')`).

## Matching

A line contains a todo when a keyword appears followed immediately by `:` and the keyword is not
preceded by a letter, digit or `_` (`-- TODO: x` and `(FIXME: y)` match; `MYTODO: x`, `TODOS: x`,
`TODO x` do not). Keywords are case-sensitive and used literally. At most one todo per line: the
one starting at the smallest column. Default keywords: `{ 'TODO', 'FIXME', 'HACK' }`.

## API

- `M.namespace`: a namespace id from `nvim_create_namespace('todos')`.

- `M.setup(opts)`: `opts` is optional; `opts.keywords` replaces the default keyword list.
  Calling `setup` again replaces the previous configuration and must not duplicate anything.
  It does all of the following:
  - Defines highlight group `TodoKeyword` linked to `Todo`, without overriding a `TodoKeyword`
    definition the user made before `setup` was called.
  - Creates the autocmd group `todos` with autocmds that call `M.refresh(<buffer>)` on
    `BufEnter`, `BufWritePost`, `TextChanged` and `InsertLeave`.
  - Creates the user command `:TodoList`: replaces the current window's location list with one
    item per todo of the current buffer (`lnum` = line, `col` = 1-based byte column of the
    keyword, `text` = `"<KEYWORD>: <text>"`) and sets its title to `Todos`. It does not open a window.

- `M.scan(buf)` → list (in line order) of `{ lnum = <1-based line>, col = <1-based byte column of
  the keyword>, keyword = 'TODO', text = <rest of the line after the colon, with leading and
  trailing whitespace removed> }`. `buf = 0` or `nil` means the current buffer.

- `M.refresh(buf)` (`0`/`nil` = current buffer) replaces everything the module previously put in
  that buffer:
  - One extmark per todo in namespace `M.namespace` highlighting exactly the keyword with
    `hl_group = 'TodoKeyword'`.
  - One diagnostic per todo in namespace `M.namespace`: `lnum`/`col` 0-based start of the keyword,
    `end_col` its end, `source = 'todos'`, `message` = the todo text (the keyword itself if the
    text is empty), `severity` ERROR for `FIXME`, WARN for `HACK`, INFO for any other keyword.
  - Buffer-local normal-mode mappings `]t` (desc `Next todo`) and `[t` (desc `Previous todo`)
    that move the cursor to the start of the next / previous todo keyword, wrapping around the
    end / start of the buffer.

Tests run headless: `nvim --headless --clean -l tests/run.lua` (the project root is on
`'runtimepath'`). Deprecated Neovim APIs are disabled in the tests (calling them raises an error).
The code must pass `stylua --check .` (config in `stylua.toml`) and `luacheck .`
(config in `.luacheckrc`).
