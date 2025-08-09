{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.gaming.emulators;

  retroarch-final = pkgs.retroarch.withCores
    (cores: with cores; [ bsnes genesis-plus-gx beetle-ngp ]);
in {
  options._custom.gaming.emulators.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # NOTE: manually download shaders, https://github.com/libretro/slang-shaders
    environment.systemPackages = with pkgs; [
      retroarch-final
      prevstable-gaming.rpcs3
      prevstable-gaming.lutris
    ];

    services.xserver.desktopManager.retroarch = {
      enable = true;
      package = retroarch-final;
    };

    _custom.hm = {
      xdg.configFile = lib._custom.linkContents "retroarch/shaders"
        "${inputs.retroarch-shaders}";
    };
  };
}

