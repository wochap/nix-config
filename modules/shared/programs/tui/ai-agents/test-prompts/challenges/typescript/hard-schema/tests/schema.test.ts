import assert from "node:assert/strict";
import { test } from "node:test";
import { s, ValidationError } from "../src/schema.ts";

const User = s.object({
  id: s.number(),
  name: s.string(),
  role: s.union(s.literal("admin"), s.literal("user")),
  tags: s.array(s.string()),
  nick: s.optional(s.string()),
});

function failure(fn: () => unknown): ValidationError {
  try {
    fn();
  } catch (error) {
    assert.ok(error instanceof ValidationError, "expected ValidationError");
    return error;
  }
  assert.fail("expected parse to throw");
}

function expectError(
  schema: { parse(input: unknown): unknown },
  input: unknown,
  path: string,
  message: string,
) {
  const error = failure(() => schema.parse(input));
  assert.equal(error.name, "ValidationError");
  assert.equal(error.path, path);
  assert.equal(error.message, message);
}

test("primitives", () => {
  assert.equal(s.string().parse("x"), "x");
  assert.equal(s.number().parse(0), 0);
  assert.equal(s.number().parse(-Infinity), -Infinity);
  assert.equal(s.boolean().parse(false), false);
  expectError(s.string(), 1, "", "expected string, got number");
  expectError(s.string(), null, "", "expected string, got null");
  expectError(s.number(), "1", "", "expected number, got string");
  expectError(s.number(), Number.NaN, "", "expected number, got NaN");
  expectError(s.boolean(), [], "", "expected boolean, got array");
  expectError(s.boolean(), undefined, "", "expected boolean, got undefined");
});

test("literals", () => {
  assert.equal(s.literal("a").parse("a"), "a");
  assert.equal(s.literal(1).parse(1), 1);
  assert.equal(s.literal(null).parse(null), null);
  assert.equal(s.literal(false).parse(false), false);
  expectError(s.literal("admin"), "root", "", 'expected "admin"');
  expectError(s.literal(1), "1", "", "expected 1");
  expectError(s.literal(null), undefined, "", "expected null");
});

test("objects parse into new objects without unknown keys", () => {
  const input = {
    id: 7,
    name: "ada",
    role: "admin",
    tags: ["x", "y"],
    extra: true,
  };
  const out = User.parse(input);
  assert.deepEqual(out, {
    id: 7,
    name: "ada",
    role: "admin",
    tags: ["x", "y"],
  });
  assert.notEqual(out, input);
  assert.notEqual(out.tags, input.tags);
  assert.equal(Object.hasOwn(out, "nick"), false);
  assert.equal(Object.hasOwn(out, "extra"), false);
  const withNick = User.parse({ ...input, nick: "a" });
  assert.equal(withNick.nick, "a");
  const undefNick = User.parse({ ...input, nick: undefined });
  assert.equal(Object.hasOwn(undefNick, "nick"), false);
});

test("object errors have paths", () => {
  const ok = { id: 1, name: "n", role: "user", tags: [] };
  expectError(User, null, "", "expected object, got null");
  expectError(User, [ok], "", "expected object, got array");
  expectError(User, "x", "", "expected object, got string");
  expectError(
    User,
    { ...ok, id: undefined },
    "id",
    "expected number, got undefined",
  );
  expectError(User, { role: "user" }, "id", "expected number, got undefined");
  expectError(User, { ...ok, name: 3 }, "name", "expected string, got number");
  expectError(User, { ...ok, role: "root" }, "role", "no union member matched");
  expectError(
    User,
    { ...ok, tags: ["a", 2] },
    "tags[1]",
    "expected string, got number",
  );
  expectError(User, { ...ok, tags: "a" }, "tags", "expected array, got string");
  expectError(User, { ...ok, nick: null }, "nick", "expected string, got null");
});

test("first error wins in shape order", () => {
  expectError(User, { name: 1, id: "x" }, "id", "expected number, got string");
});

test("nested paths", () => {
  const Order = s.object({
    address: s.object({ zip: s.string() }),
    items: s.array(s.object({ sku: s.string(), qty: s.number() })),
  });
  const ok = { address: { zip: "1000" }, items: [{ sku: "a", qty: 1 }] };
  assert.deepEqual(Order.parse(ok), ok);
  expectError(
    Order,
    { ...ok, address: { zip: 1 } },
    "address.zip",
    "expected string, got number",
  );
  expectError(
    Order,
    { ...ok, address: undefined },
    "address",
    "expected object, got undefined",
  );
  expectError(
    Order,
    {
      ...ok,
      items: [
        { sku: "a", qty: 1 },
        { sku: "b", qty: "2" },
      ],
    },
    "items[1].qty",
    "expected number, got string",
  );
  const Grid = s.array(s.array(s.number()));
  expectError(Grid, [[1], [2, true]], "[1][1]", "expected number, got boolean");
});

test("unions try members in order", () => {
  const Id = s.union(s.number(), s.string());
  assert.equal(Id.parse(1), 1);
  assert.equal(Id.parse("1"), "1");
  expectError(Id, true, "", "no union member matched");
  const Shape = s.union(
    s.object({ kind: s.literal("circle"), r: s.number() }),
    s.object({ kind: s.literal("square"), side: s.number() }),
  );
  assert.deepEqual(Shape.parse({ kind: "square", side: 2, r: 9 }), {
    kind: "square",
    side: 2,
  });
});

test("optional", () => {
  const Maybe = s.optional(s.number());
  assert.equal(Maybe.parse(undefined), undefined);
  assert.equal(Maybe.parse(3), 3);
  expectError(Maybe, null, "", "expected number, got null");
});

test("safeParse never throws", () => {
  const good = User.safeParse({ id: 1, name: "n", role: "user", tags: [] });
  assert.deepEqual(good, {
    success: true,
    data: { id: 1, name: "n", role: "user", tags: [] },
  });
  const bad = User.safeParse({ id: 1, name: "n", role: "user", tags: [0] });
  assert.equal(bad.success, false);
  if (!bad.success) {
    assert.ok(bad.error instanceof ValidationError);
    assert.ok(bad.error instanceof Error);
    assert.equal(bad.error.path, "tags[0]");
    assert.equal(bad.error.message, "expected string, got number");
  }
});
