import { createReadStream } from "node:fs";
import { mkdir, readdir, rename, rm, writeFile } from "node:fs/promises";
import { dirname, join, relative, sep } from "node:path";
import { createInterface } from "node:readline";
import { createGunzip } from "node:zlib";

const LEVELS = ["info", "warn", "error"];

async function findLogs(dir) {
  const entries = await readdir(dir, { recursive: true, withFileTypes: true });
  return entries
    .filter(
      (e) =>
        e.isFile() && (e.name.endsWith(".log") || e.name.endsWith(".log.gz")),
    )
    .map((e) => relative(dir, join(e.parentPath, e.name)).split(sep).join("/"))
    .toSorted();
}

function openLines(path) {
  const raw = createReadStream(path);
  let input = raw;
  if (path.endsWith(".gz")) {
    input = createGunzip();
    raw.on("error", (err) => input.destroy(err));
    raw.pipe(input);
  }
  return createInterface({ input, crlfDelay: Number.POSITIVE_INFINITY });
}

function parseEntry(text) {
  let value;
  try {
    value = JSON.parse(text);
  } catch {
    return null;
  }
  if (
    typeof value !== "object" ||
    value === null ||
    !LEVELS.includes(value.level) ||
    typeof value.msg !== "string" ||
    !Number.isFinite(value.ms)
  ) {
    return null;
  }
  return value;
}

function bySlowest(a, b) {
  if (a.ms !== b.ms) return b.ms - a.ms;
  if (a.file !== b.file) return a.file < b.file ? -1 : 1;
  return a.line - b.line;
}

export async function summarizeDir(dir) {
  const files = await findLogs(dir);
  const summary = {
    files: files.length,
    entries: 0,
    invalid: 0,
    levels: { info: 0, warn: 0, error: 0 },
    maxMs: null,
    slowest: [],
  };
  for (const file of files) {
    let line = 0;
    for await (const text of openLines(join(dir, file))) {
      line++;
      if (text.trim() === "") continue;
      const entry = parseEntry(text);
      if (!entry) {
        summary.invalid++;
        continue;
      }
      summary.entries++;
      summary.levels[entry.level]++;
      summary.maxMs = Math.max(summary.maxMs ?? entry.ms, entry.ms);
      const item = { file, line, ms: entry.ms, msg: entry.msg };
      summary.slowest = [...summary.slowest, item]
        .toSorted(bySlowest)
        .slice(0, 3);
    }
  }
  return summary;
}

export async function writeReport(summary, outPath) {
  await mkdir(dirname(outPath), { recursive: true });
  const tmp = `${outPath}.${process.pid}.${Date.now()}.tmp`;
  try {
    await writeFile(tmp, `${JSON.stringify(summary, null, 2)}\n`, "utf8");
    await rename(tmp, outPath);
  } catch (err) {
    await rm(tmp, { force: true });
    throw err;
  }
}
