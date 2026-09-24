// agents — one CLI for coding agent CLIs (claude, ...), for humans and agents.
//
//   run     headless run; live rendered progress on a TTY, only the final
//           answer when piped (what an agent calling this wants)
//   attach  resume a session interactively
//   last    last agent message of a session (also after interactive turns)
//   ls      list sessions
//   watch   follow a session's progress from another terminal
//
// Agents are adapters (adapters/); the core only sees normalized events.

import { openSync, readSync, closeSync, existsSync } from "node:fs";
import { resolve } from "node:path";
import { parseArgs } from "node:util";
import { adapters, getAdapter } from "./adapters";
import type { Event } from "./adapters/types";
import { header, render } from "./render";
import * as store from "./store";
import { bell, color, interactive, onInterruptCleanup, warn } from "./term";

const HELP = `Usage: agents <command> [options]

Commands:
  run [<prompt>|-]   headless run; prompt from stdin when "-" or piped
    -a, --agent <name>   agent (default: claude)
    -m, --model <m>      model (default: the agent's)
    -C, --cwd <dir>      working directory (default: current)
    -r, --resume <id>    continue a session headless
    -q, --quiet          print only the final answer (default when stdout is not a TTY)
        --verbose        print live progress (default on a TTY)
        --json           print {id,agent,model,result,costUsd,durationMs,status}
  attach [<id>]      take over a session interactively (default: latest)
  last [<id>]        last agent message (default: latest)
  ls                 list sessions
  watch [<id>]       follow a session (default: latest running, else latest)

Ids may be a unique prefix.
Agents:   ${Object.keys(adapters).join(", ")}
Sessions: ${store.dir}`;

const { values: opts, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    agent: { type: "string", short: "a" },
    model: { type: "string", short: "m" },
    cwd: { type: "string", short: "C" },
    resume: { type: "string", short: "r" },
    quiet: { type: "boolean", short: "q" },
    verbose: { type: "boolean" },
    json: { type: "boolean" },
    help: { type: "boolean", short: "h" },
  },
});

const [command, ...args] = positionals;

if (opts.help || !command) {
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

function pick(id: string | undefined, fallback: () => store.Session | null): store.Session {
  if (id) return store.resolveId(id);
  const s = fallback();
  if (!s) throw new Error("no sessions yet");
  return s;
}

async function readPrompt(): Promise<string> {
  const arg = args.join(" ");
  if (arg && arg !== "-") return arg;
  if (arg === "-" || !process.stdin.isTTY) return (await Bun.stdin.text()).trim();
  return "";
}

async function run() {
  type Mode = "json" | "quiet" | "verbose";
  const mode: Mode = opts.json ? "json" : opts.quiet ? "quiet" : opts.verbose ? "verbose" : process.stdout.isTTY ? "verbose" : "quiet";

  const prompt = await readPrompt();
  if (!prompt) {
    console.error(HELP);
    process.exit(1);
  }

  let session: store.Session;
  if (opts.resume) {
    const prev = store.resolveId(opts.resume);
    if (prev.status === "running") throw new Error(`session ${prev.id} is still running`);
    if (opts.agent && opts.agent !== prev.agent) throw new Error(`session ${prev.id} belongs to ${prev.agent}`);
    session = store.restartSession(prev, opts.model ?? prev.model);
  } else {
    const agent = getAdapter(opts.agent ?? "claude");
    session = store.createSession({
      id: crypto.randomUUID(),
      agent: agent.name,
      model: opts.model ?? agent.defaultModel,
      cwd: opts.cwd ? resolve(opts.cwd) : process.cwd(),
      prompt,
    });
  }
  const agent = getAdapter(session.agent);
  const { id } = session;
  onInterruptCleanup(() => store.finishSession(id, "failed"));

  if (mode === "verbose") header(agent.name, session.model, id);
  else process.stderr.write(`session: ${id}\n`);

  let last: Extract<Event, { type: "result" }> | null = null;
  let status: store.Status = "done";
  let result = "";
  try {
    ({ result } = await agent.run({
      id,
      prompt,
      model: session.model,
      cwd: session.cwd,
      resume: Boolean(opts.resume),
      rawLog: store.rawPath(id),
      async onEvent(e) {
        store.appendEvent(id, e);
        if (e.type === "result") last = e;
        if (mode === "verbose") await render(e);
      },
    }));
  } catch (err) {
    status = "failed";
    const message = err instanceof Error ? err.message : String(err);
    const e: Event = { type: "error", message };
    store.appendEvent(id, e);
    if (mode === "verbose") await render(e);
    else warn(`error: ${message}`);
    result = (last as Extract<Event, { type: "result" }> | null)?.result ?? "";
  }
  store.finishSession(id, status);
  bell();

  const done = last as Extract<Event, { type: "result" }> | null;
  if (mode === "json") {
    console.log(
      JSON.stringify({
        id,
        agent: agent.name,
        model: session.model,
        result,
        costUsd: done?.costUsd ?? null,
        durationMs: done?.durationMs ?? null,
        status,
      }),
    );
  } else if (mode === "quiet" && result) {
    process.stdout.write(result.endsWith("\n") ? result : `${result}\n`);
  }
  process.exit(status === "done" ? 0 : 1);
}

async function attach() {
  const s = pick(args[0], store.latest);
  if (s.status === "running") throw new Error(`session ${s.id} is still running`);
  await interactive(() => getAdapter(s.agent).takeOver(s.id, s.model, s.cwd));
}

async function last() {
  const s = pick(args[0], store.latest);
  const text = await getAdapter(s.agent).lastResponse(s.id);
  if (text === null) throw new Error(`no messages in session ${s.id}`);
  console.log(text);
}

function ls() {
  const statusColor = { running: color.blue, done: color.dim, failed: color.yellow };
  for (const s of store.listSessions()) {
    const started = new Date(s.startedAt).toLocaleString("sv").slice(0, 16);
    const prompt = s.prompt.replace(/\s+/g, " ").slice(0, 60);
    console.log(
      [s.id.slice(0, 8), s.agent.padEnd(6), statusColor[s.status](s.status.padEnd(7)), started, s.cwd, color.dim(prompt)].join("  "),
    );
  }
}

// Renders events.jsonl and keeps following while the session runs.
async function watch() {
  const s = pick(args[0], () => store.latestRunning() ?? store.latest());
  header(s.agent, s.model, s.id);
  const path = store.eventsPath(s.id);
  let offset = 0;
  let buf = "";
  const chunk = Buffer.alloc(64 * 1024);
  while (true) {
    const running = store.readSession(s.id)?.status === "running";
    if (existsSync(path)) {
      const fd = openSync(path, "r");
      let n: number;
      while ((n = readSync(fd, chunk, 0, chunk.length, offset)) > 0) {
        offset += n;
        buf += chunk.toString("utf8", 0, n);
      }
      closeSync(fd);
      let i: number;
      while ((i = buf.indexOf("\n")) >= 0) {
        const line = buf.slice(0, i);
        buf = buf.slice(i + 1);
        try {
          await render(JSON.parse(line));
        } catch {}
      }
    }
    if (!running) return;
    await Bun.sleep(300);
  }
}

const commands: Record<string, () => unknown> = { run, attach, last, ls, watch };
const fn = commands[command];
if (!fn) {
  console.error(HELP);
  process.exit(1);
}
await fn();
