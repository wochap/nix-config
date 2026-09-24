// openspec-pipeline — runs apply -> sync -> archive for each OpenSpec change,
// one fresh headless agent session per step, committing between steps:
//   apply   -> "feat: <change>"            (code only, never openspec/)
//   sync    -> "feat: spec sync <change>"  (openspec/specs only)
//   archive -> no commit
//
// After apply, the agent's last response is printed and tasks.md is checked:
//   - all tasks done, or only manual/smoke-test tasks open  -> continue
//   - 1..max-open non-manual tasks open                     -> ask [y/i/q]
//   - more than max-open tasks open, or agent needs input   -> resume the
//     apply session interactively; on exit, check again
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
// Steps run through the agents CLI (agents.ts), claude only for now. Ctrl-T
// takes a running step over, Ctrl-Z inside it detaches back.

import { parseArgs } from "node:util";
import * as agents from "./agents";
import type { Step } from "./agents";
import { ask, bell, interactive, log, warn } from "./term";
import { changeExists, codeDirty, commit, hasCommit, readTasks, repoRoot, type Tasks } from "./repo";

const HELP = `Usage: openspec-pipeline [options] <change>...

Runs apply -> sync -> archive for each change, in the given order.
Re-run with the same arguments to resume after an interruption.

Options:
      --apply-model <m>     model for apply   (default: ${agents.defaultModel("apply")})
      --sync-model <m>      model for sync    (default: ${agents.defaultModel("sync")})
      --archive-model <m>   model for archive (default: ${agents.defaultModel("archive")})
      --max-open <n>        open tasks above this hand the session to you (default: 5)
      --gate <cmd>          shell command that must pass after apply; repeatable
  -h, --help

Each step is an agents session (claude): ctrl+t takes a running step over,
ctrl+z inside it detaches back. Sessions: agents ls`;

const STEPS: Step[] = ["apply", "sync", "archive"];
const STATUS_DONE = "PIPELINE_STATUS: DONE";
const STATUS_INPUT = "PIPELINE_STATUS: NEEDS_INPUT";
const NO_ASK = "Run non-interactively: never ask questions, pick sensible defaults and continue.";

const { values: opts, positionals: changes } = parseArgs({
  allowPositionals: true,
  options: {
    "apply-model": { type: "string" },
    "sync-model": { type: "string" },
    "archive-model": { type: "string" },
    "max-open": { type: "string", default: "5" },
    gate: { type: "string", multiple: true, default: [] },
    help: { type: "boolean", short: "h" },
  },
});

if (opts.help || changes.length === 0) {
  console.log(HELP);
  process.exit(opts.help ? 0 : 1);
}

// Expected failures print one line instead of a stack trace.
process.on("uncaughtException", (err) => {
  warn(`error: ${err.message}`);
  process.exit(1);
});
process.on("unhandledRejection", (err) => {
  warn(`error: ${err instanceof Error ? err.message : String(err)}`);
  process.exit(1);
});

const maxOpen = Number(opts["max-open"]);
const models = {} as Record<Step, string>;
for (const step of STEPS) models[step] = opts[`${step}-model`] ?? agents.defaultModel(step);

process.chdir(repoRoot());

async function runStep(step: Step, change: string, instructions: string) {
  const prompt = `${agents.invoke(step, change)} — ${instructions}`;
  log(`${step} (${models[step]}): ${prompt}`);
  const run = await agents.run(prompt, models[step]);
  log(`[${change}] ${step} session: ${run.sessionId}`);
  return run;
}

// Nothing open except manual checks.
const tasksDone = (t: Tasks) => t.other.length === 0 && t.open.length <= maxOpen;

async function apply(change: string) {
  let tasks = readTasks(change);
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

  const run = await runStep(
    "apply",
    change,
    `Implement all tasks. Leave manual smoke-test tasks unchecked. ${NO_ASK}
${resumeNote}When finished, end your final message with exactly one line:
'${STATUS_DONE}' if nothing needs the user, or
'${STATUS_INPUT}' if you have questions, blockers, decisions for the user,
or a needed action was denied by permissions.`,
  );
  const { sessionId } = run;
  let fallback = run.result;
  let tookOver = false;

  while (true) {
    const resp = (await agents.last(sessionId)) ?? fallback;
    log(`[${change}] apply agent last response:`);
    console.log(resp);

    tasks = readTasks(change);
    const needsInput = resp.includes(STATUS_INPUT);
    log(`[${change}] open tasks: ${tasks.open.length} (${tasks.other.length} non-manual), needs input: ${needsInput}`);
    if (tasks.open.length) console.log(tasks.open.join("\n"));

    if (!needsInput && tasksDone(tasks)) return;

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
      process.exit(1);
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
    const p = Bun.spawnSync(["sh", "-c", cmd], { stdio: ["inherit", "inherit", "inherit"] });
    if (p.exitCode !== 0) {
      warn(`gate failed: ${cmd}`);
      process.exit(1);
    }
  }
}

function commitStep(message: string, paths: string[]) {
  log(commit(message, paths) ? `committed: ${message}` : `nothing to commit for: ${message}`);
}

for (const change of changes) {
  if (!changeExists(change)) {
    warn(`skip ${change}: openspec/changes/${change} not found (typo or already archived?)`);
    continue;
  }

  if (hasCommit(`feat: spec sync ${change}`)) {
    log(`[${change}] apply and sync already committed, resuming at archive`);
  } else {
    if (hasCommit(`feat: ${change}`)) {
      log(`[${change}] apply already committed, resuming at sync`);
    } else {
      log(`[${change}] apply`);
      await apply(change);
      gate();
      commitStep(`feat: ${change}`, [".", ":!openspec"]);
    }

    log(`[${change}] sync`);
    await runStep("sync", change, NO_ASK);
    commitStep(`feat: spec sync ${change}`, ["openspec/specs"]);
  }

  log(`[${change}] archive`);
  await runStep("archive", change, `Archive now. Incomplete tasks are fine; specs are already synced. ${NO_ASK}`);
}

log("done");
