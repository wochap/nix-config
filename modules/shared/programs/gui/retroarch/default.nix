{ config, pkgs, lib, ... }:

let
  cfg = config._custom.gui.retroarch;
  retroarchFinal = with pkgs;
    (unstable.retroarch.override { cores = with libretro; [ bsnes ]; });
in {
  options._custom.gui.retroarch.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = { systemPackages = [ retroarchFinal ]; };

    services.xserver.desktopManager.retroarch = {
      enable = true;
      package = retroarchFinal;
    };

    programs.gamemode = {
      enable = true;
      settings.general.inhibit_screensaver = 0;
    };
  };
}

