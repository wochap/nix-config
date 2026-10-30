import { describe, expect, test } from "bun:test";
import { existsSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

describe("store prompt preservation and retrieval", () => {
  test("createSession stores the full untruncated prompt and writes .prompt.txt", async () => {
    const tmp = mkdtempSync(join(tmpdir(), "agents-store-test-"));
    const prevEnv = process.env.XDG_STATE_HOME;
    process.env.XDG_STATE_HOME = tmp;

    try {
      // Dynamic import to pick up XDG_STATE_HOME
      const store = await import(`../src/store?t=${Date.now()}`);
      const longPrompt = "A".repeat(500);

      const session = store.createSession({
        id: "test-session-123",
        agent: "claude",
        model: "claude-3-5-sonnet",
        cwd: tmp,
        prompt: longPrompt,
      });

      expect(session.prompt).toBe(longPrompt);

      const readBack = store.readSession("test-session-123");
      expect(readBack?.prompt).toBe(longPrompt);

      const promptFile = store.promptPath("test-session-123");
      expect(existsSync(promptFile)).toBe(true);
      expect(readFileSync(promptFile, "utf8")).toBe(longPrompt);

      expect(store.readPrompt("test-session-123")).toBe(longPrompt);
    } finally {
      if (prevEnv !== undefined) process.env.XDG_STATE_HOME = prevEnv;
      else delete process.env.XDG_STATE_HOME;
      rmSync(tmp, { recursive: true, force: true });
    }
  });

  test("readPrompt falls back to session.prompt if .prompt.txt does not exist", async () => {
    const tmp = mkdtempSync(join(tmpdir(), "agents-store-test-"));
    const prevEnv = process.env.XDG_STATE_HOME;
    process.env.XDG_STATE_HOME = tmp;

    try {
      const store = await import(`../src/store?t=${Date.now() + 1}`);
      const session = store.createSession({
        id: "test-session-fallback",
        agent: "agy",
        model: "gemini-3.8-flash",
        cwd: tmp,
        prompt: "Legacy prompt without file",
      });

      // Remove .prompt.txt if it was created
      const promptFile = store.promptPath("test-session-fallback");
      if (existsSync(promptFile)) rmSync(promptFile);

      expect(store.readPrompt("test-session-fallback")).toBe("Legacy prompt without file");
    } finally {
      if (prevEnv !== undefined) process.env.XDG_STATE_HOME = prevEnv;
      else delete process.env.XDG_STATE_HOME;
      rmSync(tmp, { recursive: true, force: true });
    }
  });
});
