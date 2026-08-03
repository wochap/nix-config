# ai-agents

## Post Install

```sh
# add playwright mcp
claude mcp add playwright --scope user -- \
    playwright-mcp \
    --executable-path /run/current-system/sw/bin/google-chrome-stable \
    --user-data-dir ~/.cache/playwright-mcp-profile
```

## Qwen

```sh
# codex with qwen, run it once
printf '%s' 'TOKEN_PLAN_API_KEY' | codex login --with-api-key
# this creates ~/.codex/auth.json
```
