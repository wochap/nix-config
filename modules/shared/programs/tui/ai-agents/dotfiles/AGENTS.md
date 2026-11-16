## Environment & Tooling
- **NixOS & Flakes**: Assume project tools are not on global `PATH`. Check the repo root and target subproject folder (e.g., `web/`, `desktop/`, `mobile/`) for `README.md` and `flake.nix` (`devShells`), then wrap commands in the appropriate Nix shell:
  - **Default shell**: `nix develop -c sh -c "<cmd>"`
  - **Named shell**: `nix develop .#<shell> -c sh -c "<cmd>"`
  - **Subfolder flake**: `nix develop ./<dir> -c sh -c "<cmd>"`

## Communication & Workflow
- never add co-authored message commits
- when asking a question, ideally provide options and state your recommendation.

## Refactoring & Technical Debt Prevention
- **Stop and Ask on Code Smells (Propose-Before-Implementing)**: Never blindly bolt new `if/else` branches, boolean flags, or wrapper functions onto convoluted existing code just because it is the safest additive path. If implementing a feature cleanly requires modifying or deleting messy existing code, **pause before writing code** and propose options:
  - **Option A (Additive Patch)**: The minimal change and why it adds technical debt.
  - **Option B (Refactor + Clean Implementation)**: What existing code should be deleted, replaced, or restructured first so the new feature fits naturally.
  - Explicitly state your recommendation (preferring Option B whenever it prevents spaghetti code).
- **Favor Deletion Over Compat Shims**: When a refactor is approved, delete obsolete functions, unused parameters, and dead branches outright. Never comment out old code or leave backwards-compatibility wrappers unless explicitly requested.

## Architecture & Unix Philosophy
- **Do One Thing Well**: Write small, focused modules and functions with a single responsibility. If a function requires "and" to describe what it does, split it.
- **Composable Interfaces**: Design functions and CLI commands around clean, predictable inputs and outputs (data in, data out) with minimal hidden state or side effects.
- **Pragmatic DRY (Rule of Three)**: Eliminate duplicated business logic and knowledge, but avoid premature abstraction. Prefer clear, straightforward duplication over complex, tightly-coupled helper abstractions until a pattern repeats at least three times (YAGNI).
- **Fail Fast & Loudly**: Never swallow exceptions (`pass` in `except` blocks) or return silent fallback values that mask broken state. Validate inputs at system boundaries and raise explicit, actionable errors immediately.
- **Explicit Over Implicit**: Avoid hidden global state, magic configuration defaults, or deep inheritance hierarchies. Pass dependencies and configuration explicitly.

## Verification & Testing
- **Diff-Scoped Verification**: Apply the verification rules below strictly to code paths, external integrations, and CLI commands that you **add or modify** in the current task. Assume pre-existing, untouched integrations already work—do not write new tests or run manual CLI checks for unchanged legacy code.
- **No Mock-Only Verification (On Touched Code)**: When adding or modifying logic that calls subprocesses or external tools (FFmpeg, DB, APIs), never rely solely on unit tests that mock the execution or only assert generated command strings. String assertions verify syntax formatting, not external tool execution.
- **Mandatory Unmocked Smoke Tests**: When adding or modifying an external tool integration (e.g., FFmpeg arguments, filters, or pipelines), ensure at least one unmocked integration test covers the changed path using fast synthetic fixtures (e.g., 1-second synthetic video via `lavfi`) to prove the tool accepts the command and exits `0`.
- **Manual CLI Verification Before Closing Tasks**: When your changes affect a CLI command or its underlying execution path, run that specific CLI command in the terminal with sample or real data before declaring the task done. Passing `pytest` alone is not sufficient for modified CLI workflows.

