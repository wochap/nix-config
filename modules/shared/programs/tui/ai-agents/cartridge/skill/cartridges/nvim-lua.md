# nvim-lua cartridge — target: Neovim 0.12 (LuaJIT 2.1)

## Rules (DON'T → DO)
- DON'T `vim.api.nvim_set_keymap` → DO `vim.keymap.set(mode, lhs, rhs_or_fn, { desc = '...' })`
- DON'T pass `buffer = n` in keymap/autocmd opts (deprecated in 0.12) → DO pass `buf = n`
- DON'T `vim.cmd('autocmd ...')` / `augroup` strings → DO `nvim_create_augroup` + `nvim_create_autocmd`
- DON'T `require('lspconfig').x.setup{}` → DO `vim.lsp.config('x', { ... })` + `vim.lsp.enable('x')`
- DON'T `vim.lsp.get_active_clients()` / `vim.lsp.buf_get_clients()` → DO `vim.lsp.get_clients({ bufnr = 0 })`
- DON'T `vim.lsp.start_client()` → DO `vim.lsp.start()` (or `vim.lsp.enable`)
- DON'T `client.supports_method(m)` / `client.request(...)` → DO `client:supports_method(m)` / `client:request(...)` (colon)
- DON'T `vim.lsp.stop_client(id)` → DO `vim.lsp.get_client_by_id(id):stop()`
- DON'T `vim.lsp.buf.formatting()` → DO `vim.lsp.buf.format({ async = false })`
- DON'T `vim.lsp.with(handler, cfg)` → DO pass opts directly: `vim.lsp.buf.hover({ border = 'rounded' })` or set `vim.o.winborder`
- DON'T `vim.lsp.codelens.refresh()` → DO `vim.lsp.codelens.enable(true)`
- DON'T `vim.diagnostic.goto_next()` / `goto_prev()` → DO `vim.diagnostic.jump({ count = 1 })` / `{ count = -1 }`
- DON'T `vim.diagnostic.disable()` → DO `vim.diagnostic.enable(false)`
- DON'T `sign_define('DiagnosticSign...')` → DO `vim.diagnostic.config({ signs = { text = { [vim.diagnostic.severity.ERROR] = 'E' } } })`
- DON'T `vim.loop` → DO `vim.uv`
- DON'T `vim.highlight.*` → DO `vim.hl.*` (e.g. `vim.hl.on_yank()`, `vim.hl.range()`)
- DON'T `nvim_buf_add_highlight` → DO `vim.hl.range()` or `nvim_buf_set_extmark`
- DON'T `nvim_buf_set_option` / `nvim_win_set_option` / `nvim_set_option` → DO `vim.bo[buf].x`, `vim.wo[win].x`, `vim.o.x` or `nvim_set_option_value`
- DON'T `nvim_buf_get_option` → DO `vim.bo[buf].x` or `nvim_get_option_value('x', { buf = buf })`
- DON'T `vim.tbl_islist` → DO `vim.islist`; DON'T `vim.tbl_flatten` → DO `vim.iter(t):flatten():totable()`
- DON'T `vim.fn.jobstart` / `io.popen` for commands → DO `vim.system({ 'cmd', 'arg' }, { text = true })`
- DON'T `termopen()` → DO `vim.fn.jobstart(cmd, { term = true })`
- DON'T `vim.diff()` → DO `vim.text.diff()`
- DON'T `nvim_err_writeln` / `nvim_out_write` → DO `vim.notify(msg, vim.log.levels.ERROR)` or `nvim_echo`
- DON'T `vim.health.report_ok/warn/error` → DO `vim.health.ok/warn/error/start`
- DON'T `vim.treesitter.get_node_at_cursor()` / `parse_query` → DO `vim.treesitter.get_node()` / `vim.treesitter.query.parse()`
- DON'T `table.unpack` (nil in LuaJIT) → DO `unpack`

