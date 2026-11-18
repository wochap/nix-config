You are in the source repository of a coding agent CLI (for example codex, pi,
opencode, gemini). Another agent will write an adapter for this CLI in a
wrapper tool called `agents`. It will NOT have access to this repository, so
your report is its only source. Research the code (and the installed CLI if it
is on PATH) and write a report of facts only.

## What the wrapper needs

The adapter must implement this contract (TypeScript, run by Bun):

```ts
type Event =
  | { type: "text"; text: string }        // assistant message (markdown)
  | { type: "tool"; label: string }       // short tool-call label, never the raw command
  | { type: "result"; result: string; costUsd?: number; durationMs?: number }
  | { type: "error"; message: string };

interface RunOptions {
  id: string;        // session id chosen by the wrapper (uuid)
  prompt: string;
  model: string;
  cwd: string;
  resume: boolean;   // true: continue session `id` with `prompt`
  rawLog: string;    // file path; adapter appends native output here
  onEvent(e: Event): void | Promise<void>;
}

interface Adapter {
  name: string;
  defaultModel: string;
  run(opts: RunOptions): Promise<{ result: string }>;   // headless, rejects on non-zero exit
  lastResponse(id: string): Promise<string | null>;     // last assistant text, incl. interactive turns
  takeOver(id: string, model: string, cwd: string): Promise<void>; // interactive resume
}
```

## Questions to answer

For each answer give the exact flag/field names, the source file and line
that proves it, and the CLI version or commit you checked.

1. **Binary and version**: executable name, how to print the version.
2. **Headless run**: exact argv to run one prompt non-interactively and exit.
   How the prompt is passed (argument, stdin, file). Does it ever wait for
   input or ask for approval in headless mode?
3. **Model**: flag to select the model, format of model names, the default
   model, and 2-3 current model ids.
4. **Permissions / sandbox**: flags that let it edit files and run commands
   without prompting. List the safe default and the "full auto" option.
5. **Session ids**:
   - Can the caller choose the session id up front (like `--session-id <uuid>`)?
   - If not, where does the id appear (first stream event, final event,
     stderr, a file) and its format.
   - Exact argv to resume a session headless with a new prompt. Does resume
     keep the same id or fork a new one?
   - Is lookup by id global or scoped to the working directory/project?
6. **Machine-readable output**: flag for JSON / JSONL streaming output. For
   each event type, give a real (trimmed) example line and its fields. Map
   them to the wrapper events:
   - assistant text  -> `text`
   - tool call (name, input, any human description field) -> `tool`
   - final answer, cost in USD, duration in ms -> `result`
   - errors (API error, max turns, aborted) -> `error`
   Note events that arrive as deltas/partials and how to get complete
   messages. Is stdout pure JSONL, or mixed with other output? What goes to
   stderr?
7. **Exit codes**: success, agent error, interrupted. Is a failed run still
   reported in the JSON stream?
8. **Transcripts on disk**: path pattern of saved sessions (with env vars that
   change it), file format, and how to find the last assistant text of a
   session by id, including turns made interactively.
9. **Interactive resume**: exact argv to open an existing session in the
   interactive TUI with a given model. Required cwd, if any.
10. **Signals**: behavior on SIGTERM/SIGINT in headless mode; does it leave
    child processes?
11. **Env vars and config** that change any of the above (config dir, API
    keys, telemetry, non-interactive switches).
12. **Gotchas**: anything that would break a wrapper (TTY detection, color
    codes in JSON mode, update prompts, first-run setup, trust prompts for
    new directories, output buffering).

If you can run the CLI, verify 2, 5, 6 and 8 with a tiny prompt (for example
"reply with the word pong") and paste the real output. Mark every answer as
**verified** (ran it), **from source** (read code) or **unknown**. Never guess;
write **unknown** instead.

## Output

Write the report to `<cli>_adapter_report.md` in the current directory, where
`<cli>` is the executable name in lowercase (e.g. `codex_adapter_report.md`).
Overwrite it if it exists. Do not change any other file.

The report is Markdown, headed `# <cli> adapter report`, one section per
question above in the same order, then a final section `## Suggested adapter`
with the argv for `run` (new and resume), `takeOver` and the event mapping as
a short table.

Reply with only the absolute path of the report file, nothing else.
