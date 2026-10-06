// OpenAI-compatible HTTP server over `agents run --json`, so chat GUIs
// (open-webui, desktop clients, editors) can talk to the local agents.
//
//   GET  /health               ok
//   GET  /v1/models            <agent>/<model> ids
//   POST /v1/chat/completions  one `agents run` per request; stream: true
//                              tails the session's events.jsonl as SSE
//
// Multi-turn: a GUI resends the whole history each time. The history up to
// the last user message is fingerprinted; a known fingerprint resumes its
// session with only the last user message, an unknown one starts a new
// session with the flattened history.

import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { adapters, getAdapter } from "./adapters";
import { EFFORTS, type Effort, type Event } from "./adapters/types";
import * as store from "./store";
import { tail } from "./tail";

export interface ServeOptions {
  host: string;
  port: number;
  /** Ids for /v1/models; default: every adapter's default model. */
  models?: string[];
  /** Stream tool labels as italic lines. */
  toolEvents: boolean;
  /** Working directory of every run. */
  cwd: string;
}

interface Message {
  role: string;
  content: unknown;
}

class HttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}

const json = (body: unknown, status = 200) => Response.json(body, { status });
const errorBody = (message: string) => ({ error: { message } });

/** String content, or the text parts of an array content. */
function text(m: Message): string {
  if (typeof m.content === "string") return m.content;
  if (!Array.isArray(m.content)) return "";
  return m.content
    .filter((p) => p?.type === "text" && typeof p.text === "string")
    .map((p) => p.text)
    .join("\n");
}

// Fingerprint -> session id; lets a GUI's next request resume the session.
const conversationsPath = join(store.dir, "..", "serve-conversations.json");
const conversations = new Map<string, string>(
  (() => {
    try {
      return Object.entries(JSON.parse(readFileSync(conversationsPath, "utf8")) as Record<string, string>);
    } catch {
      return [];
    }
  })(),
);

function remember(fingerprint: string, id: string) {
  conversations.set(fingerprint, id);
  writeFileSync(conversationsPath, `${JSON.stringify(Object.fromEntries(conversations))}\n`);
}

// Trimmed, since GUIs tend to trim what they echo back.
const fp = (model: string, messages: Message[]) =>
  createHash("sha256")
    .update(JSON.stringify([model, messages.map((m) => [m.role, text(m).trim()])]))
    .digest("hex");

/** History as one prompt, for a conversation the server has not seen. */
function flatten(messages: Message[]): string {
  const system = messages.filter((m) => m.role === "system" || m.role === "developer");
  const turns = messages.filter((m) => m.role === "user" || m.role === "assistant");
  if (system.length === 0 && turns.length === 1) return text(turns[0]);
  return [
    ...system.map((m) => `<system>\n${text(m)}\n</system>`),
    ...turns.map((m) => `${m.role}: ${text(m)}`),
  ].join("\n\n");
}

interface Plan {
  model: string;
  agent: string;
  agentModel: string;
  effort?: Effort;
  prompt: string;
  resume?: string;
  messages: Message[];
}

function plan(body: any): Plan {
  if (typeof body?.model !== "string" || !body.model) throw new HttpError(400, "model is required");
  const model: string = body.model;
  const slash = model.indexOf("/");
  const agentName = slash === -1 ? model : model.slice(0, slash);
  let adapter;
  try {
    adapter = getAdapter(agentName);
  } catch (err) {
    throw new HttpError(400, (err as Error).message);
  }
  const agentModel = slash === -1 ? adapter.defaultModel : model.slice(slash + 1);

  const rawEffort = body.reasoning_effort ?? body.reasoning?.effort;
  let effort: Effort | undefined;
  if (rawEffort !== undefined && rawEffort !== null && rawEffort !== "none" && rawEffort !== "minimal") {
    if (!EFFORTS.includes(rawEffort)) {
      throw new HttpError(400, `reasoning_effort: expected none, minimal, ${EFFORTS.join(", ")}`);
    }
    effort = rawEffort;
  }

  const messages: Message[] = Array.isArray(body.messages) ? body.messages : [];
  const lastMsg = messages.at(-1);
  if (!lastMsg || lastMsg.role !== "user" || !text(lastMsg).trim()) {
    throw new HttpError(400, "messages must end with a non-empty user message");
  }

  const known = conversations.get(fp(model, messages.slice(0, -1)));
  const prev = known ? store.readSession(known) : null;
  if (prev?.status === "running") throw new HttpError(409, `session ${prev.id} is still running`);
  if (prev && prev.agent === adapter.name) {
    return { model, agent: adapter.name, agentModel, effort, prompt: text(lastMsg), resume: prev.id, messages };
  }
  return { model, agent: adapter.name, agentModel, effort, prompt: flatten(messages), messages };
}

