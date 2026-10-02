# NixOS: tinyweb module + host config

Target: current NixOS unstable. Write two files.

## `tinyweb.nix` — a NixOS module

Options under `services.tinyweb`:

| option | type | default |
| --- | --- | --- |
| `enable` | bool | `false` |
| `package` | package | `pkgs.darkhttpd` |
| `sites` | attribute set of sites (below) | `{ }` |

Each `services.tinyweb.sites.<name>` has:

| option | type | default |
| --- | --- | --- |
| `port` | TCP port number (0-65535, anything else is a type error) | none (required) |
| `root` | string | none (required) |
| `index` | string | `"index.html"` |
| `openFirewall` | bool | `false` |

When `services.tinyweb.enable` is true (and only then):

- `package` is in `environment.systemPackages`.
- For every site `<name>` there is a systemd service `tinyweb-<name>` that starts at boot
  (wanted by `multi-user.target`), is ordered after `network.target`, and has these
  `serviceConfig` values:
  - `ExecStart = "<main program of package> <root> --port <port> --index <index>"`, where
    `<main program of package>` is the absolute path of the package's main executable
    (for darkhttpd: `/nix/store/...-darkhttpd-.../bin/darkhttpd`; for `pkgs.hello`: `.../bin/hello`).
  - `DynamicUser = true;`
  - `Restart = "on-failure";`
- The ports of sites with `openFirewall = true` are in `networking.firewall.allowedTCPPorts`
  (ports set by other modules must stay too).
- If two or more sites use the same port, `config.assertions` contains a failing assertion
  whose message contains `tinyweb` and the duplicated port number (e.g. `8081`).

## `host.nix` — a NixOS configuration module

It imports `./tinyweb.nix` and configures:

- Host name `web1`; `system.stateVersion = "26.05"`.
- OpenSSH server enabled; sshd setting `PermitRootLogin` is `"no"`, sshd setting
  `PasswordAuthentication` is `false`.
- Hardware graphics acceleration enabled, including 32-bit support.
- Sound through PipeWire with its ALSA and PulseAudio compatibility layers enabled
  (the standalone PulseAudio server stays disabled).
- Default font packages enabled, plus `pkgs.noto-fonts` installed as a font.
- Nix experimental features exactly `[ "nix-command" "flakes" ]`.
- User `alice`: normal (non-system) user, extra groups `wheel` and `networkmanager`,
  login shell `pkgs.zsh`.
- tinyweb enabled with two sites:
  - `docs`: port `8081`, root `/srv/docs`, firewall opened.
  - `wiki`: port `8082`, root `/srv/wiki`, index `Home.html`, firewall closed.

Do not set boot loader, file systems or `nixpkgs.hostPlatform` in `host.nix`; the tests add them.

## Checks

`tests/test.nix` evaluates `nixpkgs.lib.nixosSystem` (nixpkgs from the flake registry) with
`host.nix` and with `tinyweb.nix` alone plus test configs. Every evaluated system must have
no warnings (`config.warnings == [ ]`) and, unless the test expects one, no failing assertions.
The code must pass `nixfmt --check`, `statix check` and `deadnix --fail`.
