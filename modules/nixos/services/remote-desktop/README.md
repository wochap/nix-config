# Remote desktop

Control a NixOS host's running Wayland session from any Moonlight client: another NixOS machine (even from a bare TTY with no compositor), or Moonlight on Android with a Bluetooth keyboard and mouse. Sunshine streams the host's screen. For the session, the host's desktop takes the resolution and frame rate the client asks for, then goes back to its own layout.

Two roles, enabled per machine:
- `host`: the machine you control. Sunshine captures the headless output `HEADLESS-2` (wlr capture, no `CAP_SYS_ADMIN`). Its ports are open only on `host.interfaces`. The host also gets `remote-display`.
- `client`: a NixOS machine you sit at. It gets Moonlight and the `remote-desktop` command for the hosts in `client.hosts`. The command reads this monitor's mode and streams with Moonlight. On exit it quits the Sunshine app, retrying for about 30 s to cover short network drops.

Sunshine does the display work for every client, through the app's prep commands: launching runs `remote-display apply` with the client's resolution and fps (`SUNSHINE_CLIENT_WIDTH`, `_HEIGHT`, `_FPS`), quitting runs `remote-display restore`. The scale comes from `host.scales`, keyed by client resolution (1 otherwise). Sunshine sends no client name, so two clients with the same resolution share a scale. Code that changes the display lives in `scripts/providers/<desktop>.sh`. Only `hyprland.sh` exists. To support another compositor, add a provider that defines `provider_apply`, `provider_restore` and `provider_status`.

Modes, one Sunshine app each:
- `mirror`, app `Desktop` (`host.app`): physical outputs mirror `HEADLESS-2` and keep their own modes. Local keyboard and mouse on the host keep working. Workspaces move to `HEADLESS-2` for the session, and the local cursor lives in its coordinate space. A different aspect ratio gives black bars on the host screen.
- `headless`, app `Desktop Headless`: physical outputs stay untouched; the stream is a separate output.

Sunshine keeps an app running when a client disconnects without quitting, and only one app runs at a time. Reconnecting resumes it without running `apply` again, so the display keeps the size of the client that launched it. `remote-desktop` therefore quits any running app before it streams. Other clients must quit it themselves (see Android below).

If kanshi runs on the host, it is stopped during a session, because it would treat `HEADLESS-2` as a profile change. `restore` runs `hyprctl reload`, then starts kanshi again. It also moves workspaces back to their monitors and refocuses the workspace that was active before. Sunshine skips `undo` when it stops with an app running, so the service's `ExecStopPost` also runs `restore`. A lock serializes overlapping runs, and a restore with nothing applied exits 0.

A Hyprland config reload drops the session's monitor rules: `HEADLESS-2` falls back to a default mode and the mirrors end. Hyprland reloads on its own when `nixos-rebuild switch` changes its config, so rebuilding the host mid-session used to change the stream's resolution. `apply` therefore starts the user unit `remote-display-watch`, which waits for Hyprland's `configreloaded` event and runs `remote-display reapply`. That command sets the session's size, fps and scale again, stops kanshi again if the rebuild started it, and recreates `HEADLESS-2` if it is gone. `restore` stops the watcher before its own reload.

Manual recovery on the host: `remote-display status`, `remote-display reapply`, `remote-display restore`. `reapply` also takes `--width`/`--height`, `--fps` and `--scale` to change the running session, for example `remote-display reapply --scale 1.25` for a different DPI. The mode (mirror or headless) stays.

## Usage

```
remote-desktop <host> [mirror|headless] [--resolution WxH] [--fps N] [--backend cage|eglfs]
remote-desktop --list
```

`<host>` is a name from `client.hosts`; shell completion knows them. A host with `commandName` also gets a short command, for example `laptop-remote` for `remote-desktop laptop`. Pair first (see Setup).

### From a TTY

You need no compositor on the client. A graphical session on another VT can keep running.

```sh
# Ctrl+Alt+F3, log in, then
remote-desktop laptop                  # mirror, the host screen shows the stream
remote-desktop laptop headless         # the host screen stays as it is
remote-desktop laptop --fps 120        # if mode detection fell back to 60 fps
remote-desktop laptop --backend eglfs  # Moonlight on KMS directly, no cage: sharpest picture
laptop-remote headless                 # same as remote-desktop laptop headless
```

The command starts cage twice. The first run is brief and only reads the monitor's modes. The second run switches the monitor to its largest, fastest mode (cage alone starts in the preferred mode, often 60 Hz), then runs Moonlight. The screen flickers once between them. cage runs with `-d`: without it, SDL draws its own libdecor frame, which shrinks the picture and leaves bars on the left, right and bottom.

A night light set by a local Hyprland session (hyprsunset) carries over to the TTY with cage: hyprsunset sets the monitor's color matrix (CTM), and cage leaves it alone. eglfs resets it, so with eglfs the command sets it again just before Moonlight starts (`drm-night-light`, hyprsunset's formula on every CRTC's `CTM`). The temperature comes from `client.nightLight`, or from the local hyprsunset when that is null.

