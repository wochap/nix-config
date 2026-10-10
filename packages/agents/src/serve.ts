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
//
// System messages replace the agent's own system prompt (run --system-file).
// Runs get no tools unless --tools: a prompt (say, scraped web text) must not
// drive tools in the run's directory.

import { createHash, timingSafeEqual } from "node:crypto";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
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
  /** Runs may use tools; otherwise every run gets --no-tools. */
  tools: boolean;
  /** Bearer token /v1/* requires; null accepts any request. */
  apiKey: string | null;
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
// Every one-shot request (a program calling the API) adds an entry, so
// entries older than CONVERSATION_TTL are dropped.
interface Conversation {
  id: string;
  /** Epoch ms of the reply. */
  at: number;
}
const CONVERSATION_TTL = 30 * 24 * 60 * 60 * 1000;
const conversationsPath = join(store.dir, "..", "serve-conversations.json");
const conversations = new Map<string, Conversation>(
  (() => {
    try {
      return Object.entries(JSON.parse(readFileSync(conversationsPath, "utf8")) as Record<string, Conversation>);
    } catch {
      return [];
    }
  })(),
);

function remember(fingerprint: string, id: string) {
  const now = Date.now();
  for (const [key, c] of conversations) if (!(now - c.at < CONVERSATION_TTL)) conversations.delete(key);
  conversations.set(fingerprint, { id, at: now });
  writeFileSync(conversationsPath, `${JSON.stringify(Object.fromEntries(conversations))}\n`);
}

// Trimmed, since GUIs tend to trim what they echo back.
const fp = (model: string, messages: Message[]) =>
  createHash("sha256")
    .update(JSON.stringify([model, messages.map((m) => [m.role, text(m).trim()])]))
    .digest("hex");

const isSystem = (m: Message) => m.role === "system" || m.role === "developer";

/** History as one prompt, for a conversation the server has not seen. */
function flatten(messages: Message[]): string {
  const turns = messages.filter((m) => m.role === "user" || m.role === "assistant");
  if (turns.length === 1) return text(turns[0]);
  return turns.map((m) => `${m.role}: ${text(m)}`).join("\n\n");
}

interface Plan {
  model: string;
  agent: string;
  agentModel: string;
  effort?: Effort;
  prompt: string;
  /** The request's system messages; replaces the agent's system prompt. */
  system?: string;
  resume?: string;
  messages: Message[];
  /** Send a usage chunk before [DONE] (stream_options.include_usage). */
  streamUsage: boolean;
}

function plan(body: any, tools: boolean): Plan {
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
  if (!tools && !adapter.noToolsFlags) throw new HttpError(400, `${adapter.name} cannot run without tools`);
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

  const system = messages.filter(isSystem).map(text).join("\n\n").trim() || undefined;
  const streamUsage = Boolean(body.stream_options?.include_usage);
  const base = { model, agent: adapter.name, agentModel, effort, system, messages, streamUsage };

  const known = conversations.get(fp(model, messages.slice(0, -1)));
  const prev = known ? store.readSession(known.id) : null;
  if (prev?.status === "running") throw new HttpError(409, `session ${prev.id} is still running`);
  if (prev && prev.agent === adapter.name) return { ...base, prompt: text(lastMsg), resume: prev.id };
  return { ...base, prompt: flatten(messages) };
}

interface RunOutput {
  id: string;
  result: string;
  status: store.Status;
  inputTokens: number | null;
  outputTokens: number | null;
}

interface Run {
  /** Resolves with the session id once the CLI prints it; null if it exits first. */
  id: Promise<string | null>;
  exited: Promise<number>;
  /** Parsed --json line, after exit. */
  output(): Promise<RunOutput | null>;
  /** Last `error:` line on stderr. */
  error(): string;
  kill(): void;
}

function spawn(p: Plan, cwd: string, tools: boolean): Run {
  // A file, not argv: system prompts can be long.
  const systemDir = p.system ? mkdtempSync(join(tmpdir(), "agents-serve-")) : null;
  const systemFile = systemDir ? join(systemDir, "system.md") : null;
  if (systemFile) writeFileSync(systemFile, p.system ?? "");
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
      ...(tools ? [] : ["--no-tools"]),
      ...(systemFile ? ["--system-file", systemFile] : []),
      "--via",
      "serve",
      "-",
    ],
    { stdin: "pipe", stdout: "pipe", stderr: "pipe", env: process.env },
  );
  proc.stdin.write(p.prompt);
  proc.stdin.end();
  if (systemDir) proc.exited.then(() => rmSync(systemDir, { recursive: true, force: true }));

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
        // The agent's own stderr (e.g. a launch failure) only shows up here.
        else if (line.trim()) console.error(line);
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

// OpenAI usage; agents that report none give zeros.
function usage(out: RunOutput | null) {
  const prompt_tokens = out?.inputTokens ?? 0;
  const completion_tokens = out?.outputTokens ?? 0;
  return { prompt_tokens, completion_tokens, total_tokens: prompt_tokens + completion_tokens };
}

async function complete(p: Plan, o: ServeOptions, signal: AbortSignal): Promise<Response> {
  const run = spawn(p, o.cwd, o.tools);
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
    usage: usage(out),
  });
}

function stream(p: Plan, o: ServeOptions, signal: AbortSignal): Response {
  // A resumed session already has events; follow only the new ones.
  let read = p.resume ? tail(store.eventsPath(p.resume), true) : null;
  const run = spawn(p, o.cwd, o.tools);
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
        } else if (e.type === "tool" && o.toolEvents) {
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
      if (p.streamUsage) {
        write(
          `data: ${JSON.stringify({ id, object: "chat.completion.chunk", created, model: p.model, choices: [], usage: usage(out) })}\n\n`,
        );
      }
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

// Constant-time compare of the request's bearer token with the key.
function authorized(req: Request, key: string): boolean {
  const match = (req.headers.get("authorization") ?? "").match(/^Bearer\s+(.+)$/i);
  if (!match) return false;
  const digest = (s: string) => createHash("sha256").update(s).digest();
  return timingSafeEqual(digest(match[1].trim()), digest(key));
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
      if (o.apiKey !== null && !authorized(req, o.apiKey)) return json(errorBody("invalid API key"), 401);
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
        const p = plan(body, o.tools);
        return body.stream ? stream(p, o, req.signal) : complete(p, o, req.signal);
      }
      return json(errorBody(`no route ${req.method} ${pathname}`), 404);
    },
    error(err) {
      const status = err instanceof HttpError ? err.status : 500;
      return json(errorBody(err.message), status);
    },
  });
  const notes = [`cwd ${o.cwd}`, o.tools ? "tools" : "no tools", ...(o.apiKey === null ? ["no auth"] : [])];
  console.error(`agents serve: http://${server.hostname}:${server.port}/v1 (${notes.join(", ")})`);
}
