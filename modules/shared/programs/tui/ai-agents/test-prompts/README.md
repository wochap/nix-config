# llm-bench

Coding challenges to rank small models per language. `llm-bench` runs an agent
in a fix-until-green loop: run the agent, grade with `check.sh` (format, lint,
build, test), and on failure start a fresh session with the check output.

```sh
llm-bench list                                  # all challenges
llm-bench run -m omniroute/qwen3-4b zig          # zig challenges, pi agent, 5 iterations
llm-bench run -m omniroute/qwen3-4b -c -n 3 easy # inline cartridge, easy only
llm-bench rank                                  # leaderboard from results.tsv
```

Results go to `~/.cache/llm-bench/results.tsv`; each run's workdir, prompts,
agent output and check logs live under `~/.cache/llm-bench/runs/<stamp>/`.
Run with and without `-c` to measure what a cartridge adds.

## Challenge layout

```
challenges/<lang>/<level>-<slug>/
  PROMPT.md   task text sent to the model
  deps        nixpkgs attributes, one per line (toolchain, formatter, linter)
  check.sh    grader; run from the workdir inside `nix shell nixpkgs#<deps>`
  starter/    files copied into the workdir (stubs, project files)
  tests/      tests copied into the workdir; restored before every check
  protected   optional; starter files (lint/format/compiler configs) restored before every check
  solution/   reference solution files; never shown to the model
```

- `<lang>` matches a cartridge name (`../cartridge/skill/cartridges/<lang>.md`).
- `<level>` is `easy` or `hard`.
- The model sees `PROMPT.md`, `starter/`, `tests/` and `check.sh`.
  `check.sh`, `tests/` and `protected` files are restored before grading, so editing them does not help.

## check.sh contract

- `#!/usr/bin/env bash` and `set -uo pipefail`.
- Steps in order: format (check only), lint, build, test. Skip a step only when
  the language has no such tool.
- Print `==> <step>` before each step. Stop at the first failing step with `exit 1`.
- A format failure prints the command that fixes it (e.g. `run: gofmt -w .`).
- Only tools from `deps`, no network, deterministic, under 2 minutes once cached.

## Validate challenges

```sh
llm-bench validate          # every challenge: starter must fail, solution must pass
llm-bench validate go/hard  # filtered
```
