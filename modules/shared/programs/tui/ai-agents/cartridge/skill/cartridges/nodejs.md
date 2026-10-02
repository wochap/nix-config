# nodejs cartridge — target: Node.js 24

## Rules (DON'T → DO)
- DON'T `require("fs")` → DO `import fs from "node:fs"` (always use the `node:` prefix for built-ins).
- DON'T use callback fs (`fs.readFile(p, cb)`) → DO `import { readFile } from "node:fs/promises"`.
- DON'T use `util.promisify(fs.x)` → DO use `node:fs/promises` or `node:timers/promises`.
- DON'T `new Promise(r => setTimeout(r, ms))` → DO `import { setTimeout as sleep } from "node:timers/promises"`.
- DON'T install `node-fetch` / `axios` for simple HTTP → DO use global `fetch`.
- DON'T install `ws` for a WebSocket client → DO use global `WebSocket` (client only; servers still need `ws`).
- DON'T install `dotenv` → DO `node --env-file=.env app.js` or `process.loadEnvFile()`.
- DON'T install `nodemon` → DO `node --watch app.js`.
- DON'T install jest/mocha for simple tests → DO `node --test` with `node:test` + `node:assert/strict`.
- DON'T install `uuid` → DO `crypto.randomUUID()`.
- DON'T install `chalk` → DO `util.styleText("red", text)`.
- DON'T install `yargs`/`minimist` for simple CLIs → DO `util.parseArgs`.
- DON'T install `glob` → DO `fs.promises.glob` / `fs.globSync`.
- DON'T install `rimraf` / `mkdirp` → DO `fs.rm(p, { recursive: true, force: true })` / `fs.mkdir(p, { recursive: true })`.
- DON'T use `__dirname` / `__filename` in ESM → DO use `import.meta.dirname` / `import.meta.filename`.
- DON'T use `process.exit(1)` after async work → DO set `process.exitCode = 1` and let the event loop drain.
- DON'T `src.pipe(dst)` without error handling → DO `await pipeline(src, ..., dst)` from `node:stream/promises`.
- DON'T use `fs.exists` (deprecated) → DO `fs.existsSync` or try `fs.promises.access` / handle `ENOENT`.
- DON'T use `new Buffer(x)` → DO `Buffer.from(x)` / `Buffer.alloc(n)`.
- DON'T use `url.parse` → DO `new URL(str)`; convert file URLs with `fileURLToPath(url)` from `node:url`.
- DON'T use `querystring` → DO `URLSearchParams`.
- DON'T use `ts-node` → DO `node file.ts` (erasable TS only) or `npx tsx file.ts`.
- DON'T use `child_process.exec` with user input → DO `execFile` / `spawn` with an args array.

## Gotchas
- `"type": "module"` in package.json makes `.js` files ESM; otherwise `.js` is CommonJS. `.mjs`/`.cjs` force it.
- ESM relative imports need the full extension: `import x from "./util.js"`.
- `require(esm)` works in Node 24 if the ES module has no top-level `await`.
- Importing CJS from ESM: default import gets `module.exports`; named imports work only when statically detectable.
- JSON import in ESM needs an attribute: `import data from "./d.json" with { type: "json" }` (not `assert`).
- Type stripping: `node file.ts` runs TS with erasable syntax only; `enum`, `namespace`, parameter properties fail.
- Type stripping does no type-checking and ignores tsconfig; imports must use `.ts` extensions; use `import type` for types.
- `--experimental-transform-types` enables enums etc. but is experimental; prefer avoiding that syntax.
- `"exports"` in package.json hides all unlisted subpaths; deep imports like `pkg/lib/x.js` break.
- `fetch` does not reject on HTTP 4xx/5xx; check `res.ok`.
- `fetch` has no default timeout; pass `signal: AbortSignal.timeout(ms)`.
- `fs.readFile` returns a Buffer unless you pass an encoding (`"utf8"`).
- `fs/promises` `readdir` returns names only; pass `{ withFileTypes: true }` for Dirent objects, `{ recursive: true }` for subdirs.
- `fs.watch` events are platform-dependent and can fire twice.
- Unhandled promise rejections crash the process (exit code 1).
- `process.env` values are always strings or undefined.
- `EventEmitter` `"error"` events with no listener throw and crash.
- `node:test` `describe`/`it` and `test` are both exported; `beforeEach`/`afterEach`/`mock` too.
- `node:assert/strict`: `assert.equal` is strict; use `assert.deepEqual` for objects.
- `--env-file` does not override variables already set in the environment.
- `node --test` with no args runs files like `*.test.js`, `*_test.js`, `*-test.js`, `test-*.js` and anything under `test/` (also `.ts`).

