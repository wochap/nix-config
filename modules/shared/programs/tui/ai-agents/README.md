# ai-agents

## Tips

- Never continue or resume a large conversation after you've exited it. Doing so will consume a lot of tokens just to restore the context.

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
