{ config, pkgs, lib, ... }:

let cfg = config._custom.xorgWm;
in {
  imports = [ ./mixins/pkgs-xorg.nix ./users ];

  options._custom.xorgWm = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    _displayServer = "xorg";
    _custom.globals.displayServer = "xorg";
  };
}