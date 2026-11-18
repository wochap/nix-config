#!/usr/bin/env bun
// Standalone bubblewrap sandbox runner for AI agents and developer commands.
// Reuses the exact Bubblewrap sandbox configuration from ./sandbox.ts.

import { resolveSandboxMode, wrapCommand } from "./sandbox";

function printUsage(): void {
  console.log(`Usage: agents-sandbox [options] [--] [command [args...]]

Bubblewrap sandbox wrapper for AI agents and commands.
Reuses the exact sandbox configuration from packages/agents.

Modes:
  permissive (default)  Read/write across filesystem, but shields sensitive
                        credentials (~/.ssh, ~/.gnupg, cloud tokens, browser cookies)
  strict                Root filesystem is read-only; clean /tmp;
                        cwd is an isolated ephemeral scratch folder
  off                   Run command directly without bubblewrap

Options:
  -s, --sandbox <mode>    Sandbox mode: permissive, strict, off (default: permissive)
                          Can also be set via AGENTS_SANDBOX or AI_SANDBOX env var.
  -C, --cwd <dir>         Working directory to isolate/chdir into (default: current directory)
      --scratch-dir <dir> Scratch directory to bind into cwd in strict mode
      --system-file <f>   Extra system file to ro-bind
      --image <f>         Extra image file to ro-bind (repeatable)
  -h, --help              Show this help message

If no command is specified, defaults to $SHELL (or /bin/bash).`);
}

function resolveShellAlias(name: string, maxDepth = 5): string[] | null {
  if (!name || name.includes("/") || maxDepth <= 0) return null;
  const shell = process.env.SHELL || "zsh";
  try {
    const isZsh = shell.endsWith("zsh");
    const script = isZsh
      ? `local a=\${aliases[$1]}; if [[ -n \$a ]]; then eval "local -a parts=( \${(z)a} )"; print -r -N -- "\${(Q@)parts}"; fi`
      : `shopt -s expand_aliases; [[ -f ~/.bashrc ]] && source ~/.bashrc; a=$(alias "$1" 2>/dev/null); if [[ -n \$a ]]; then a="\${a#*=}"; a="\${a#\\'}"; a="\${a%\\'}"; eval "arr=( \$a )"; printf "%s\\0" "\${arr[@]}"; fi`;

    const proc = Bun.spawnSync([shell, "-i", "-c", script, "_", name], {
      stderr: "ignore",
    });
    if (proc.exitCode !== 0) return null;
    const out = proc.stdout.toString();
    if (!out) return null;
    const parts = out.split("\0").filter((s) => s.length > 0);
    if (parts.length === 0) return null;

    if (parts[0] !== name) {
      const nested = resolveShellAlias(parts[0], maxDepth - 1);
      if (nested) {
        return [...nested, ...parts.slice(1)];
      }
    }
    return parts;
  } catch {
    return null;
  }
}

function expandCommand(cmd: string[]): string[] {
  if (cmd.length === 0) return cmd;
  const expanded = resolveShellAlias(cmd[0]);
  if (expanded && expanded.length > 0) {
    return [...expanded, ...cmd.slice(1)];
  }
  return cmd;
}

const args = process.argv.slice(2);
let requestedMode: string | undefined;
let cwd = process.cwd();
let scratchDir: string | undefined;
let systemFile: string | undefined;
const images: string[] = [];
let command: string[] = [];

for (let i = 0; i < args.length; i++) {
  const arg = args[i];
  if (arg === "--") {
    command.push(...args.slice(i + 1));
    break;
  }
  if (arg === "-h" || arg === "--help") {
    printUsage();
    process.exit(0);
  }
  if (arg === "-s" || arg === "--sandbox") {
    if (i + 1 >= args.length) {
      console.error("agents-sandbox: --sandbox requires an argument");
      process.exit(1);
    }
    requestedMode = args[++i];
    continue;
  }
  if (arg.startsWith("--sandbox=")) {
    requestedMode = arg.slice("--sandbox=".length);
    continue;
  }
  if (arg === "-C" || arg === "--cwd") {
    if (i + 1 >= args.length) {
      console.error("agents-sandbox: --cwd requires an argument");
      process.exit(1);
    }
    cwd = args[++i];
    continue;
  }
  if (arg.startsWith("--cwd=")) {
    cwd = arg.slice("--cwd=".length);
    continue;
  }
  if (arg === "--scratch-dir" || arg === "--scratch") {
    if (i + 1 >= args.length) {
      console.error(`agents-sandbox: ${arg} requires an argument`);
      process.exit(1);
    }
    scratchDir = args[++i];
    continue;
  }
  if (arg.startsWith("--scratch-dir=") || arg.startsWith("--scratch=")) {
    scratchDir = arg.split("=")[1];
    continue;
  }
  if (arg === "--system-file") {
    if (i + 1 >= args.length) {
      console.error("agents-sandbox: --system-file requires an argument");
      process.exit(1);
    }
    systemFile = args[++i];
    continue;
  }
  if (arg.startsWith("--system-file=")) {
    systemFile = arg.slice("--system-file=".length);
    continue;
  }
  if (arg === "--image") {
    if (i + 1 >= args.length) {
      console.error("agents-sandbox: --image requires an argument");
      process.exit(1);
    }
    images.push(args[++i]);
    continue;
  }
  if (arg.startsWith("--image=")) {
    images.push(arg.slice("--image=".length));
    continue;
  }
  if (arg.startsWith("-")) {
    console.error(`agents-sandbox: unknown option: ${arg}`);
    process.exit(1);
  }
  // First non-flag argument starts the command
  command.push(...args.slice(i));
  break;
}

if (command.length === 0) {
  command = [process.env.SHELL || "/bin/bash"];
} else {
  command = expandCommand(command);
}

let mode;
try {
  mode = resolveSandboxMode(requestedMode, "permissive");
} catch (err: any) {
  console.error(`agents-sandbox: ${err?.message ?? err}`);
  process.exit(1);
}

const wrappedCmd = wrapCommand(command, {
  mode,
  cwd,
  scratchDir,
  systemFile,
  images,
});

const proc = Bun.spawn(wrappedCmd, {
  cwd,
  stdio: ["inherit", "inherit", "inherit"],
  env: process.env,
});

for (const sig of ["SIGINT", "SIGTERM", "SIGHUP"] as const) {
  process.on(sig, () => {
    try {
      proc.kill(sig);
    } catch {}
  });
}

const exitCode = await proc.exited;
process.exit(exitCode);
