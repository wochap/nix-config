// Git and OpenSpec state of the current repository. The pipeline reads its
// progress only from here, so a re-run after a crash never repeats work.

import { existsSync, readFileSync } from "node:fs";

function git(args: string[]): { code: number; out: string } {
  const p = Bun.spawnSync(["git", ...args], { stdout: "pipe", stderr: "inherit" });
  return { code: p.exitCode, out: p.stdout.toString() };
}

export function repoRoot(): string {
  const { code, out } = git(["rev-parse", "--show-toplevel"]);
  if (code !== 0) throw new Error("not inside a git repository");
  return out.trim();
}

export const changeDir = (change: string) => `openspec/changes/${change}`;
export const changeExists = (change: string) => existsSync(changeDir(change));

export function hasCommit(subject: string): boolean {
  return git(["log", "--format=%s"]).out.split("\n").includes(subject);
}

/** Uncommitted changes outside openspec/. */
export function codeDirty(): boolean {
  return git(["status", "--porcelain", "--", ".", ":!openspec"]).out.trim() !== "";
}

/** Commits the given paths; returns false when there was nothing to commit. */
export function commit(message: string, paths: string[]): boolean {
  if (git(["add", "-A", "--", ...paths]).code !== 0) throw new Error("git add failed");
  if (git(["diff", "--cached", "--quiet"]).code === 0) return false;
  if (git(["commit", "-q", "-m", message]).code !== 0) throw new Error("git commit failed");
  return true;
}

// Open tasks matching this are manual checks the agent cannot do headless.
const MANUAL_RE = /\b(manual(ly)?|smoke|visually)\b/i;

export interface Tasks {
  open: string[];
  /** Open tasks that are not manual checks. */
  other: string[];
}

export function readTasks(change: string): Tasks {
  const file = `${changeDir(change)}/tasks.md`;
  const text = existsSync(file) ? readFileSync(file, "utf8") : "";
  const open = text.split("\n").filter((l) => /^\s*- \[ \]/.test(l));
  return { open, other: open.filter((l) => !MANUAL_RE.test(l)) };
}
