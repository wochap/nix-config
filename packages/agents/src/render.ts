// Renders normalized events for humans, like Claude Code does: messages as
// text (markdown via glow when installed), a dim line per tool call, a
// duration/cost line at the end.

import type { Event } from "./adapters/types";
import { color, log } from "./term";

const glow = Bun.which("glow");

async function printMessage(text: string) {
  if (!glow) {
    console.log(`\n${color.bold("⏺")} ${text}`);
    return;
  }
  const p = Bun.spawn([glow, "-"], { stdin: new Blob([text]), stdout: "inherit", stderr: "inherit" });
  await p.exited;
}

export const header = (agent: string, model: string, id: string) => log(`${agent} (${model}) ${id}`);

export async function render(e: Event) {
  switch (e.type) {
    case "text":
      return printMessage(e.text);
    case "tool":
      return console.log(`  ${color.dim(`· ${e.label}`)}`);
    case "result": {
      const secs = Math.floor((e.durationMs ?? 0) / 1000);
      const cost = (e.costUsd ?? 0).toFixed(2);
      return console.log(`\n${color.dim(`✓ finished (${secs}s, $${cost})`)}`);
    }
    case "error":
      return console.log(`\n${color.yellow(`✗ ${e.message}`)}`);
  }
}