Volume keys (and mute, mic mute) change the volume on the client, which plays the stream's audio. Moonlight drops media keys instead of sending them to the host, so `remote-desktop-local-keys` reads the keyboards next to cage and runs `wpctl` on the default sink. With eglfs, where Moonlight reads the keyboards itself, it grabs them and passes everything else to Moonlight through uinput clones, which also keeps Ctrl+Alt+Fn local. Your user needs read access to `/dev/input` (the `input` group).

Switching to another VT stops Moonlight, but not the session. The host keeps its layout and Sunshine keeps the app running. When you come back to the VT, the command reconnects. Ctrl+C on the TTY while it waits ends the session and runs restore.

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

Moonlight runs with `--capture-system-keys always`, so Super combos reach the host's compositor while the stream has focus. In a local compositor, binds marked to bypass the inhibitor still act locally. Volume keys need such a bind, because Moonlight drops media keys: in Hyprland, add `dont_inhibit = true` (the `p` flag) to the volume binds, which this repo's Hyprland config does. Press Ctrl+Alt+Shift+Z to release or recapture keyboard and mouse. The stream uses AV1 with 4:2:0 color. Requesting 4:4:4 from a host whose encoder lacks it made Moonlight fall back to H.264, which looked soft. Override with `extraArgs`, for example `[ "--video-codec" "HEVC" ]`.

With no `WAYLAND_DISPLAY` (an X11 session), cage starts nested as a window. Pass `--backend eglfs` only from a TTY, because eglfs takes over the display.

### During a session

Moonlight shortcuts:
- Ctrl+Alt+Shift+Q: quit. The host goes back to its own layout.
- Ctrl+Alt+Shift+Z: capture or release keyboard and mouse.
- Ctrl+Alt+Shift+X: toggle fullscreen.
- Ctrl+Alt+Shift+S: show stream stats.

Quitting Moonlight (while its VT is active), Ctrl+C in the shell, and closing the terminal all quit the Sunshine app, whose `undo` restores the host. The quit ignores further Ctrl+C until it finishes (at most about 2 min of retries). If the host stays unreachable longer, run `remote-display restore` on it. The command refuses to start when the host is not paired.

### From Android

Install Moonlight (Play Store or F-Droid), add the host by address and pair it (see Pairing). Start `Desktop` or `Desktop Headless`. A Bluetooth keyboard and mouse work; the mouse is captured as relative input. Android or Samsung DeX may keep the Meta key for themselves, so Super binds might not reach the host; DeX has a setting to pass Meta through.

- Pick the resolution in Moonlight's settings. Mirroring the phone's screen to a monitor keeps the phone's aspect ratio (letterboxed); DeX or Android's desktop mode gives the monitor its own resolution.
- Leaving the stream only disconnects: the host stays mirrored at the phone's size. To end the session, long-press the app in Moonlight and choose Quit, or start `remote-desktop` from a NixOS client, which quits it first.
- Moonlight Android's default codec choice is fine. The NixOS client forces AV1, which a phone may not decode in hardware.

## Setup

### Options

```nix
# host
_custom.services.remote-desktop.host = {
  enable = true;
  interfaces = [ "wlan0" ];  # interfaces clients reach the host on, e.g. also "tailscale0"
  # scales."3840x2160" = 1.5;  # scale per client resolution, 1 otherwise
};

# client, one entry per host to control
_custom.services.remote-desktop.client = {
  enable = true;
  # nightLight = 4000;               # eglfs night light, null follows hyprsunset
  hosts = {
    laptop = {
      address = "laptop.local";      # Moonlight host
      commandName = "laptop-remote"; # optional short command
      # maxFps = 120;
      # bitrate = 50000;             # Kbps, null lets Moonlight pick (soft on a desktop)
      # extraArgs = [ "--video-codec" "HEVC" ];
      # app = "Desktop";             # the host's host.app, headless adds " Headless"
    };
    desktop2.address = "192.168.0.20";
  };
};
```

The `.local` names in the examples resolve through avahi; any name or IP works, including a Tailscale address when `tailscale0` is in `host.interfaces`. Sunshine runs as the host user, which must be the one logged in to the graphical session. `remote-display` finds that session through `systemctl --user show-environment`.

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

- No picture or wrong size from the TTY: try `--backend eglfs`, or run the command inside a compositor to rule out cage.
- Wrong mode detected (falls back to 60 fps when cage cannot report it): pass `--resolution` and `--fps`.
- Sunshine logs: `journalctl --user -u sunshine` on the host. The log lists the outputs it sees, and `HEADLESS-2` must be among them during a session. Output of `remote-display apply` and `restore` lands there too, and a failed `apply` fails the launch.
- "An app is already running" from another client: quit the running app from the client that started it, or from any paired client with `moonlight quit <host>`.
- Host left mirrored after a client vanished: `remote-display restore` on the host.
- Stream changed size after a rebuild or config reload on the host: `remote-display reapply` there. Check the watcher with `systemctl --user status remote-display-watch`.
