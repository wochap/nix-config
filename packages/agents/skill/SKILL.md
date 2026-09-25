---
name: agents
description: Run a coding agent (claude, pi) headless via the agents CLI and get only its final answer; resume or hand a session to the user.
disable-model-invocation: true
---

# agents

Use to delegate a self-contained task to another coding agent session, e.g. work
in another repo (`-C <dir>`) or a second opinion, without filling your context.

```sh
agents run -q "<prompt>"                 # stdout: final answer only; stderr: "session: <id>"
agents run --json "<prompt>"             # stdout: {"id","agent","model","result","costUsd","durationMs","status"}
agents run -q -C ~/repo -m claude-sonnet-5 "<prompt>"
agents run -q -a pi "<prompt>"           # another agent (default: claude)
echo "<long prompt>" | agents run -q -   # prompt from stdin
agents run -q -r <id> "<follow-up>"      # continue a session headless
agents last <id>                         # last message of a session
agents ls                                # list sessions
```

- Agents: `claude` (default), `pi`. `-m` defaults to the chosen agent's model.
  `-r`, `last` take the session's own agent; no `-a` needed.
- Ids may be a unique prefix.
- Always pass `-q` or `--json`; the prompt must be self-contained (the agent has none of your context).
- `agents run` blocks until the agent finishes; exit code 1 means the agent failed.
- Tell the user the session id: they can follow it live with `agents watch <id>`
  or take it over with `agents attach <id>`.
- Never run `agents attach` or `agents watch` yourself; both are for the user's terminal.
- Taking over a running session (`ctrl+t` in the `run` view, `ctrl+z` to detach
  back) needs a person at a TTY. You never press these keys; with `-q` or
  piped stdin there are none.
