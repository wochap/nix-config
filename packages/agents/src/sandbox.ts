// Bubblewrap sandboxing for agents.
//
// Two modes:
//   - "permissive" (default for `agents run` & interactive sessions):
//       Read/write across filesystem, but shields common sensitive folders
//       (~/.ssh, ~/.gnupg, cloud credentials, browser data, auth files)
//       using tmpfs / dev/null so credentials cannot be read or stolen.
//   - "strict" (default for `agents serve`):
//       Root filesystem is strictly read-only. Working directory (cwd) is
//       an isolated ephemeral scratch folder (tmpfs) that can be read/written
//       without touching the host. /tmp is a clean tmpfs.
//   - "off":
//       No bubblewrap wrapper. Runs command directly.
//
// Gracefully falls back to "off" if `bwrap` is not installed on the system.

import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { dir as storeDir } from "./store";

export type SandboxMode = "permissive" | "strict" | "off";

export interface SandboxOptions {
  mode?: SandboxMode;
  cwd: string;
  agent?: string;
  systemFile?: string;
  images?: string[];
  scratchDir?: string;
  noToolsHook?: string;
}

export function resolveSandboxMode(requested?: string, defaultMode: SandboxMode = "permissive"): SandboxMode {
  const envVal = process.env.AGENTS_SANDBOX;
  const raw = (requested ?? envVal)?.toLowerCase();
  if (!raw) return defaultMode;
  if (raw === "strict" || raw === "permissive" || raw === "off") return raw;
  if (raw === "true" || raw === "1" || raw === "yes") return defaultMode;
  if (raw === "false" || raw === "0" || raw === "no") return "off";
  throw new Error(`--sandbox: expected permissive, strict, or off (got ${raw})`);
}

function getSensitivePaths(): { dirs: string[]; files: string[] } {
  const home = homedir();
  const dirs = [
    // SSH keys & config
    join(home, ".ssh"),
    join(home, ".config", "ssh"),
    // GnuPG keys & password stores
    join(home, ".gnupg"),
    join(home, ".password-store"),
    join(home, ".local", "share", "keyrings"),
    // Cloud / Infra credentials
    join(home, ".aws"),
    join(home, ".azure"),
    join(home, ".kube"),
    join(home, ".oci"),
    // Browser profiles & session cookies
    join(home, ".mozilla"),
    join(home, ".config", "google-chrome"),
    join(home, ".config", "chromium"),
    join(home, ".config", "BraveSoftware"),
    join(home, ".config", "microsoft-edge"),
    join(home, ".config", "opera"),
    join(home, ".config", "vivaldi"),
    join(home, ".cache", "mozilla"),
    join(home, ".cache", "google-chrome"),
    join(home, ".cache", "chromium"),
  ];

  const files = [
    join(home, ".netrc"),
    join(home, ".git-credentials"),
  ];

  return {
    dirs: dirs.filter((d) => existsSync(d)),
    files: files.filter((f) => existsSync(f)),
  };
}

