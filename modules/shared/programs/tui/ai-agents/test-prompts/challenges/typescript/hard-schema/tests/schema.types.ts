import { type Infer, s } from "../src/schema.ts";

const User = s.object({
  id: s.number(),
  name: s.string(),
  role: s.union(s.literal("admin"), s.literal("user")),
  tags: s.array(s.string()),
  nick: s.optional(s.string()),
});
type User = Infer<typeof User>;

export const a: User = { id: 1, name: "a", role: "admin", tags: [] };
export const b: User = { id: 1, name: "b", role: "user", tags: [], nick: "n" };
// @ts-expect-error name is required
export const noName: User = { id: 1, role: "admin", tags: [] };
// @ts-expect-error role is "admin" | "user"
export const badRole: User = { id: 1, name: "c", role: "root", tags: [] };
// @ts-expect-error tags are strings
export const badTags: User = { id: 1, name: "d", role: "user", tags: [1] };
// @ts-expect-error id is a number
export const badId: User = { id: "1", name: "e", role: "user", tags: [] };

export function describe(input: unknown): string {
  const u = User.parse(input);
  const id: number = u.id;
  const tags: string[] = u.tags;
  // @ts-expect-error nick may be undefined
  const nick: string = u.nick;
  const role: "admin" | "user" = u.role;
  return `${id}${tags.length}${nick}${role}`;
}

export function safe(input: unknown): string {
  const r = User.safeParse(input);
  if (r.success) return r.data.name;
  // @ts-expect-error data only exists on success
  const data = r.data;
  return `${r.error.path}${r.error.message}${String(data)}`;
}

const Answer = s.literal(42);
export const answer: Infer<typeof Answer> = 42;
// @ts-expect-error only 42 is allowed
export const notAnswer: Infer<typeof Answer> = 41;

const Flag = s.literal(true);
// @ts-expect-error only true is allowed
export const flag: Infer<typeof Flag> = false;

const Id = s.union(s.number(), s.string(), s.literal(null));
export const ids: Infer<typeof Id>[] = [1, "x", null];
// @ts-expect-error booleans are not ids
export const badIdValue: Infer<typeof Id> = true;

const Nested = s.object({
  items: s.array(s.object({ sku: s.string(), qty: s.optional(s.number()) })),
});
export const nested: Infer<typeof Nested> = { items: [{ sku: "a" }] };
// @ts-expect-error sku is required in nested objects
export const badNested: Infer<typeof Nested> = { items: [{ qty: 1 }] };

const Maybe = s.optional(s.boolean());
export const maybe: Infer<typeof Maybe>[] = [true, undefined];
