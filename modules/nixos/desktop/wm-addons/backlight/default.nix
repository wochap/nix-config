{ config, pkgs, lib, ... }:

let cfg = config._custom.de.backlight;
in {
  options._custom.de.backlight.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        brightnessctl
        (writeScriptBin "backlight" (builtins.readFile ./scripts/backlight.sh))
        (writeScriptBin "kbd-backlight"
          (builtins.readFile ./scripts/kbd-backlight.sh))
      ];
    };
  };
}
