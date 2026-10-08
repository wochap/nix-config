# Remote desktop

Control a NixOS host's running Wayland session from another NixOS machine on the LAN, even from a bare TTY with no compositor. Sunshine streams the host's screen. Moonlight shows it fullscreen on the client. For the session, the host's desktop takes the client monitor's resolution and scale, then goes back to its own layout.

Two roles, enabled per machine:
- `host`: the machine you control. Sunshine captures the headless output `HEADLESS-2` (wlr capture, no `CAP_SYS_ADMIN`). Its ports are open only on `host.lanInterface`. The host also gets `remote-display`.
- `client`: the machine you sit at. It gets Moonlight and the `remote-desktop` command for the hosts in `client.hosts`. The command reads this monitor's mode, runs `remote-display apply` on the host over ssh, and streams with Moonlight. On exit it runs `remote-display restore` and retries for about 30 s to cover short network drops.

`remote-display` sizes `HEADLESS-2` to the client (`client.hosts.<name>.scale`, frame rate capped at `client.hosts.<name>.maxFps`). `restore` puts the original layout back. Code that changes the display lives in `scripts/providers/<desktop>.sh`. Only `hyprland.sh` exists. To support another compositor, add a provider that defines `provider_apply`, `provider_restore` and `provider_status`.

Modes:
- `mirror`: physical outputs mirror `HEADLESS-2` and keep their own modes. Local keyboard and mouse on the host keep working. Workspaces move to `HEADLESS-2` for the session, and the local cursor lives in its coordinate space. A different aspect ratio gives black bars on the host screen.
- `headless`: physical outputs stay untouched; the stream is a separate output.

If kanshi runs on the host, it is stopped during a session, because it would treat `HEADLESS-2` as a profile change. `restore` runs `hyprctl reload`, then starts kanshi again. It also moves workspaces back to their monitors and refocuses the workspace that was active before. `restore` can run twice at once (Moonlight `--quit-after` triggers Sunshine's `undo`, and the client's trap also calls it). A lock serializes the two, and the second exits 0.

Manual recovery on the host: `remote-display status`, `remote-display restore`.

## Usage

```
remote-desktop <host> [mirror|headless] [--resolution WxH] [--fps N] [--backend cage|eglfs]
remote-desktop --list
```

`<host>` is a name from `client.hosts`; shell completion knows them. A host with `commandName` also gets a short command, for example `laptop-remote` for `remote-desktop laptop`. Complete the setup below first: ssh access and pairing.

### From a TTY

You need no compositor on the client. A graphical session on another VT can keep running.

```sh
# Ctrl+Alt+F3, log in, then
remote-desktop laptop                  # mirror, the host screen shows the stream
remote-desktop laptop headless         # the host screen stays as it is
remote-desktop laptop --fps 120        # if mode detection fell back to 60 fps
remote-desktop laptop --backend eglfs  # if cage shows no picture
laptop-remote headless                 # same as remote-desktop laptop headless
```

The command starts cage twice. The first run is brief and only reads the monitor mode. The second run holds Moonlight. The screen flickers once between them. You can switch to another VT while the stream keeps running (`cage -s` allows VT switching).

### From a compositor

When `WAYLAND_DISPLAY` is set, the command skips cage. Moonlight opens as a fullscreen window and the mode comes from wlr-randr. Run it from a terminal or bind it to a key:

```sh
# terminal inside Hyprland, Sway, river, ...
remote-desktop laptop headless
```

```lua
-- Hyprland (lua config)
hl.bind(mod .. " + R", hl.dsp.exec_cmd("remote-desktop laptop"), { description = "Remote laptop" })
```

The local compositor still sees every key first, so its own binds act locally. Press Ctrl+Alt+Shift+Z in Moonlight to capture keyboard and mouse, which sends most combos to the host.

With no `WAYLAND_DISPLAY` (an X11 session), cage starts nested as a window. Pass `--backend eglfs` only from a TTY, because eglfs takes over the display.

### During a session

Moonlight shortcuts:
- Ctrl+Alt+Shift+Q: quit. The host goes back to its own layout.
- Ctrl+Alt+Shift+Z: capture or release keyboard and mouse.
- Ctrl+Alt+Shift+X: toggle fullscreen.
- Ctrl+Alt+Shift+S: show stream stats.

Quitting Moonlight, Ctrl+C in the shell, and closing the terminal all run restore. Restore ignores further Ctrl+C until it finishes (at most about 80 s of retries). The command refuses to start when the host is not paired, before it touches the host's display.

## Setup

### Options

```nix
# host
_custom.services.remote-desktop.host = {
  enable = true;
  lanInterface = "wlan0";   # interface the client reaches the host on
};

# client, one entry per host to control
_custom.services.remote-desktop.client = {
  enable = true;
  hosts = {
    laptop = {
      address = "laptop.local";      # ssh destination and Moonlight host
      commandName = "laptop-remote"; # optional short command
      # scale = 1;                   # scale the host uses for the stream, match the client monitor
      # maxFps = 120;
      # app = "Desktop";             # the host's host.app
    };
    desktop2.address = "192.168.0.20";
  };
};
```

### SSH

The command runs `ssh <address> remote-display ...` as the current user. The `.local` names in the examples resolve through avahi; any name or IP works. One ssh connection (`ControlMaster`, kept 10 min) carries both apply and restore. It prompts for a password at most once, on the TTY, before Moonlight starts. Key login is better, because restore after a network drop then works without a prompt:

```sh
# client
ssh-copy-id laptop.local
ssh laptop.local true   # accept the host key once
```

Repeat for each host.

The host user must be the one logged in to the graphical session. `remote-display` finds that session through `systemctl --user show-environment`.

### Sunshine web UI login (optional)

You need the web UI only to pair. Without secrets, Sunshine asks you to create a login on the first visit to `https://<host>:47990`. To manage the login with sops instead, add both keys to a SOPS file:

```sh
sops secrets.yaml
# local-sunshine-user: <user>
# local-sunshine-password: <password>
```

Then point the host at it:

```nix
_custom.services.remote-desktop.host.credentials.sopsFile = ./secrets.yaml;
```

The secrets belong to the desktop user. `ExecStartPre` writes them with `sunshine --creds` every time Sunshine starts. Change the key names with `credentials.userKey` and `credentials.passwordKey`.

### Pairing (once)

On the client, from a graphical session:

```sh
moonlight pair laptop.local          # prints a PIN
# open https://sunshine-laptop.wochap.local/pin, enter it
moonlight list laptop.local          # shows "Desktop" when paired
```

Repeat for each host.

The web UI is also at `https://sunshine.wochap.local` on the host itself, and at `https://<address>:47990` with Sunshine's own certificate. Sunshine's CSRF check rejects proxied origins it does not know ("CSRF Protection Error"). `host.webUi.allowedOrigins` defaults to the host's own proxy and `https://sunshine-<hostName>.<certificate domain>`, which matches a client entry named after the host's `networking.hostName`. Add the origin there when the client uses another name. Moonlight stores the pairing in your user config, so the TTY session uses it too.

## Troubleshooting

- No picture from the TTY: try `--backend eglfs`, or run the command inside a compositor to rule out cage.
- Wrong mode detected (falls back to 60 fps when cage cannot report it): pass `--resolution` and `--fps`.
- Sunshine logs: `journalctl --user -u sunshine` on the host. The log lists the outputs it sees, and `HEADLESS-2` must be among them during a session.
