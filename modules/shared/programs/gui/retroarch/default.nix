{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.retroarch;
  retroarchFinal = with pkgs;
    (unstable.retroarch.override {
      cores = with libretro; [ bsnes genesis-plus-gx beetle-ngp ];
    });
in {
  options._custom.programs.retroarch.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # NOTE: manually download shaders, https://github.com/libretro/slang-shaders
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

