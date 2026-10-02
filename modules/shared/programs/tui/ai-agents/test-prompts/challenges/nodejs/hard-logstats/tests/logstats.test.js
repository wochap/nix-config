import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import {
  mkdir,
  mkdtemp,
  readdir,
  readFile,
  rm,
  writeFile,
} from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { after, before, test } from "node:test";
import { promisify } from "node:util";
import { gzipSync } from "node:zlib";
import { summarizeDir, writeReport } from "../src/logstats.js";

const run = promisify(execFile);
const CLI = join(import.meta.dirname, "..", "src", "cli.js");
const line = (level, msg, ms) => JSON.stringify({ level, msg, ms });

let root;
let logs;

before(async () => {
  root = await mkdtemp(join(tmpdir(), "logstats-"));
  logs = join(root, "logs");
  await mkdir(join(logs, "api", "v2"), { recursive: true });
  await mkdir(join(logs, "empty"), { recursive: true });
  await writeFile(
    join(logs, "app.log"),
    [
      line("info", "boot", 5),
      "",
      line("warn", "disk", 40),
      "not json",
      line("error", "crash", 120),
      "   ",
      line("debug", "nope", 1),
      line("info", "tick", 7),
    ].join("\n"),
  );
  await writeFile(
    join(logs, "api", "a.log.gz"),
    gzipSync(
      `${[
        line("info", "req", 3),
        line("info", "req", 2),
        "[1,2]",
        line("warn", "slow query", 120),
      ].join("\r\n")}\r\n`,
    ),
  );
  await writeFile(
    join(logs, "api", "v2", "b.log"),
    `${[
      line("info", "ok", 40),
      JSON.stringify({ level: "info", msg: "no ms" }),
      JSON.stringify({ level: "info", msg: 3, ms: 1 }),
      "null",
      line("warn", "late", 40),
    ].join("\n")}\n`,
  );
  await writeFile(join(logs, "notes.txt"), "not a log\n");
  await writeFile(join(logs, "api", "old.log.bak"), "garbage\n");
});

after(async () => {
  await rm(root, { recursive: true, force: true });
});

const EXPECTED = {
  files: 3,
  entries: 9,
  invalid: 6,
  levels: { info: 5, warn: 3, error: 1 },
  maxMs: 120,
  slowest: [
    { file: "api/a.log.gz", line: 4, ms: 120, msg: "slow query" },
    { file: "app.log", line: 5, ms: 120, msg: "crash" },
    { file: "api/v2/b.log", line: 1, ms: 40, msg: "ok" },
  ],
};

test("summarizeDir walks, decompresses and counts", async () => {
  assert.deepEqual(await summarizeDir(logs), EXPECTED);
});

test("summarizeDir on a directory without logs", async () => {
  assert.deepEqual(await summarizeDir(join(logs, "empty")), {
    files: 0,
    entries: 0,
    invalid: 0,
    levels: { info: 0, warn: 0, error: 0 },
    maxMs: null,
    slowest: [],
  });
});

test("summarizeDir rejects for a missing directory", async () => {
  await assert.rejects(summarizeDir(join(root, "missing")), { code: "ENOENT" });
});

test("summarizeDir handles a large file", async () => {
  const dir = join(root, "big");
  await mkdir(dir);
  const chunk = `${Array.from({ length: 1000 }, (_, i) => line("info", "x", i % 50)).join("\n")}\n`;
  await writeFile(join(dir, "big.log"), chunk.repeat(100));
  const s = await summarizeDir(dir);
  assert.equal(s.entries, 100000);
  assert.equal(s.maxMs, 49);
  assert.deepEqual(
    s.slowest.map((e) => e.line),
    [50, 100, 150],
  );
});

test("writeReport creates parents and leaves no temp files", async () => {
  const out = join(root, "reports", "deep", "r.json");
  await writeReport(EXPECTED, out);
  assert.equal(
    await readFile(out, "utf8"),
    `${JSON.stringify(EXPECTED, null, 2)}\n`,
  );
  await writeReport({ files: 0 }, out);
  assert.equal(await readFile(out, "utf8"), '{\n  "files": 0\n}\n');
  assert.deepEqual(await readdir(join(root, "reports", "deep")), ["r.json"]);
});

test("cli prints the summary", async () => {
  const { stdout, stderr } = await run(process.execPath, [CLI, logs]);
  assert.equal(stderr, "");
  assert.equal(stdout, `${JSON.stringify(EXPECTED, null, 2)}\n`);
});

test("cli writes the report with --out and -o", async () => {
  for (const flag of ["--out", "-o"]) {
    const out = join(root, `cli-${flag}`, "report.json");
    const { stdout } = await run(process.execPath, [CLI, flag, out, logs]);
    assert.equal(stdout, "");
    assert.deepEqual(JSON.parse(await readFile(out, "utf8")), EXPECTED);
  }
});

test("cli errors exit with code 2", async () => {
  const cases = [[], [logs, logs], ["--bogus", logs], [join(root, "missing")]];
  for (const args of cases) {
    await assert.rejects(run(process.execPath, [CLI, ...args]), (err) => {
      assert.equal(err.code, 2, args.join(" "));
      assert.match(err.stderr, /^error: .+\n$/);
      assert.equal(err.stdout, "");
      return true;
    });
  }
});
