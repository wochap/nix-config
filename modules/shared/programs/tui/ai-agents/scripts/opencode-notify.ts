// opencode-notify.ts — opencode desktop notification plugin
//
// opencode has no shell hooks; plugins subscribe to bus events instead.
// Install (handled by home-manager):
//   ~/.config/opencode/plugins/opencode-notify.ts
//
// Fires only for events that need your attention:
//   - permission.asked — opencode blocked on tool approval
//   - question.asked   — opencode waiting for your input (question tool)
//   - session.status   — busy → idle transition, i.e. the turn finished
//   - session.error    — turn ended due to an error (aborts are skipped,
//                        you already know you pressed escape)
//
// Title carries the session title, falling back to "opencode". Body carries
// the reason, <br>, the session cwd, and — depending on event — the pending
// tool, the question, cost/tokens, or the error name.
//
// Every notification also rings the terminal bell (BEL, \x07) — the one
// attention signal every terminal understands. Inside tmux it lights the
// window bell flag; terminals like foot can escalate it to urgency or their
// own desktop notification when unfocused. The bell is written to /dev/tty
// directly (override with OPENCODE_BELL_TTY; set to "none" to disable),
// which is skipped silently when there is no controlling terminal, e.g.
// under `opencode serve`.
//
// Disable per machine with OPENCODE_NOTIFY=0.

import type { Plugin } from "@opencode-ai/plugin";
import { spawn } from "node:child_process";
import { closeSync, openSync, writeSync } from "node:fs";
import os from "node:os";
import path from "node:path";

type SessionInfo = {
  title?: string;
  directory?: string;
  parentID?: string;
  cost?: number;
  tokens?: {
    input?: number;
    output?: number;
    reasoning?: number;
    cache?: { read?: number; write?: number };
  };
};

type PermissionProps = {
  id: string;
  sessionID: string;
  permission: string;
  patterns?: string[];
  metadata?: Record<string, unknown>;
};

const HOME = os.homedir();

const pretty = (cwd?: string) => {
  const dir = cwd || process.cwd();
  return dir.startsWith(HOME) ? "~" + dir.slice(HOME.length) : dir;
};

const clip = (text: string, max: number) => {
  const flat = text.replace(/\s+/g, " ").trim();
  return flat.length > max ? flat.slice(0, max) + "…" : flat;
};

const str = (value: unknown) => (typeof value === "string" ? value : "");

// --- Describe what the pending tool is about to do ---
// opencode has no native tool description, but permission metadata carries
// the command/file/url; fall back to the first 50 chars of anything.
function describePermission(props: PermissionProps): string {
  const metadata = props.metadata ?? {};
  const pattern = props.patterns?.[0] ?? "";
  switch (props.permission) {
    case "bash":
      return "shell: " + clip(str(metadata.command) || pattern, 50);
    case "edit": {
      const filepath = str(metadata.filepath) || pattern;
      const label =
        filepath.includes(", ") || !filepath.includes("/")
          ? filepath
          : path.basename(filepath);
      return "edit: " + clip(label, 50);
    }
    case "external_directory": {
      const target =
        str(metadata.filepath) ||
        (metadata.directories as string[] | undefined)?.join(", ") ||
        pattern;
      return "outside workspace: " + clip(target, 50);
    }
    case "task":
      return (
        "task: " +
        clip(
          str(metadata.description) || str(metadata.subagent_type) || pattern,
          80,
        )
      );
    case "webfetch":
      return "webfetch: " + clip(str(metadata.url) || pattern, 80);
    case "websearch":
      return "websearch: " + clip(str(metadata.query) || pattern, 80);
    case "doom_loop":
      return "stuck repeating " + clip(str(metadata.tool) || pattern, 50);
    default: {
      const detail = Object.keys(metadata).length
        ? JSON.stringify(metadata)
        : pattern;
      return props.permission + ": " + clip(detail, 50);
    }
  }
}

// Ring the terminal bell by writing BEL straight to the controlling tty.
// Bypasses the TUI render stream safely — BEL carries no display content.
function ring() {
  const target = process.env["OPENCODE_BELL_TTY"] ?? "/dev/tty";
  if (target === "none") return;
  try {
    const fd = openSync(target, "w");
    try {
      writeSync(fd, "\x07");
    } finally {
      closeSync(fd);
    }
  } catch {
    // no controlling terminal (e.g. `opencode serve`) — skip
  }
}

