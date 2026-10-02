import assert from "node:assert/strict";
import { test } from "node:test";
import { omit, pick } from "../src/pick.ts";

test("pick copies listed keys", () => {
  assert.deepEqual(pick({ a: 1, b: 2, c: 3 }, ["a", "c"]), { a: 1, c: 3 });
  assert.deepEqual(pick({ a: 1 }, []), {});
});

test("pick skips missing and inherited keys", () => {
  const proto = { inherited: 1 };
  const obj: { own: number; inherited: number; opt?: string } =
    Object.create(proto);
  obj.own = 2;
  assert.deepEqual(pick(obj, ["own", "inherited", "opt"]), { own: 2 });
  assert.equal(Object.hasOwn(pick(obj, ["opt"]), "opt"), false);
});

test("pick keeps undefined values that exist", () => {
  const obj: { a: number | undefined; b: number } = { a: undefined, b: 1 };
  const r = pick(obj, ["a"]);
  assert.equal(Object.hasOwn(r, "a"), true);
  assert.equal(r.a, undefined);
});

test("omit drops listed keys", () => {
  assert.deepEqual(omit({ a: 1, b: 2, c: 3 }, ["a"]), { b: 2, c: 3 });
  assert.deepEqual(omit({ a: 1, b: 2 }, ["a", "b"]), {});
  assert.deepEqual(omit({ a: 1 }, []), { a: 1 });
});

test("inputs are not modified and results are new objects", () => {
  const src = Object.freeze({ a: 1, b: 2 });
  const p = pick(src, ["a", "b"]);
  const o = omit(src, []);
  assert.notEqual(p, src);
  assert.notEqual(o, src);
  assert.deepEqual(src, { a: 1, b: 2 });
});

test("readonly key arrays work", () => {
  const keys = ["b"] as const;
  assert.deepEqual(pick({ a: 1, b: "x" }, keys), { b: "x" });
  assert.deepEqual(omit({ a: 1, b: "x" }, keys), { a: 1 });
});
