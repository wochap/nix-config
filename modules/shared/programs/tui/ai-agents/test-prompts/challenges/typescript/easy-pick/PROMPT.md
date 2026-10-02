# Typed pick and omit

Implement `src/pick.ts` (TypeScript, ES module) with two named exports:

```ts
pick(obj, keys) // new object with only the listed keys
omit(obj, keys) // new object with every own key except the listed keys
```

Runtime behavior:
- `obj` is a plain object; `keys` is an array (it may be a readonly array).
- Only own enumerable properties of `obj` are copied. `pick` skips listed keys
  that `obj` does not have as own properties.
- The input object is never modified; a new object is always returned.

```ts
pick({ a: 1, b: 2, c: 3 }, ["a", "c"]) // { a: 1, c: 3 }
omit({ a: 1, b: 2, c: 3 }, ["a"])      // { b: 2, c: 3 }
pick({ a: 1 }, [])                     // {}
```

Types (checked by `tsc` in strict mode; see `tests/pick.types.ts`):
- `keys` only accepts keys of `obj`'s type; an unknown key is a type error.
- The result of `pick` has exactly the picked keys, with their original types.
- The result of `omit` has every key except the omitted ones.
- No `any` in the public signatures.

Files: `src/pick.ts`. Tests: `tests/*.test.ts` run with `node --test` (Node
runs TypeScript directly, so only erasable syntax works: no `enum`,
`namespace` or constructor parameter properties). Type tests in
`tests/pick.types.ts` use `// @ts-expect-error`, so each marked line must be a
type error.
