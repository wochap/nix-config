// Adapter: Claude Code (`claude` CLI).
//
// Env:
//   CLAUDE_FLAGS="..."   permission flags (default "--permission-mode auto")
//   CLAUDE_CMD="..."     launcher (default "sessiontap claude", see launch.ts)

import { readdirSync, existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { color, track } from "../term";
import { launcher } from "./launch";
import type { Adapter, RunOptions, RunResult, Step } from "./types";

const cmd = launcher("claude");
const permFlags = (process.env.CLAUDE_FLAGS ?? "--permission-mode auto").split(/\s+/).filter(Boolean);

const MODELS: Record<Step, string> = {
  apply: "claude-opus-5-5[1m]", // Opus 5.5, 1M context
  sync: "claude-opus-5-5[1m]", // Opus 5.5, 1M context
  archive: "claude-sonnet-5", // Sonnet 5
};

const glow = Bun.which("glow");

async function printMessage(text: string) {
  if (!glow) {
    console.log(`\n${color.bold("⏺")} ${text}`);
    return;
  }
  const p = Bun.spawn([glow, "-"], { stdin: new Blob([text]), stdout: "inherit", stderr: "inherit" });
  await p.exited;
}

// Short label for a tool call: the agent's own description when it gave
// one, else tool name plus path. Never the command itself.
function toolLabel(block: any, root: string): string {
  const input = block.input ?? {};
  const label =
    input.description ?? [block.name, input.file_path ?? input.pattern ?? input.skill ?? ""].join(" ");
  return String(label).replace(/\s+/g, " ").split(`${root}/`).join("").slice(0, 120);
}

// Renders one stream-json event like Claude Code: messages as text (markdown
// via glow when installed), a dim line per tool call, a duration/cost line.
async function render(event: any, root: string) {
  if (event.type === "assistant") {
    for (const block of event.message?.content ?? []) {
      if (block.type === "text") await printMessage(block.text);
      else if (block.type === "tool_use") console.log(`  ${color.dim(`· ${toolLabel(block, root)}`)}`);
    }
  } else if (event.type === "result") {
    const secs = Math.floor((event.duration_ms ?? 0) / 1000);
    const cost = (event.total_cost_usd ?? 0).toFixed(2);
    console.log(`\n${color.dim(`✓ finished (${secs}s, $${cost})`)}`);
  }
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

function transcriptPath(sessionId: string): string | null {
  const projects = join(homedir(), ".claude", "projects");
  if (!existsSync(projects)) return null;
  for (const dir of readdirSync(projects)) {
    const f = join(projects, dir, `${sessionId}.jsonl`);
    if (existsSync(f)) return f;
  }
  return null;
}

export const claude: Adapter = {
  name: "claude",

  defaultModel: (step) => MODELS[step],

  invoke: (step, change) => `/opsx:${step} ${change}`,

  async run({ prompt, model, logBase }: RunOptions): Promise<RunResult> {
    const child = track(
      Bun.spawn(
        [...cmd, "-p", prompt, "--model", model, ...permFlags, "--output-format", "stream-json", "--verbose"],
        { stdin: "ignore", stdout: "pipe", stderr: "inherit" },
      ),
    );
    const logFile = Bun.file(`${logBase}.jsonl`).writer();
    const root = process.cwd();
    let result: RunResult = { sessionId: null, result: "" };

    for await (const line of lines(child.stdout)) {
      logFile.write(`${line}\n`);
      let event: any;
      try {
        event = JSON.parse(line);
      } catch {
        continue;
      }
      if (event.type === "result") result = { sessionId: event.session_id ?? null, result: event.result ?? "" };
      await render(event, root);
    }
    await logFile.end();

    const code = await child.exited;
    if (code !== 0) throw new Error(`claude exited with code ${code}`);
    return result;
  },

  // Read from the session transcript, so it also covers turns made
  // interactively after a takeover.
  async lastResponse(sessionId) {
    const f = transcriptPath(sessionId);
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

  // Same model as the headless run keeps the prompt cache warm.
  async takeOver(sessionId, model) {
    const child = Bun.spawn([...cmd, "--resume", sessionId, "--model", model, ...permFlags], {
      stdin: "inherit",
      stdout: "inherit",
      stderr: "inherit",
    });
    await child.exited;
  },
};
