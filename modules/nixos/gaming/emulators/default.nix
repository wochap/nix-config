{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.gaming.emulators;

  retroarchFinal = with pkgs;
    (retroarch.override {
      cores = with libretro; [ bsnes genesis-plus-gx beetle-ngp ];
    });
in {
  options._custom.gaming.emulators.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # NOTE: manually download shaders, https://github.com/libretro/slang-shaders
    environment.systemPackages = with pkgs; [
      retroarchFinal
      prevstable-gaming.rpcs3
      prevstable-gaming.lutris
    ];

    services.xserver.desktopManager.retroarch = {
      enable = true;
      package = retroarchFinal;
    };

    _custom.hm = {
      xdg.configFile."retroarch/shaders" = {
        source = "${inputs.retroarch-shaders}";
        recursive = true;
      };
    };
  };
}

