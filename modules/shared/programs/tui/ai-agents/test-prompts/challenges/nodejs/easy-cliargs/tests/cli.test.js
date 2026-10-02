import assert from "node:assert/strict";
import { test } from "node:test";
import { parseCli } from "../src/cli.js";

const defaults = { name: "world", count: 1, verbose: false, files: [] };

test("defaults", () => {
  assert.deepEqual(parseCli([]), defaults);
});

test("long options", () => {
  assert.deepEqual(parseCli(["--name", "bob", "--count", "4", "--verbose"]), {
    name: "bob",
    count: 4,
    verbose: true,
    files: [],
  });
  assert.deepEqual(parseCli(["--name=a b", "--count=12"]), {
    ...defaults,
    name: "a b",
    count: 12,
  });
});

test("short and grouped options", () => {
  assert.deepEqual(parseCli(["-vn", "bob", "a.txt"]), {
    name: "bob",
    count: 1,
    verbose: true,
    files: ["a.txt"],
  });
  assert.deepEqual(parseCli(["-c3", "-n", "x"]), {
    ...defaults,
    name: "x",
    count: 3,
  });
});

test("negation and repeats", () => {
  assert.equal(parseCli(["-v", "--no-verbose"]).verbose, false);
  assert.equal(parseCli(["--no-verbose", "-v"]).verbose, true);
  assert.equal(parseCli(["-n", "a", "--name", "b"]).name, "b");
});

test("positionals and --", () => {
  assert.deepEqual(parseCli(["a", "-v", "b", "--", "-x", "--name"]), {
    ...defaults,
    verbose: true,
    files: ["a", "b", "-x", "--name"],
  });
});

test("parse errors are TypeErrors", () => {
  for (const argv of [["--bogus"], ["-z"], ["--name"], ["--verbose=yes"]]) {
    assert.throws(() => parseCli(argv), TypeError, argv.join(" "));
  }
});

test("invalid counts are RangeErrors", () => {
  for (const bad of ["0", "-2", "1.5", "abc", "1e3", "", " 3"]) {
    assert.throws(() => parseCli([`--count=${bad}`]), RangeError, bad);
  }
});

test("input is not modified", () => {
  const argv = Object.freeze(["-v", "x"]);
  assert.deepEqual(parseCli(argv).files, ["x"]);
});
