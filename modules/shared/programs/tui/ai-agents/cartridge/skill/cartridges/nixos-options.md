# nixos-options cartridge — target: NixOS unstable (26.05+) / home-manager master

## Rules (DON'T → DO)
- DON'T use `fonts.fonts` → DO use `fonts.packages`
- DON'T use `fonts.enableDefaultFonts` → DO use `fonts.enableDefaultPackages`
- DON'T use `hardware.opengl.*` → DO use `hardware.graphics.enable` / `hardware.graphics.enable32Bit`
- DON'T use `sound.enable` (removed) → DO use `services.pipewire.enable` (+ `alsa.enable`, `pulse.enable`)
- DON'T use `hardware.pulseaudio.*` → DO use `services.pulseaudio.*`
- DON'T use `services.xserver.displayManager.gdm/sddm` → DO use `services.displayManager.gdm.enable` / `services.displayManager.sddm.enable`
- DON'T use `services.xserver.desktopManager.gnome` → DO use `services.desktopManager.gnome.enable`
- DON'T use `services.xserver.libinput` → DO use `services.libinput.enable`
- DON'T use `services.xserver.layout` → DO use `services.xserver.xkb.layout`
- DON'T use `services.openssh.permitRootLogin` → DO use `services.openssh.settings.PermitRootLogin`
- DON'T use `services.openssh.passwordAuthentication` → DO use `services.openssh.settings.PasswordAuthentication`
- DON'T use `types.string` (removed) → DO use `types.str` (or `types.lines` for mergeable text)
- DON'T use `with lib;` over a whole module → DO write `lib.mkIf`, `lib.types.str` explicitly
- DON'T use `config.foo` inside `imports` or to decide `options` → DO only read `config` inside `config = ...`
- DON'T put option values at top level when the module has `options` → DO put them under `config = { ... };`
- DON'T use `mkIf` to wrap a whole module including `options` → DO wrap only `config = lib.mkIf cfg.enable { ... };`
- DON'T use HM `programs.zsh.initExtra` → DO use `programs.zsh.initContent` (ordered via `lib.mkOrder`)
- DON'T use HM `programs.git.userName/userEmail` → DO use `programs.git.settings.user.name/email`
- DON'T use HM `programs.neovim.extraLuaConfig` → DO use `programs.neovim.initLua`

## Gotchas
- A module is a function `{ config, lib, pkgs, ... }:` returning `{ imports; options; config; }`. Keep the `...`.
- Without an `options` key, all non-`imports` attrs are treated as `config` (shorthand form).
- "The option `x` does not exist": typo, renamed option, or module not imported (HM option used in NixOS config or vice versa).
- "infinite recursion encountered": usually `config` used in `imports`, or `mkIf` on a value that depends on itself; or `pkgs` used in `imports`.
- "The option `x` has conflicting definition values": two modules set a non-mergeable value; use `lib.mkForce` or `lib.mkDefault`.
- Priority: `mkForce` (50) beats normal (100) beats `mkDefault` (1000) beats option default (1500).
- Lists (systemPackages, extraGroups, allowedTCPPorts) merge across modules; strings of `types.str` do not.
- `environment.systemPackages` is system-wide; `users.users.<n>.packages` is per user; HM uses `home.packages`.
- `nix.settings.experimental-features = [ "nix-command" "flakes" ];` is the current way (not `nix.extraOptions`).
- `nixpkgs.config.allowUnfree = true;` does not apply to `nixpkgs.legacyPackages` in flakes; import nixpkgs with `config` or set it in the NixOS module.
- `system.stateVersion` / `home.stateVersion` = install-time version. Never bump it to "upgrade".
- `systemd.services.<n>.wantedBy = [ "multi-user.target" ];` is required or the service never starts at boot.
- `serviceConfig` keys are systemd names in PascalCase: `ExecStart`, `Restart`, `User`, `DynamicUser`.
- `script = "...";` generates ExecStart for you; do not set both.
- In HM, `home.file."x".source` copies into the store; edits need a rebuild. Use `config.lib.file.mkOutOfStoreSymlink` for a live link.
- HM as NixOS module: set `home-manager.useGlobalPkgs = true;` and `home-manager.useUserPackages = true;`; module args get `osConfig`.
- HM file clashes abort activation; set `home-manager.backupFileExtension = "bak";`.
- Many apps need `programs.<x>.enable` (not just the package) to install wrappers, groups, udev rules (steam, hyprland, zsh, gnupg, nix-ld).

