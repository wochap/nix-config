// Taking over a running session, and detaching from it again.
//
// One agent process per session: the headless run is stopped (SIGINT) and
// the same session resumes in the agent's TUI. The TUI runs on its own pty
// under `dtach -N <sock>`, which exits when the TUI does, so detaching does
// not stop it. attach() below is the dtach client: `dtach -a` only sees
// Ctrl-Z as the raw 0x1a byte, but TUIs like claude turn on the kitty
// keyboard protocol, which sends it as an escape sequence; dtach -a would
// pass that to the TUI, which suspends itself.
//
// While detached, the agent's native transcript is tailed and rendered like a
// headless run, and appended to events.jsonl so `agents watch` follows it.

import { existsSync, rmSync } from "node:fs";
import { connect } from "node:net";
import { join } from "node:path";
import type { Adapter, Effort, Event } from "./adapters/types";
import { hint, render } from "./render";
import * as store from "./store";
import { tail } from "./tail";
import { bell, interrupt, out, println, track } from "./term";

const dtach = process.env.AGENTS_DTACH ?? Bun.which("dtach");

const CTRL_C = "\x03";
export const CTRL_T = "\x14";
const CTRL_Z = "\x1a";

// Ctrl+letter with the kitty keyboard protocol (CSI code;5u, optionally
// with :event-type) or xterm modifyOtherKeys (CSI 27;5;code~), as the plain
// control byte. Repeat and release events are dropped.
const CSI_CTRL = /\x1b\[(\d+)(?::\d+)*;5(?::(\d+))?u|\x1b\[27;5;(\d+)~/g;
const normalize = (s: string) =>
  s.replace(CSI_CTRL, (seq, kitty: string | undefined, event: string | undefined, other: string | undefined) => {
    const code = Number(kitty ?? other);
    if (code < 97 || code > 122) return seq;
    return event && event !== "1" ? "" : String.fromCharCode(code & 0x1f);
  });

// Raw key reader. In raw mode the terminal sends Ctrl-C as a byte instead of
// SIGINT, so it is handled here. A passthrough gets the raw input instead.
let onKey: ((key: string) => void) | null = null;
let passthrough: ((data: Buffer) => void) | null = null;
let reading = false;

export const keys = {
  /** Keys work only when a person is at a terminal. */
  available: () => Boolean(process.stdin.isTTY),
  start() {
    if (!reading) {
      reading = true;
      process.stdin.on("data", (data: Buffer) => {
        if (passthrough) return passthrough(data);
        for (const key of normalize(data.toString("utf8"))) {
          if (key === CTRL_C) interrupt();
          else onKey?.(key);
        }
      });
      process.on("exit", () => keys.stop());
    }
    process.stdin.setRawMode(true);
    process.stdin.resume();
  },
  /** Releases the terminal, e.g. for a child that reads it. */
  stop() {
    if (!reading) return;
    process.stdin.setRawMode(false);
    process.stdin.pause();
  },
  on(fn: ((key: string) => void) | null) {
    onKey = fn;
  },
  /** Resolves with the first pressed key out of `choices`. */
  wait<T extends string>(choices: readonly T[]): Promise<T> {
    return new Promise((resolve) =>
      keys.on((key) => {
        if (!choices.includes(key as T)) return;
        keys.on(null);
        resolve(key as T);
      }),
    );
  },
};

// dtach socket protocol (dtach.h): the client sends fixed 10-byte packets
// {type, len, 8-byte union of key bytes or struct winsize}; the master sends
// the pty's raw output.
const MSG_PUSH = 0;
const MSG_ATTACH = 1;
const MSG_WINCH = 3;
const MSG_REDRAW = 4;
const REDRAW_WINCH = 3;

function packet(type: number, len = 0, body?: Buffer): Buffer {
  const p = Buffer.alloc(10);
  p[0] = type;
  p[1] = len;
  body?.copy(p, 2);
  return p;
}

function winsize(narrower = 0): Buffer {
  const ws = Buffer.alloc(8);
  ws.writeUInt16LE(out.rows ?? 24, 0);
  ws.writeUInt16LE((out.columns ?? 80) - narrower, 2);
  return ws;
}

// Modes a TUI may have turned on, reset on detach so this view (and the
// shell afterwards) gets plain keys: kitty keyboard flags, modifyOtherKeys,
// bracketed paste, focus events, mouse, hidden cursor.
const RESET_MODES = "\x1b[=0;1u\x1b[>4m\x1b[?2004l\x1b[?1004l\x1b[?1000l\x1b[?1002l\x1b[?1003l\x1b[?1006l\x1b[?25h";

// The terminal must pass the TUI's output unchanged (no \n -> \r\n); raw
// mode keeps output processing on.
const stty = (arg: string) => Bun.spawnSync(["stty", arg], { stdio: ["inherit", "ignore", "ignore"] });

/** Shows the TUI on this terminal until Ctrl-Z ("detached") or the TUI exits ("exited"). */
function attach(sock: string): Promise<"detached" | "exited"> {
  return new Promise((resolve) => {
    const conn = connect(sock);
    let done = false;
    const onResize = () => conn.write(packet(MSG_WINCH, 0, winsize()));
    const finish = (how: "detached" | "exited") => {
      if (done) return;
      done = true;
      passthrough = null;
      out.off("resize", onResize);
      stty("opost");
      resolve(how);
    };
    keys.start();
    stty("-opost");
    passthrough = (data) => {
      if (normalize(data.toString("utf8")).includes(CTRL_Z)) {
        conn.end();
        out.write(`${RESET_MODES}\x1b[999H\r\n[detached]\r\n`);
        return finish("detached");
      }
      for (let i = 0; i < data.length; i += 8) {
        const chunk = data.subarray(i, i + 8);
        conn.write(packet(MSG_PUSH, chunk.length, chunk));
      }
    };
    conn.on("connect", () => {
      out.write("\x1b[H\x1b[J");
      conn.write(packet(MSG_ATTACH));
      // TUIs like claude only draw everything again when the size really
      // changes: one column narrower, then the real size.
      conn.write(packet(MSG_WINCH, 0, winsize(1)));
      setTimeout(() => conn.write(packet(MSG_REDRAW, REDRAW_WINCH, winsize())), 100);
      out.on("resize", onResize);
    });
    conn.on("data", (data) => out.write(data));
    conn.on("close", () => finish("exited"));
    conn.on("error", () => finish("exited"));
  });
}

// Taking over interrupts the agent mid-task; the TUI starts by resuming it.
// Esc in the TUI stops it again to steer it instead.
const CONTINUE = "The user took over this session, which interrupted you. Continue the task where you left off.";

const FINISH_AFTER_MS = 3000;

interface Options {
  agent: Adapter;
  id: string;
  model: string;
  effort?: Effort;
  cwd: string;
  onEvent(e: Event): Promise<void>;
}

/**
 * Runs the session's TUI until the user exits it ("exited"), or until the
 * agent finishes its turn while the user is detached ("finished"): nobody is
 * there to answer, so the TUI is closed and the run ends like a headless one.
 * The user can detach (Ctrl-Z) and attach again (Ctrl-T) any number of times.
 */
export async function takeOver({ agent, id, model, effort, cwd, onEvent }: Options): Promise<"exited" | "finished"> {
  if (!dtach) throw new Error("dtach not found, cannot take over a running session");
  const sock = join(store.dir, `${id}.sock`);
  rmSync(sock, { force: true });
  // dtach -N copies the terminal's settings to the TUI's pty: cooked, not raw.
  keys.stop();
  const tui = track(Bun.spawn([dtach, "-N", sock, ...agent.takeOverCmd(id, model, effort, CONTINUE)], { cwd, stdio: ["inherit", "inherit", "inherit"] }));
  let exited = false;
  tui.exited.then(() => (exited = true));
  for (let i = 0; i < 50 && !existsSync(sock) && !exited; i++) await Bun.sleep(20);

  // What the TUI writes, from now on.
  let read: (() => string[]) | null = null;
  const path = agent.transcriptPath(id);
  if (path) read = tail(path, true);
  // Agent waits for the user, and when the transcript last grew.
  let idle = false;
  let activeAt = Date.now();
  const follow = async () => {
    if (!read) {
      const p = agent.transcriptPath(id);
      if (!p) return;
      read = tail(p);
    }
    for (const line of read()) {
      activeAt = Date.now();
      let entry: any;
      try {
        entry = JSON.parse(line);
      } catch {
        continue;
      }
      const r = agent.transcriptEvents(entry, cwd);
      for (const e of r.events) await onEvent(e);
      if (r.events.length) idle = r.idle;
    }
  };

  while (!exited) {
    if ((await attach(sock)) === "exited") {
      await tui.exited;
      break;
    }

    hint("ctrl+t attach · ctrl+c stop");
    let reattach = false;
    keys.on((key) => {
      if (key === CTRL_T) reattach = true;
    });
    while (!reattach && !exited) {
      await follow();
      // Quiet for a while: a Stop hook may still resume the turn.
      if (idle && Date.now() - activeAt > FINISH_AFTER_MS) {
        keys.on(null);
        tui.kill("SIGTERM"); // dtach hangs up the TUI's pty; the TUI exits
        await tui.exited;
        await follow();
        rmSync(sock, { force: true });
        return "finished";
      }
      await Bun.sleep(300);
    }
    keys.on(null);
  }
  await follow();
  rmSync(sock, { force: true });
  return "exited";
}

/** After the TUI exits: hand back to a headless run, or finish. */
export async function askHandBack(): Promise<"continue" | "done"> {
  println();
  hint("[c]ontinue headless · [d]one");
  bell();
  return (await keys.wait(["c", "d"])) === "c" ? "continue" : "done";
}
