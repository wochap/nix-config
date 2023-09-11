{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  cfg = config._custom.gnome;
in {
  options._custom.gnome = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment.gnome.excludePackages = with pkgs; [ epiphany ];

    services.xserver.displayManager.lightdm.enable = false;
    services.xserver.desktopManager.gnome.enable = true;
    services.gnome.games.enable = false;
  };
}
