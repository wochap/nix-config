{ config, pkgs, lib, ... }:

let cfg = config._custom.gui.retroarch;
in {
  options._custom.gui.retroarch = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs;
        [ (retroarch.override { cores = with libretro; [ beetle-ngp ]; }) ];
    };

    programs.gamemode = {
      enable = true;
      settings.general.inhibit_screensaver = 0;
    };
  };
}

