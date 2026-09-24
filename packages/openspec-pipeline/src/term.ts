// Terminal output, prompts and Ctrl-C.

import { createInterface } from "node:readline/promises";

export const color = {
  blue: (s: string) => `\x1b[1;34m${s}\x1b[0m`,
  yellow: (s: string) => `\x1b[1;33m${s}\x1b[0m`,
  bold: (s: string) => `\x1b[1m${s}\x1b[0m`,
  dim: (s: string) => `\x1b[2m${s}\x1b[0m`,
};

export const log = (msg: string) => console.log(`\n${color.blue(`==> ${msg}`)}`);
export const warn = (msg: string) => console.log(`\n${color.yellow(`==> ${msg}`)}`);

// Terminal bell (BEL). Rings when the run ends for any reason and whenever
// the pipeline waits on the user; terminals turn it into urgency/notification.
export const bell = () => process.stdout.write("\x07");
process.on("exit", bell);

/** Reads one of the given answers from the terminal. */
export async function ask<T extends string>(question: string, answers: readonly T[]): Promise<T> {
  bell();
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  try {
    while (true) {
      const answer = (await rl.question(`${question} `)).trim() as T;
      if (answers.includes(answer)) return answer;
    }
  } finally {
    rl.close();
  }
}

// Ctrl-C stops the whole run; the running agents child gets it from the
// terminal too and cleans up after itself. While the user is inside a
// taken-over interactive session, Ctrl-C belongs to that agent and is ignored
// here.
let inTakeover = false;

export async function interactive<T>(fn: () => Promise<T>): Promise<T> {
  inTakeover = true;
  try {
    return await fn();
  } finally {
    inTakeover = false;
  }
}

function onInterrupt() {
  if (inTakeover) return;
  process.stderr.write(`\n${color.yellow("==> interrupted, stopping agents")}\n`);
  process.exit(130);
}
process.on("SIGINT", onInterrupt);
process.on("SIGTERM", onInterrupt);
