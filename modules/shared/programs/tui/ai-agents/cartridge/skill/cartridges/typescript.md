# typescript cartridge — target: TypeScript 5.9

## Rules (DON'T → DO)
- DON'T use `any` → DO use `unknown` and narrow it before use.
- DON'T cast with `as Foo` to silence errors → DO narrow with type guards or fix the type.
- DON'T annotate a literal config as `const x: Config = {...}` when you need its literal types → DO use `const x = {...} satisfies Config`.
- DON'T use `!` (non-null assertion) to skip checks → DO check `if (x == null) throw ...` or use `?.` / `??`.
- DON'T use `enum` → DO use `as const` objects or string literal unions.
- DON'T use `namespace` → DO use ES modules.
- DON'T write constructor parameter properties (`constructor(private x: number)`) under `erasableSyntaxOnly` → DO declare fields explicitly.
- DON'T import types as values → DO use `import type { T }` or `import { type T, value }`.
- DON'T omit extensions in ESM relative imports with `nodenext` → DO write `./util.js` (even though the file is `util.ts`).
- DON'T write `./util.ts` in imports unless `allowImportingTsExtensions` or `rewriteRelativeImportExtensions` is set.
- DON'T use `moduleResolution: "node"` / `"node10"` → DO use `nodenext` (Node) or `bundler` (Vite/esbuild/etc.).
- DON'T use `Function`, `Object`, `{}` as types → DO use `(...args: never[]) => unknown`, `object`, `Record<string, unknown>`.
- DON'T use `String`, `Number`, `Boolean` wrapper types → DO use `string`, `number`, `boolean`.
- DON'T write `catch (e: Error)` → DO write `catch (e)` (it is `unknown`) and check `e instanceof Error`.
- DON'T write overloads when a union or generic works → DO use one signature.
- DON'T add a generic used only once → DO use the concrete type.
- DON'T use `@ts-ignore` → DO use `@ts-expect-error` with a reason (it fails when no longer needed).
- DON'T return `Promise<any>` from fetch wrappers → DO validate JSON (e.g. zod) and return a real type.

## Gotchas
- `strict: true` is required for useful checking; it enables `strictNullChecks`, `noImplicitAny`, etc.
- `strict` does NOT enable `noUncheckedIndexedAccess`; turn it on so `arr[i]` is `T | undefined`.
- `exactOptionalPropertyTypes` makes `x?: string` reject explicit `undefined`.
- Types are erased at runtime; you cannot `instanceof` an interface or type alias.
- `typeof x === "object"` is also true for `null`; check `x !== null` too.
- Narrowing is lost inside callbacks for `let` variables that are reassigned; copy to a `const`.
- `in` narrowing: `if ("kind" in x)` narrows unions by property presence.
- Discriminated unions need a shared literal field (`kind: "a" | "b"`); switch on it.
- `Object.keys(obj)` returns `string[]`, not `(keyof T)[]`; this is by design.
- `array.filter(Boolean)` does NOT narrow the type; use `filter((x) => x != null)` (TS 5.5+ infers the predicate).
- `as const` makes arrays `readonly` tuples; functions taking `string[]` reject them, accept `readonly string[]`.
- Interfaces merge when declared twice; type aliases error instead.
- `interface` can only describe object shapes; use `type` for unions, tuples, mapped and conditional types.
- `verbatimModuleSyntax: true` keeps imports exactly as written: type-only imports must use `import type`.
- With `verbatimModuleSyntax` and `module: nodenext`, a `.ts` file in a CJS package cannot use `import`/`export` (ESM syntax); set `"type": "module"`.
- `module: nodenext` reads `package.json` `"type"` to decide ESM vs CJS per file; `.mts`/`.cts` force it.
- `module: node20` (TS 5.9) is a stable alternative to `nodenext` for Node 20+.
- Node's built-in type stripping requires `erasableSyntaxOnly: true` (no enums, namespaces, parameter properties).
- `tsc` never bundles and never rewrites import paths unless `rewriteRelativeImportExtensions` is on.
- `paths` in tsconfig only affects type-checking; the runtime/bundler must resolve them too.
- `skipLibCheck: true` is normal; it skips checking `.d.ts` files.
- `readonly` on properties is compile-time only.
- Excess property checks only apply to fresh object literals, not to variables.

## Correct API names
- `Partial<T>`, `Required<T>`, `Readonly<T>`, `Pick<T, K>`, `Omit<T, K>`, `Record<K, V>`
- `Exclude<U, X>` (unions) vs `Omit<T, K>` (object keys); do not swap them.
- `Extract<U, X>`, `NonNullable<T>`, `ReturnType<F>`, `Parameters<F>`, `Awaited<T>`, `InstanceType<C>`
- `NoInfer<T>` (5.4+) blocks inference from one argument.
- `ValueOf<T>` does not exist → `T[keyof T]`
- `Nullable<T>` does not exist → `T | null`
- `DeepPartial` / `DeepReadonly` do not exist → write your own or use a library.
- `ElementType<A>` does not exist → `A[number]`
- `PromiseType<P>` does not exist → `Awaited<P>`
- `satisfies` is an operator, not a type: `expr satisfies T`.
- Type predicate syntax: `(x: unknown): x is Foo`; assertion: `asserts x is Foo`.
- `const` type params: `function f<const T>(x: T)` infers literal types.
- `using` / `await using` declarations exist (5.2+) for `Symbol.dispose` / `Symbol.asyncDispose`.

## Idioms
```ts
const Color = { Red: "red", Blue: "blue" } as const;
type Color = (typeof Color)[keyof typeof Color]; // "red" | "blue"
```
```ts
type Shape = { kind: "circle"; r: number } | { kind: "square"; s: number };
function area(s: Shape): number {
  switch (s.kind) {
    case "circle": return Math.PI * s.r ** 2;
    case "square": return s.s ** 2;
    default: { const _never: never = s; throw new Error(`unhandled ${_never}`); }
  }
}
```
```ts
function isUser(x: unknown): x is User {
  return typeof x === "object" && x !== null && "id" in x;
}
```
```ts
const routes = { home: "/", about: "/about" } satisfies Record<string, string>;
```
```ts
function getProp<T, K extends keyof T>(obj: T, key: K): T[K] { return obj[key]; }
```
```ts
import type { Config } from "./config.js";
import { load, type Options } from "./load.js";
```
tsconfig for Node 24 (ESM):
```json
{ "compilerOptions": {
  "target": "es2024", "module": "nodenext", "moduleResolution": "nodenext",
  "strict": true, "noUncheckedIndexedAccess": true, "verbatimModuleSyntax": true,
  "erasableSyntaxOnly": true, "skipLibCheck": true, "outDir": "dist" } }
```
tsconfig for a bundler (Vite): `"module": "esnext", "moduleResolution": "bundler", "noEmit": true`.

## Tooling
- Type-check only: `npx tsc --noEmit`
- Build: `npx tsc -p tsconfig.json`; watch: `npx tsc -w`
- Create config: `npx tsc --init`
- Run TS directly: `node file.ts` (Node 23.6+, erasable syntax only) or `npx tsx file.ts`.
- Types for Node: `npm i -D @types/node`.
- Lint: `npx eslint .` with `typescript-eslint` (flat config `eslint.config.js`).
- Test: `npx vitest run` or `node --test`.
