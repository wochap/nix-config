// Terminal output and child process tracking for Ctrl-C.
// Status lines go to stderr so stdout carries only what the caller asked for.

import type { Subprocess } from "bun";

/**
 * Where progress goes: stdout, or stderr when stdout carries JSON. Colors
 * follow that stream: plain text when piped (e.g. `agents ls | grep`) or
 * NO_COLOR is set.
 */
export let out: NodeJS.WriteStream = process.stdout;
export const progressToStderr = () => {
  out = process.stderr;
};
export const println = (s = "") => out.write(`${s}\n`);

const paint = (code: string) => (s: string) => (out.isTTY && !process.env.NO_COLOR ? `\x1b[${code}m${s}\x1b[0m` : s);

export const color = {
  blue: paint("1;34"),
  yellow: paint("1;33"),
  bold: paint("1"),
  dim: paint("2"),
};

export const log = (msg: string) => println(`\n${color.blue(`==> ${msg}`)}`);
export const warn = (msg: string) => process.stderr.write(`${color.yellow(`==> ${msg}`)}\n`);

// Terminal bell (BEL) when a run ends; terminals turn it into
// urgency/notification. Only on a terminal, never into a pipe.
export const bell = () => {
  if (process.stderr.isTTY) process.stderr.write("\x07");
};

// Ctrl-C stops the run, including the running agent and a taken-over session
// running in the background. While the user is inside a taken-over
// interactive session, Ctrl-C belongs to that agent and is ignored here.
const children = new Set<Subprocess>();
let inTakeover = false;
const onStop: (() => void)[] = [];

export function track<T extends Subprocess>(child: T): T {
  children.add(child);
  child.exited.finally(() => children.delete(child));
  return child;
}

/** Runs cleanup (e.g. marking the session failed) before exiting on Ctrl-C. */
export const onInterruptCleanup = (fn: () => void) => onStop.push(fn);

export async function interactive<T>(fn: () => Promise<T>): Promise<T> {
  inTakeover = true;
  try {
    return await fn();
  } finally {
    inTakeover = false;
  }
}

/** Ctrl-C: also called for the raw Ctrl-C byte while keys are read raw. */
export function interrupt() {
  if (inTakeover) return;
  warn("interrupted, stopping agent");
  for (const child of children) child.kill("SIGTERM");
  for (const fn of onStop) fn();
  process.exit(130);
}
process.on("SIGINT", interrupt);
process.on("SIGTERM", interrupt);
