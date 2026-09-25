---
name: openspec-pipeline
description: Run OpenSpec changes end to end (apply, sync, archive, with commits) headless via the openspec-pipeline CLI, keeping your context small; handle or relay questions from its apply agent.
---

# openspec-pipeline

Use when the user wants one or more OpenSpec changes implemented, synced and
archived without doing each step yourself. Each step runs in its own agent
session, so none of the work enters your context. You only read one JSON line.

```sh
openspec-pipeline --json --on-input stop <change>... > "$out" 2> "$log"
openspec-pipeline --json --on-input auto <change>... > "$out" 2> "$log"
openspec-pipeline --json --on-input stop --resume <session> --answer "<reply>" <change>... > "$out" 2> "$log"
```

## How to run

- Run it yourself, in the background if your harness supports it (it takes
  minutes to hours). Do not wrap it in a subagent: the pipeline already
  isolates every step, and a subagent only adds cost and loses your context
  for answering questions.
- Always pass `--json` and `--on-input stop` or `auto`. Never use `ask`; it
  needs a TTY.
- Send stderr to a log file in your scratch or temp directory. Do not read
  the log unless the run failed and the JSON `reason` is not enough; then read
  only its tail.
- Pass the changes in the order the user gave. Add `--gate '<cmd>'` for the
  project's test or build command when the user wants checks before commits.
- Tell the user they can follow a step with `agents watch <id>` or take it
  over with `agents attach <id>`. Never run those two yourself.
- Do not edit the repository while the pipeline runs; it commits with
  `git add -A`.

## Pick a mode

- `stop` (default choice): the pipeline exits 3 at the first blocker. You
  decide who answers.
- `auto`: the user wants it to finish unattended. The apply agent resolves
  blockers by itself (`--auto-tries`, default 2), then stops like `stop`.

## Read the result

stdout is one line:
`{"status","done":[...],"change","step","session","reason","openTasks":[...],"message"}`.

- Exit 0, `status: done`: report the finished changes (`done`) and the new
  commits (`git log --oneline`).
- Exit 3, `status: needs_input`: `message` holds the apply agent's questions,
  `openTasks` the unchecked tasks.
  - You can answer from the user's instructions, the specs or the code: re-run
    with `--resume <session> --answer "<reply>"` and the same changes. State
    in your reply to the user what you decided.
  - The answer is a product decision, a secret, or a permission only the user
    can give: show the user the questions (short) and the session id, then
    re-run with their answer. The user can also run `agents attach <session>`
    to resolve it in the TUI; then re-run without `--resume`.
  - Only a few open tasks and no question: `--answer "Finish the remaining
    tasks."`.
- Exit 1, `status: failed`: show `reason`, `change` and `step`. A gate failure
  leaves the code uncommitted; fix it or tell the user, then re-run the same
  command. Re-running is always safe: finished steps are skipped.
