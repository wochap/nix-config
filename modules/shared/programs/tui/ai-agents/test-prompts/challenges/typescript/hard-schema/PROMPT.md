# Mini schema validator

Implement `src/schema.ts` (TypeScript, ES module): a small runtime validator
whose static types are inferred from the schema, like this:

```ts
import { type Infer, s } from "./schema.ts";

const User = s.object({
  id: s.number(),
  name: s.string(),
  role: s.union(s.literal("admin"), s.literal("user")),
  tags: s.array(s.string()),
  nick: s.optional(s.string()),
});
type User = Infer<typeof User>;
// { id: number; name: string; role: "admin" | "user"; tags: string[]; nick?: string | undefined }

const u = User.parse(JSON.parse(text)); // u: User, or throws ValidationError
const r = User.safeParse(data);         // never throws
if (r.success) r.data.name; else r.error.path;
```

## Exports

```ts
export class ValidationError extends Error // name "ValidationError", plus `path: string`
export interface Schema<T> {
  parse(input: unknown): T;                // throws ValidationError
  safeParse(input: unknown): SafeResult<T>;
}
export type SafeResult<T> =
  | { success: true; data: T }
  | { success: false; error: ValidationError };
export type Infer<S> // the T of a Schema<T>
export const s // object with the builders below
```

| builder | accepts | inferred type |
|---|---|---|
| `s.string()` | strings | `string` |
| `s.number()` | numbers except `NaN` | `number` |
| `s.boolean()` | booleans | `boolean` |
| `s.literal(v)` | exactly `v` (`===`); `v` is a string, number, boolean or `null` | the literal type of `v` (`s.literal("a")` is `"a"`) |
| `s.array(item)` | arrays whose every element matches `item` | `T[]` |
| `s.object(shape)` | non-null, non-array objects; each shape key is validated | object type, see below |
| `s.optional(inner)` | `undefined`, or what `inner` accepts | `T \| undefined` |
| `s.union(a, b, ...)` | the first member (in order) that accepts | union of the member types |

`s.object` details:
- Keys wrapped in `s.optional(...)` become optional properties (`nick?:`);
  all other keys are required.
- A missing key is validated as `undefined`.
- The output is a new object with only the shape's keys (unknown keys are
  dropped). Optional keys whose value is `undefined` are left out.
- `s.array` also returns a new array.

## Errors
Validation stops at the first error. Object keys are checked in shape order,
array elements in index order. The `ValidationError` has:
- `path`: where it failed. `""` for the top level, `name` for a key,
  `tags[1]` for an array element, `address.zip`, `items[0].qty` when nested,
  `[2]` or `[1][0]` for elements of a top-level array.
- `message`: exactly one of
  - `expected <kind>, got <type>` where `<kind>` is `string`, `number`,
    `boolean`, `array` or `object`, and `<type>` is `typeof input`, except
    `null`, `array` (for arrays) and `NaN` (for `NaN`).
    Example: `expected string, got undefined`.
  - `expected <JSON.stringify(v)>` for a failed literal, e.g. `expected "admin"`.
  - `no union member matched` for a failed union (path of the union itself).

`safeParse` returns `{ success: false, error }` instead of throwing.

## Rules
Files: `src/schema.ts`. Tests: `tests/*.test.ts` run with `node --test`
(Node runs TypeScript directly, so only erasable syntax works: no `enum`,
`namespace` or constructor parameter properties). Type tests in
`tests/schema.types.ts` are checked by `tsc` in strict mode and use
`// @ts-expect-error`, so each marked line must be a type error.
No `any` in the public types.
