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
// Images: image_url parts of the last user message, as data: URLs only
// (fetching a GUI-given URL from this machine is an SSRF risk), go to
// `run --image`; earlier turns' images become "[image]" in a flattened
// history. Agents without Adapter.images get a 400.
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
import { extension, IMAGE_TYPES, type ImageType, MAX_IMAGE_BASE64, MAX_IMAGES, sniff } from "./image";
import type { SandboxMode } from "./sandbox";
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
  /** Bubblewrap sandbox mode (default: "strict"). */
  sandbox?: SandboxMode;
}

export interface ToolCall {
  id: string;
  type: "function";
  function: { name: string; arguments: string };
}

export interface ToolDef {
  type: "function";
  function: { name: string; description?: string; parameters?: Record<string, unknown> };
}

export interface Message {
  role: string;
  content: unknown;
  name?: string;
  tool_call_id?: string;
  tool_calls?: ToolCall[];
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

/** URLs of the image_url parts; clients send {url} or a bare string. */
function imageUrls(m: Message): string[] {
  if (!Array.isArray(m.content)) return [];
  return m.content
    .filter((p) => p?.type === "image_url")
    .map((p) => (typeof p.image_url === "string" ? p.image_url : p.image_url?.url))
    .filter((u): u is string => typeof u === "string");
}

/** Text with a marker per image, for turns whose images are not sent. */
function textWithMarkers(m: Message): string {
  const markers = imageUrls(m).map(() => "[image]");
  return [text(m), ...markers].filter(Boolean).join("\n");
}

interface Image {
  type: ImageType;
  bytes: Uint8Array;
}

/** Decodes a base64 data: URL; the type comes from the bytes, not the URL. */
function decodeImage(url: string): Image {
  const match = url.match(/^data:[^;,]*(;[^,]*)?;base64,(.*)$/s);
  if (!match) {
    throw new HttpError(400, /^https?:/.test(url) ? "image_url: only base64 data: URLs are accepted" : "image_url: invalid data: URL");
  }
  const base64 = match[2].replace(/\s/g, "");
  if (base64.length > MAX_IMAGE_BASE64) {
    throw new HttpError(413, `image_url: image over ${MAX_IMAGE_BASE64 / 1024 / 1024} MiB base64`);
  }
  const bytes = new Uint8Array(Buffer.from(base64, "base64"));
  const type = sniff(bytes);
  if (!type) throw new HttpError(400, `image_url: not a ${IMAGE_TYPES.map(extension).join("/")} image`);
  return { type, bytes };
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
export const fp = (model: string, messages: Message[]) =>
  createHash("sha256")
    .update(
      JSON.stringify([
        model,
        messages.map((m) => [
          m.role,
          text(m).trim(),
          m.tool_call_id ?? "",
          m.tool_calls ? m.tool_calls.map((c) => [c.id, c.function?.name, c.function?.arguments]) : [],
        ]),
      ]),
    )
    .digest("hex");

const isSystem = (m: Message) => m.role === "system" || m.role === "developer";

/** History as one prompt, for a conversation the server has not seen. */
export function flatten(messages: Message[]): string {
  const toolNames = new Map<string, string>();
  for (const m of messages) {
    if (m.tool_calls) {
      for (const tc of m.tool_calls) {
        if (tc.id && tc.function?.name) toolNames.set(tc.id, tc.function.name);
      }
    }
  }

  const turns = messages.filter(
    (m) => m.role === "user" || m.role === "assistant" || m.role === "tool" || m.role === "function",
  );
  if (turns.length === 1 && turns[0].role === "user") return text(turns[0]);

  return turns
    .map((m) => {
      if (m.role === "user") {
        const body = m === turns.at(-1) ? text(m) : textWithMarkers(m);
        return `user: ${body}`;
      }
      if (m.role === "assistant") {
        const parts: string[] = [];
        const txt = text(m).trim();
        if (txt) parts.push(txt);
        if (m.tool_calls && m.tool_calls.length > 0) {
          for (const tc of m.tool_calls) {
            let argsObj: any;
            try {
              argsObj = typeof tc.function?.arguments === "string" ? JSON.parse(tc.function.arguments) : tc.function?.arguments;
            } catch {
              argsObj = tc.function?.arguments;
            }
            parts.push(`<tool_call>${JSON.stringify({ name: tc.function?.name, arguments: argsObj })}</tool_call>`);
          }
        }
        return `assistant: ${parts.join("\n")}`;
      }
      if (m.role === "tool" || m.role === "function") {
        const id = m.tool_call_id ?? "";
        const name = (id ? toolNames.get(id) : undefined) ?? m.name ?? "";
        const body = typeof m.content === "string" ? m.content : JSON.stringify(m.content);
        return `<tool_result name="${name}" id="${id}">\n${body}\n</tool_result>`;
      }
      return `${m.role}: ${text(m)}`;
    })
    .join("\n\n");
}

export function buildToolInstructions(
  tools: ToolDef[],
  toolChoice: any,
  parallel: boolean,
  agentName: string,
): string {
  let effectiveTools = tools;
  let choiceInstruction = "";
  if (typeof toolChoice === "object" && toolChoice?.function?.name) {
    effectiveTools = tools.filter((t) => t.function.name === toolChoice.function.name);
    choiceInstruction = `\nYou MUST call function '${toolChoice.function.name}'.`;
  } else if (toolChoice === "required") {
    choiceInstruction = "\nYou MUST call at least one function.";
  }
  const parallelInstruction = !parallel ? "\nCall at most one function." : "";
  const agyPrefix =
    agentName === "agy" ? "Your built-in tools are disabled; use only the functions listed below.\n\n" : "";

  return `${agyPrefix}You can call these external functions. They are executed by the user's system, not by you; you cannot see results until they are returned to you.
<functions>
${JSON.stringify(effectiveTools.map((t) => t.function), null, 2)}
</functions>
To call a function, output exactly:
<tool_call>{"name": "<function_name>", "arguments": { ... }}</tool_call>
You may write a short sentence before the call. To call several functions, output several <tool_call> blocks. After calling, stop and wait for <tool_result>. If no function is needed, answer normally.${choiceInstruction}${parallelInstruction}`;
}

export interface ParsedToolOutput {
  content: string | null;
  toolCalls: ToolCall[];
}

export function parseToolCalls(raw: string, declaredTools: ToolDef[], parallel: boolean = true): ParsedToolOutput {
  const validNames = new Map(declaredTools.map((t) => [t.function.name, t]));
  const toolCalls: ToolCall[] = [];

  const toolCallRegex = /<tool_call>([\s\S]*?)(?:<\/tool_call>|$)/gi;
  let match: RegExpExecArray | null;

  while ((match = toolCallRegex.exec(raw)) !== null) {
    let inner = match[1].trim();
    if (!inner) continue;
    const fenceMatch = inner.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/i);
    if (fenceMatch) inner = fenceMatch[1].trim();

    try {
      const parsed = JSON.parse(inner);
      if (parsed && typeof parsed.name === "string" && validNames.has(parsed.name)) {
        const def = validNames.get(parsed.name)!;
        let args = parsed.arguments;
        if (typeof args === "string") {
          try {
            args = JSON.parse(args);
          } catch {}
        }
        if (typeof args !== "object" || args === null) {
          args = {};
        }

        const required = (def.function.parameters as any)?.required;
        let valid = true;
        if (Array.isArray(required)) {
          for (const reqKey of required) {
            if (typeof reqKey === "string" && !(reqKey in args)) {
              valid = false;
              break;
            }
          }
        }
        if (!valid) continue;

        const id = `call_${crypto.randomUUID().replaceAll("-", "").slice(0, 24)}`;
        toolCalls.push({
          id,
          type: "function",
          function: {
            name: parsed.name,
            arguments: JSON.stringify(args),
          },
        });
      }
    } catch {}
  }

  if (toolCalls.length === 0) {
    return { content: raw, toolCalls: [] };
  }

  const effectiveCalls = parallel ? toolCalls : toolCalls.slice(0, 1);
  const stripped = raw.replace(/<tool_call>[\s\S]*?(?:<\/tool_call>|$)/gi, "").trim();
  return {
    content: stripped || null,
    toolCalls: effectiveCalls,
  };
}

export interface Plan {
  model: string;
  agent: string;
  agentModel: string;
  effort?: Effort;
  prompt: string;
  /** The request's system messages; replaces the agent's system prompt. */
  system?: string;
  resume?: string;
  /** Images of the last user message. */
  images: Image[];
  messages: Message[];
  /** Send a usage chunk before [DONE] (stream_options.include_usage). */
  streamUsage: boolean;
  tools: ToolDef[];
  toolChoice?: any;
  parallelToolCalls: boolean;
}

export function plan(body: any, tools: boolean, sandbox: SandboxMode = "strict"): Plan {
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

  const rawTools = body?.tools;
  const toolsList: ToolDef[] = [];
  if (rawTools !== undefined && rawTools !== null) {
    if (!Array.isArray(rawTools)) throw new HttpError(400, "tools must be an array");
    const seenNames = new Set<string>();
    for (const t of rawTools) {
      if (t?.type !== "function" || typeof t?.function?.name !== "string") {
        throw new HttpError(400, "each tool must be {type: 'function', function: {name: string}}");
      }
      const name = t.function.name;
      if (!/^[a-zA-Z0-9_-]{1,64}$/.test(name)) {
        throw new HttpError(400, `invalid tool name "${name}": must match ^[a-zA-Z0-9_-]{1,64}$`);
      }
      if (seenNames.has(name)) {
        throw new HttpError(400, `duplicate tool name "${name}"`);
      }
      seenNames.add(name);
      toolsList.push({
        type: "function",
        function: {
          name,
          description: typeof t.function.description === "string" ? t.function.description : undefined,
          parameters: typeof t.function.parameters === "object" && t.function.parameters !== null ? t.function.parameters : undefined,
        },
      });
    }
  }

  let toolChoice = body?.tool_choice;
  if (toolChoice !== undefined && toolChoice !== null) {
    if (typeof toolChoice === "string") {
      if (toolChoice !== "auto" && toolChoice !== "none" && toolChoice !== "required") {
        throw new HttpError(400, `tool_choice: expected auto, none, required, or a function object (got "${toolChoice}")`);
      }
    } else if (typeof toolChoice === "object" && toolChoice?.type === "function" && typeof toolChoice?.function?.name === "string") {
      const name = toolChoice.function.name;
      if (!toolsList.some((t) => t.function.name === name)) {
        throw new HttpError(400, `tool_choice specifies unknown tool "${name}"`);
      }
    } else {
      throw new HttpError(400, "invalid tool_choice format");
    }
  }

  const parallelToolCalls = body?.parallel_tool_calls !== false;
  const hasHarnessTools = toolsList.length > 0;

  if ((!tools || hasHarnessTools) && !adapter.supportsNoTools(sandbox)) {
    throw new HttpError(400, `${adapter.name} cannot run without tools`);
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
  if (!lastMsg) throw new HttpError(400, "messages must not be empty");

  let isToolResultTurn = false;
  if (lastMsg.role === "tool" || lastMsg.role === "function") {
    isToolResultTurn = true;
    let assistantIdx = -1;
    for (let i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role === "assistant") {
        assistantIdx = i;
        break;
      }
    }
    if (assistantIdx === -1 || !messages[assistantIdx].tool_calls || messages[assistantIdx].tool_calls!.length === 0) {
      throw new HttpError(400, "tool result turn must be preceded by an assistant message with tool_calls");
    }
    const assistantCalls = messages[assistantIdx].tool_calls!;
    const validCallIds = new Set(assistantCalls.map((tc) => tc.id));
    const validCallNames = new Set(assistantCalls.map((tc) => tc.function?.name));

    for (let i = assistantIdx + 1; i < messages.length; i++) {
      const m = messages[i];
      if (m.role !== "tool" && m.role !== "function") {
        throw new HttpError(400, `unexpected ${m.role} message after assistant tool calls; expected tool results`);
      }
      if (m.tool_call_id) {
        if (!validCallIds.has(m.tool_call_id)) {
          throw new HttpError(400, `tool message has tool_call_id "${m.tool_call_id}" which does not match any preceding assistant tool_calls`);
        }
      } else if (m.name) {
        if (!validCallNames.has(m.name)) {
          throw new HttpError(400, `tool message has name "${m.name}" which does not match any preceding assistant tool_calls`);
        }
      } else {
        throw new HttpError(400, "tool message must have tool_call_id (or name)");
      }
    }
  } else if (lastMsg.role === "user") {
    const urls = imageUrls(lastMsg);
    if (!(text(lastMsg).trim() || urls.length)) {
      throw new HttpError(400, "messages must end with a non-empty user message");
    }
  } else {
    throw new HttpError(400, `messages must end with a user or tool message (got ${lastMsg.role})`);
  }

  const urls = (!isToolResultTurn && lastMsg.role === "user") ? imageUrls(lastMsg) : [];
  if (urls.length && !adapter.images) throw new HttpError(400, `${adapter.name} cannot take images`);
  if (urls.length > MAX_IMAGES) throw new HttpError(400, `at most ${MAX_IMAGES} images per message`);
  const images = urls.map(decodeImage);

  let system = messages.filter(isSystem).map(text).join("\n\n").trim() || undefined;
  if (hasHarnessTools && toolChoice !== "none") {
    const toolInstructions = buildToolInstructions(toolsList, toolChoice, parallelToolCalls, adapter.name);
    system = system ? `${system}\n\n${toolInstructions}` : toolInstructions;
  }

  const streamUsage = Boolean(body.stream_options?.include_usage);
  const base = {
    model,
    agent: adapter.name,
    agentModel,
    effort,
    system,
    images,
    messages,
    streamUsage,
    tools: toolsList,
    toolChoice,
    parallelToolCalls,
  };

  if (hasHarnessTools || isToolResultTurn) {
    return { ...base, prompt: flatten(messages) };
  }

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

function spawn(p: Plan, cwd: string, tools: boolean, sandbox: SandboxMode = "strict"): Run {
  // Files, not argv: system prompts can be long, images are bytes. The
  // agents read them at startup (claude via `run`, pi itself).
  const tmp = p.system || p.images.length ? mkdtempSync(join(tmpdir(), "agents-serve-")) : null;
  const cleanup = () => tmp && rmSync(tmp, { recursive: true, force: true });
  const systemFile = tmp && p.system ? join(tmp, "system.md") : null;
  if (systemFile) writeFileSync(systemFile, p.system ?? "", { mode: 0o600 });
  const imageFiles = p.images.map((image, i) => {
    const f = join(tmp ?? "", `image-${i}.${extension(image.type)}`);
    writeFileSync(f, image.bytes, { mode: 0o600 });
    return f;
  });
  const effectiveTools = p.tools.length > 0 ? false : tools;
  const argv = [
    process.execPath,
    join(import.meta.dir, "main.ts"),
    "run",
    "--json",
    "--sandbox",
    sandbox,
    "-a",
    p.agent,
    "-m",
    p.agentModel,
    ...(p.effort ? ["-e", p.effort] : []),
    "-C",
    cwd,
    ...(p.resume ? ["-r", p.resume] : []),
    ...(effectiveTools ? [] : ["--no-tools"]),
    ...(systemFile ? ["--system-file", systemFile] : []),
    ...imageFiles.flatMap((f) => ["--image", f]),
    "--via",
    "serve",
    "-",
  ];
  let proc;
  try {
    proc = Bun.spawn(argv, { stdin: "pipe", stdout: "pipe", stderr: "pipe", env: process.env });
  } catch (err) {
    cleanup();
    throw err;
  }
  proc.stdin.write(p.prompt);
  proc.stdin.end();
  proc.exited.then(cleanup);

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

// Runs longer than this answer with keepalive whitespace first, so a client
// or proxy with a response-start timeout (OmniRoute: 30 s) does not give up and
// kill the run. Faster runs keep their real HTTP status.
const EARLY_HEADERS_MS = 10_000;

async function complete(p: Plan, o: ServeOptions, signal: AbortSignal): Promise<Response> {
  const run = spawn(p, o.cwd, o.tools, o.sandbox ?? "strict");
  signal.addEventListener("abort", run.kill);

  const reply = async (): Promise<{ body: unknown; status: number }> => {
    let out = await run.output();
    if (!out) return { body: errorBody(run.error() || "agents run printed no result"), status: 500 };
    if (out.status !== "done") return { body: errorBody(out.result || run.error() || "agent failed"), status: 500 };

    let parsed = p.tools.length > 0 ? parseToolCalls(out.result, p.tools, p.parallelToolCalls) : null;
    const isNamedChoice = typeof p.toolChoice === "object" && Boolean(p.toolChoice?.function?.name);
    const requiredSatisfied = parsed && (
      isNamedChoice
        ? parsed.toolCalls.some((tc) => tc.function.name === (p.toolChoice as any).function.name)
        : parsed.toolCalls.length > 0
    );

    if (p.tools.length > 0 && (p.toolChoice === "required" || isNamedChoice) && !requiredSatisfied) {
      const reminder = isNamedChoice
        ? `You MUST call function '${(p.toolChoice as any).function.name}' using <tool_call> tags.`
        : "You MUST call at least one function using <tool_call> tags.";
      const retryPlan: Plan = {
        ...p,
        prompt: `${p.prompt}\n\nassistant: ${out.result}\n\nuser: ${reminder}`,
      };
      const retryRun = spawn(retryPlan, o.cwd, false, o.sandbox ?? "strict");
      signal.addEventListener("abort", retryRun.kill);
      const retryOut = await retryRun.output();
      if (retryOut && retryOut.status === "done") {
        out = retryOut;
        parsed = parseToolCalls(out.result, p.tools, p.parallelToolCalls);
      }
    }

    if (parsed && parsed.toolCalls.length > 0) {
      return {
        status: 200,
        body: {
          id: completionId(out.id),
          object: "chat.completion",
          created: now(),
          model: p.model,
          choices: [
            {
              index: 0,
              message: {
                role: "assistant",
                content: parsed.content,
                tool_calls: parsed.toolCalls,
              },
              finish_reason: "tool_calls",
            },
          ],
          usage: usage(out),
        },
      };
    }

    if (p.tools.length === 0) {
      remembered(p, out.id, [out.result]);
    }

    return {
      status: 200,
      body: {
        id: completionId(out.id),
        object: "chat.completion",
        created: now(),
        model: p.model,
        choices: [
          {
            index: 0,
            message: { role: "assistant", content: parsed?.content ?? out.result },
            finish_reason: "stop",
          },
        ],
        usage: usage(out),
      },
    };
  };

  const pending = reply();
  const early = await Promise.race([pending, Bun.sleep(EARLY_HEADERS_MS).then(() => null)]);
  if (early) return json(early.body, early.status);

  // Headers go out now with a 200; a late failure is reported as an error
  // object in the body. Leading whitespace is valid JSON.
  const encoder = new TextEncoder();
  let timer: ReturnType<typeof setInterval>;
  const body = new ReadableStream({
    async start(controller) {
      controller.enqueue(encoder.encode(" "));
      timer = setInterval(() => {
        try {
          controller.enqueue(encoder.encode(" "));
        } catch {}
      }, 15_000);
      try {
        const { body: result } = await pending;
        controller.enqueue(encoder.encode(JSON.stringify(result)));
        controller.close();
      } catch {
      } finally {
        clearInterval(timer);
      }
    },
    cancel() {
      clearInterval(timer);
      run.kill();
    },
  });
  return new Response(body, { headers: { "Content-Type": "application/json", "Cache-Control": "no-cache" } });
}

function stream(p: Plan, o: ServeOptions, signal: AbortSignal): Response {
  // A resumed session already has events; follow only the new ones.
  let read = p.resume ? tail(store.eventsPath(p.resume), true) : null;
  const run = spawn(p, o.cwd, o.tools, o.sandbox ?? "strict");
  signal.addEventListener("abort", run.kill);
  const encoder = new TextEncoder();
  const created = now();
  const inToolMode = p.tools.length > 0;

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

      if (inToolMode) {
        // Buffered mode for tool calls: do not forward intermediate text events
        let exited = false;
        run.exited.then(() => {
          exited = true;
        });
        const sessionId = await run.id;
        if (sessionId) id = completionId(sessionId);

        while (!exited) {
          if (Date.now() - lastWrite > 15_000) write(": ping\n\n");
          await Bun.sleep(200);
        }

        let out = await run.output();
        if (out?.status !== "done") {
          const failure = out?.result || run.error() || "agent failed";
          write(`data: ${JSON.stringify(errorBody(failure))}\n\n`);
          write("data: [DONE]\n\n");
          if (!closed) controller.close();
          return;
        }

        let parsed = parseToolCalls(out.result, p.tools, p.parallelToolCalls);
        const isNamedChoice = typeof p.toolChoice === "object" && Boolean(p.toolChoice?.function?.name);
        const requiredSatisfied = (
          isNamedChoice
            ? parsed.toolCalls.some((tc) => tc.function.name === (p.toolChoice as any).function.name)
            : parsed.toolCalls.length > 0
        );

        if ((p.toolChoice === "required" || isNamedChoice) && !requiredSatisfied) {
          const reminder = isNamedChoice
            ? `You MUST call function '${(p.toolChoice as any).function.name}' using <tool_call> tags.`
            : "You MUST call at least one function using <tool_call> tags.";
          const retryPlan: Plan = {
            ...p,
            prompt: `${p.prompt}\n\nassistant: ${out.result}\n\nuser: ${reminder}`,
          };
          const retryRun = spawn(retryPlan, o.cwd, false, o.sandbox ?? "strict");
          signal.addEventListener("abort", retryRun.kill);
          let retryExited = false;
          retryRun.exited.then(() => {
            retryExited = true;
          });
          while (!retryExited) {
            if (Date.now() - lastWrite > 15_000) write(": ping\n\n");
            await Bun.sleep(200);
          }
          const retryOut = await retryRun.output();
          if (retryOut && retryOut.status === "done") {
            out = retryOut;
            parsed = parseToolCalls(out.result, p.tools, p.parallelToolCalls);
          }
        }

        if (parsed.toolCalls.length > 0) {
          if (parsed.content) {
            chunk({ content: parsed.content }, null);
          }
          for (let i = 0; i < parsed.toolCalls.length; i++) {
            const tc = parsed.toolCalls[i];
            chunk(
              {
                tool_calls: [
                  {
                    index: i,
                    id: tc.id,
                    type: "function",
                    function: {
                      name: tc.function.name,
                      arguments: tc.function.arguments,
                    },
                  },
                ],
              },
              null,
            );
          }
          chunk({}, "tool_calls");
        } else {
          chunk({ content: parsed.content ?? out.result }, null);
          chunk({}, "stop");
        }

        if (p.streamUsage) {
          write(
            `data: ${JSON.stringify({ id, object: "chat.completion.chunk", created, model: p.model, choices: [], usage: usage(out) })}\n\n`,
          );
        }
        write("data: [DONE]\n\n");
        if (!closed) controller.close();
        return;
      }

      // Non-tool mode: What the GUI shows, and so echoes back next turn.
      let sent = "";
      let lastText = "";
      let sawText = false;
      let ended = false;
      let failure: string | null = null;
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
          failure = e.message;
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
      } else if (!ended || failure !== null) {
        failure = failure ?? (out?.result || run.error() || "agent failed");
      }
      if (failure !== null && out?.status !== "done") {
        // Not answer text: clients must be able to tell a failure from a reply.
        write(`data: ${JSON.stringify(errorBody(failure))}\n\n`);
        write("data: [DONE]\n\n");
        if (!closed) controller.close();
        return;
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
  if ((o.sandbox ?? "strict") === "strict" && !Bun.which("bwrap")) {
    throw new Error("serve: strict sandbox requires bubblewrap (bwrap)");
  }
  const models = o.models?.length ? o.models : Object.values(adapters).map((a) => `${a.name}/${a.defaultModel}`);

  const server = Bun.serve({
    hostname: o.host,
    port: o.port,
    // Runs take minutes; streams send a ping every 15 s.
    idleTimeout: 0,
    // Room for MAX_IMAGES images plus history; larger bodies get a 413.
    maxRequestBodySize: 32 * 1024 * 1024,
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
        const p = plan(body, o.tools, o.sandbox ?? "strict");
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
