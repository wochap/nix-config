// Adapter contract. One adapter per coding agent CLI (claude, codex, ...).
// To add an agent: implement Adapter in adapters/<name>.ts and register it in
// adapters/index.ts. The pipeline never calls an agent CLI directly.

export type Step = "apply" | "sync" | "archive";

export interface RunOptions {
  /** Full prompt, already starting with invoke(step, change). */
  prompt: string;
  model: string;
  /** Path without extension; the adapter writes its raw output there. */
  logBase: string;
}

export interface RunResult {
  /** Session id usable with lastResponse() and takeOver(). */
  sessionId: string | null;
  /** Final text answer of the headless run. */
  result: string;
}

export interface Adapter {
  name: string;
  /** Default model per step; overridden by --<step>-model. */
  defaultModel(step: Step): string;
  /** Text that starts the OpenSpec skill, e.g. "/opsx:apply my-change". */
  invoke(step: Step, change: string): string;
  /**
   * Headless run. Prints readable progress (messages and short tool
   * descriptions, no raw JSON or commands) while it runs. Rejects when the
   * agent exits with an error.
   */
  run(opts: RunOptions): Promise<RunResult>;
  /**
   * Last agent message of a session, including turns made interactively
   * after takeOver(). Null when unknown.
   */
  lastResponse(sessionId: string): Promise<string | null>;
  /** Resumes the session interactively on the terminal; resolves on exit. */
  takeOver(sessionId: string, model: string): Promise<void>;
}
