import { describe, expect, test } from "bun:test";
import { chmodSync, existsSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const AGENTTAP_MAIN = join(import.meta.dir, "..", "src", "main.ts");
const PIPELINE_MAIN = join(import.meta.dir, "..", "..", "openspec-pipeline", "src", "main.ts");

function makeAgyShim(dir: string): { shimPath: string; logPath: string } {
  const shimPath = join(dir, "agy-shim.ts");
  const logPath = join(dir, "shim-calls.jsonl");
  const script = `#!/usr/bin/env bun
import { appendFileSync, writeFileSync } from "node:fs";

const args = process.argv.slice(2);
const stdin = await Bun.stdin.text();
const callIndex = process.env.SHIM_LOG ? 0 : 0;
const logFile = ${JSON.stringify(logPath)};
const isResume = args.includes("--conversation");
const cid = "conv-shim-123";

appendFileSync(logFile, JSON.stringify({ args, stdin, isResume }) + "\\n");

if (!isResume) {
  // First turn: emit conversation_id + text event, then wait for SIGINT.
  console.log(JSON.stringify({ event: "step_update", conversation_id: cid, step_update: { step_type: "agent_response", step_index: 0, text_delta: "working...", state: "DONE" } }));
  if (process.env.SHIM_READY_FILE) {
    writeFileSync(process.env.SHIM_READY_FILE, "ready");
  }
  await new Promise<void>((resolve) => {
    process.on("SIGINT", () => {
      appendFileSync(logFile, JSON.stringify({ sigint: true }) + "\\n");
      resolve();
    });
    setTimeout(resolve, 15000);
  });
  process.exit(0);
} else {
  // Second turn: emit steered result and exit 0.
  console.log(JSON.stringify({ event: "result", conversation_id: cid, result: { response: "steered-done:" + stdin.trim(), duration_seconds: 0.01, usage: { input_tokens: 1, output_tokens: 1 } } }));
  process.exit(0);
}
`;
  writeFileSync(shimPath, script);
  chmodSync(shimPath, 0o755);
  return { shimPath, logPath };
}

async function waitForFile(path: string, timeoutMs = 5000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (existsSync(path)) return;
    await Bun.sleep(50);
  }
  throw new Error(`Timed out waiting for ${path}`);
}