function send(title: string, body: string) {
  ring();
  try {
    if (process.platform === "darwin") {
      const escape = (value: string) => value.replace(/["\\]/g, "\\$&");
      spawn(
        "osascript",
        [
          "-e",
          `display notification "${escape(body)}" with title "${escape(title)}"`,
        ],
        {
          detached: true,
          stdio: "ignore",
        },
      ).unref();
    } else if (process.platform === "win32") {
      spawn(
        "powershell.exe",
        [
          "-Command",
          `[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('${body.replace(/'/g, "''")}', '${title.replace(/'/g, "''")}')`,
        ],
        { detached: true, stdio: "ignore" },
      ).unref();
    } else {
      spawn(
        "notify-send",
        [
          "--app-name=opencode",
          "--app-icon=opencode",
          "--icon=opencode",
          "--hint=string:custom-sound:message",
          title,
          body,
        ],
        { detached: true, stdio: "ignore" },
      ).unref();
    }
  } catch {
    // never take the agent down over a notification
  }
}

export default (async ({ client, directory }) => {
  if (process.env["OPENCODE_NOTIFY"] === "0") return {};

  const busy = new Set<string>();
  const errored = new Set<string>();
  const permissions = new Set<string>();
  const questions = new Set<string>();

  async function sessionInfo(
    sessionID?: string,
  ): Promise<SessionInfo | undefined> {
    if (!sessionID) return;
    try {
      const res = await client.session.get({ path: { id: sessionID } });
      if (res.error) return;
      return res.data as SessionInfo;
    } catch {
      return;
    }
  }

  async function notify(
    sessionID: string | undefined,
    reason: string,
    extra?: string,
  ) {
    const info = await sessionInfo(sessionID);
    const title = info?.title || "opencode";
    const body = [reason, pretty(info?.directory ?? directory), extra]
      .filter(Boolean)
      .join("<br>");
    send(title, body);
    return info;
  }

  return {
    event: async ({ event }) => {
      const type = (event as { type: string }).type;
      const properties =
        (event as { properties?: Record<string, any> }).properties ?? {};

      switch (type) {
        // track busy sessions so "idle" only pings when a turn actually finished
        case "session.status": {
          const sessionID = properties.sessionID as string;
          const status = properties.status as { type: string };
          if (!sessionID || !status) return;
          if (status.type === "busy" || status.type === "retry") {
            busy.add(sessionID);
            errored.delete(sessionID);
            return;
          }
          if (status.type !== "idle" || !busy.has(sessionID)) return;
          busy.delete(sessionID);
          if (errored.has(sessionID)) {
            errored.delete(sessionID);
            return;
          }
          const info = await sessionInfo(sessionID);
          if (info?.parentID) return; // subagents finishing is not your cue
          const extras: string[] = [];
          if (typeof info?.cost === "number" && info.cost > 0)
            extras.push(`Cost: $${info.cost.toFixed(4)}`);
          const total =
            (info?.tokens?.input ?? 0) +
            (info?.tokens?.output ?? 0) +
            (info?.tokens?.reasoning ?? 0);
          if (total > 0) extras.push(`Tokens: ${(total / 1000).toFixed(1)}k`);
          send(
            info?.title || "opencode",
            [
              "Finished",
              pretty(info?.directory ?? directory),
              extras.join(" · "),
            ]
              .filter(Boolean)
              .join("<br>"),
          );
          return;
        }

        case "session.error": {
          const sessionID = properties.sessionID as string | undefined;
          if (sessionID) {
            if (!busy.has(sessionID)) return;
            busy.delete(sessionID);
            errored.add(sessionID);
          }
          const error = properties.error as
            { name?: string; data?: { message?: string } } | undefined;
          if (error?.name === "MessageAbortedError") return;
          const detail =
            error?.name === "APIError"
              ? clip(str(error.data?.message), 80)
              : undefined;
          await notify(
            sessionID,
            `Stopped due to an error (${error?.name ?? "unknown"})`,
            detail,
          );
          return;
        }

        case "permission.asked": {
          const props = properties as unknown as PermissionProps;
          if (permissions.has(props.id)) return;
          permissions.add(props.id);
          await notify(
            props.sessionID,
            "opencode needs your permission",
            describePermission(props),
          );
          return;
        }
        case "permission.replied":
          permissions.delete(properties.requestID as string);
          return;

        case "question.asked": {
          const id = properties.id as string;
          if (questions.has(id)) return;
          questions.add(id);
          const question = (
            properties.questions as Array<{ question?: string }> | undefined
          )?.[0];
          await notify(
            properties.sessionID as string,
            "opencode is waiting for your input",
            clip(str(question?.question), 100),
          );
          return;
        }
        case "question.replied":
        case "question.rejected":
          questions.delete(properties.requestID as string);
          return;
      }
    },
  };
}) satisfies Plugin;
