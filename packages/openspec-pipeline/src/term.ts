// Terminal output, prompts and Ctrl-C.

import { createInterface } from "node:readline/promises";

// Log lines go to stdout, or to stderr with --json so stdout holds only the
// final JSON result.
let out: NodeJS.WriteStream = process.stdout;
export const logToStderr = () => {
  out = process.stderr;
};

const paint = (code: string) => (s: string) => (out.isTTY && !process.env.NO_COLOR ? `\x1b[${code}m${s}\x1b[0m` : s);

export const color = {
  blue: paint("1;34"),
  yellow: paint("1;33"),
  bold: paint("1"),
  dim: paint("2"),
};

export const print = (text: string) => out.write(text.endsWith("\n") ? text : `${text}\n`);
export const log = (msg: string) => print(`\n${color.blue(`==> ${msg}`)}`);
export const warn = (msg: string) => print(`\n${color.yellow(`==> ${msg}`)}`);

// Terminal bell (BEL). Rings when the run ends for any reason and whenever
// the pipeline waits on the user; terminals turn it into urgency/notification.
// Only on a terminal, never into a log file or piped JSON.
export const bell = () => {
  if (process.stderr.isTTY) process.stderr.write("\x07");
};
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
