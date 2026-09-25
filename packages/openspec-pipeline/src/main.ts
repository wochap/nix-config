// openspec-pipeline — runs apply -> sync -> archive for each OpenSpec change,
// one fresh headless agent session per step, committing between steps:
//   apply   -> "feat: <change>"            (code only, never openspec/)
//   sync    -> "feat: spec sync <change>"  (openspec/specs only)
//   archive -> no commit
//
// After apply, the agent's last response is printed and tasks.md is checked:
//   - all tasks done, or only manual/smoke-test tasks open  -> continue
//   - otherwise, or when the agent needs input               -> --on-input:
//       ask:  1..max-open non-manual tasks open -> ask [y/i/q]; more, or the
//             agent needs input -> resume the apply session interactively;
//             on exit, check again (needs a TTY)
//       stop: exit 3 with a report; re-run with --resume/--answer to continue
//       auto: resume the apply session headless, telling it to decide by
//             itself, up to --auto-tries times, then stop
//
// Safe to re-run after a crash, power cut or network loss. Progress is read
// from git and the filesystem, never from a state file:
//   - openspec/changes/<c> missing        -> archived (or typo), skip
//   - commit "feat: spec sync <c>" exists -> run archive only
//   - commit "feat: <c>" exists           -> run sync, then archive
//   - no apply commit, tasks already done -> skip apply agent, commit code
//   - no apply commit, tasks open         -> run apply (told to resume if
//     uncommitted code changes exist from an interrupted run)
//
// Steps run through the agents CLI (agents.ts), claude only for now. On a
// TTY, Ctrl-T takes a running step over, Ctrl-Z inside it detaches back.
//
// Exit codes: 0 done, 1 failed or quit, 3 needs input (stop).

import { parseArgs } from "node:util";
import * as agents from "./agents";
import type { Step } from "./agents";
import { ask, bell, interactive, log, logToStderr, print, warn } from "./term";
import { changeExists, codeDirty, commit, hasCommit, readTasks, repoRoot, type Tasks } from "./repo";

const HELP = `Usage: openspec-pipeline [options] <change>...

Runs apply -> sync -> archive for each change, in the given order.
Re-run with the same arguments to resume after an interruption.

Options:
      --apply-model <m>     model for apply   (default: ${agents.defaultModel("apply")})
      --sync-model <m>      model for sync    (default: ${agents.defaultModel("sync")})
      --archive-model <m>   model for archive (default: ${agents.defaultModel("archive")})
      --apply-effort <e>    effort for apply   (default: ${agents.defaultEffort("apply")})
      --sync-effort <e>     effort for sync    (default: ${agents.defaultEffort("sync")})
      --archive-effort <e>  effort for archive (default: ${agents.defaultEffort("archive")})
                              low, medium, high, xhigh, max
      --max-open <n>        open tasks above this need attention (default: 5)
      --gate <cmd>          shell command that must pass after apply; repeatable
      --on-input <mode>     when apply needs attention (default: ask on a TTY, else stop)
                              ask   prompt you / hand you the session (needs a TTY)
                              stop  exit 3 with a report
                              auto  let the agent decide by itself, then stop
      --auto-tries <n>      auto: headless resumes before stopping (default: 2)
      --resume <id>         continue this apply session (from a stop report)
      --answer <text>       message for the --resume session (default: "Continue.")
      --json                logs to stderr, one JSON result line on stdout
  -h, --help

Exit codes: 0 done, 1 failed or quit, 3 needs input.

On a TTY each step is an agents session (claude): ctrl+t takes a running
step over, ctrl+z inside it detaches back. Sessions: agents ls`;

const STEPS: Step[] = ["apply", "sync", "archive"];
const STATUS_DONE = "PIPELINE_STATUS: DONE";
const STATUS_INPUT = "PIPELINE_STATUS: NEEDS_INPUT";
const NO_ASK = "Run non-interactively: never ask questions, pick sensible defaults and continue.";
const STATUS_LINE = `When finished, end your final message with exactly one line:
'${STATUS_DONE}' if nothing needs the user, or
'${STATUS_INPUT}' if you have questions, blockers, decisions for the user,
or a needed action was denied by permissions.`;
const AUTO_PROMPT = `No user is available. Resolve your open questions, blockers and decisions yourself:
pick the most sensible option, state each assumption in your final message, and finish the
remaining tasks. Leave manual smoke-test tasks unchecked. Use '${STATUS_INPUT}' only when you
truly cannot continue (for example a needed action was denied by permissions).
${STATUS_LINE}`;