## Correct API names
- `fs.promises.exists` does not exist → `fs.existsSync` or `access`.
- `fs.readJson` (fs-extra) does not exist → `JSON.parse(await readFile(p, "utf8"))`.
- `fs.copy` (fs-extra) → `fs.promises.cp(src, dst, { recursive: true })`.
- `path.join` vs `path.resolve`: `resolve` returns an absolute path from cwd.
- `process.env.load()` / `dotenv.config()` → `process.loadEnvFile(".env")`.
- `util.colors` / `util.colorize` → `util.styleText(format, text)` (format can be an array: `["bold", "red"]`).
- `util.parseArguments` / `util.args` → `util.parseArgs({ args, options, allowPositionals })`.
- `stream.pipelineAsync` → `pipeline` from `node:stream/promises`.
- `events.once` is real: `await once(emitter, "ready")` from `node:events`.
- `import.meta.dir` / `import.meta.path` (Bun) → `import.meta.dirname` / `import.meta.filename`.
- `test.mock` → `mock` export from `node:test` (`mock.fn()`, `mock.method(obj, "name")`, `mock.timers`).
- `assert.throwsAsync` → `await assert.rejects(promise)`.
- `crypto.uuid()` → `crypto.randomUUID()`.
- `node:sqlite` `DatabaseSync` is real (built-in SQLite, no npm package needed).
- `AbortSignal.timeout(ms)` and `AbortSignal.any([s1, s2])` are real.

## Idioms
```js
import { readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
const cfg = JSON.parse(await readFile(join(import.meta.dirname, "cfg.json"), "utf8"));
```
```js
const res = await fetch(url, { signal: AbortSignal.timeout(5000) });
if (!res.ok) throw new Error(`HTTP ${res.status}`);
const body = await res.json();
```
```js
import { pipeline } from "node:stream/promises";
import { createReadStream, createWriteStream } from "node:fs";
import { createGzip } from "node:zlib";
await pipeline(createReadStream("in.txt"), createGzip(), createWriteStream("in.txt.gz"));
```
```js
import { parseArgs, styleText } from "node:util";
const { values, positionals } = parseArgs({
  options: { verbose: { type: "boolean", short: "v" }, out: { type: "string" } },
  allowPositionals: true,
});
console.error(styleText("red", "error"));
```
```js
import { test } from "node:test";
import assert from "node:assert/strict";
test("adds", () => { assert.equal(1 + 1, 2); });
test("rejects", async () => { await assert.rejects(load("bad")); });
```
```js
import { execFile } from "node:child_process";
import { promisify } from "node:util";
const { stdout } = await promisify(execFile)("git", ["status", "--short"]);
```
package.json:
```json
{ "type": "module", "exports": { ".": "./dist/index.js", "./utils": "./dist/utils.js" },
  "engines": { "node": ">=24" } }
```

## Tooling
- Run: `node app.js`; TS: `node app.ts`.
- Watch: `node --watch app.js` (`--watch-path=src` to limit).
- Env: `node --env-file=.env app.js` (`--env-file-if-exists` for optional).
- Test: `node --test`; filter `--test-name-pattern="adds"`; coverage `--experimental-test-coverage`.
- Run package.json script without npm: `node --run build`.
- Install: `npm ci` in CI (uses lockfile exactly), `npm install` locally.
- Debug: `node --inspect-brk app.js`.
