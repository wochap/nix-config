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

/** Default model per step; overridden by --<step>-model. */
export const defaultModel = (step: Step) => MODELS[step];

/** Text that starts the OpenSpec skill, e.g. "/opsx:apply my-change". */
export const invoke = (step: Step, change: string) => `/opsx:${step} ${change}`;

/**
 * Headless run in the current directory. Progress and the takeover keys stay
 * on the terminal (stdin, stderr); stdout carries agents' JSON result.
 * Rejects when the agent fails.
 */
export async function run(prompt: string, model: string): Promise<{ sessionId: string; result: string }> {
  const child = Bun.spawn(
    [...cmd, "run", "--json", "--verbose", "-a", "claude", "-C", process.cwd(), "-m", model, prompt],
    { stdin: "inherit", stdout: "pipe", stderr: "inherit" },
  );
  const out = await new Response(child.stdout).text();
  const code = await child.exited;
  let json: { id: string; result: string; status: string };
  try {
    json = JSON.parse(out.trim().split("\n").at(-1) ?? "");
  } catch {
    throw new Error(`agents exited with code ${code}`);
  }
  if (json.status !== "done") throw new Error(`agent failed (session ${json.id})`);
  return { sessionId: json.id, result: json.result };
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
