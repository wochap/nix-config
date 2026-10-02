import assert from "node:assert/strict";
import { test } from "node:test";
import { decode, encode } from "../src/rle.js";

test("encode basic runs", () => {
  assert.equal(encode("aaabcc"), "3a1b2c");
  assert.equal(encode("abc"), "1a1b1c");
  assert.equal(encode("aabaa"), "2a1b2a");
});

test("encode empty", () => {
  assert.equal(encode(""), "");
});

test("encode multi-digit counts", () => {
  assert.equal(encode("a".repeat(12)), "12a");
  assert.equal(encode(`${"x".repeat(100)}y`), "100x1y");
});

test("encode code points", () => {
  assert.equal(encode("😀😀x"), "2😀1x");
  assert.equal(encode("🎉"), "1🎉");
  assert.equal(encode("  "), "2 ");
});

test("decode basic", () => {
  assert.equal(decode("3a1b2c"), "aaabcc");
  assert.equal(decode(""), "");
  assert.equal(decode("12a"), "a".repeat(12));
  assert.equal(decode("2😀1x"), "😀😀x");
});

test("round trip", () => {
  for (const s of [
    "hello  world",
    "😀😀🎉🎉🎉a",
    "zzzzzzzzzzzzzzzzzzzzzz",
    "x",
  ]) {
    assert.equal(decode(encode(s)), s);
  }
});

test("decode rejects invalid input", () => {
  for (const bad of ["a", "3", "0a", "2a3", "05a", "1a b"]) {
    assert.throws(() => decode(bad), SyntaxError, bad);
  }
});
