// How adapters start an agent CLI. Agents run through the SessionTap wrapper
// (`sessiontap <provider> ...`) so pipeline sessions are tracked like any
// other; the wrapper forwards argv, stdio, signals and exit code unchanged.
// Falls back to the bare CLI when sessiontap is not on PATH.
//
// Env override per provider, e.g. CLAUDE_CMD="claude" to skip the wrapper.

export function launcher(provider: string): string[] {
  const override = process.env[`${provider.toUpperCase()}_CMD`];
  if (override) return override.split(/\s+/).filter(Boolean);
  return Bun.which("sessiontap") ? ["sessiontap", provider] : [provider];
}
