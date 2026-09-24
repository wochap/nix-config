# ai-agents

## Tips

- Never continue or resume a large conversation after you've exited it. Doing so will consume a lot of tokens just to restore the context.

## openspec-pipeline

Runs `apply -> sync -> archive` for OpenSpec changes, one fresh headless agent
session per step, committing between steps. Re-run the same command to resume
after an interruption. Source: `packages/openspec-pipeline/src/`.

```sh
openspec-pipeline export-formats-quality-config inspector-redesign
openspec-pipeline --archive-model claude-opus-5-5 --gate 'npm test' my-change
openspec-pipeline --help
```

Each step runs through the `agents` CLI (`packages/agents/`), claude only for
now. While a step runs, `ctrl+t` takes it over in the claude TUI, which
continues the step (`esc` stops it to steer); `ctrl+z`
inside the TUI detaches back to the progress view while it keeps working, and
`ctrl+t` attaches again. When the agent finishes while you are detached,
the step ends and the pipeline goes on. Exit the TUI yourself, then `c`
continues headless or `d` finishes the step. `agents ls` lists the step sessions.

## Post Install

### Claude

```sh
# add playwright-mcp
claude mcp add playwright --scope user -- \
    playwright-mcp \
    --executable-path /run/current-system/sw/bin/google-chrome-stable \
    --user-data-dir ~/.cache/playwright-mcp-profile

# add chrome-devtools-mcp
claude mcp add chrome-devtools --scope user -- \
    npx -y chrome-devtools-mcp@latest \
    --executablePath /run/current-system/sw/bin/google-chrome-stable \
    --isolated
```

### Codex

```sh
# enable hooks:
# run `codex`, open /hooks and trust the 3 entries (Codex then writes ~/.codex/config.toml)
```

## Qwen

```sh
# codex with qwen, run it once
printf '%s' 'TOKEN_PLAN_API_KEY' | codex login --with-api-key
# this creates ~/.codex/auth.json
```