interface Run {
  /** Resolves with the session id once the CLI prints it; null if it exits first. */
  id: Promise<string | null>;
  exited: Promise<number>;
  /** Parsed --json line, after exit. */
  output(): Promise<{ id: string; result: string; status: store.Status } | null>;
  /** Last `error:` line on stderr. */
  error(): string;
  kill(): void;
}

function spawn(p: Plan, cwd: string): Run {
  const proc = Bun.spawn(
    [
      process.execPath,
      join(import.meta.dir, "main.ts"),
      "run",
      "--json",
      "-a",
      p.agent,
      "-m",
      p.agentModel,
      ...(p.effort ? ["-e", p.effort] : []),
      "-C",
      cwd,
      ...(p.resume ? ["-r", p.resume] : []),
      "-",
    ],
    { stdin: "pipe", stdout: "pipe", stderr: "pipe", env: process.env },
  );
  proc.stdin.write(p.prompt);
  proc.stdin.end();

  let lastError = "";
  let resolveId: (id: string | null) => void = () => {};
  const id = new Promise<string | null>((r) => {
    resolveId = r;
  });
  const stderrDone = (async () => {
    const decoder = new TextDecoder();
    let buf = "";
    for await (const chunk of proc.stderr) {
      buf += decoder.decode(chunk, { stream: true });
      const lines = buf.split("\n");
      buf = lines.pop() ?? "";
      for (const line of lines) {
        const session = line.match(/^session: (\S+)/);
        if (session) resolveId(session[1]);
        const error = line.match(/error: (.*)/);
        if (error) lastError = error[1];
      }
    }
    resolveId(null);
  })();
  const stdout = new Response(proc.stdout).text();

  return {
    id,
    exited: proc.exited,
    async output() {
      await proc.exited;
      await stderrDone;
      const line = (await stdout).trim().split("\n").at(-1);
      try {
        return line ? JSON.parse(line) : null;
      } catch {
        return null;
      }
    },
    error: () => lastError,
    kill: () => proc.kill("SIGINT"),
  };
}

const completionId = (id: string | null) => `chatcmpl-${id ?? crypto.randomUUID()}`;
const now = () => Math.floor(Date.now() / 1000);

function remembered(p: Plan, id: string, replies: string[]) {
  for (const reply of new Set(replies.filter((r) => r.trim()))) {
    remember(fp(p.model, [...p.messages, { role: "assistant", content: reply }]), id);
  }
}

async function complete(p: Plan, cwd: string, signal: AbortSignal): Promise<Response> {
  const run = spawn(p, cwd);
  signal.addEventListener("abort", run.kill);
  const out = await run.output();
  if (!out) throw new HttpError(500, run.error() || "agents run printed no result");
  if (out.status !== "done") throw new HttpError(500, out.result || run.error() || "agent failed");
  remembered(p, out.id, [out.result]);
  return json({
    id: completionId(out.id),
    object: "chat.completion",
    created: now(),
    model: p.model,
    choices: [{ index: 0, message: { role: "assistant", content: out.result }, finish_reason: "stop" }],
    usage: { prompt_tokens: 0, completion_tokens: 0, total_tokens: 0 },
  });
}

