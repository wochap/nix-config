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

const args = process.argv.slice(2);
let requestedMode: string | undefined;
let cwd = process.cwd();
let scratchDir: string | undefined;
let systemFile: string | undefined;
const images: string[] = [];
const command: string[] = [];

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
  command.push(process.env.SHELL || "/bin/bash");
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
