{ config, pkgs, lib, ... }:

let
  customThunar = pkgs.xfce.thunar.override {
    thunarPlugins = [ pkgs.xfce.thunar-archive-plugin ];
  };
  userName = config._userName;
in {
  config = {
    environment = {
      systemPackages = with pkgs; [
        xfce.thunar-volman # auto mont devices
        customThunar
      ];
    };

    # Systemd services
    systemd.packages = [ customThunar ];

    home-manager.users.${userName} = {
      xdg.configFile = {
        "Thunar/uca.xml".source = ./dotfiles/Thunar/uca.xml;
      };
    };
  };
}

