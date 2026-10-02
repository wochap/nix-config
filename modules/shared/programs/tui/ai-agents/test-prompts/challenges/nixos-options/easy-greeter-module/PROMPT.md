# NixOS module: services.greeter

Write `module.nix`, a NixOS module (current NixOS unstable) that declares these options:

| option | type | default |
| --- | --- | --- |
| `services.greeter.enable` | bool | `false`; description exactly `"Whether to enable the greeter service."` |
| `services.greeter.port` | TCP port number (0-65535; anything else is a type error) | `8080` |
| `services.greeter.message` | string | `"Hello"` |
| `services.greeter.openFirewall` | bool | `false` |

When `services.greeter.enable` is true, and only then:

- `/etc/greeter.conf` exists with exactly this text (note the trailing newline):
  ```
  port=<port>
  message=<message>
  ```
- If `openFirewall` is true, `<port>` is added to `networking.firewall.allowedTCPPorts`
  (other modules can add ports too; all of them must stay in the list).

When disabled, the module must not change any other option.
Evaluating a system that imports the module must produce no warnings (`config.warnings == [ ]`).

Tests (`tests/test.nix`) evaluate `nixpkgs.lib.nixosSystem` (nixpkgs from the flake registry)
with your module plus small test configs, e.g.:

```nix
{ services.greeter = { enable = true; port = 9000; message = "Hi"; openFirewall = true; }; }
# => config.environment.etc."greeter.conf".text == "port=9000\nmessage=Hi\n"
# => config.networking.firewall.allowedTCPPorts contains 9000
```

The code must pass `nixfmt --check`, `statix check` and `deadnix --fail`.
