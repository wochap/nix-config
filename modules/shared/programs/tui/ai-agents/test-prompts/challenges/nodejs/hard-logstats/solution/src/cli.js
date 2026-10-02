import { parseArgs } from "node:util";
import { summarizeDir, writeReport } from "./logstats.js";

try {
  const { values, positionals } = parseArgs({
    options: { out: { type: "string", short: "o" } },
    allowPositionals: true,
  });
  if (positionals.length !== 1) {
    throw new Error("usage: cli.js [--out <file>] <dir>");
  }
  const summary = await summarizeDir(positionals[0]);
  if (values.out === undefined) {
    process.stdout.write(`${JSON.stringify(summary, null, 2)}\n`);
  } else {
    await writeReport(summary, values.out);
  }
} catch (err) {
  process.stderr.write(`error: ${err.message}\n`);
  process.exitCode = 2;
}