function stream(p: Plan, cwd: string, toolEvents: boolean, signal: AbortSignal): Response {
  // A resumed session already has events; follow only the new ones.
  let read = p.resume ? tail(store.eventsPath(p.resume), true) : null;
  const run = spawn(p, cwd);
  signal.addEventListener("abort", run.kill);
  const encoder = new TextEncoder();
  const created = now();

  const body = new ReadableStream({
    async start(controller) {
      let closed = false;
      let lastWrite = Date.now();
      const write = (s: string) => {
        if (closed) return;
        try {
          controller.enqueue(encoder.encode(s));
          lastWrite = Date.now();
        } catch {
          closed = true;
        }
      };
      let id = completionId(p.resume ?? null);
      let first = true;
      const chunk = (delta: Record<string, unknown>, finish: string | null = null) => {
        if (first) delta = { role: "assistant", ...delta };
        first = false;
        write(
          `data: ${JSON.stringify({ id, object: "chat.completion.chunk", created, model: p.model, choices: [{ index: 0, delta, finish_reason: finish }] })}\n\n`,
        );
      };

      // What the GUI shows, and so echoes back next turn.
      let sent = "";
      let lastText = "";
      let sawText = false;
      let ended = false;
      const content = (s: string) => {
        sent += s;
        chunk({ content: s });
      };
      const handle = (e: Event) => {
        if (ended) return;
        if (e.type === "text") {
          sawText = true;
          lastText = e.text;
          content(`${e.text}\n\n`);
        } else if (e.type === "tool" && toolEvents) {
          content(`_> ${e.label}_\n\n`);
        } else if (e.type === "error") {
          content(e.message);
          ended = true;
        } else if (e.type === "result") {
          if (!sawText && e.result && e.result !== lastText) content(e.result);
          ended = true;
        }
      };
      const drain = () => {
        if (!read) return;
        for (const line of read()) {
          try {
            handle(JSON.parse(line));
          } catch {}
        }
      };

      let exited = false;
      run.exited.then(() => {
        exited = true;
      });
      if (!read) {
        const sessionId = await run.id;
        if (sessionId) {
          id = completionId(sessionId);
          read = tail(store.eventsPath(sessionId));
        }
      }
      while (!exited) {
        drain();
        if (Date.now() - lastWrite > 15_000) write(": ping\n\n");
        await Bun.sleep(200);
      }
      drain();

      const out = await run.output();
      if (out?.status === "done") {
        remembered(p, out.id, [sent, out.result]);
      } else if (!ended) {
        content(out?.result || run.error() || "agent failed");
      }
      chunk({}, "stop");
      write("data: [DONE]\n\n");
      if (!closed) controller.close();
    },
    cancel() {
      run.kill();
    },
  });

  return new Response(body, {
    headers: { "Content-Type": "text/event-stream", "Cache-Control": "no-cache", Connection: "keep-alive" },
  });
}

export function serve(o: ServeOptions) {
  const models = o.models?.length ? o.models : Object.values(adapters).map((a) => `${a.name}/${a.defaultModel}`);

  const server = Bun.serve({
    hostname: o.host,
    port: o.port,
    // Runs take minutes; streams send a ping every 15 s.
    idleTimeout: 0,
    async fetch(req) {
      const { pathname } = new URL(req.url);
      if (req.method === "GET" && pathname === "/health") return new Response("ok");
      if (req.method === "GET" && pathname === "/v1/models") {
        return json({
          object: "list",
          data: models.map((id) => ({ id, object: "model", created: 0, owned_by: id.split("/")[0] })),
        });
      }
      if (req.method === "POST" && pathname === "/v1/chat/completions") {
        let body: any;
        try {
          body = await req.json();
        } catch {
          throw new HttpError(400, "invalid JSON body");
        }
        const p = plan(body);
        return body.stream ? stream(p, o.cwd, o.toolEvents, req.signal) : complete(p, o.cwd, req.signal);
      }
      return json(errorBody(`no route ${req.method} ${pathname}`), 404);
    },
    error(err) {
      const status = err instanceof HttpError ? err.status : 500;
      return json(errorBody(err.message), status);
    },
  });
  console.error(`agents serve: http://${server.hostname}:${server.port}/v1 (cwd ${o.cwd})`);
}
