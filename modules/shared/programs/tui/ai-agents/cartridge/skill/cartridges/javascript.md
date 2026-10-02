# javascript cartridge — target: ECMAScript 2024 (modern browsers)

## Rules (DON'T → DO)
- DON'T use `var` → DO use `const` by default, `let` only when reassigned.
- DON'T use `==` / `!=` → DO use `===` / `!==` (only exception: `x == null` checks null and undefined).
- DON'T use `||` for defaults when 0, "" or false are valid → DO use `??`.
- DON'T chain `a && a.b && a.b.c` → DO use `a?.b?.c`; call optional functions with `fn?.()`.
- DON'T call `arr.sort()` / `arr.reverse()` / `arr.splice()` on shared data → DO use `toSorted()` / `toReversed()` / `toSpliced()` (they return copies).
- DON'T copy-then-assign `copy[i] = v` → DO use `arr.with(i, v)`.
- DON'T use `arr[arr.length - 1]` → DO use `arr.at(-1)`.
- DON'T use `[...arr].reverse().find(...)` → DO use `arr.findLast(...)` / `arr.findLastIndex(...)`.
- DON'T deep-copy with `JSON.parse(JSON.stringify(x))` → DO use `structuredClone(x)`.
- DON'T hand-roll groupBy with `reduce` → DO use `Object.groupBy(arr, fn)` or `Map.groupBy(arr, fn)`.
- DON'T use `obj.hasOwnProperty(k)` → DO use `Object.hasOwn(obj, k)`.
- DON'T `await` inside `arr.forEach(async ...)` → DO use `for...of` (sequential) or `Promise.all(arr.map(...))` (parallel).
- DON'T `await` independent promises one by one → DO use `Promise.all([...])`.
- DON'T use `Promise.all` when you need every result even on failure → DO use `Promise.allSettled`.
- DON'T call `parseInt(s)` without radix → DO use `parseInt(s, 10)` or `Number(s)`.
- DON'T use global `isNaN(x)` → DO use `Number.isNaN(x)`; use `Number.isInteger` / `Number.isFinite` too.
- DON'T write `catch (e) {}` when e is unused → DO write `catch {}` (optional catch binding).
- DON'T use `new Promise` around a promise-returning call → DO return/await the promise directly.
- DON'T build a deferred by leaking resolve from a constructor → DO use `Promise.withResolvers()`.
- DON'T use `str.replace(/x/g, y)` just to replace all literals → DO use `str.replaceAll("x", y)`.
- DON'T use `arguments` → DO use rest params `(...args)`.
- DON'T use `for...in` on arrays → DO use `for...of` (for...in gives string keys and inherited props).
- DON'T use CommonJS `require` / `module.exports` in browser/ESM code → DO use `import` / `export`.
- DON'T mix default and named imports by guess → DO match exactly how the module exports.

