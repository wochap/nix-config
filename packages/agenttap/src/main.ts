// agenttap — one CLI for coding agent CLIs (claude, pi, agy), for humans and agents.
//
//   run     headless run; live rendered progress on a TTY, only the final
//           answer when piped (what an agent calling this wants). On a TTY,
//           Ctrl-T takes the running session over (see takeover.ts)
//   send    steer a running session live (message, --model, --effort)
//   attach  resume a session interactively
//   last    last agent message of a session (also after interactive turns)
//   ls      list sessions
//   watch   follow a session's progress from another terminal
//   serve   OpenAI-compatible HTTP API over `run` (see serve.ts)
//
// Agents are adapters (adapters/); the core only sees normalized events.

import { rmSync } from "node:fs";
import { resolve } from "node:path";
import { parseArgs } from "node:util";
import { adapters, getAdapter } from "./adapters";
import { EFFORTS, type Effort, type Event } from "./adapters/types";
import { IMAGE_TYPES, MAX_IMAGES, extension, readImage } from "./image";
import { header, hint, prompt as renderPrompt, render } from "./render";
import { resolveSandboxMode, wrapCommand } from "./sandbox";
import * as store from "./store";
import { tail } from "./tail";
import { askHandBack, CTRL_T, keys, takeOver } from "./takeover";
import { bell, color, interactive, onInterruptCleanup, progressToStderr, warn } from "./term";

const HELP = `Usage: agenttap <command> [options]

Commands:
  run [<prompt>|-]   headless run; prompt from stdin when "-" or piped
    -a, --agent <name>   agent (default: claude)
    -m, --model <m>      model (default: the agent's)
    -e, --effort <e>     ${EFFORTS.join(", ")}; mapped to the agent's own
                         flag (default: the agent's setting)
    -C, --cwd <dir>      working directory (default: current)
    -r, --resume <id>    continue a session headless
        --no-tools       the agent gets no tools and only answers; per run,
                         not kept for -r or attach
        --system-file <f>  replace the agent's system prompt with the file's
                         text (agents that cannot: put it atop the prompt);
                         per run, not kept for -r or attach
        --image <f>      attach an image (${IMAGE_TYPES.map(extension).join(", ")}; up to ${MAX_IMAGES});
                         repeatable; the prompt may then be empty
        --via <name>     mark the session as started by <name>; ls hides it
        --sandbox <mode> bubblewrap sandbox (permissive, strict, off; default: permissive)
    -q, --quiet          print only the final answer (default when stdout is not a TTY)
        --verbose        print live progress (default on a TTY)
        --json           print {id,agent,model,result,costUsd,durationMs,
                         inputTokens,outputTokens,status}, plus error
                         (the agent's error text) when it failed;
                         progress goes to stderr when it is a TTY or with --verbose
    keys on a TTY: ctrl+t take over (the agent's TUI), ctrl+z inside it
    detaches back here while it keeps working, ctrl+t attaches again
  send [<id>] [<message>|-]  steer a running session live without stopping it
    -s, --session <id>   target session id (default: running in cwd, else latest)
    -C, --cwd <dir>      target running session in directory
    -m, --model <m>      switch model for the next turn
    -e, --effort <e>     switch effort for the next turn
        --json           print {"status":"sent","id",...}
  attach [<id>]      take over a session interactively (default: latest)
  last [<id>]        last agent message (default: latest)
  ls                 list sessions of the last 7 days, oldest first
        --full           list all sessions
        --all            also list sessions started by a program (serve)
        --via <name>     only sessions started by <name>, e.g. serve
        --json           print the sessions' metadata as one JSON array, newest first
  watch [<id>]       follow a session (default: latest running, else latest)
  serve              OpenAI-compatible API: /v1/chat/completions, /v1/models
        --host <h>       listen address (default: 127.0.0.1)
        --port <n>       port (default: 20940)
    -C, --cwd <dir>      working directory of every run (default: current)
        --models <list>  comma-separated <agent>/<model> ids for /v1/models
                         (default: each agent's default model)
        --api-key-file <f>  require "Authorization: Bearer <key>" on /v1/*
                         (or AGENTTAP_API_KEY); one of them or --no-auth
        --no-auth        accept any request
        --tools          let runs use tools (default: --no-tools, so chats
                         only answer and prompts cannot drive tools)
        --tool-events    stream tool calls as italic lines (with --tools)
        --sandbox <mode> bubblewrap sandbox (permissive, strict, off; default: strict)

Ids may be a unique prefix.
Agents:   ${Object.keys(adapters).join(", ")}
Sessions: ${store.dir}`;