const { values: opts, positionals: changes } = parseArgs({
  allowPositionals: true,
  options: {
    "apply-model": { type: "string" },
    "sync-model": { type: "string" },
    "archive-model": { type: "string" },
    "apply-effort": { type: "string" },
    "sync-effort": { type: "string" },
    "archive-effort": { type: "string" },
    "max-open": { type: "string", default: "5" },
    gate: { type: "string", multiple: true, default: [] },
    "on-input": { type: "string" },
    "auto-tries": { type: "string", default: "2" },
    resume: { type: "string" },
    answer: { type: "string" },
    json: { type: "boolean" },
    help: { type: "boolean", short: "h" },
  },
});

if (opts.help || changes.length === 0) {
  console.log(HELP);
  process.exit(opts.help ? 0 : 1);
}

if (opts.json) logToStderr();

// Final result; with --json printed as one line on stdout.
interface Result {
  status: "done" | "needs_input" | "failed";
  /** Changes that finished all steps (or were already archived) in this run. */
  done: string[];
  change?: string;
  step?: Step;
  session?: string;
  reason?: string;
  openTasks?: string[];
  /** Apply agent's last message: its questions or blockers. */
  message?: string;
}

const done: string[] = [];
// Where the run is, for failure reports.
const current: { change?: string; step?: Step } = {};

function finish(r: Omit<Result, "done">, code: number): never {
  const result: Result = { ...r, done };
  if (opts.json) console.log(JSON.stringify(result));
  process.exit(code);
}

// Expected failures print one line instead of a stack trace.
const fail = (err: unknown) => {
  const message = err instanceof Error ? err.message : String(err);
  warn(`error: ${message}`);
  finish({ status: "failed", change: current.change, step: current.step, reason: message }, 1);
};
process.on("uncaughtException", fail);
process.on("unhandledRejection", fail);

const tty = Boolean(process.stdin.isTTY && process.stdout.isTTY);
const onInput = opts["on-input"] ?? (tty ? "ask" : "stop");
if (!["ask", "stop", "auto"].includes(onInput)) throw new Error(`--on-input: unknown mode ${onInput}`);
if (onInput === "ask" && !tty) throw new Error("--on-input ask needs a TTY; use stop or auto");
if (opts.answer !== undefined && !opts.resume) throw new Error("--answer needs --resume");

const maxOpen = Number(opts["max-open"]);
const autoTries = Number(opts["auto-tries"]);
const models = {} as Record<Step, string>;
for (const step of STEPS) models[step] = opts[`${step}-model`] ?? agents.defaultModel(step);
const efforts = {} as Record<Step, string>;
for (const step of STEPS) efforts[step] = opts[`${step}-effort`] ?? agents.defaultEffort(step);

process.chdir(repoRoot());

async function runStep(step: Step, prompt: string, resume?: string) {
  log(`${step} (${models[step]}, ${efforts[step]})${resume ? ` resuming ${resume}` : ""}: ${prompt}`);
  const run = await agents.run(prompt, models[step], efforts[step], { resume, tty });
  log(`[${current.change}] ${step} session: ${run.sessionId}`);
  return run;
}

const stepPrompt = (step: Step, change: string, instructions: string) =>
  `${agents.invoke(step, change)} — ${instructions}`;

// Nothing open except manual checks.
const tasksDone = (t: Tasks) => t.other.length === 0 && t.open.length <= maxOpen;

// --resume applies to the first apply this run reaches: the one that stopped.
let pendingResume = opts.resume;

