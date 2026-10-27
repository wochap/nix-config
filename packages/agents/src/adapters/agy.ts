// Adapter: Google Antigravity CLI (`agy` CLI).
//
// Env:
//   AGY_FLAGS="..."   permission flags (default "--dangerously-skip-permissions")
//   AGY_CMD="..."     launcher (default "sessiontap agy", see launch.ts)
//   AGY_DATA_DIR="..." override for ~/.gemini/antigravity-cli

import { appendFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { dir } from "../store";
import { wrapCommand } from "../sandbox";
import { track } from "../term";
import { launcher } from "./launch";
import type { Adapter, Effort, Event, RunOptions } from "./types";

const cmd = launcher("agy");
const permFlags = (process.env.AGY_FLAGS ?? "--dangerously-skip-permissions").split(/\s+/).filter(Boolean);
const DEFAULT_EFFORT: Effort = "medium";
const EFFORT: Record<Effort, string> = { low: "low", medium: "medium", high: "high", xhigh: "xhigh", max: "max" };
const effortFlags = (effort: Effort = DEFAULT_EFFORT) => ["--effort", EFFORT[effort]];

// Antigravity's model catalog suffixes tiered models with -low/-medium/-high.
// Map bare family names (e.g. "gemini-4-argon", "gemini-3.8-flash") using the
// requested effort (defaulting to "medium"), while leaving explicit IDs untouched.
const TIERED_FAMILIES = new Set(["gemini-4-argon", "gemini-3.8-flash", "claude-opus-5-5", "claude-sonnet-5-5"]);
const MODEL_TIER: Record<Effort, "low" | "medium" | "high"> = {
  low: "low",
  medium: "medium",
  high: "high",
  xhigh: "high",
  max: "high",
};
function resolveModel(model: string, effort: Effort = DEFAULT_EFFORT): string {
  if (TIERED_FAMILIES.has(model)) {
    return `${model}-${MODEL_TIER[effort]}`;
  }
  return model;
}

const nativeIdPath = (id: string) => join(dir, `${id}.native`);

function readNativeId(id: string): string | null {
  const p = nativeIdPath(id);
  if (existsSync(p)) {
    const val = readFileSync(p, "utf8").trim();
    if (val) return val;
  }
  const rawP = join(dir, `${id}.raw.jsonl`);
  if (existsSync(rawP)) {
    try {
      const content = readFileSync(rawP, "utf8");
      for (const line of content.split("\n")) {
        if (!line) continue;
        try {
          const parsed = JSON.parse(line);
          const cid = parsed.conversation_id ?? parsed.step_update?.conversation_id ?? parsed.result?.conversation_id;
          if (cid) return String(cid);
        } catch {}
      }
    } catch {}
  }
  return null;
}

function toolLabel(name: string, params: Record<string, any> = {}, root: string): string {
  const p = params ?? {};
  let label = name;
  if (name === "run_command") {
    label = p.toolSummary ? `run_command ${p.toolSummary}` : "run_command";
  } else {
    const target =
      p.Path ??
      p.path ??
      p.DirectoryPath ??
      p.directory_path ??
      p.Query ??
      p.query ??
      p.Pattern ??
      p.pattern ??
      p.Role ??
      p.role ??
      p.Url ??
      p.url ??
      p.description ??
      "";
    if (target) {
      label = `${name} ${target}`;
    }
  }
  return String(label).replace(/\s+/g, " ").trim().split(`${root}/`).join("").slice(0, 120);
}

async function* lines(stream: ReadableStream<Uint8Array>) {
  const decoder = new TextDecoder();
  let buf = "";
  for await (const chunk of stream) {
    buf += decoder.decode(chunk, { stream: true });
    let i: number;
    while ((i = buf.indexOf("\n")) >= 0) {
      yield buf.slice(0, i);
      buf = buf.slice(i + 1);
    }
  }
  if (buf) yield buf;
}

function transcriptPath(id: string): string | null {
  const nativeId = readNativeId(id) ?? id;
  const dataDir = process.env.AGY_DATA_DIR || join(homedir(), ".gemini", "antigravity-cli");
  const full = join(dataDir, "brain", nativeId, ".system_generated", "logs", "transcript_full.jsonl");
  if (existsSync(full)) return full;
  const compact = join(dataDir, "brain", nativeId, ".system_generated", "logs", "transcript.jsonl");
  if (existsSync(compact)) return compact;
  return null;
}

async function lastResponse(id: string): Promise<string | null> {
  const f = transcriptPath(id);
  if (!f) return null;
  let last: string | null = null;
  for (const line of readFileSync(f, "utf8").split("\n")) {
    if (!line) continue;
    try {
      const entry = JSON.parse(line);
      if (entry.type === "PLANNER_RESPONSE" && typeof entry.content === "string" && entry.content.trim()) {
        last = entry.content;
      }
    } catch {}
  }
  return last;
}

function takeOverCmd(id: string, model: string, effort?: Effort, prompt?: string): string[] {
  const nativeId = readNativeId(id) ?? id;
  return [
    ...cmd,
    "--conversation",
    nativeId,
    "--model",
    resolveModel(model, effort),
    ...effortFlags(effort),
    ...permFlags,
    ...(prompt ? ["-i", prompt] : []),
  ];
}

function transcriptEvents(entry: any, root: string): { events: Event[]; idle: boolean } {
  if (entry.type !== "PLANNER_RESPONSE") return { events: [], idle: false };
  const out: Event[] = [];
  if (typeof entry.content === "string" && entry.content.trim()) {
    out.push({ type: "text", text: entry.content });
  }
  for (const tc of entry.tool_calls ?? []) {
    out.push({ type: "tool", label: toolLabel(tc.name ?? "tool", tc.args ?? {}, root) });
  }
  return { events: out, idle: entry.status === "DONE" && !(entry.tool_calls?.length > 0) };
}

export const agy: Adapter = {
  name: "agy",
  defaultModel: "gemini-3.8-flash",
  supportsNoTools: (sandbox) => sandbox === "strict" && Boolean(Bun.which("bwrap")),

  async run({ id, prompt, model, effort, cwd, resume, noTools, systemFile, images, rawLog, signal, sandbox, onEvent }: RunOptions) {
    const effectivePrompt = noTools
      ? `IMPORTANT: Do not call or invoke any tools. Answer directly using plain text only.\n\n${prompt}`
      : prompt;
    const stdin = `${JSON.stringify({ event: "user", message: { role: "user", content: [{ type: "text", text: effectivePrompt }] } })}\n`;
    const child = track(
      Bun.spawn(
        wrapCommand(
          [
            ...cmd,
            "--input-format",
            "stream-json",
            "--output-format",
            "stream-json",
            "--model",
            resolveModel(model, effort),
            ...effortFlags(effort),
            ...(noTools ? [] : permFlags),
            ...(resume ? ["--conversation", readNativeId(id) ?? id] : []),
            "-p=",
          ],
          {
            mode: sandbox,
            cwd,
            agent: "agy",
            systemFile,
            images,
            noToolsHook: noTools ? join(import.meta.dir, "agy-no-tools-hooks.json") : undefined,
          },
        ),
        { cwd, stdin: new Blob([stdin]), stdout: "pipe", stderr: "inherit" },
      ),
    );
    signal?.addEventListener("abort", () => child.kill("SIGINT"));

    let result = "";
    let error: string | null = null;
    let savedNativeId = existsSync(nativeIdPath(id));
    const accumulatedText = new Map<number, string>();

    for await (const line of lines(child.stdout)) {
      appendFileSync(rawLog, `${line}\n`);
      let event: any;
      try {
        event = JSON.parse(line);
      } catch {
        continue;
      }

      const cid = event.conversation_id ?? event.step_update?.conversation_id ?? event.result?.conversation_id;
      if (!savedNativeId && cid) {
        try {
          mkdirSync(dir, { recursive: true });
          writeFileSync(nativeIdPath(id), `${cid}\n`);
          savedNativeId = true;
        } catch {}
      }

      if (event.event === "step_update") {
        const su = event.step_update ?? {};
        if (su.step_type === "agent_response") {
          const idx = su.step_index ?? 0;
          accumulatedText.set(idx, (accumulatedText.get(idx) ?? "") + (su.text_delta ?? ""));
          if (su.state === "DONE") {
            const text = accumulatedText.get(idx) ?? "";
            accumulatedText.delete(idx);
            if (text.trim()) {
              await onEvent({ type: "text", text });
            }
          }
        } else if (su.step_type === "tool" && su.state === "ACTIVE") {
          const name = su.tool_info?.name ?? su.tool_name ?? "tool";
          const params = su.tool_info?.parameters ?? {};
          const label = toolLabel(name, params, cwd);
          await onEvent({ type: "tool", label });
        }
      } else if (event.event === "result") {
        const r = event.result ?? {};
        if (r.status === "ERROR" || r.error) {
          error = String(r.error || "agy error");
          if (!r.response) {
            await onEvent({ type: "error", message: error });
          }
        } else {
          result = r.response ?? "";
          await onEvent({
            type: "result",
            result: r.response ?? "",
            durationMs: r.duration_seconds != null ? Math.round(r.duration_seconds * 1000) : undefined,
            inputTokens: (r.usage?.input_tokens ?? 0) + (r.usage?.cache_read_tokens ?? 0),
            outputTokens: r.usage?.output_tokens ?? 0,
          });
        }
      }
    }

    const code = await child.exited;
    if (error) throw new Error(error);
    if (code !== 0) throw new Error(`agy exited with code ${code}`);
    return { result };
  },

  lastResponse,
  takeOverCmd,
  transcriptPath,
  transcriptEvents,
};
