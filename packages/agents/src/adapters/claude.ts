// Adapter: Claude Code (`claude` CLI).
//
// Env:
//   CLAUDE_FLAGS="..."   permission flags (default "--permission-mode auto")
//   CLAUDE_CMD="..."     launcher (default "sessiontap claude", see launch.ts)

import { appendFileSync, existsSync, readdirSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { track } from "../term";
import { launcher } from "./launch";
import type { Adapter, Event, RunOptions } from "./types";

const cmd = launcher("claude");
const permFlags = (process.env.CLAUDE_FLAGS ?? "--permission-mode auto").split(/\s+/).filter(Boolean);

// Short label for a tool call: the agent's own description when it gave
// one, else tool name plus path. Never the command itself.
function toolLabel(block: any, root: string): string {
  const input = block.input ?? {};
  const label =
    input.description ?? [block.name, input.file_path ?? input.pattern ?? input.skill ?? ""].join(" ");
  return String(label).replace(/\s+/g, " ").split(`${root}/`).join("").slice(0, 120);
}

// Maps one stream-json line to normalized events.
function toEvents(event: any, root: string): Event[] {
  if (event.type === "assistant") {
    const out: Event[] = [];
    for (const block of event.message?.content ?? []) {
      if (block.type === "text") out.push({ type: "text", text: block.text });
      else if (block.type === "tool_use") out.push({ type: "tool", label: toolLabel(block, root) });
    }
    return out;
  }
  if (event.type === "result") {
    if (event.is_error && !event.result) return [{ type: "error", message: event.subtype ?? "error" }];
    return [
      { type: "result", result: event.result ?? "", costUsd: event.total_cost_usd, durationMs: event.duration_ms },
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

function transcriptPath(id: string): string | null {
  const projects = join(homedir(), ".claude", "projects");
  if (!existsSync(projects)) return null;
  for (const dir of readdirSync(projects)) {
    const f = join(projects, dir, `${id}.jsonl`);
    if (existsSync(f)) return f;
  }
  return null;
}

export const claude: Adapter = {
  name: "claude",

  defaultModel: "claude-opus-5-5[1m]", // Opus 5.5, 1M context

  async run({ id, prompt, model, cwd, resume, rawLog, signal, onEvent }: RunOptions) {
    const child = track(
      Bun.spawn(
        [
          ...cmd,
          "-p",
          prompt,
          "--model",
          model,
          ...permFlags,
          "--output-format",
          "stream-json",
          "--verbose",
          resume ? "--resume" : "--session-id",
          id,
        ],
        { cwd, stdin: "ignore", stdout: "pipe", stderr: "inherit" },
      ),
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
      for (const e of toEvents(event, cwd)) {
        if (e.type === "result") result = e.result;
        await onEvent(e);
      }
    }

    const code = await child.exited;
    if (code !== 0) throw new Error(`claude exited with code ${code}`);
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
        if (entry.type !== "assistant") continue;
        for (const block of entry.message?.content ?? []) if (block.type === "text") last = block.text;
      } catch {}
    }
    return last;
  },

  // Same model as the headless run keeps the prompt cache warm. Runs in the
  // session's cwd: claude looks sessions up per project directory.
  takeOverCmd: (id, model, prompt) => [...cmd, "--resume", id, "--model", model, ...permFlags, ...(prompt ? ["--", prompt] : [])],

  transcriptPath,

  // Transcript assistant entries have the stream-json shape. Synthetic ones
  // (e.g. "No response requested." after an interrupt) are claude's, not the model's.
  transcriptEvents(entry, root) {
    if (entry.type !== "assistant" || entry.message?.model === "<synthetic>") return { events: [], idle: false };
    return { events: toEvents(entry, root), idle: entry.message?.stop_reason === "end_turn" };
  },
};
