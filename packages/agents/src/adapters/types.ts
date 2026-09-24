// Adapter contract. One adapter per coding agent CLI (claude, codex, ...).
// To add an agent: implement Adapter in adapters/<name>.ts and register it in
// adapters/index.ts. The core never calls an agent CLI directly.
//
// Adapters translate their native output into normalized Events; the core
// renders and logs those, so `watch` and rendering stay agent-agnostic.

export type Event =
  /** Assistant message (markdown). */
  | { type: "text"; text: string }
  /** Short tool-call label, never the raw command. */
  | { type: "tool"; label: string }
  | { type: "result"; result: string; costUsd?: number; durationMs?: number }
  | { type: "error"; message: string };

export interface RunOptions {
  /** Session id chosen by the core (uuid); used as native id when possible. */
  id: string;
  prompt: string;
  model: string;
  cwd: string;
  /** True: continue session `id` with `prompt`. */
  resume: boolean;
  /** Path; the adapter appends its provider-native output here. */
  rawLog: string;
  onEvent(e: Event): void | Promise<void>;
}

export interface Adapter {
  name: string;
  defaultModel: string;
  /** Headless run. Resolves with the final answer; rejects on non-zero exit. */
  run(opts: RunOptions): Promise<{ result: string }>;
  /**
   * Last agent message of a session, read from the native transcript so it
   * covers turns made interactively after takeOver(). Null when unknown.
   */
  lastResponse(id: string): Promise<string | null>;
  /** Resumes the session interactively on the terminal; resolves on exit. */
  takeOver(id: string, model: string, cwd: string): Promise<void>;
}
