// Adapter registry. Add new agents here.

import { claude } from "./claude";
import { pi } from "./pi";
import type { Adapter } from "./types";

export const adapters: Record<string, Adapter> = {
  claude,
  pi,
};

export function getAdapter(name: string): Adapter {
  const adapter = adapters[name];
  if (!adapter) throw new Error(`unknown agent "${name}", available: ${Object.keys(adapters).join(", ")}`);
  return adapter;
}
