{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config._custom.services.tt;
  ttPackages = inputs.tt.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ./daemon.nix
    ./server.nix
    ./hooks.nix
  ];

  options._custom.services.tt = {
    enable = lib.mkEnableOption "tt task and time tracker";
    package = lib.mkOption {
      type = lib.types.package;
      default = ttPackages.tt;
      description = "Package with the `tt` CLI/daemon and `tt-server`.";
    };
    webPackage = lib.mkOption {
      type = lib.types.package;
      default = ttPackages.tt-web;
      description = "Static web bundle served by `tt-server serve --web-dir`.";
    };
  };

  config = lib.mkIf cfg.enable {
    # On PATH for hooks, quickshell (`tt watch`) and the shell
    _custom.hm.home.packages = [ cfg.package ];
  };
}
