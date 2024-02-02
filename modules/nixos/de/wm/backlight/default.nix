{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.wm.backlight;
in {
  options._custom.wm.backlight.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ brightnessctl ];

      etc = {
        "scripts/backlight.sh" = {
          source = ./scripts/backlight.sh;
          mode = "0755";
        };
        "scripts/kbd-backlight.sh" = {
          source = ./scripts/kbd-backlight.sh;
          mode = "0755";
        };
      };
    };
  };
}
