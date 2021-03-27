{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        libqalculate # rofi-calc dependency
        rofi-calc
      ];
      etc = {
        "powermenu.sh" = {
          source = ./scripts/powermenu.sh;
          mode = "0755";
        };
        "powermenu.rasi" = {
          source = ./dotfiles/powermenu.rasi;
          mode = "0755";
        };
      };
    };
    home-manager.users.gean = {
      programs.rofi.enable = true;
    };
  };
}