const { values: opts, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    agent: { type: "string", short: "a" },
    model: { type: "string", short: "m" },
    effort: { type: "string", short: "e" },
    cwd: { type: "string", short: "C" },
    resume: { type: "string", short: "r" },
    session: { type: "string", short: "s" },
    sandbox: { type: "string" },
    quiet: { type: "boolean", short: "q" },
    verbose: { type: "boolean" },
    json: { type: "boolean" },
    host: { type: "string" },
    port: { type: "string" },
    models: { type: "string" },
    "tool-events": { type: "boolean" },
    "no-tools": { type: "boolean" },
    "system-file": { type: "string" },
    image: { type: "string", multiple: true },
    via: { type: "string" },
    "api-key-file": { type: "string" },
    "no-auth": { type: "boolean" },
    tools: { type: "boolean" },
    full: { type: "boolean" },
    all: { type: "boolean" },
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

// Told to the agent when a user hands a taken-over session back.
const HANDBACK = "The user took over and handed back. Continue the original task.";
const STEER_PREFIX = "The user sent a new instruction while you were working:";

async function run() {
  type Mode = "json" | "quiet" | "verbose";
  const mode: Mode = opts.json ? "json" : opts.quiet ? "quiet" : opts.verbose ? "verbose" : process.stdout.isTTY ? "verbose" : "quiet";
  // --json keeps stdout for the JSON; progress goes to stderr when a person
  // (or --verbose) wants it.
  const progress = mode === "verbose" || (mode === "json" && (opts.verbose || process.stderr.isTTY));
  if (mode === "json" && progress) progressToStderr();

  const effort = opts.effort as Effort | undefined;
  if (effort && !EFFORTS.includes(effort)) throw new Error(`--effort: expected one of ${EFFORTS.join(", ")}`);

  // Absolute: the agent runs in the session's cwd.
  const images = (opts.image ?? []).map((f) => resolve(f));
  if (images.length > MAX_IMAGES) throw new Error(`--image: at most ${MAX_IMAGES} images`);
  for (const f of images) await readImage(f);

  let prompt = await readPrompt();
  if (!prompt && !images.length) {
    console.error(HELP);
    process.exit(1);
  }
  // Ctrl-T needs someone at the terminal who sees the progress.
  const takeover = progress && keys.available();

  if (opts["no-tools"]) {
    const name = opts.resume ? store.resolveId(opts.resume).agent : (opts.agent ?? "claude");
    const agent = getAdapter(name);
    const sandbox = resolveSandboxMode(opts.sandbox, "permissive");
    if (!agent.supportsNoTools(sandbox)) {
      if (agent.name === "agy" && sandbox !== "strict") {
        throw new Error("agy: --no-tools requires --sandbox strict");
      }
      throw new Error(`--no-tools: ${name} cannot run without tools`);
    }
  }
  if (images.length) {
    const name = opts.resume ? store.resolveId(opts.resume).agent : (opts.agent ?? "claude");
    if (!getAdapter(name).images) throw new Error(`--image: ${name} cannot take images`);
  }

  let session: store.Session;
  if (opts.resume) {
    const prev = store.resolveId(opts.resume);
    if (prev.status === "running") throw new Error(`session ${prev.id} is still running`);
    if (opts.agent && opts.agent !== prev.agent) throw new Error(`session ${prev.id} belongs to ${prev.agent}`);
    session = store.restartSession(prev, opts.model ?? prev.model, effort ?? prev.effort);
  } else {
    const agent = getAdapter(opts.agent ?? "claude");
    session = store.createSession({
      id: crypto.randomUUID(),
      agent: agent.name,
      model: opts.model ?? agent.defaultModel,
      effort,
      cwd: opts.cwd ? resolve(opts.cwd) : process.cwd(),
      prompt: images.length ? `${prompt} [${images.length} image${images.length > 1 ? "s" : ""}]`.trim() : prompt,
      via: opts.via,
    });
  }
  const agent = getAdapter(session.agent);
  const { id } = session;

  // Absolute: the agent runs in the session's cwd.
  const systemFile = opts["system-file"] ? resolve(opts["system-file"]) : undefined;
  if (systemFile && !agent.systemPromptFlags) {
    const system = (await Bun.file(systemFile).text()).trim();
    if (system) prompt = `${system}\n\n${prompt}`;
  }

  onInterruptCleanup(() => {
    rmSync(store.sendPath(id), { force: true });
    store.finishSession(id, "failed");
  });

  if (progress) header(agent.name, session.model, id);
  else process.stderr.write(`session: ${id}\n`);

  const onEvent = async (e: Event) => {
    store.appendEvent(id, e);
    if (progress) await render(e);
  };

  let last: Extract<Event, { type: "result" }> | null = null;
  let status: store.Status = "done";
  let result = "";
  let error: string | null = null;
  let resume = Boolean(opts.resume);
  let hasStarted = Boolean(opts.resume);
  // Sent with the first attempt only; a handback must not resend them.
  let attach = images;
  const sandbox = resolveSandboxMode(opts.sandbox, "permissive");

  const applySend = async (payload: store.SendPayload) => {
    if (payload.model || payload.effort) {
      session = store.updateSessionConfig(id, payload.model ?? session.model, payload.effort ?? session.effort);
    }
    await onEvent({ type: "send", text: payload.message ?? "", model: payload.model, effort: payload.effort });
    const started = hasStarted || Boolean(agent.transcriptPath(id));
    if (started) {
      prompt = payload.message
        ? `${STEER_PREFIX}\n\n${payload.message}\n\nContinue the task with this instruction in mind.`
        : "Continue the task where you left off.";
      attach = [];
      resume = true;
    } else {
      if (payload.message) {
        prompt = `${prompt}\n\n${STEER_PREFIX}\n\n${payload.message}`;
      }
      resume = false;
    }
  };

  let currentStop: AbortController | null = null;
  let abortReason: "takeover" | "send" | null = null;
  const onSigUsr1 = () => {
    abortReason = "send";
    currentStop?.abort();
  };
  process.on("SIGUSR1", onSigUsr1);

  try {
    // Headless attempts; Ctrl-T stops one and hands the session to the user,
    // SIGUSR1 stops one and injects a live `send` steering message.
    while (true) {
      const prePending = store.consumeSend(id);
      if (prePending) await applySend(prePending);

      const stop = new AbortController();
      currentStop = stop;
      abortReason = null;
      if (takeover) {
        keys.start();
        keys.on((key) => {
          if (key === CTRL_T) {
            abortReason = "takeover";
            stop.abort();
          }
        });
        hint("ctrl+t take over");
      }
      try {
        ({ result } = await agent.run({
          id,
          prompt,
          model: session.model,
          effort: session.effort,
          cwd: session.cwd,
          resume,
          noTools: Boolean(opts["no-tools"]),
          systemFile: agent.systemPromptFlags ? systemFile : undefined,
          images: attach,
          rawLog: store.rawPath(id),
          signal: stop.signal,
          sandbox,
          async onEvent(e) {
            hasStarted = true;
            // After Ctrl-T or send abort the agent only reports its own interruption.
            if (stop.signal.aborted) return;
            if (e.type === "result") last = e;
            await onEvent(e);
          },
        }));
      } catch (err) {
        if (!stop.signal.aborted) {
          status = "failed";
          const message = err instanceof Error ? err.message : String(err);
          error = message;
          const e: Event = { type: "error", message };
          store.appendEvent(id, e);
          if (progress) await render(e);
          else warn(`error: ${message}`);
          result = (last as Extract<Event, { type: "result" }> | null)?.result ?? "";
        }
      }
      currentStop = null;
      keys.on(null);
      if (!stop.signal.aborted) {
        const postPending = store.consumeSend(id);
        if (postPending) {
          await applySend(postPending);
          continue;
        }
        break;
      }

      if (abortReason === "send") {
        const payload = store.consumeSend(id);
        if (payload) await applySend(payload);
        continue;
      }

      await onEvent({ type: "takeover" });
      const how = await takeOver({ agent, id, model: session.model, effort: session.effort, cwd: session.cwd, sandbox, onEvent });
      if (how === "finished" || (await askHandBack()) === "done") {
        result = (await agent.lastResponse(id)) ?? "";
        last = null;
        break;
      }
      await onEvent({ type: "handback" });
      hasStarted = true;
      prompt = HANDBACK;
      attach = [];
      resume = true;
    }
  } finally {
    process.off("SIGUSR1", onSigUsr1);
    rmSync(store.sendPath(id), { force: true });
  }
  keys.stop();
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
        inputTokens: done?.inputTokens ?? null,
        outputTokens: done?.outputTokens ?? null,
        status,
        ...(error ? { error } : {}),
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
  const cmd = getAdapter(s.agent).takeOverCmd(s.id, s.model, s.effort);
  const sandboxedCmd = wrapCommand(cmd, {
    mode: resolveSandboxMode(opts.sandbox, "permissive"),
    cwd: s.cwd,
    agent: s.agent,
  });
  await interactive(() => Bun.spawn(sandboxedCmd, { cwd: s.cwd, stdio: ["inherit", "inherit", "inherit"] }).exited);
}

async function last() {
  const s = pick(args[0], store.latest);
  const text = await getAdapter(s.agent).lastResponse(s.id);
  if (text === null) throw new Error(`no messages in session ${s.id}`);
  console.log(text);
}

// Last 7 days unless --full, people's sessions unless --all (--via <name>:
// only that program's); oldest first so the newest ends up by the prompt.
// --json: the same sessions' metadata, newest first, for programs.
function ls() {
  const statusColor = { running: color.blue, done: color.dim, failed: color.yellow };
  const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
  const sessions = store
    .listSessions()
    .filter((s) => (opts.full || s.startedAt >= since) && (opts.via ? s.via === opts.via : opts.all || !s.via));
  if (opts.json) {
    console.log(JSON.stringify(sessions));
    return;
  }
  for (const s of sessions.reverse()) {
    const started = new Date(s.startedAt).toLocaleString("sv").slice(0, 16);
    const prompt = (s.via && !opts.via ? `[${s.via}] ` : "") + s.prompt.replace(/\s+/g, " ").slice(0, 60);
    console.log(
      [s.id.slice(0, 8), s.agent.padEnd(6), statusColor[s.status](s.status.padEnd(7)), started, s.cwd, color.dim(prompt)].join("  "),
    );
  }
}

// Renders events.jsonl and keeps following while the session runs.
async function watch() {
  const s = pick(args[0], () => store.latestRunning() ?? store.latest());
  header(s.agent, s.model, s.id);
  const promptText = store.readPrompt(s.id);
  if (promptText?.trim()) renderPrompt(promptText);
  const read = tail(store.eventsPath(s.id));
  while (true) {
    const running = store.readSession(s.id)?.status === "running";
    for (const line of read()) {
      try {
        await render(JSON.parse(line));
      } catch {}
    }
    if (!running) return;
    await Bun.sleep(300);
  }
}

// The key /v1/* requires; null only with --no-auth.
async function apiKey(): Promise<string | null> {
  if (opts["no-auth"]) return null;
  const key = opts["api-key-file"] ? await Bun.file(opts["api-key-file"]).text() : process.env.AGENTTAP_API_KEY;
  if (key?.trim()) return key.trim();
  throw new Error("serve: give --api-key-file, AGENTTAP_API_KEY, or --no-auth");
}

async function serve() {
  // Lazy: loads the conversation map, only the server needs it.
  const { serve: startServer } = await import("./serve");
  const port = Number(opts.port ?? 20940);
  if (!Number.isInteger(port) || port <= 0) throw new Error("--port: expected a port number");
  startServer({
    host: opts.host ?? "127.0.0.1",
    port,
    cwd: opts.cwd ? resolve(opts.cwd) : process.cwd(),
    models: opts.models
      ?.split(",")
      .map((m) => m.trim())
      .filter(Boolean),
    toolEvents: Boolean(opts["tool-events"]),
    tools: Boolean(opts.tools),
    apiKey: await apiKey(),
    sandbox: resolveSandboxMode(opts.sandbox, "strict"),
  });
}

async function send() {
  const effort = opts.effort as Effort | undefined;
  if (effort && !EFFORTS.includes(effort)) throw new Error(`--effort: expected one of ${EFFORTS.join(", ")}`);

  const targetCwd = opts.cwd ? resolve(opts.cwd) : process.cwd();
  const findRunning = () => {
    const s = store.latestRunning(targetCwd) ?? (opts.cwd ? null : store.latestRunning());
    if (!s) throw new Error(opts.cwd ? `no running session in ${targetCwd}` : "no running session");
    return s;
  };

  let s: store.Session;
  let message = "";

  const explicitId = opts.session ?? opts.resume;
  if (explicitId) {
    s = store.resolveId(explicitId);
    const arg = args.join(" ");
    if (arg === "-" || (!arg && !process.stdin.isTTY)) message = (await Bun.stdin.text()).trim();
    else message = arg;
  } else if (args.length >= 2 || (args.length === 1 && !process.stdin.isTTY && args[0] !== "-")) {
    let resolved: store.Session | null = null;
    try {
      resolved = store.resolveId(args[0]);
    } catch {}
    if (resolved) {
      s = resolved;
      const rest = args.slice(1).join(" ");
      if (rest === "-" || (!rest && !process.stdin.isTTY)) message = (await Bun.stdin.text()).trim();
      else message = rest;
    } else {
      s = findRunning();
      message = args.join(" ");
    }
  } else if (args.length === 1) {
    if (args[0] === "-") {
      s = findRunning();
      message = (await Bun.stdin.text()).trim();
    } else if (opts.model || opts.effort) {
      const matches = store.listSessions().filter((x) => x.status === "running" && x.id.startsWith(args[0]));
      if (matches.length > 1) throw new Error(`ambiguous session "${args[0]}", ${matches.length} matches`);
      if (matches.length === 1) {
        s = matches[0];
      } else {
        s = findRunning();
        message = args[0];
      }
    } else {
      s = findRunning();
      message = args[0];
    }
  } else {
    s = findRunning();
    if (!process.stdin.isTTY) message = (await Bun.stdin.text()).trim();
  }

  if (s.status !== "running") {
    throw new Error(
      `session ${s.id} is not running (status: ${s.status}); use "agenttap run -r ${s.id.slice(0, 8)} ..." to resume it`,
    );
  }
  if (!message && !opts.model && !effort) {
    throw new Error("send: provide a message, --model, or --effort");
  }

  store.enqueueSend(s.id, {
    message: message || undefined,
    model: opts.model,
    effort,
    sentAt: new Date().toISOString(),
  });
  process.kill(s.pid, "SIGUSR1");

  if (opts.json) {
    console.log(JSON.stringify({ status: "sent", id: s.id, ...(opts.model ? { model: opts.model } : {}), ...(effort ? { effort } : {}) }));
  } else {
    console.log(`sent to session ${s.id.slice(0, 8)}`);
  }
}

const commands: Record<string, () => unknown> = { run, send, attach, last, ls, watch, serve };
const fn = commands[command];
if (!fn) {
  console.error(HELP);
  process.exit(1);
}
await fn();
