// Session store: ${XDG_STATE_HOME:-~/.local/state}/agents/sessions/
//   <id>.json          metadata (Session)
//   <id>.events.jsonl  normalized events, one per line (what `watch` tails)
//   <id>.raw.jsonl     provider-native output (written by the adapter)

import { appendFileSync, existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { Effort, Event } from "./adapters/types";

export type Status = "running" | "done" | "failed";

export interface Session {
  id: string;
  agent: string;
  model: string;
  effort?: Effort;
  cwd: string;
  /** First 200 chars of the first prompt. */
  prompt: string;
  startedAt: string;
  endedAt?: string;
  status: Status;
  pid: number;
}

const stateHome = process.env.XDG_STATE_HOME ?? join(homedir(), ".local", "state");
export const dir = join(stateHome, "agents", "sessions");

export const metaPath = (id: string) => join(dir, `${id}.json`);
export const eventsPath = (id: string) => join(dir, `${id}.events.jsonl`);
export const rawPath = (id: string) => join(dir, `${id}.raw.jsonl`);

function write(s: Session) {
  writeFileSync(metaPath(s.id), `${JSON.stringify(s, null, 2)}\n`);
}

export function createSession(s: Omit<Session, "startedAt" | "status" | "pid">): Session {
  mkdirSync(dir, { recursive: true });
  const session: Session = { ...s, prompt: s.prompt.slice(0, 200), startedAt: new Date().toISOString(), status: "running", pid: process.pid };
  write(session);
  return session;
}

/** Marks a session as running again for a resumed run. */
export function restartSession(s: Session, model: string, effort?: Effort): Session {
  const session: Session = { ...s, model, effort, status: "running", pid: process.pid, endedAt: undefined };
  write(session);
  return session;
}

export function finishSession(id: string, status: Status) {
  const s = readSession(id);
  if (s) write({ ...s, status, endedAt: new Date().toISOString() });
}

export function appendEvent(id: string, e: Event) {
  appendFileSync(eventsPath(id), `${JSON.stringify(e)}\n`);
}

function alive(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

export function readSession(id: string): Session | null {
  try {
    const s: Session = JSON.parse(readFileSync(metaPath(id), "utf8"));
    // A run killed without cleanup leaves "running" behind.
    if (s.status === "running" && !alive(s.pid)) s.status = "failed";
    return s;
  } catch {
    return null;
  }
}

/** All sessions, newest first. */
export function listSessions(): Session[] {
  if (!existsSync(dir)) return [];
  return readdirSync(dir)
    .filter((f) => f.endsWith(".json"))
    .map((f) => readSession(f.slice(0, -".json".length)))
    .filter((s): s is Session => s !== null)
    .sort((a, b) => b.startedAt.localeCompare(a.startedAt));
}

export const latest = (): Session | null => listSessions()[0] ?? null;
export const latestRunning = (): Session | null => listSessions().find((s) => s.status === "running") ?? null;

/** Session by full id or unique id prefix. */
export function resolveId(prefix: string): Session {
  const matches = listSessions().filter((s) => s.id.startsWith(prefix));
  if (matches.length === 0) throw new Error(`no session "${prefix}"`);
  if (matches.length > 1) throw new Error(`ambiguous session "${prefix}", ${matches.length} matches`);
  return matches[0];
}
