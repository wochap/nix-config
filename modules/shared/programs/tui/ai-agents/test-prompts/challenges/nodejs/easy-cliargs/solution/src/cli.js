import { parseArgs } from "node:util";

const options = {
  name: { type: "string", short: "n", default: "world" },
  count: { type: "string", short: "c", default: "1" },
  verbose: { type: "boolean", short: "v", default: false },
};

export function parseCli(argv) {
  const { values, positionals } = parseArgs({
    args: argv,
    options,
    allowPositionals: true,
    allowNegative: true,
  });
  if (!/^\d+$/.test(values.count) || Number(values.count) < 1) {
    throw new RangeError(`invalid --count: ${values.count}`);
  }
  return {
    name: values.name,
    count: Number(values.count),
    verbose: values.verbose,
    files: positionals,
  };
}
