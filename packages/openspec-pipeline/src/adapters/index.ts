// Adapter registry. Add new agents here.

import { claude } from "./claude";
import type { Adapter } from "./types";

export const adapters: Record<string, Adapter> = {
  claude,
};

export function getAdapter(name: string): Adapter {
  const adapter = adapters[name];
  if (!adapter) throw new Error(`unknown agent "${name}", available: ${Object.keys(adapters).join(", ")}`);
  return adapter;
}