export function wrapCommand(cmd: string[], opts: SandboxOptions): string[] {
  const mode = opts.mode ?? "permissive";
  if (mode === "off") return cmd;

  const bwrap = Bun.which("bwrap");
  if (!bwrap) {
    if (mode === "strict") {
      throw new Error("sandbox: strict mode requires bubblewrap (bwrap)");
    }
    // Graceful fallback when bwrap is not installed
    return cmd;
  }

  const uid = process.getuid?.() ?? 1000;
  const runtimeDir = process.env.XDG_RUNTIME_DIR || `/run/user/${uid}`;
  const home = homedir();

  if (mode === "permissive") {
    const { dirs, files } = getSensitivePaths();
    const args: string[] = [
      bwrap,
      "--bind", "/", "/",
      "--dev", "/dev",
      "--proc", "/proc",
    ];

    if (existsSync(runtimeDir)) {
      args.push("--bind", runtimeDir, runtimeDir);
    }

    // Mask sensitive directories with empty tmpfs
    for (const d of dirs) {
      args.push("--tmpfs", d);
    }

    // Mask sensitive files with read-only /dev/null
    for (const f of files) {
      args.push("--ro-bind", "/dev/null", f);
    }

    return [...args, "--", ...cmd];
  }

  if (mode === "strict") {
    const { dirs, files } = getSensitivePaths();
    const args: string[] = [
      bwrap,
      "--ro-bind", "/", "/",
      "--dev", "/dev",
      "--proc", "/proc",
      "--tmpfs", "/tmp",
    ];

    // Mask sensitive directories with empty tmpfs
    for (const d of dirs) {
      args.push("--tmpfs", d);
    }

    // Mask sensitive files with read-only /dev/null
    for (const f of files) {
      args.push("--ro-bind", "/dev/null", f);
    }

    // Do not bind runtimeDir read-write in strict mode. If sessiontap dir exists,
    // isolate it with tmpfs so sessiontap can create per-run scratch tracking without host access.
    const sessiontapDir = join(runtimeDir, "sessiontap");
    if (existsSync(sessiontapDir)) {
      args.push("--tmpfs", sessiontapDir);
    }

    // Ensure session tracking directory works so events & logs can be written
    if (existsSync(storeDir)) {
      args.push("--bind", storeDir, storeDir);
    }

    // In strict mode: cwd is an isolated temporary scratch folder read/write
    if (opts.scratchDir && existsSync(opts.scratchDir)) {
      args.push("--bind", opts.scratchDir, opts.cwd);
    } else {
      args.push("--tmpfs", opts.cwd);
    }

    // Per-run deny hook for disabling tools in strict mode
    if (opts.noToolsHook && existsSync(opts.noToolsHook)) {
      args.push("--dir", join(opts.cwd, ".agents"), "--ro-bind", opts.noToolsHook, join(opts.cwd, ".agents", "hooks.json"));
    }

    // Explicit read-only binds for systemFile and images (e.g. if stored under /tmp)
    if (opts.systemFile && existsSync(opts.systemFile)) {
      args.push("--ro-bind", opts.systemFile, opts.systemFile);
    }
    for (const img of opts.images ?? []) {
      if (existsSync(img)) {
        args.push("--ro-bind", img, img);
      }
    }

    // Provide agent scratch subdirectories on tmpfs so they can write temporary runtime caches/logs:
    // 1. agy (Antigravity)
    const agyData = process.env.AGY_DATA_DIR || join(home, ".gemini", "antigravity-cli");
    if (existsSync(agyData)) {
      for (const sub of ["brain", "conversations", "log", "cache", "annotations", "crashes", "bin", "scratch"]) {
        const subPath = join(agyData, sub);
        if (existsSync(subPath)) {
          args.push("--tmpfs", subPath);
        }
      }
    }

    // 2. Claude Code
    const claudeDir = join(home, ".claude");
    if (existsSync(claudeDir)) {
      args.push("--tmpfs", claudeDir);
      for (const f of [".credentials.json", "settings.json"]) {
        const filePath = join(claudeDir, f);
        if (existsSync(filePath)) {
          args.push("--ro-bind", filePath, filePath);
        }
      }
    }

    // 3. Pi
    const piDir = join(home, ".pi");
    if (existsSync(piDir)) {
      const piAgent = join(piDir, "agent");
      if (existsSync(piAgent)) {
        args.push("--tmpfs", piAgent);
        for (const f of ["models.json", "auth.json", "settings.json", "trust.json"]) {
          const filePath = join(piAgent, f);
          if (existsSync(filePath)) {
            args.push("--ro-bind", filePath, filePath);
          }
        }
      } else {
        args.push("--tmpfs", piDir);
      }
    }

    return [...args, "--", ...cmd];
  }

  return cmd;
}