## Correct API names
- `lib.mkEnableOption "foo"` → bool option, default false, description "Whether to enable foo."
- `lib.mkPackageOption pkgs "foo" { }` → package option defaulting to `pkgs.foo`.
- `lib.mkOption { type; default; example; description; }` (no `mkOpt`, no `required`).
- `lib.types`: `str`, `lines`, `bool`, `int`, `port`, `path`, `package`, `enum [ ]`, `nullOr t`, `listOf t`, `attrsOf t`, `submodule { options = { }; }`, `either a b`, `oneOf [ ]`, `anything`.
- `users.users.<n>` → `isNormalUser`, `extraGroups`, `shell`, `hashedPassword`, `openssh.authorizedKeys.keys`.
- `users.groups.<n>`, `security.sudo.wheelNeedsPassword`, `security.rtkit.enable`.
- `networking.firewall.allowedTCPPorts` / `allowedUDPPorts` / `allowedTCPPortRanges`.
- `networking.hostName`, `networking.networkmanager.enable`, `services.resolved.enable`.
- `boot.loader.systemd-boot.enable`, `boot.loader.efi.canTouchEfiVariables`, `boot.kernelPackages`.
- `environment.variables`, `environment.sessionVariables`, `environment.etc."path".text`.
- `systemd.user.services`, `systemd.tmpfiles.rules`, `systemd.timers.<n>.timerConfig`.
- `services.getty.autologinUser`, `services.displayManager.autoLogin.user`.
- `nix.gc.automatic`, `nix.optimise.automatic`, `programs.nix-ld.enable`, `zramSwap.enable`.
- `virtualisation.docker.enable`, `virtualisation.podman.enable`, `hardware.nvidia.open`, `services.xserver.videoDrivers`.
- HM: `home.packages`, `home.file."p".text|source|executable`, `xdg.configFile."app/x".source`, `xdg.dataFile`.
- HM: `home.sessionVariables`, `home.sessionPath`, `home.shellAliases`, `home.activation`, `home.pointerCursor`.
- HM: `programs.home-manager.enable`, `programs.direnv.nix-direnv.enable`, `services.gpg-agent.enable`.

## Idioms
```nix
{ config, lib, pkgs, ... }:
let cfg = config.my.foo; in {
  options.my.foo = {
    enable = lib.mkEnableOption "foo";
    package = lib.mkPackageOption pkgs "foo" { };
    port = lib.mkOption { type = lib.types.port; default = 8080; description = "Port."; };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
```
```nix
systemd.services.foo = {
  wantedBy = [ "multi-user.target" ]; after = [ "network-online.target" ]; wants = [ "network-online.target" ];
  serviceConfig = { ExecStart = "${lib.getExe pkgs.foo} --port 8080"; DynamicUser = true; Restart = "on-failure"; };
};
```
```nix
config = lib.mkMerge [ { a = 1; } (lib.mkIf cfg.x { b = 2; }) ];
```

## Tooling
- Look up options: https://search.nixos.org/options and https://home-manager-options.extranix.com
- `man configuration.nix`, `man home-configuration.nix` (offline option docs)
- `nixos-option services.openssh.enable` shows value, default, declaration
- `nix eval .#nixosConfigurations.host.config.services.openssh.enable`
- `nixos-rebuild build --flake .#host` (test eval/build), `switch`, `boot`, `build-vm`
- `nh os switch .` (if nh is used), `home-manager switch --flake .#user` (standalone HM)
- `nix repl` then `:lf .` and inspect `nixosConfigurations.host.config`
- Add `--show-trace` to see where an eval error comes from
