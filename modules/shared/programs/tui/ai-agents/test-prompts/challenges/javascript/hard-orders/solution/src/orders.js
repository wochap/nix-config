const AMOUNT = /^(\d+)(?:\.(\d{1,2}))?$/;
const SIGN = { paid: 1n, refunded: -1n, pending: 0n };

export function toCents(amount) {
  const m = typeof amount === "string" ? AMOUNT.exec(amount) : null;
  if (!m) throw new TypeError(`invalid amount: ${String(amount)}`);
  const [, whole, frac = ""] = m;
  return BigInt(whole) * 100n + BigInt(frac.padEnd(2, "0"));
}

export function formatCents(cents) {
  const abs = cents < 0n ? -cents : cents;
  const text = `${abs / 100n}.${String(abs % 100n).padStart(2, "0")}`;
  return cents < 0n ? `-${text}` : text;
}

function compareBig(a, b) {
  if (a === b) return 0;
  return a < b ? -1 : 1;
}

function compareText(a, b) {
  if (a === b) return 0;
  return a < b ? -1 : 1;
}

function centsOf(order) {
  try {
    return toCents(order.amount);
  } catch (err) {
    throw new TypeError(`order ${order.id}: ${err.message}`, { cause: err });
  }
}

export function summarize(orders) {
  const byStatus = {};
  const perCustomer = new Map();
  let net = 0n;
  for (const order of orders) {
    if (!Object.hasOwn(SIGN, order.status)) {
      throw new TypeError(`order ${order.id}: unknown status ${order.status}`);
    }
    const delta = centsOf(order) * SIGN[order.status];
    byStatus[order.status] = (byStatus[order.status] ?? 0) + 1;
    perCustomer.set(
      order.customer,
      (perCustomer.get(order.customer) ?? 0n) + delta,
    );
    net += delta;
  }
  const topCustomers = [...perCustomer]
    .toSorted(([a, x], [b, y]) => compareBig(y, x) || compareText(a, b))
    .map(([customer, cents]) => ({ customer, total: formatCents(cents) }));
  return {
    count: orders.length,
    net: formatCents(net),
    byStatus,
    topCustomers,
  };
}

export function sortOrders(orders) {
  return orders.toSorted(
    (a, b) => compareBig(centsOf(b), centsOf(a)) || compareText(a.id, b.id),
  );
}

export async function runLimited(tasks, limit) {
  if (!Number.isInteger(limit) || limit < 1) {
    throw new RangeError(`limit must be a positive integer: ${limit}`);
  }
  const results = new Array(tasks.length);
  let next = 0;
  async function worker() {
    while (next < tasks.length) {
      const i = next++;
      try {
        results[i] = { status: "fulfilled", value: await tasks[i]() };
      } catch (reason) {
        results[i] = { status: "rejected", reason };
      }
    }
  }
  const workers = Array.from({ length: Math.min(limit, tasks.length) }, worker);
  await Promise.all(workers);
  return results;
}