describe("live mid-run steering (agenttap send & openspec-pipeline --send)", () => {
  test("agenttap send interrupts turn 1 with SIGINT, logs send event, and resumes turn 2 with new effort and prompt", async () => {
    const tmp = mkdtempSync(join(tmpdir(), "agenttap-send-test-"));
    const stateHome = join(tmp, "state");
    const cwd = join(tmp, "work");
    const readyFile = join(tmp, "turn1-ready");
    const { shimPath, logPath } = makeAgyShim(tmp);

    try {
      const env = {
        ...process.env,
        XDG_STATE_HOME: stateHome,
        AGY_CMD: `${process.execPath} ${shimPath}`,
        SHIM_READY_FILE: readyFile,
      };
      // Create cwd
      Bun.spawnSync(["mkdir", "-p", cwd]);

      const runProc = Bun.spawn(
        [process.execPath, AGENTTAP_MAIN, "run", "--json", "-a", "agy", "--sandbox", "off", "-C", cwd, "initial task"],
        { env, stdout: "pipe", stderr: "pipe" },
      );

      await waitForFile(readyFile);

      // Find running session id via `agenttap ls --json`
      const lsProc = Bun.spawnSync([process.execPath, AGENTTAP_MAIN, "ls", "--json"], { env, stdout: "pipe", stderr: "pipe" });
      expect(lsProc.exitCode).toBe(0);
      const sessions = JSON.parse(lsProc.stdout.toString());
      expect(sessions.length).toBe(1);
      const sessionId: string = sessions[0].id;
      expect(sessions[0].status).toBe("running");

      // Send live instruction + effort override
      const sendProc = Bun.spawnSync(
        [process.execPath, AGENTTAP_MAIN, "send", sessionId, "new live instruction", "-e", "high", "--json"],
        { env, stdout: "pipe", stderr: "pipe" },
      );
      expect(sendProc.exitCode).toBe(0);
      const sendOut = JSON.parse(sendProc.stdout.toString().trim());
      expect(sendOut.status).toBe("sent");
      expect(sendOut.id).toBe(sessionId);

      const exitCode = await runProc.exited;
      const runOut = await new Response(runProc.stdout).text();
      expect(exitCode).toBe(0);

      const finalJson = JSON.parse(runOut.trim().split("\n").at(-1)!);
      expect(finalJson.status).toBe("done");
      expect(finalJson.id).toBe(sessionId);
      expect(finalJson.result).toContain("new live instruction");

      // Verify shim saw SIGINT on turn 1 and --conversation + --effort high on turn 2
      const shimCalls = readFileSync(logPath, "utf8")
        .trim()
        .split("\n")
        .map((l) => JSON.parse(l));
      expect(shimCalls.some((c) => c.sigint === true)).toBe(true);
      const turn2 = shimCalls.find((c) => c.isResume === true);
      expect(turn2).toBeDefined();
      expect(turn2.args).toContain("--conversation");
      expect(turn2.args).toContain("high");
      expect(turn2.stdin).toContain("new live instruction");

      // Verify events.jsonl recorded the send event
      const eventsPath = join(stateHome, "agenttap", "sessions", `${sessionId}.events.jsonl`);
      const events = readFileSync(eventsPath, "utf8")
        .trim()
        .split("\n")
        .map((l) => JSON.parse(l));
      const sendEvent = events.find((e) => e.type === "send");
      expect(sendEvent).toEqual({ type: "send", text: "new live instruction", effort: "high" });
    } finally {
      rmSync(tmp, { recursive: true, force: true });
    }
  });

  test("agenttap send without <id> targets the running session in the current cwd/worktree", async () => {
    const tmp = mkdtempSync(join(tmpdir(), "agenttap-send-wt-"));
    const stateHome = join(tmp, "state");
    const wtA = join(tmp, "wt-a");
    const wtB = join(tmp, "wt-b");
    const readyA = join(tmp, "ready-a");
    const readyB = join(tmp, "ready-b");
    const { shimPath } = makeAgyShim(tmp);

    try {
      Bun.spawnSync(["mkdir", "-p", wtA, wtB]);
      const baseEnv = { ...process.env, XDG_STATE_HOME: stateHome, AGY_CMD: `${process.execPath} ${shimPath}` };

      const procA = Bun.spawn(
        [process.execPath, AGENTTAP_MAIN, "run", "--json", "-a", "agy", "--sandbox", "off", "-C", wtA, "task A"],
        { env: { ...baseEnv, SHIM_READY_FILE: readyA }, stdout: "pipe", stderr: "pipe" },
      );
      const procB = Bun.spawn(
        [process.execPath, AGENTTAP_MAIN, "run", "--json", "-a", "agy", "--sandbox", "off", "-C", wtB, "task B"],
        { env: { ...baseEnv, SHIM_READY_FILE: readyB }, stdout: "pipe", stderr: "pipe" },
      );

      await Promise.all([waitForFile(readyA), waitForFile(readyB)]);

      const lsProc = Bun.spawnSync([process.execPath, AGENTTAP_MAIN, "ls", "--json"], { env: baseEnv, stdout: "pipe" });
      const sessions: any[] = JSON.parse(lsProc.stdout.toString());
      const sessA = sessions.find((s) => s.cwd === realpathSync(wtA))!;
      const sessB = sessions.find((s) => s.cwd === realpathSync(wtB))!;
      expect(sessA).toBeDefined();
      expect(sessB).toBeDefined();

      // Run `agenttap send "steer B"` from wtB without specifying an ID
      const sendB = Bun.spawnSync([process.execPath, AGENTTAP_MAIN, "send", "steer B", "--json"], {
        cwd: wtB,
        env: baseEnv,
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(sendB.exitCode).toBe(0);
      const outB = JSON.parse(sendB.stdout.toString().trim());
      expect(outB.id).toBe(sessB.id);

      expect(await procB.exited).toBe(0);

      // Session A should not have received any send event
      const eventsA = readFileSync(join(stateHome, "agenttap", "sessions", `${sessA.id}.events.jsonl`), "utf8");
      expect(eventsA).not.toContain('"type":"send"');

      // Clean up procA
      procA.kill();
      await procA.exited;
    } finally {
      rmSync(tmp, { recursive: true, force: true });
    }
  });

  test("openspec-pipeline --send steers the active /opsx:apply session in the git worktree", async () => {
    const tmp = mkdtempSync(join(tmpdir(), "openspec-send-test-"));
    const stateHome = join(tmp, "state");
    const repo = join(tmp, "repo");
    const readyFile = join(tmp, "ready");
    const { shimPath } = makeAgyShim(tmp);

    try {
      Bun.spawnSync(["mkdir", "-p", repo]);
      Bun.spawnSync(["git", "init"], { cwd: repo });

      const env = {
        ...process.env,
        XDG_STATE_HOME: stateHome,
        AGY_CMD: `${process.execPath} ${shimPath}`,
        AGENTTAP_CMD: `${process.execPath} ${AGENTTAP_MAIN}`,
        SHIM_READY_FILE: readyFile,
      };

      const runProc = Bun.spawn(
        [
          process.execPath,
          AGENTTAP_MAIN,
          "run",
          "--json",
          "-a",
          "agy",
          "--sandbox",
          "off",
          "-C",
          repo,
          "/opsx:apply my-change — Implement all tasks.",
        ],
        { env, stdout: "pipe", stderr: "pipe" },
      );

      await waitForFile(readyFile);

      const pipeSend = Bun.spawnSync(
        [process.execPath, PIPELINE_MAIN, "--send", "Use postgres instead of sqlite", "--json"],
        { cwd: repo, env, stdout: "pipe", stderr: "pipe" },
      );
      expect(pipeSend.exitCode).toBe(0);
      const sentJson = JSON.parse(pipeSend.stdout.toString().trim());
      expect(sentJson.status).toBe("sent");

      const exitCode = await runProc.exited;
      expect(exitCode).toBe(0);
      const finalJson = JSON.parse((await new Response(runProc.stdout).text()).trim().split("\n").at(-1)!);
      expect(finalJson.status).toBe("done");
      expect(finalJson.result).toContain("Use postgres instead of sqlite");
      expect(finalJson.result).toContain("PIPELINE_STATUS: DONE");
    } finally {
      rmSync(tmp, { recursive: true, force: true });
    }
  });
});
