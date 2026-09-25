# openspec-pipeline

Runs `apply -> sync -> archive` for OpenSpec changes, one fresh headless agent
session per step, committing between steps. Works for you on a terminal and
for agents headless. Source: `packages/openspec-pipeline/src/`. Agents learn
it from the `openspec-pipeline` skill (`skill/SKILL.md`, install to
`~/.agents/skills/openspec-pipeline/SKILL.md`).

```sh
openspec-pipeline export-formats-quality-config inspector-redesign
openspec-pipeline --archive-model claude-opus-5-5 --gate 'npm test' my-change
openspec-pipeline --help
```

## Steps

| Step    | Commit                     | Paths                  |
| ------- | -------------------------- | ---------------------- |
| apply   | `feat: <change>`           | everything but `openspec/` |
| sync    | `feat: spec sync <change>` | `openspec/specs`       |
| archive | none                       |                        |

After apply, `--gate <cmd>` commands (repeatable) must pass before the commit.

Re-run the same command to resume after a crash, power cut or network loss.
Progress comes from git and the filesystem, never from a state file: an
existing `feat: spec sync <c>` commit skips to archive, an existing
`feat: <c>` commit skips to sync, a missing `openspec/changes/<c>` means
already archived. Uncommitted code from an interrupted apply is handed to the
next apply agent to check and continue.

## When apply needs attention

The apply agent ends with `PIPELINE_STATUS: DONE` or
`PIPELINE_STATUS: NEEDS_INPUT`. The pipeline then reads `tasks.md`. Open tasks
that mention `manual`, `smoke` or `visually` never block. Apply needs
attention when the agent asks for input, when non-manual tasks stay open, or
when more than `--max-open` (default 5) tasks stay open. `--on-input` picks
what happens:

- `ask` (default on a TTY): up to `--max-open` non-manual tasks open, it asks
  `[y]continue [i]nteract [q]uit`. More, or the agent needs input, it hands
  you the apply session in the claude TUI. Exit the TUI to re-check.
- `stop` (default without a TTY): exits 3 with a report (session id, open
  tasks, the agent's last message). Continue with `--resume <id> --answer
  "<reply>"` and the same changes.
- `auto`: resumes the apply session headless and tells the agent to decide by
  itself, up to `--auto-tries` times (default 2), then acts like `stop`.

```sh
openspec-pipeline --on-input stop a b c          # exit 3 at the first blocker
openspec-pipeline --resume 1f3c --answer "use postgres" a b c
openspec-pipeline --on-input auto --json a b c 2>pipeline.log
```

## Headless and `--json`

Without a TTY, steps get no stdin and no live progress: `agents` prints only
`session: <id>` to stderr. `--json` moves the logs to stderr and prints one
line on stdout:

```json
{"status":"needs_input","done":["a"],"change":"b","step":"apply","session":"1f3c...",
 "reason":"agent needs input","openTasks":["- [ ] 2.1 ..."],"message":"Which DB? ..."}
```

`status` is `done`, `needs_input` or `failed` (with `reason`). `done` lists
the changes finished in this run. Exit codes: 0 done, 1 failed or quit, 3
needs input.

## Takeover

Each step runs through the `agents` CLI (`packages/agents/`), claude only for
now. On a TTY, `ctrl+t` takes a running step over in the claude TUI, which
continues the step (`esc` stops it to steer). `ctrl+z` inside the TUI detaches
back to the progress view while it keeps working; `ctrl+t` attaches again.
When the agent finishes while you are detached, the step ends and the pipeline
goes on. Exit the TUI yourself, then `c` continues headless or `d` finishes
the step. `agents ls` lists the step sessions. For a headless run, follow a
step with `agents watch <id>` or take it over with `agents attach <id>` from
another terminal.

## Models

| Step    | Default               | Flag              |
| ------- | --------------------- | ----------------- |
| apply   | `claude-opus-5-5[1m]` | `--apply-model`   |
| sync    | `claude-opus-5-5[1m]` | `--sync-model`    |
| archive | `claude-sonnet-5`     | `--archive-model` |

Env: `AGENTS_CMD` (agents binary, set by the package).