## Gotchas
- `vim.opt.x` returns an Option object; read with `vim.opt.x:get()`. Use `vim.o.x` to read/write plain values.
- `vim.opt` supports list/map ops: `vim.opt.shortmess:append('c')`, `vim.opt.listchars = { tab = '> ' }`.
- `vim.o` = global value, `vim.bo` = buffer-local, `vim.wo` = window-local, `vim.opt_local` = like `:setlocal`.
- Set `vim.g.mapleader` before any mapping or plugin load, or `<leader>` maps use the old leader.
- API calls are not allowed inside `vim.uv` callbacks ("E5560: must not be called in a fast event"); wrap with `vim.schedule`.
- `vim.system(...)` is async unless you call `:wait()`; its callback runs in a fast event (use `vim.schedule`).
- `vim.system` takes a list, not a shell string; for pipes use `{ 'sh', '-c', '...' }`.
- API indexes: lines are 0-based, end-exclusive (`nvim_buf_get_lines(0, 0, -1, false)`); cursor row is 1-based, col 0-based.
- `nvim_create_augroup(name, { clear = true })` prevents duplicate autocmds on re-source.
- Autocmd callback returning `true` deletes the autocmd.
- Diagnostics: `virtual_text` is off by default since 0.11; enable via `vim.diagnostic.config({ virtual_text = true })` or `virtual_lines = true`.
- `vim.diagnostic.jump` `float` opt is deprecated in 0.12; use `on_jump`.
- Default LSP maps exist: `grn` rename, `gra` code action, `grr` references, `gri` implementation, `grt` type definition, `gO` symbols, `K` hover, `<C-s>` signature help (insert).
- LSP configs can live in `lsp/<name>.lua` on 'runtimepath' (returning a table); `vim.lsp.config('*', {...})` sets defaults for all.
- `vim.lsp.enable` needs the server binary on PATH; check with `:checkhealth vim.lsp`.
- `vim.pack` (built-in plugin manager, new in 0.12) installs to `stdpath('data')/site/pack/core/opt`; lockfile `nvim-pack-lock.json` in config dir.
- `vim.fn.has('nvim-0.12') == 1` (returns number, not boolean; `0` is truthy in Lua).
- `vim.fn.*` returns Vimscript types: empty string/0 for "nothing", not nil.

## Correct API names
- `vim.api.nvim_create_user_command(name, fn, { nargs = '?', desc = '' })`; fn gets `opts.args`, `opts.fargs`, `opts.bang`.
- `vim.api.nvim_set_hl(0, 'Group', { fg = '#ffffff', bold = true, link = 'Other' })`; `nvim_get_hl(0, { name = 'Group' })`.
- `vim.lsp.completion.enable(true, client.id, buf, { autotrigger = true })`.
- `vim.lsp.inlay_hint.enable(true, { bufnr = buf })`, `vim.lsp.inlay_hint.is_enabled()`.
- `vim.lsp.foldexpr()`, `vim.treesitter.foldexpr()`, `vim.treesitter.start(buf, lang)`.
- `vim.fs.root(buf, { '.git' })`, `vim.fs.find`, `vim.fs.joinpath`, `vim.fs.dirname`, `vim.fs.basename`, `vim.fs.normalize`.
- `vim.uv.fs_stat(path)` (nil if missing), `vim.uv.cwd()`, `vim.uv.os_homedir()`, `vim.uv.new_timer()`.
- `vim.iter(t):filter(f):map(f):totable()`, `vim.tbl_deep_extend('force', a, b)`, `vim.tbl_get(t, 'a', 'b')`, `vim.tbl_contains`, `vim.list_extend`.
- `vim.split(s, sep, { plain = true, trimempty = true })`, `vim.trim`, `vim.startswith`, `vim.endswith`, `vim.inspect`.
- `vim.schedule(fn)`, `vim.schedule_wrap(fn)`, `vim.defer_fn(fn, ms)`, `vim.ui.select(items, opts, cb)`, `vim.ui.input(opts, cb)`.
- `vim.cmd.colorscheme('x')`, `vim.cmd('normal! gg')`, `vim.fn.stdpath('config' | 'data' | 'state' | 'cache')`.
- `vim.json.encode/decode`, `vim.base64.encode`, `vim.version()`, `vim.version.range('1.0')`.

## Idioms
```lua
vim.lsp.config('lua_ls', { cmd = { 'lua-language-server' }, filetypes = { 'lua' }, root_markers = { '.luarc.json', '.git' } })
vim.lsp.enable({ 'lua_ls', 'nixd' })
```
```lua
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('my.lsp', { clear = true }),
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    if client:supports_method('textDocument/formatting') then
      vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format({ bufnr = ev.buf }) end, { buf = ev.buf })
    end
  end,
})
```
```lua
vim.api.nvim_create_autocmd('TextYankPost', { callback = function() vim.hl.on_yank() end })
```
```lua
vim.pack.add({ 'https://github.com/user/plugin', { src = 'https://github.com/user/p2', version = 'main' } })
```
```lua
-- lazy.nvim spec (if used): opts → require(main).setup(opts)
return { 'user/plugin', event = 'VeryLazy', dependencies = { 'dep/x' }, opts = {}, keys = { { '<leader>x', '<cmd>Foo<cr>', desc = 'Foo' } } }
```

## Tooling
- Version: `nvim --version`; `:lua print(vim.version())`
- Health: `:checkhealth`, `:checkhealth vim.lsp`; LSP log: `:lua vim.cmd.edit(vim.lsp.log.get_filename())`
- Docs: `:help vim.lsp.config`, `:help deprecated` (lists replacements), `:help news`
- Plugins: `:lua vim.pack.update()` then `:write` to confirm; `:restart` reloads Nvim
- Headless test: `nvim --headless -c 'lua ...' -c q`; tests: `busted` / `mini.test` / `plenary`
- Format: `stylua .`; lint: `selene .` (std `vim`); LSP: `lua-language-server` with `runtime.version = 'LuaJIT'`
