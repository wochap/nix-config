export function pick<T extends object, K extends keyof T>(
  obj: T,
  keys: readonly K[],
): Pick<T, K> {
  const out: Partial<Pick<T, K>> = {};
  for (const key of keys) {
    if (Object.hasOwn(obj, key)) out[key] = obj[key];
  }
  return out as Pick<T, K>;
}

export function omit<T extends object, K extends keyof T>(
  obj: T,
  keys: readonly K[],
): Omit<T, K> {
  const drop = new Set<PropertyKey>(keys);
  const out: Record<PropertyKey, unknown> = {};
  for (const [key, value] of Object.entries(obj)) {
    if (!drop.has(key)) out[key] = value;
  }
  return out as Omit<T, K>;
}