async function apply(change: string) {
  let tasks = readTasks(change);
  let run: { sessionId: string; result: string };

  if (pendingResume) {
    const id = pendingResume;
    pendingResume = undefined;
    run = await runStep("apply", `${opts.answer ?? "Continue."}\n\n${STATUS_LINE}`, id);
  } else {
    if (tasksDone(tasks)) {
      log(`[${change}] tasks already done (${tasks.open.length} manual open), skipping apply agent`);
      return;
    }

    let resumeNote = "";
    if (codeDirty()) {
      warn(`[${change}] uncommitted code changes found, resuming an interrupted apply`);
      resumeNote =
        "A previous run of this apply was interrupted. Some tasks may already be implemented in the " +
        "uncommitted changes; check them against tasks.md, fix task checkboxes if needed, then continue with the rest.\n";
    }

    run = await runStep(
      "apply",
      stepPrompt(
        "apply",
        change,
        `Implement all tasks. Leave manual smoke-test tasks unchecked. ${NO_ASK}\n${resumeNote}${STATUS_LINE}`,
      ),
    );
  }

  const { sessionId } = run;
  let fallback = run.result;
  let tookOver = false;
  let tries = 0;

  while (true) {
    const resp = (await agents.last(sessionId)) ?? fallback;
    log(`[${change}] apply agent last response:`);
    print(resp);

    tasks = readTasks(change);
    const needsInput = resp.includes(STATUS_INPUT);
    log(`[${change}] open tasks: ${tasks.open.length} (${tasks.other.length} non-manual), needs input: ${needsInput}`);
    if (tasks.open.length) print(tasks.open.join("\n"));

    if (!needsInput && tasksDone(tasks)) return;

    if (onInput === "auto" && tries < autoTries) {
      tries++;
      warn(`[${change}] needs attention, letting the agent decide (${tries}/${autoTries})`);
      fallback = (await runStep("apply", AUTO_PROMPT, sessionId)).result;
      continue;
    }

    if (onInput !== "ask") {
      const reason = needsInput ? "agent needs input" : `${tasks.other.length} non-manual task(s) open`;
      warn(`[${change}] ${reason}; continue with: --resume ${sessionId} --answer "<reply>"`);
      finish(
        { status: "needs_input", change, step: "apply", session: sessionId, reason, openTasks: tasks.open, message: resp },
        3,
      );
    }

    let answer: "y" | "i" | "q";
    if (!needsInput && tasks.open.length <= maxOpen) {
      answer = await ask(`[${change}] ${tasks.other.length} non-manual task(s) open. [y]continue [i]nteract [q]uit:`, ["y", "i", "q"]);
    } else if (!tookOver) {
      answer = "i"; // first time: hand over directly
    } else {
      answer = await ask(`[${change}] still needs attention after your session. [y]continue [i]nteract [q]uit:`, ["y", "i", "q"]);
    }

    if (answer === "y") return;
    if (answer === "q") {
      warn(`stopped at ${change} (session ${sessionId})`);
      finish({ status: "failed", change, step: "apply", session: sessionId, reason: "quit" }, 1);
    }
    warn(`taking over apply session ${sessionId} — resolve it, then exit the agent to re-check`);
    bell();
    await interactive(() => agents.attach(sessionId));
    tookOver = true;
    fallback = "";
  }
}

function gate() {
  for (const cmd of opts.gate) {
    log(`gate: ${cmd}`);
    // With --json, stdout is reserved for the result.
    const p = Bun.spawnSync(["sh", "-c", cmd], { stdin: "ignore", stdout: opts.json ? "pipe" : "inherit", stderr: "inherit" });
    if (opts.json) print(p.stdout.toString());
    if (p.exitCode !== 0) throw new Error(`gate failed: ${cmd}`);
  }
}

function commitStep(message: string, paths: string[]) {
  log(commit(message, paths) ? `committed: ${message}` : `nothing to commit for: ${message}`);
}

for (const change of changes) {
  current.change = change;
  current.step = undefined;
  if (!changeExists(change)) {
    warn(`skip ${change}: openspec/changes/${change} not found (typo or already archived?)`);
    done.push(change);
    continue;
  }

  if (hasCommit(`feat: spec sync ${change}`)) {
    log(`[${change}] apply and sync already committed, resuming at archive`);
  } else {
    if (hasCommit(`feat: ${change}`)) {
      log(`[${change}] apply already committed, resuming at sync`);
    } else {
      current.step = "apply";
      log(`[${change}] apply`);
      await apply(change);
      gate();
      commitStep(`feat: ${change}`, [".", ":!openspec"]);
    }

    current.step = "sync";
    log(`[${change}] sync`);
    await runStep("sync", stepPrompt("sync", change, NO_ASK));
    commitStep(`feat: spec sync ${change}`, ["openspec/specs"]);
  }

  current.step = "archive";
  log(`[${change}] archive`);
  await runStep("archive", stepPrompt("archive", change, `Archive now. Incomplete tasks are fine; specs are already synced. ${NO_ASK}`));
  done.push(change);
}

log("done");
finish({ status: "done" }, 0);
