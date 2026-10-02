import assert from "node:assert/strict";
import { test } from "node:test";
import {
  formatCents,
  runLimited,
  sortOrders,
  summarize,
  toCents,
} from "../src/orders.js";

const deepFreeze = (value) => {
  if (value && typeof value === "object") {
    for (const v of Object.values(value)) deepFreeze(v);
    Object.freeze(value);
  }
  return value;
};

const delay = (ms, value) =>
  new Promise((resolve) => setTimeout(() => resolve(value), ms));

test("toCents parses valid amounts exactly", () => {
  assert.equal(toCents("12.34"), 1234n);
  assert.equal(toCents("7"), 700n);
  assert.equal(toCents("0.5"), 50n);
  assert.equal(toCents("0.05"), 5n);
  assert.equal(toCents("90071992547409.93"), 9007199254740993n);
});

test("toCents rejects invalid amounts", () => {
  for (const bad of [
    "",
    "1.",
    ".5",
    "-1",
    " 1",
    "1e3",
    "1.234",
    "abc",
    12,
    null,
  ]) {
    assert.throws(() => toCents(bad), TypeError, String(bad));
  }
});

test("formatCents", () => {
  assert.equal(formatCents(1234n), "12.34");
  assert.equal(formatCents(5n), "0.05");
  assert.equal(formatCents(-250n), "-2.50");
  assert.equal(formatCents(0n), "0.00");
  assert.equal(formatCents(9007199254740993n), "90071992547409.93");
});

const ORDERS = deepFreeze([
  { id: "o1", customer: "bob", amount: "10.00", status: "paid" },
  { id: "o2", customer: "amy", amount: "5.5", status: "paid" },
  { id: "o3", customer: "bob", amount: "2.25", status: "refunded" },
  { id: "o4", customer: "cid", amount: "99", status: "pending" },
  { id: "o5", customer: "amy", amount: "2.25", status: "paid" },
  { id: "o6", customer: "dan", amount: "7.75", status: "paid" },
]);

test("summarize", () => {
  const s = summarize(ORDERS);
  assert.equal(s.count, 6);
  assert.equal(s.net, "23.25");
  assert.deepEqual({ ...s.byStatus }, { paid: 4, refunded: 1, pending: 1 });
  assert.deepEqual(s.topCustomers, [
    { customer: "amy", total: "7.75" },
    { customer: "bob", total: "7.75" },
    { customer: "dan", total: "7.75" },
    { customer: "cid", total: "0.00" },
  ]);
});

test("summarize empty and negative net", () => {
  const empty = summarize([]);
  assert.equal(empty.count, 0);
  assert.equal(empty.net, "0.00");
  assert.deepEqual({ ...empty.byStatus }, {});
  assert.deepEqual(empty.topCustomers, []);
  const s = summarize([
    { id: "r", customer: "zed", amount: "1.01", status: "refunded" },
  ]);
  assert.equal(s.net, "-1.01");
  assert.deepEqual(s.topCustomers, [{ customer: "zed", total: "-1.01" }]);
  assert.deepEqual({ ...s.byStatus }, { refunded: 1 });
});

test("summarize is exact beyond 2^53 cents", () => {
  const s = summarize([
    { id: "a", customer: "x", amount: "90071992547409.93", status: "paid" },
    { id: "b", customer: "y", amount: "0.01", status: "paid" },
    { id: "c", customer: "y", amount: "90071992547409.92", status: "paid" },
  ]);
  assert.equal(s.net, "180143985094819.86");
  assert.deepEqual(s.topCustomers, [
    { customer: "x", total: "90071992547409.93" },
    { customer: "y", total: "90071992547409.93" },
  ]);
});

test("summarize errors mention the order id", () => {
  assert.throws(
    () =>
      summarize([
        { id: "bad-7", customer: "x", amount: "1.2.3", status: "paid" },
      ]),
    (err) => err instanceof TypeError && err.message.includes("bad-7"),
  );
  assert.throws(
    () =>
      summarize([{ id: "bad-8", customer: "x", amount: "1", status: "lost" }]),
    (err) => err instanceof TypeError && err.message.includes("bad-8"),
  );
});

test("sortOrders returns a sorted copy", () => {
  const sorted = sortOrders(ORDERS);
  assert.deepEqual(
    sorted.map((o) => o.id),
    ["o4", "o1", "o6", "o2", "o3", "o5"],
  );
  assert.equal(sorted[0], ORDERS[3]);
  assert.notEqual(sorted, ORDERS);
  assert.deepEqual(
    ORDERS.map((o) => o.id),
    ["o1", "o2", "o3", "o4", "o5", "o6"],
  );
});

test("sortOrders compares exactly", () => {
  const big = [
    { id: "a", amount: "90071992547409.92" },
    { id: "b", amount: "90071992547409.93" },
    { id: "c", amount: "100" },
  ];
  assert.deepEqual(
    sortOrders(big).map((o) => o.id),
    ["b", "a", "c"],
  );
});

test("runLimited keeps order and settles every task", async () => {
  const boom = new Error("boom");
  const results = await runLimited(
    [
      () => delay(20, "a"),
      () => Promise.reject(boom),
      () => "plain",
      () => {
        throw boom;
      },
      () => delay(1, "e"),
    ],
    2,
  );
  assert.deepEqual(results, [
    { status: "fulfilled", value: "a" },
    { status: "rejected", reason: boom },
    { status: "fulfilled", value: "plain" },
    { status: "rejected", reason: boom },
    { status: "fulfilled", value: "e" },
  ]);
});

test("runLimited respects the limit and refills slots", async () => {
  let running = 0;
  let peak = 0;
  const log = [];
  const task = (name, ms) => async () => {
    running++;
    peak = Math.max(peak, running);
    log.push(`start ${name}`);
    await delay(ms);
    log.push(`end ${name}`);
    running--;
    return name;
  };
  const results = await runLimited(
    [task("a", 80), task("b", 5), task("c", 5), task("d", 5), task("e", 5)],
    2,
  );
  assert.equal(peak, 2);
  assert.deepEqual(log.slice(0, 2), ["start a", "start b"]);
  assert.equal(log.at(-1), "end a");
  assert.deepEqual(
    results.map((r) => r.value),
    ["a", "b", "c", "d", "e"],
  );
});

test("runLimited edge cases", async () => {
  assert.deepEqual(await runLimited([], 3), []);
  assert.deepEqual(await runLimited([() => 1], 10), [
    { status: "fulfilled", value: 1 },
  ]);
  for (const bad of [0, -1, 1.5, Number.NaN, "2"]) {
    await assert.rejects(runLimited([() => 1], bad), RangeError);
  }
});
