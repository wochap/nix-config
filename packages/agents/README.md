# agents

One CLI over coding agent CLIs (only `claude` for now), for you and for
agents. On a TTY `run` shows live progress (rendered messages, tool lines,
cost); piped, it prints only the final answer. Sessions live in
`${XDG_STATE_HOME:-~/.local/state}/agents/sessions/`. Source:
`packages/agents/src/`. Agents learn it from the `agents` skill
(`~/.agents/skills/agents/SKILL.md`).

```sh
agents run "fix the failing test"            # live progress
agents run -q -C ~/repo "summarize the repo" # final answer only
agents run -r <id> "continue"                # resume headless
agents ls                                    # list sessions
agents watch                                 # follow the latest running session
agents attach <id>                           # take it over interactively
agents last <id>                             # last agent message
```

Env: `CLAUDE_FLAGS` (default `--permission-mode auto`), `CLAUDE_CMD` (default
`sessiontap claude`).

To add an agent, implement `Adapter` (`src/adapters/types.ts`, emits
normalized events) in `src/adapters/<name>.ts` and register it in
`src/adapters/index.ts`. Two prompts in `packages/agents/prompts/` do this
with agents:

```sh
# 1. in the agent CLI's source repo: writes <cli>_adapter_report.md there, prints its path
report=$(agents run -q -C ~/src/codex - < packages/agents/prompts/extract-adapter-info.md)
# 2. here: write the adapter from the report
cat packages/agents/prompts/write-adapter.md "$report" | agents run -
```
