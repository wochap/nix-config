{ config, pkgs, lib, ... }:

let cfg = config._custom.waylandWm;
in {
  imports = [ ./mixins/wayland-tiling.nix ./users ];

  options._custom.waylandWm = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    _displayServer = "wayland";
    _custom.globals.displayServer = "wayland";

    programs.xwayland.enable = true;

    services.xserver = {
      enable = true;
      displayManager.lightdm.enable = false;
    };

  };
}
