---
name: agenttap
description: Run a coding agent (claude, pi, agy) headless via the agenttap CLI and get only its final answer; resume or hand a session to the user.
disable-model-invocation: true
---

# agenttap

Use to delegate a self-contained task to another coding agent session, e.g. work
in another repo (`-C <dir>`) or a second opinion, without filling your context.

```sh
agenttap run -q "<prompt>"                 # stdout: final answer only; stderr: "session: <id>"
agenttap run --json "<prompt>"             # stdout: {"id","agent","model","result","costUsd","durationMs","status"}
agenttap run -q -C ~/repo -m claude-sonnet-5 -e high "<prompt>"
agenttap run -q -a pi "<prompt>"           # another agent (default: claude)
agenttap run -q -a agy "<prompt>"          # agy (default: gemini-4-hydrogen)
echo "<long prompt>" | agenttap run -q -   # prompt from stdin
agenttap run -q -r <id> "<follow-up>"      # continue a session headless
agenttap run -q --no-tools "<question>"    # answer only, no tools (pass again on -r)
agenttap last <id>                         # last message of a session
agenttap ls                                # sessions of the last 7 days, --full for all
```

- Agents: `claude` (default), `pi`, `agy` (default model `gemini-4-hydrogen`). `-m` defaults to the chosen agent's model.
  `-e` (low, medium, high, xhigh, max) defaults to the agent's own setting.
  `-r`, `last` take the session's own agent; no `-a` needed.
- Ids may be a unique prefix.
- Always pass `-q` or `--json`; the prompt must be self-contained (the agent has none of your context).
- `agenttap run` blocks until the agent finishes; exit code 1 means the agent failed.
- Tell the user the session id: they can follow it live with `agenttap watch <id>`
  or take it over with `agenttap attach <id>`.
- Never run `agenttap attach` or `agenttap watch` yourself; both are for the user's terminal.
- `agenttap serve` is a long-running OpenAI-compatible server for chat GUIs; never start it yourself.
- Taking over a running session (`ctrl+t` in the `run` view, `ctrl+z` to detach
  back) needs a person at a TTY. You never press these keys; with `-q` or
  piped stdin there are none.
