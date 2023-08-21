{ config, pkgs, lib, inputs, ... }:

{
  config = {
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
