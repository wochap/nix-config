# Order report

Implement `src/orders.js` (an ES module) with these named exports.
Money amounts are strings with up to two decimals. They can be larger than
2^53 cents, so all money math must be exact.

## `toCents(amount)`
Parses an amount string to a `bigint` number of cents.
Valid input matches: one or more digits, optionally followed by `.` and one or
two digits. Anything else (including non-strings, `""`, `"1."`, `".5"`,
`"-1"`, `" 1"`, `"1e3"`) throws a `TypeError`.
```
toCents("12.34") -> 1234n
toCents("7")     -> 700n
toCents("0.5")   -> 50n
toCents("90071992547409.93") -> 9007199254740993n
```

## `formatCents(cents)`
Formats a `bigint` number of cents as a string with exactly two decimals,
with a leading `-` for negative values.
```
formatCents(1234n) -> "12.34"
formatCents(5n)    -> "0.05"
formatCents(-250n) -> "-2.50"
formatCents(0n)    -> "0.00"
```

## `summarize(orders)`
`orders` is an array of `{ id, customer, amount, status }` where `id` and
`customer` are strings, `amount` is an amount string, and `status` is
`"paid"`, `"refunded"` or `"pending"`. Paid orders add to the net, refunded
orders subtract, pending orders count as zero. Returns:
```js
{
  count,         // number of orders
  net,           // formatCents(sum over all orders)
  byStatus,      // { paid: n, ... } only statuses that occur
  topCustomers,  // [{ customer, total }] one entry per customer that occurs,
                 // total = formatCents(that customer's net),
                 // sorted by net descending, ties by customer name ascending
}
```
An invalid amount or an unknown status throws a `TypeError` whose message
contains the order `id`.

## `sortOrders(orders)`
Returns a new array of the same order objects sorted by amount descending
(exact), ties by `id` ascending. The input array must not be modified
(it may be frozen).

## `runLimited(tasks, limit)` (async)
`tasks` is an array of functions; each returns a value or a promise.
Run them with at most `limit` running at the same time, starting them in
array order and starting the next one as soon as any running task finishes.
Resolve to an array, in the same order as `tasks`, of
`{ status: "fulfilled", value }` or `{ status: "rejected", reason }`.
A task that throws synchronously counts as rejected. `runLimited` never
rejects because of a task. If `limit` is not a positive integer, the returned
promise rejects with a `RangeError`.

Files: `src/orders.js`. Tests live in `tests/` and run with `node --test`.
