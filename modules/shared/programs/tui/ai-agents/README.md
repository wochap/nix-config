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

To add an agent, implement `Adapter` (`adapters/types.ts`) in
`adapters/<name>.ts` and register it in `adapters/index.ts`.

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
