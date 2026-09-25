// Adapter: pi coding agent (`pi` CLI).
//
// Env:
//   PI_FLAGS="..."   extra flags (default none: pi has no tool permission
//                    prompts, and headless runs ignore untrusted project
//                    resources instead of asking; "--approve" trusts them)
//   PI_CMD="..."     launcher (default "sessiontap pi", see launch.ts)

import { appendFileSync, existsSync, readdirSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { track } from "../term";
import { launcher } from "./launch";
import type { Adapter, Effort, Event, RunOptions } from "./types";

const cmd = launcher("pi");
const permFlags = (process.env.PI_FLAGS ?? "").split(/\s+/).filter(Boolean);
// Normalized effort to pi's --thinking levels (pi also has off, minimal).
const EFFORT: Record<Effort, string> = { low: "low", medium: "medium", high: "high", xhigh: "xhigh", max: "max" };
const effortFlags = (effort?: Effort) => (effort ? ["--thinking", EFFORT[effort]] : []);

// Short label for a tool call: the agent's own description when it gave
// one, else tool name plus path. Never the command itself.
function toolLabel(block: any, root: string): string {
  const args = block.arguments ?? {};
  const label = args.description ?? [block.name, args.path ?? args.pattern ?? ""].join(" ");
  return String(label).replace(/\s+/g, " ").trim().split(`${root}/`).join("").slice(0, 120);
}

const texts = (message: any): string[] =>
  (message?.content ?? []).filter((b: any) => b.type === "text").map((b: any) => b.text);

// Maps one --mode json line to normalized events. Only complete messages
// (message_end); message_update deltas are ignored.
function toEvents(event: any, root: string, startedAt: number): Event[] {
  const message = event.message;
  if (event.type === "message_end" && message?.role === "assistant") {
    if (message.stopReason === "error") return [{ type: "error", message: message.errorMessage ?? "error" }];
    const out: Event[] = [];
    for (const block of message.content ?? []) {
      if (block.type === "text" && block.text) out.push({ type: "text", text: block.text });
      else if (block.type === "toolCall") out.push({ type: "tool", label: toolLabel(block, root) });
    }
    return out;
  }
  // agent_end carries the whole run; cost is the sum over its assistant
  // messages, duration is wall clock (pi reports neither as a total).
  if (event.type === "agent_end") {
    const assistant = (event.messages ?? []).filter((m: any) => m.role === "assistant");
    const final = assistant.at(-1);
    if (final?.stopReason === "error") return [];
    return [
      {
        type: "result",
        result: texts(final).join("\n"),
        costUsd: assistant.reduce((sum: number, m: any) => sum + (m.usage?.cost?.total ?? 0), 0),
        durationMs: Date.now() - startedAt,
      },
    ];
  }
  return [];
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

// Transcripts live in <sessions>/<encoded-cwd>/<timestamp>_<id>.jsonl.
function transcriptPath(id: string): string | null {
  const sessions =
    process.env.PI_CODING_AGENT_SESSION_DIR ??
    join(process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent"), "sessions");
  if (!existsSync(sessions)) return null;
  for (const dir of readdirSync(sessions)) {
    const path = join(sessions, dir);
    let files: string[];
    try {
      files = readdirSync(path);
    } catch {
      continue;
    }
    const f = files.find((name) => name.endsWith(`_${id}.jsonl`));
    if (f) return join(path, f);
  }
  return null;
}

export const pi: Adapter = {
  name: "pi",

  defaultModel: "omniroute/desktop-free", // the only model configured here

  // pi takes a caller-chosen id: --session-id creates the session when
  // missing and continues it otherwise, so new and resumed runs match.
  // Sessions are looked up per cwd, hence cwd is always the session's.
  async run({ id, prompt, model, effort, cwd, rawLog, signal, onEvent }: RunOptions) {
    const startedAt = Date.now();
    const child = track(
      Bun.spawn([...cmd, "--session-id", id, "--model", model, ...effortFlags(effort), ...permFlags, "--mode", "json", "-p", prompt], {
        cwd,
        stdin: "ignore",
        stdout: "pipe",
        stderr: "inherit",
      }),
    );
    signal?.addEventListener("abort", () => child.kill("SIGINT"));
    let result = "";

    for await (const line of lines(child.stdout)) {
      appendFileSync(rawLog, `${line}\n`);
      let event: any;
      try {
        event = JSON.parse(line);
      } catch {
        continue;
      }
      for (const e of toEvents(event, cwd, startedAt)) {
        if (e.type === "result") result = e.result;
        await onEvent(e);
      }
    }

    const code = await child.exited;
    if (code !== 0) throw new Error(`pi exited with code ${code}`);
    return { result };
  },

  async lastResponse(id) {
    const f = transcriptPath(id);
    if (!f) return null;
    let last: string | null = null;
    for (const line of readFileSync(f, "utf8").split("\n")) {
      if (!line) continue;
      try {
        const entry = JSON.parse(line);
        if (entry.type !== "message" || entry.message?.role !== "assistant") continue;
        const text = texts(entry.message).join("\n");
        if (text) last = text;
      } catch {}
    }
    return last;
  },

  takeOverCmd: (id, model, effort, prompt) => [...cmd, "--session-id", id, "--model", model, ...effortFlags(effort), ...permFlags, ...(prompt ? ["--", prompt] : [])],

  transcriptPath,

  // Transcript message entries hold what message_end carries.
  transcriptEvents(entry, root) {
    if (entry.type !== "message" || entry.message?.role !== "assistant") return { events: [], idle: false };
    return {
      events: toEvents({ type: "message_end", message: entry.message }, root, 0),
      idle: entry.message.stopReason !== "toolUse",
    };
  },
};
