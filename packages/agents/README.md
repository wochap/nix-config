# agents

One CLI over coding agent CLIs (`claude`, `pi`), for you and for agents. On
a TTY `run` shows live progress (rendered messages, tool lines, cost); piped,
it prints only the final answer. Sessions live in
`${XDG_STATE_HOME:-~/.local/state}/agents/sessions/`. Source:
`packages/agents/src/`. Agents learn it from the `agents` skill
(`~/.agents/skills/agents/SKILL.md`).

```sh
agents run "fix the failing test"            # live progress, claude
agents run -a pi "fix the failing test"      # pi, its default model
agents run -a pi -m omniroute/desktop-free "fix the failing test"
agents run -q -C ~/repo "summarize the repo" # final answer only
agents run -r <id> "continue"                # resume headless
agents ls                                    # list sessions
agents watch                                 # follow the latest running session
agents attach <id>                           # take it over interactively
agents last <id>                             # last agent message
```

Take over a running session from its `run` view: `ctrl+t` stops the headless
run and resumes the same session in the agent's TUI, which starts by
continuing the interrupted task (`esc` there stops it to steer). Inside the TUI, `ctrl+z`
detaches back to the progress view while the TUI keeps working (it runs under
`dtach`); the view then follows what the TUI does. `ctrl+t` attaches again. When the agent finishes its
turn while you are detached, the TUI is closed and the run ends with its
last message, like a headless run. When you exit the TUI yourself, pick
`c` to continue headless or `d` to finish with its last message. `--json`
shows progress (and takes the keys) on stderr when stderr is a TTY or with
`--verbose`, so a script can read the JSON while you watch.

Pick the agent with `-a/--agent` (`claude` or `pi`, default `claude`); `-m`
defaults to that agent's model. Resumed runs (`-r`), `attach` and `last` use
the session's own agent, so they need no `-a`.

`-e/--effort` (`low`, `medium`, `high`, `xhigh`, `max`) maps to the agent's
own flag: `--effort` for claude, `--thinking` for pi. Unset, the agent uses
its own setting. The session keeps it for `-r` and `attach`.

Env: `CLAUDE_FLAGS` (default `--permission-mode auto`), `CLAUDE_CMD` (default
`sessiontap claude`), `PI_FLAGS` (default none; `--approve` trusts
project-local files), `PI_CMD` (default `sessiontap pi`), `AGENTS_DTACH`
(dtach binary, set by the package; default `dtach` on PATH).

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

## Use from an agent

`skill/SKILL.md` teaches an agent to delegate a task with `agents run` and read
only the final answer. It is linked into `~/.claude/skills` and
`~/.pi/agent/skills` when `_custom.programs.ai-agents.enableSkills` is on. The
skill sets `disable-model-invocation: true`, so it never enters the agent's
context until you call it:

```text
/agents <task>          # Claude Code
/skill:agents <task>    # pi
```

Name the agent, model or directory in the task if needed, e.g.
`/agents ask pi in ~/src/foo why the build fails`.
