{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      etc = {

        "scripts/system/sway-lock.sh" = {
          source = ./scripts/sway-lock.sh;
          mode = "0755";
        };
        "scripts/system/clipboard-manager.sh" = {
          source = ./scripts/clipboard-manager.sh;
          mode = "0755";
        };
        "scripts/system/color-picker.sh" = {
          source = ./scripts/color-picker.sh;
          mode = "0755";
        };
        "scripts/system/takeshot.sh" = {
          source = ./scripts/takeshot.sh;
          mode = "0755";
        };
        "scripts/system/recorder.sh" = {
          source = ./scripts/recorder.sh;
          mode = "0755";
        };
      };
    };
  };
}

