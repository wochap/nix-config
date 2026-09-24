// Renders normalized events for humans, like Claude Code does: messages as
// text (markdown via glow when installed), a dim line per tool call, a
// duration/cost line at the end. Writes to the progress stream (term.out).

import type { Event } from "./adapters/types";
import { color, log, out, println } from "./term";

const glow = Bun.which("glow");

async function printMessage(text: string) {
  if (!glow) {
    println(`\n${color.bold("⏺")} ${text}`);
    return;
  }
  const p = Bun.spawn([glow, "-"], { stdin: new Blob([text]), stdout: out.fd, stderr: "inherit" });
  await p.exited;
}

export const header = (agent: string, model: string, id: string) => log(`${agent} (${model}) ${id}`);

/** Dim one-line hint, e.g. the keys that work right now. */
export const hint = (text: string) => println(color.dim(text));

export async function render(e: Event) {
  switch (e.type) {
    case "text":
      return printMessage(e.text);
    case "tool":
      return println(`  ${color.dim(`· ${e.label}`)}`);
    case "result": {
      const secs = Math.floor((e.durationMs ?? 0) / 1000);
      const cost = (e.costUsd ?? 0).toFixed(2);
      return println(`\n${color.dim(`✓ finished (${secs}s, $${cost})`)}`);
    }
    case "error":
      return println(`\n${color.yellow(`✗ ${e.message}`)}`);
    case "takeover":
      return println(`\n${color.blue("⇄ you took over")}`);
    case "handback":
      return println(`\n${color.blue("⇄ handed back")}`);
  }
}
