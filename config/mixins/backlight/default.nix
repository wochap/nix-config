{ config, pkgs, lib, inputs, ... }:

{
  config = {
    programs.light.enable = true;

    environment = {
      systemPackages = with pkgs; [ brightnessctl ];

      etc = {
        "scripts/backlight.sh" = {
          source = ./scripts/backlight.sh;
          mode = "0755";
        };
      };
    };
  };
}
