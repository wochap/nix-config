// Every step runs through the agents CLI (packages/agents): headless with
// live progress, Ctrl-T to take a running step over. Forced to claude for now.
//
// Env: AGENTS_CMD="..." (default "agents", set by the package)

export type Step = "apply" | "sync" | "archive";

const cmd = (process.env.AGENTS_CMD ?? "agents").split(/\s+/).filter(Boolean);

const MODELS: Record<Step, string> = {
  apply: "claude-opus-5-5[1m]", // Opus 5.5, 1M context
  sync: "claude-opus-5-5[1m]", // Opus 5.5, 1M context
  archive: "claude-sonnet-5", // Sonnet 5
};

// Passed as `agents run --effort`, so a step never inherits the caller's
// CLAUDE_EFFORT or the user's effortLevel setting.
const EFFORTS: Record<Step, string> = {
  apply: "medium",
  sync: "medium",
  archive: "low",
};

/** Default model per step; overridden by --<step>-model. */
export const defaultModel = (step: Step) => MODELS[step];

/** Default effort per step; overridden by --<step>-effort. */
export const defaultEffort = (step: Step) => EFFORTS[step];

/** Text that starts the OpenSpec skill, e.g. "/opsx:apply my-change". */
export const invoke = (step: Step, change: string) => `/opsx:${step} ${change}`;

// claude's usage or rate limit messages, e.g. "You've hit your session limit · resets 3:30pm".
const LIMIT_RE = /hit your .*limit|usage limit|limit reached|rate limit|resets \d/i;

/** A step's agent failed. Re-running the pipeline resumes `session`. */
export class AgentError extends Error {
  constructor(
    message: string,
    readonly session: string | undefined,
    /** The agent hit a usage or rate limit. */
    readonly limit: boolean,
  ) {
    super(message);
  }
}

export interface RunOptions {
  /** Continue this session instead of starting a new one. */
  resume?: string;
  /** Someone is at the terminal: show live progress and allow Ctrl-T. */
  tty: boolean;
}

/**
 * Headless run in the current directory. With a TTY, progress and the
 * takeover keys stay on the terminal (stdin, stderr); without one, stderr
 * gets only "session: <id>". stdout carries agents' JSON result.
 * Rejects when the agent fails.
 */
export async function run(prompt: string, model: string, effort: string, o: RunOptions): Promise<{ sessionId: string; result: string }> {
  const target = o.resume ? ["-r", o.resume] : ["-a", "claude", "-C", process.cwd()];
  const child = Bun.spawn(
    [...cmd, "run", "--json", ...(o.tty ? ["--verbose"] : []), ...target, "-m", model, "-e", effort, prompt],
    { stdin: o.tty ? "inherit" : "ignore", stdout: "pipe", stderr: "inherit" },
  );
  const out = await new Response(child.stdout).text();
  const code = await child.exited;
  let json: { id: string; result: string; status: string; error?: string };
  try {
    json = JSON.parse(out.trim().split("\n").at(-1) ?? "");
  } catch {
    throw new AgentError(`agents exited with code ${code}`, undefined, false);
  }
  if (json.status !== "done") {
    const error = json.error ?? "unknown error";
    throw new AgentError(`agent failed (session ${json.id}): ${error}`, json.id, LIMIT_RE.test(error));
  }
  return { sessionId: json.id, result: json.result };
}

/**
 * The step's latest session in this directory when it was interrupted
 * (Ctrl-C, usage limit, crash) after the agent wrote something, so a re-run
 * continues it instead of starting over. Null when the latest one finished,
 * or none exists in the last 7 days.
 */
export async function interrupted(step: Step, change: string): Promise<string | null> {
  const child = Bun.spawn([...cmd, "ls", "--json"], { stdin: "ignore", stdout: "pipe", stderr: "ignore" });
  const out = await new Response(child.stdout).text();
  if ((await child.exited) !== 0) return null;
  let sessions: { id: string; cwd: string; prompt: string; status: string }[];
  try {
    sessions = JSON.parse(out);
  } catch {
    return null;
  }
  // Newest first; the stored prompt is the first run's, e.g. "/opsx:apply <c> — ...".
  const latest = sessions.find((s) => s.cwd === process.cwd() && s.prompt.startsWith(`${invoke(step, change)} `));
  if (latest?.status !== "failed") return null;
  // Killed before any reply: nothing to continue.
  return (await last(latest.id)) === null ? null : latest.id;
}

/** Last agent message of a session, also after interactive turns. Null when unknown. */
export async function last(id: string): Promise<string | null> {
  const child = Bun.spawn([...cmd, "last", id], { stdin: "ignore", stdout: "pipe", stderr: "ignore" });
  const out = await new Response(child.stdout).text();
  return (await child.exited) === 0 ? out.replace(/\n$/, "") : null;
}

/** Resumes a finished session interactively on the terminal; resolves on exit. */
export async function attach(id: string): Promise<void> {
  await Bun.spawn([...cmd, "attach", id], { stdio: ["inherit", "inherit", "inherit"] }).exited;
}