## Gotchas
- `this` in an arrow function is lexical; in a regular function it depends on the call site.
- Do not use arrow functions as object methods that need `this`, or as constructors.
- Passing `obj.method` as a callback loses `this`; use `() => obj.method()` or `.bind(obj)`.
- `let`/`const` are block-scoped and in the TDZ until declared; `var` is function-scoped and hoisted.
- Closures in `for (let i...)` capture a fresh `i` each iteration; with `var` they all share one.
- `arr.sort()` sorts as strings by default: `[10, 9, 1].sort()` → `[1, 10, 9]`. Pass `(a, b) => a - b`.
- `sort`, `reverse`, `splice`, `fill`, `copyWithin` mutate in place and return the same array.
- `0.1 + 0.2 !== 0.3`; compare with `Math.abs(a - b) < Number.EPSILON` or use integer cents.
- Integers above `Number.MAX_SAFE_INTEGER` (2^53-1) lose precision; use `BigInt` (`123n`).
- `Number("")` is 0, `Number(" ")` is 0, `Number(null)` is 0, `Number(undefined)` is NaN.
- `parseInt("12px", 10)` is 12 but `Number("12px")` is NaN; pick the one you mean.
- `NaN !== NaN`; use `Number.isNaN` or `Object.is(x, NaN)`.
- `typeof null === "object"`; `Array.isArray(x)` is the only reliable array check.
- `Date` months are 0-based (`new Date(2024, 0, 31)` is Jan 31); days of month are 1-based.
- `new Date("2024-01-31")` parses as UTC; `new Date("2024-01-31T00:00")` parses as local time.
- `JSON.parse` throws `SyntaxError` on bad input; wrap in try/catch.
- `JSON.stringify` drops `undefined`, functions and symbols; Map/Set become `{}`; BigInt throws.
- `structuredClone` cannot clone functions, DOM nodes or class prototypes (instances become plain objects).
- `Promise.all` rejects on the first failure; other promises keep running (no cancel).
- `Promise.any` rejects with `AggregateError` only if all reject; `Promise.race` settles on the first settle.
- Unawaited async calls swallow ordering and errors become unhandled rejections.
- `async` functions always return a Promise, even when returning a plain value.
- `Object.groupBy` returns a null-prototype object; it has no `hasOwnProperty` method.
- `Array(3)` makes holes, not undefined; use `Array.from({ length: 3 }, (_, i) => i)`.
- `const` prevents reassignment, not mutation; use `Object.freeze` (shallow) for immutability.
- ESM imports are live bindings and hoisted; you cannot conditionally `import` (use `await import()`).
- ESM is strict mode by default; top-level `await` works only in modules.
- Import paths in browsers need full file names with extension (`./util.js`), or an import map.
- `Set` methods (`union`, `intersection`, `difference`) and iterator helpers (`.map` on iterators) are ES2025; check target before using.

## Correct API names
- `array.contains` → `array.includes`
- `array.last()` / `array.first()` → `array.at(-1)` / `array.at(0)`
- `array.groupBy` / `Array.groupBy` → `Object.groupBy(arr, fn)` / `Map.groupBy(arr, fn)`
- `array.sorted()` → `array.toSorted()`
- `array.flatten()` → `array.flat()`
- `array.remove(i)` → `array.toSpliced(i, 1)` or `array.splice(i, 1)`
- `array.unique()` → `[...new Set(array)]`
- `array.sum()` → `array.reduce((a, b) => a + b, 0)`
- `object.map` / `object.entries()` → `Object.entries(obj)` then `Object.fromEntries(...)`
- `Object.clone` / `deepClone` → `structuredClone`
- `string.contains` → `string.includes`
- `string.trimLeft` / `trimRight` → `trimStart` / `trimEnd`
- `string.substr` (deprecated) → `string.slice`
- `Promise.allResolved` → `Promise.allSettled`
- `Promise.defer` → `Promise.withResolvers`
- `Array.fromAsync` is real (ES2024) for async iterables.
- `str.isWellFormed()` / `str.toWellFormed()` are real (ES2024).
- `Atomics.waitAsync` and `ArrayBuffer.prototype.resize` are real (ES2024).

## Idioms
```js
const results = await Promise.all(ids.map((id) => load(id)));
for (const id of ids) await save(id); // sequential
```
```js
const settled = await Promise.allSettled(tasks);
const ok = settled.filter((r) => r.status === "fulfilled").map((r) => r.value);
```
```js
const byType = Object.groupBy(items, (it) => it.type); // { a: [...], b: [...] }
const sorted = items.toSorted((a, b) => a.price - b.price);
```
```js
const { promise, resolve, reject } = Promise.withResolvers();
```
```js
let data;
try { data = JSON.parse(text); } catch { data = null; }
```
```js
const port = Number.parseInt(input, 10);
if (Number.isNaN(port)) throw new Error(`bad port: ${input}`);
```
```js
export function f() {}          // named export
export default class App {}     // default export
import App, { f } from "./app.js";
const mod = await import("./lazy.js"); // dynamic import
```
```js
throw new Error("load failed", { cause: err }); // error chaining
```

## Tooling
- Format: `npx prettier --write .`
- Lint: `npx eslint .` (flat config file is `eslint.config.js`; `.eslintrc` is legacy).
- Fast lint+format alternative: `npx @biomejs/biome check --write .`
- Bundle/dev server: `npx vite`, `npx vite build`.
- Test (vitest): `npx vitest run`.
- Type-check plain JS: add `// @ts-check` at file top or `"checkJs": true` in jsconfig.
